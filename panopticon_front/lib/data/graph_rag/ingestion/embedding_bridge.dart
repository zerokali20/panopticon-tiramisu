// ============================================================
// panopticon/data/graph_rag/ingestion/embedding_bridge.dart
//
// Abstract interface and stub for the on-device text embedding model.
//
// The actual implementation connects to the ONNX / TFLite / llama.cpp
// inference runtime via Dart FFI or a platform channel.  This file
// provides the contract and a deterministic stub used for:
//   • Unit testing without a loaded model.
//   • UI-layer development before the LLM team delivers the binary.
//
// Zero-egress guarantee: no HTTP calls, no external libraries beyond
// the local FFI bridge.  The stub generates pseudo-random but
// deterministic vectors seeded by the text hash.
// ============================================================

import 'dart:math' as math;
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../objectbox/document_chunk.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Contract for any on-device text embedding provider.
///
/// Implementations may wrap:
///   • A TFLite delegate (CPU / NNAPI / GPU)
///   • An ONNX Runtime session (ort_flutter)
///   • A llama.cpp embedding endpoint via Dart FFI
abstract class EmbeddingBridge {
  const EmbeddingBridge();

  /// Number of float dimensions this model outputs.
  int get dimensions;

  /// Name of the underlying model, for diagnostic logging.
  String get modelName;

  /// Embeds [text] and returns a float vector of length [dimensions].
  ///
  /// Must NOT block the UI thread.  Implementations should run inference
  /// on a background isolate or a platform thread and return a [Future].
  Future<List<double>> embed(String text);

  /// Batch-embeds all texts and returns vectors in the same order.
  ///
  /// Default implementation calls [embed] sequentially; override for
  /// batch-optimised inference (e.g., TFLite batch mode).
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    final results = <List<double>>[];
    for (final text in texts) {
      results.add(await embed(text));
    }
    return results;
  }

  /// Embeds each [DocumentChunk.textContent] in [chunks], fills in the
  /// [DocumentChunk.embedding] field, and returns the modified list.
  ///
  /// The original list objects are mutated in-place and also returned
  /// for chaining convenience.
  Future<List<DocumentChunk>> embedChunks(
    List<DocumentChunk> chunks,
  ) async {
    final texts = chunks.map((c) => c.textContent).toList();
    final vectors = await embedBatch(texts);

    for (var i = 0; i < chunks.length; i++) {
      chunks[i].embedding = vectors[i];
    }
    return chunks;
  }
}

// ---------------------------------------------------------------------------
// Deterministic stub — used until the real FFI bridge is wired up
// ---------------------------------------------------------------------------

/// A deterministic, pseudo-random embedding stub.
///
/// Given identical input text, this stub always returns the same vector,
/// making it safe to use in unit tests and UI previews.  The vectors are
/// seeded from the SHA-256 hash of the input text and are L2-normalised
/// to simulate the output of a sentence-transformer model.
///
/// ⚠ Replace with [OnnxEmbeddingBridge] or [TFLiteEmbeddingBridge] once
///   the on-device model is integrated.
class DeterministicStubEmbeddingBridge extends EmbeddingBridge {
  @override
  final int dimensions;

  @override
  String get modelName => 'DeterministicStub-${dimensions}d';

  const DeterministicStubEmbeddingBridge({this.dimensions = 384});

  @override
  Future<List<double>> embed(String text) async {
    // Derive a deterministic seed from the text content.
    final hash = sha256.convert(utf8.encode(text));
    final seedBytes = hash.bytes;

    // Build a pseudo-random vector from the hash bytes.
    final rng = _SeededRandom(seedBytes);
    final raw = List.generate(dimensions, (_) => rng.nextDouble() * 2 - 1);

    // L2-normalise to unit sphere (mimics sentence-transformer output).
    return _l2Normalise(raw);
  }

  List<double> _l2Normalise(List<double> vec) {
    final norm =
        math.sqrt(vec.fold(0.0, (sum, v) => sum + v * v));
    if (norm == 0.0) return List.filled(vec.length, 0.0);
    return vec.map((v) => v / norm).toList(growable: false);
  }
}

/// Minimal linear-congruential generator seeded from a byte array.
class _SeededRandom {
  int _state;

  _SeededRandom(List<int> seedBytes)
      : _state = seedBytes.fold(0, (acc, b) => acc * 31 + b);

  double nextDouble() {
    _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_state & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}

// ---------------------------------------------------------------------------
// Placeholder for the real ONNX bridge (to be implemented by LLM team)
// ---------------------------------------------------------------------------

/// Placeholder for the real ONNX Runtime embedding bridge.
///
/// The LLM team should implement this class using the `ort_flutter` package
/// (or equivalent Dart FFI wrapper) targeting the quantised MiniLM model.
///
/// Contract:
///   • Must operate without any network access.
///   • Should run on a background Dart isolate to avoid jank.
///   • Must output L2-normalised vectors of [dimensions] floats.
class OnnxEmbeddingBridge extends EmbeddingBridge {
  @override
  final int dimensions;

  @override
  String get modelName => 'all-MiniLM-L6-v2-int8';

  /// Path to the quantised ONNX model file inside the app's assets or
  /// documents directory.
  final String modelPath;

  OnnxEmbeddingBridge({
    required this.modelPath,
    this.dimensions = 384,
  });

  @override
  Future<List<double>> embed(String text) {
    // TODO(llm-team): Implement ONNX Runtime inference via FFI.
    // Steps:
    //   1. Tokenise [text] using the bundled tokeniser vocab.
    //   2. Run forward pass through the ONNX session.
    //   3. Mean-pool the token embeddings.
    //   4. L2-normalise the result.
    //   5. Return as List<double>.
    throw UnimplementedError(
      'OnnxEmbeddingBridge.embed() requires the ONNX runtime FFI bridge. '
      'Use DeterministicStubEmbeddingBridge for development.',
    );
  }
}
