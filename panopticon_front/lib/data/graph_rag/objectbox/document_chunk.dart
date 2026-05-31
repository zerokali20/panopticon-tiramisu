// ============================================================
// panopticon/data/graph_rag/objectbox/document_chunk.dart
//
// ObjectBox entity definition for the semantic vector store.
//
// Required pubspec.yaml additions:
// dependencies:
//   objectbox: ^4.0.0
//   objectbox_flutter_libs: ^4.0.0    # includes the native .so/.dylib
//
// dev_dependencies:
//   build_runner: ^2.4.0
//   objectbox_generator: ^4.0.0
//
// Code-generation step (run once after any schema change):
//   dart run build_runner build --delete-conflicting-outputs
// ============================================================

import 'package:objectbox/objectbox.dart';

// ---------------------------------------------------------------------------
// Source type enumeration stored as a plain int in ObjectBox.
// ---------------------------------------------------------------------------

/// Identifies the origin of a text chunk stored in the vector store.
/// Stored as [int] to align with ObjectBox's primitive-only field types.
class DocumentSourceType {
  static const int email = 0;
  static const int sms = 1;
  static const int calendarEvent = 2;
  static const int contactNote = 3;
  static const int corporateNotice = 4;
  static const int fraudAdvisory = 5;
  static const int webClipping = 6;

  static String label(int type) => switch (type) {
        email => 'Email',
        sms => 'SMS',
        calendarEvent => 'Calendar Event',
        contactNote => 'Contact Note',
        corporateNotice => 'Corporate Notice',
        fraudAdvisory => 'Fraud Advisory',
        webClipping => 'Web Clipping',
        _ => 'Unknown',
      };
}

// ---------------------------------------------------------------------------
// ObjectBox entity — the leaf node of the vector store.
// ---------------------------------------------------------------------------

/// A single text chunk stored in ObjectBox alongside its embedding vector.
///
/// Documents are chunked BEFORE insertion (see [DocumentChunkingPipeline])
/// using a sliding-window strategy.  Each chunk is independently embedded
/// and retrievable via nearest-neighbour search.
///
/// Design decisions:
///   • [embedding] uses [HnswIndex] (HNSW algorithm) for sub-millisecond
///     approximate nearest-neighbour lookup on-device.
///   • [sourceDocumentId] allows linking chunks back to the parent doc
///     without fetching the full text.
///   • [chunkIndex] preserves reading order for context reconstruction.
///   • [ingestionTimestampMs] supports future TTL-based eviction.
@Entity()
class DocumentChunk {
  /// ObjectBox internal ID (auto-assigned).
  @Id()
  int id;

  // ── Provenance ────────────────────────────────────────────────

  /// Stable identifier of the parent document (SHA-256 hash or UUID).
  final String sourceDocumentId;

  /// One of the [DocumentSourceType] int constants.
  final int sourceType;

  /// Optional human-readable title, e.g. "Commercial Bank – Phishing Alert".
  final String? sourceTitle;

  // ── Content ──────────────────────────────────────────────────

  /// The raw text of this chunk (up to ~512 tokens of source text).
  final String textContent;

  /// Zero-based ordinal within the parent document.
  /// Allows reassembly of adjacent chunks for prompt injection.
  final int chunkIndex;

  /// Total number of chunks the parent document was split into.
  final int totalChunks;

  // ── Vector Embedding ─────────────────────────────────────────

  /// Floating-point embedding vector produced by the on-device model.
  ///
  /// Dimensions must match the embedding model exactly:
  ///   • all-MiniLM-L6-v2  →  384 dimensions
  ///   • BERT-mini          →  256 dimensions
  ///
  /// [HnswIndex] configures ObjectBox to build an in-memory HNSW graph
  /// over this property for approximate nearest-neighbour search.
  ///
  /// [distanceType]: DistanceType.cosine is preferred for normalised
  /// sentence embeddings.  Switch to euclidean if your model outputs
  /// un-normalised vectors.
  @HnswIndex(
    dimensions: 384, // ← adjust to match your embedding model output
    distanceType: VectorDistanceType.cosine,
    neighborsPerNode: 32, // M parameter — higher = better recall, more RAM
    indexingSearchCount: 200, // ef_construction — trade-off: speed vs quality
  )
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  // ── Metadata ─────────────────────────────────────────────────

  /// Unix epoch milliseconds of ingestion.  Used for relevance decay.
  final int ingestionTimestampMs;

  /// Optional JSON blob for arbitrary key-value metadata.
  /// Example: {"sender": "fraud@bank.lk", "subject": "Security Notice"}
  final String? metadataJson;

  // ── Constructor ───────────────────────────────────────────────

  DocumentChunk({
    this.id = 0, // ObjectBox assigns the real id on put()
    required this.sourceDocumentId,
    required this.sourceType,
    required this.textContent,
    required this.chunkIndex,
    required this.totalChunks,
    required this.ingestionTimestampMs,
    this.sourceTitle,
    this.embedding,
    this.metadataJson,
  });

  // ── Convenience Factories ──────────────────────────────────────

  /// Creates a [DocumentChunk] from a raw text block before embedding.
  /// The [embedding] field is left null and must be filled by the
  /// embedding pipeline before the entity is written to ObjectBox.
  factory DocumentChunk.fromText({
    required String sourceDocumentId,
    required int sourceType,
    required String textContent,
    required int chunkIndex,
    required int totalChunks,
    String? sourceTitle,
    String? metadataJson,
  }) =>
      DocumentChunk(
        sourceDocumentId: sourceDocumentId,
        sourceType: sourceType,
        textContent: textContent,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        ingestionTimestampMs: DateTime.now().millisecondsSinceEpoch,
        sourceTitle: sourceTitle,
        metadataJson: metadataJson,
      );

  @override
  String toString() =>
      'DocumentChunk(id=$id, src=$sourceDocumentId, '
      'chunk=$chunkIndex/$totalChunks, '
      'type=${DocumentSourceType.label(sourceType)})';
}
