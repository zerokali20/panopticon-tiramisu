// ============================================================
// panopticon/data/graph_rag/ingestion/document_chunking_pipeline.dart
//
// On-device text chunking pipeline.
//
// Takes a raw text document, splits it into overlapping chunks
// using a sliding window, and returns [DocumentChunk] objects
// ready for embedding.  Embedding is NOT performed here — this
// is the job of the EmbeddingBridge (see embedding_bridge.dart).
//
// Design:
//   • Chunk size and overlap are tunable per source type.
//   • Chunks preserve sentence boundaries where possible to
//     maximise embedding quality.
//   • Zero network I/O — purely in-process text processing.
// ============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../objectbox/document_chunk.dart';

/// Configuration for the sliding-window chunker.
class ChunkingConfig {
  /// Target number of characters per chunk (soft limit).
  final int targetChunkSize;

  /// Number of overlapping characters between adjacent chunks.
  /// Must be < [targetChunkSize].
  final int overlapSize;

  /// Minimum chunk size to emit (avoids tiny trailing fragments).
  final int minChunkSize;

  const ChunkingConfig({
    this.targetChunkSize = 1200,
    this.overlapSize = 200,
    this.minChunkSize = 100,
  });

  /// Conservative preset for short SMS/notification text.
  static const sms = ChunkingConfig(
    targetChunkSize: 400,
    overlapSize: 50,
    minChunkSize: 30,
  );

  /// Standard preset for emails and corporate notices.
  static const email = ChunkingConfig(
    targetChunkSize: 1200,
    overlapSize: 200,
    minChunkSize: 100,
  );

  /// Aggressive overlap for fraud advisory documents where every
  /// sentence can be a standalone claim worth matching.
  static const fraudAdvisory = ChunkingConfig(
    targetChunkSize: 800,
    overlapSize: 300,
    minChunkSize: 80,
  );
}

/// Splits a source document into embedding-ready [DocumentChunk]s.
class DocumentChunkingPipeline {
  final ChunkingConfig config;

  const DocumentChunkingPipeline({
    this.config = const ChunkingConfig(),
  });

  // ── Public API ────────────────────────────────────────────────

  /// Chunks [rawText] and returns a list of [DocumentChunk]s with
  /// [embedding] == null.  Pass the result to [EmbeddingBridge] to
  /// fill in the embedding vectors before writing to ObjectBox.
  ///
  /// Parameters:
  ///   [rawText]          – Full source document text.
  ///   [sourceType]       – One of [DocumentSourceType] int constants.
  ///   [sourceTitle]      – Optional human-readable title.
  ///   [metadataJson]     – Optional JSON string for additional context.
  ///   [sourceDocumentId] – If null, computed as SHA-256 of [rawText].
  List<DocumentChunk> chunk({
    required String rawText,
    required int sourceType,
    String? sourceTitle,
    String? metadataJson,
    String? sourceDocumentId,
  }) {
    final docId = sourceDocumentId ?? _sha256Id(rawText);
    final cleanText = _preprocess(rawText);
    final windows = _slidingWindowChunk(cleanText);

    return List.generate(windows.length, (i) {
      return DocumentChunk.fromText(
        sourceDocumentId: docId,
        sourceType: sourceType,
        textContent: windows[i],
        chunkIndex: i,
        totalChunks: windows.length,
        sourceTitle: sourceTitle,
        metadataJson: metadataJson,
      );
    });
  }

  // ── Private Helpers ──────────────────────────────────────────

  /// Cleans whitespace and normalises line endings.
  String _preprocess(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Splits text using a sentence-boundary-aware sliding window.
  ///
  /// Strategy:
  ///   1. Prefer to break on sentence boundaries ('. ', '! ', '? ').
  ///   2. Fall back to word boundaries if no sentence boundary is found
  ///      within the target window.
  ///   3. Apply overlap by re-including the tail of the previous chunk.
  List<String> _slidingWindowChunk(String text) {
    if (text.length <= config.targetChunkSize) {
      return [text];
    }

    final chunks = <String>[];
    int start = 0;

    while (start < text.length) {
      final end = (start + config.targetChunkSize).clamp(0, text.length);
      int splitAt = end;

      // Only search for boundaries if we haven't reached the end of the document
      if (end < text.length) {
        splitAt = _findSentenceBoundary(text, start, end);
        if (splitAt == -1) {
          splitAt = _findWordBoundary(text, start, end);
        }
        if (splitAt == -1 || splitAt <= start) {
          splitAt = end;
        }
      }

      final chunk = text.substring(start, splitAt).trim();
      if (chunk.length >= config.minChunkSize) {
        chunks.add(chunk);
      }

      // If we've consumed all the text, break to prevent infinite loops
      if (splitAt >= text.length) {
        break;
      }

      final prevStart = start;
      // Advance start, stepping back by [overlapSize] for the next window.
      start = (splitAt - config.overlapSize).clamp(0, text.length);

      // Safety: MUST force forward progress to prevent infinite OOM loops.
      // If the extracted chunk was smaller than the overlap size, stepping back
      // would cause us to go backwards. In this case, use zero overlap.
      if (start <= prevStart) {
        start = splitAt;
      }
    }

    return chunks;
  }

  /// Finds the latest sentence boundary ('.', '!', '?') before [end].
  int _findSentenceBoundary(String text, int start, int end) {
    final sentenceEnders = RegExp(r'[.!?]\s');
    final sub = text.substring(start, end);
    final match = sentenceEnders.allMatches(sub).lastOrNull;
    return match != null ? start + match.end : -1;
  }

  /// Finds the latest whitespace character before [end].
  int _findWordBoundary(String text, int start, int end) {
    for (int i = end - 1; i > start; i--) {
      if (text[i] == ' ' || text[i] == '\n') return i;
    }
    return -1;
  }

  /// Computes a stable SHA-256 document ID from the raw text.
  String _sha256Id(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // first 64 bits, URL-safe
  }
}
