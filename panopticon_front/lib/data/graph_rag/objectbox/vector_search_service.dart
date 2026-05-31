// ============================================================
// panopticon/data/graph_rag/objectbox/vector_search_service.dart
//
// Thin service layer over ObjectBox vector search.
//
// Responsibilities:
//   • Perform approximate nearest-neighbour (ANN) search using
//     the HNSW index on DocumentChunk.embedding.
//   • Return ranked [SemanticSearchResult] objects for consumption
//     by the ContextRetrievalService.
//   • Never perform network I/O — all embeddings are generated
//     on-device by the local embedding model.
// ============================================================


import 'document_chunk.dart';
import 'objectbox_store.dart';
import '../../../objectbox.g.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

/// A single hit returned by the vector ANN search.
class SemanticSearchResult {
  /// The matched [DocumentChunk] entity.
  final DocumentChunk chunk;

  /// Cosine similarity score in [0, 1] (higher = more similar).
  /// Derived from the raw ObjectBox distance: score = 1 - distance.
  final double score;

  const SemanticSearchResult({required this.chunk, required this.score});

  @override
  String toString() =>
      'SemanticSearchResult(score=${score.toStringAsFixed(4)}, '
      'src=${chunk.sourceDocumentId}[${chunk.chunkIndex}])';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Executes semantic nearest-neighbour searches over the ObjectBox store.
///
/// Requires that [ObjectBoxStore.instance] has been initialised before use.
class VectorSearchService {
  final ObjectBoxStore _store;

  VectorSearchService(this._store);

  /// Factory constructor for async initialisation.
  static Future<VectorSearchService> create() async {
    final store = await ObjectBoxStore.instance;
    return VectorSearchService(store);
  }

  // ── Core Search ────────────────────────────────────────────────

  /// Returns the [topK] most semantically similar [DocumentChunk]s for
  /// the given [queryEmbedding] vector.
  ///
  /// Parameters:
  ///   [queryEmbedding]  – Float vector produced by the on-device model.
  ///                       Must have the same dimensionality as stored chunks.
  ///   [topK]            – Maximum number of results to return (default 5).
  ///   [scoreThreshold]  – Minimum cosine similarity to include in results.
  ///                       Chunks below this threshold are filtered out.
  ///   [sourceTypeFilter] – Optional [DocumentSourceType] int to narrow
  ///                        the search to a specific document category.
  ///
  /// Returns results sorted by descending similarity score.
  Future<List<SemanticSearchResult>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    double scoreThreshold = 0.30,
    int? sourceTypeFilter,
  }) async {
    final box = _store.documentChunkBox;

    // Build the HNSW nearest-neighbour condition.
    final nnCondition = DocumentChunk_.embedding.nearestNeighborsF32(
      queryEmbedding,
      topK,
    );

    // Combine with optional source-type filter using ObjectBox's & operator.
    final condition = sourceTypeFilter != null
        ? nnCondition & DocumentChunk_.sourceType.equals(sourceTypeFilter)
        : nnCondition;

    // .findWithScores() returns pairs of [entity, distance].
    // For cosine distance: similarity = 1 - distance.
    final rawResults = box.query(condition).build().findWithScores();

    final results = rawResults
        .map(
          (pair) => SemanticSearchResult(
            chunk: pair.object,
            score: 1.0 - pair.score, // convert cosine distance → similarity
          ),
        )
        .where((r) => r.score >= scoreThreshold)
        .toList();

    // Sort descending by score (findWithScores returns ascending distance).
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  // ── Write Operations ──────────────────────────────────────────

  /// Inserts a single [DocumentChunk] with its embedding into the store.
  ///
  /// Throws [ArgumentError] if the chunk's [embedding] is null.
  int putChunk(DocumentChunk chunk) {
    if (chunk.embedding == null || chunk.embedding!.isEmpty) {
      throw ArgumentError(
        'DocumentChunk must have a non-null embedding before insertion. '
        'Run the embedding model first.',
      );
    }
    return _store.documentChunkBox.put(chunk);
  }

  /// Batch-inserts a list of embedding-ready [DocumentChunk]s.
  ///
  /// Wrapped in a single ObjectBox transaction for performance.
  List<int> putChunks(List<DocumentChunk> chunks) {
    for (final chunk in chunks) {
      if (chunk.embedding == null || chunk.embedding!.isEmpty) {
        throw ArgumentError(
          'All DocumentChunks must have embeddings. '
          'Chunk index ${chunk.chunkIndex} of document '
          '${chunk.sourceDocumentId} is missing one.',
        );
      }
    }
    return _store.documentChunkBox.putMany(chunks);
  }

  /// Removes all chunks belonging to [sourceDocumentId].
  /// Call this when a source document is updated or revoked.
  int removeBySourceDocument(String sourceDocumentId) {
    final box = _store.documentChunkBox;
    final query = box
        .query(DocumentChunk_.sourceDocumentId.equals(sourceDocumentId))
        .build();
    final ids = query.findIds();
    query.close();
    return box.removeMany(ids);
  }

  /// Returns the total number of chunks currently in the store.
  int get chunkCount => _store.documentChunkBox.count();
}
