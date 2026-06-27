// ============================================================
// panopticon/data/graph_rag/services/context_retrieval_service.dart
//
// THE BRIDGE — Unified hybrid query orchestrator.
//
// This is the single entry point that the Sentry Agent and
// Context Agent call during a live call.  It fans out queries
// to both the ObjectBox vector engine and the SQLite graph
// engine CONCURRENTLY using Dart's Future.wait(), then
// consolidates both results into a [DiscrepancyReport] with a
// pre-formatted [llmContextString] ready for prompt injection.
//
// Architecture invariants:
//   • ZERO network I/O — no HTTP clients, no sockets.
//   • The volatile call transcript (live ASR tokens) is passed
//     in only via method parameters; it is never written to disk.
//   • All write operations on the graph (seeding) are separate
//     from the hot-path read operations called here.
// ============================================================

import 'dart:async';

import '../db/panopticon_database.dart';
import '../models/graph_query_result.dart';
import '../objectbox/vector_search_service.dart';
import '../ingestion/embedding_bridge.dart';
import 'discrepancy_report.dart';

/// Query parameters extracted from live call metadata and ASR transcript.
///
/// These fields are the ONLY runtime data structures that touch
/// call content — they live purely in RAM and are never persisted.
class CallQueryParams {
  /// Raw phone number from the incoming call (any format).
  final String rawPhoneNumber;

  /// Institution name claimed verbally by the caller.
  /// Extracted from the live ASR transcript by the Sentry Agent.
  final String institutionClaimed;

  /// The relevant semantic claim text from the live transcript.
  /// Used to query the vector store for matching truth documents.
  /// Example: "your credit card has been frozen, confirm your OTP".
  final String semanticClaimText;

  /// Optional: limit vector search to a specific source type.
  /// Null means search across all document categories.
  final int? vectorSourceTypeFilter;

  /// Maximum semantic results to retrieve (default 5).
  final int topKVector;

  const CallQueryParams({
    required this.rawPhoneNumber,
    required this.institutionClaimed,
    required this.semanticClaimText,
    this.vectorSourceTypeFilter,
    this.topKVector = 5,
  });
}

// ---------------------------------------------------------------------------
// The Service
// ---------------------------------------------------------------------------

/// Hybrid GraphRAG query orchestrator.
///
/// Performs a PARALLEL dual-engine lookup:
///   • SQLite Relational Graph  → structural identity verification
///   • ObjectBox Vector Store   → semantic truth document retrieval
///
/// Both queries execute concurrently via [Future.wait].  The service then
/// applies a deterministic risk-fusion algorithm and returns a single
/// [DiscrepancyReport] ready for consumption by the UI and LLM layers.
///
/// Usage:
/// ```dart
/// final service = await ContextRetrievalService.create(
///   embeddingBridge: DeterministicStubEmbeddingBridge(),
/// );
///
/// final report = await service.query(CallQueryParams(
///   rawPhoneNumber: '+94112345678',
///   institutionClaimed: 'Commercial Bank',
///   semanticClaimText: 'Your card has been frozen. Confirm your OTP.',
/// ));
///
/// // Inject into LLM prompt:
/// final prompt = '${report.llmContextString}\n\nUser: <transcript>';
///
/// // Push to UI stream:
/// _reportController.add(report);
/// ```
class ContextRetrievalService {
  final PanopticonDatabase _graphDb;
  final VectorSearchService _vectorService;
  final EmbeddingBridge _embeddingBridge;

  // Stream controller that broadcasts live DiscrepancyReports to the UI.
  final StreamController<DiscrepancyReport> _reportController =
      StreamController<DiscrepancyReport>.broadcast();

  ContextRetrievalService._({
    required PanopticonDatabase graphDb,
    required VectorSearchService vectorService,
    required EmbeddingBridge embeddingBridge,
  })  : _graphDb = graphDb,
        _vectorService = vectorService,
        _embeddingBridge = embeddingBridge;

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Creates and initialises all engine dependencies asynchronously.
  ///
  /// [embeddingBridge] defaults to the deterministic stub; replace with
  /// [OnnxEmbeddingBridge] when the model is available.
  static Future<ContextRetrievalService> create({
    EmbeddingBridge? embeddingBridge,
  }) async {
    final vectorService = await VectorSearchService.create();

    return ContextRetrievalService._(
      graphDb: PanopticonDatabase.instance,
      vectorService: vectorService,
      embeddingBridge:
          embeddingBridge ?? const DeterministicStubEmbeddingBridge(),
    );
  }

  // ── Public API ────────────────────────────────────────────────

  /// Broadcasts all [DiscrepancyReport]s produced by [query] calls.
  ///
  /// The Flutter UI team should listen to this stream to update the
  /// Reasoning Tree overlay in real time:
  /// ```dart
  /// service.reports.listen((report) {
  ///   setState(() => _latestReport = report);
  /// });
  /// ```
  Stream<DiscrepancyReport> get reports => _reportController.stream;

  /// ════════════════════════════════════════════════════════════════
  ///  PRIMARY HOT-PATH METHOD
  /// ════════════════════════════════════════════════════════════════
  ///
  /// Executes a parallel dual-engine verification for an in-progress call.
  ///
  /// The method:
  ///   1. Embeds [params.semanticClaimText] using the on-device model.
  ///   2. Fans out CONCURRENTLY to:
  ///        a. [GraphDao.verifyIncomingMetadata] (SQLite)
  ///        b. [VectorSearchService.search]     (ObjectBox HNSW)
  ///   3. Fuses both results into a [RiskLevel] using the hybrid
  ///      risk-fusion algorithm.
  ///   4. Formats a plain-text [llmContextString] for prompt injection.
  ///   5. Emits the [DiscrepancyReport] on the [reports] stream.
  ///   6. Returns the report synchronously to the awaiting caller.
  ///
  /// Parameters:
  ///   [params] — runtime query parameters extracted from the live call.
  ///              These MUST NOT be persisted anywhere.
  ///
  /// This method is designed to complete in < 50 ms on a mid-range
  /// Android device when both stores are properly indexed.
  Future<DiscrepancyReport> query(CallQueryParams params) async {
    // ── Step 1: Embed the semantic claim text (needed for vector search) ──
    // Run embedding on the claim text concurrently while setting up the
    // graph query (embedding is typically the slowest step).
    final embeddingFuture =
        _embeddingBridge.embed(params.semanticClaimText);

    // ── Step 2: Fan-out parallel engine queries ────────────────────────
    // Both futures are fired BEFORE awaiting either one, achieving
    // maximum concurrency on mobile hardware.
    final graphFuture = _graphDb.graphDao.verifyIncomingMetadata(
      params.rawPhoneNumber,
      params.institutionClaimed,
    );

    // We await the embedding before the vector search because the search
    // requires the embedding vector as input.
    final queryVector = await embeddingFuture;

    final vectorFuture = _vectorService.search(
      queryVector,
      topK: params.topKVector,
      sourceTypeFilter: params.vectorSourceTypeFilter,
    );

    // ── Step 3: Await both engine results concurrently ─────────────────
    final results = await Future.wait<Object>([
      graphFuture,
      vectorFuture,
    ]);

    final graphResult = results[0] as GraphVerificationResult;
    final vectorResults = results[1] as List<SemanticSearchResult>;

    // ── Step 4: Risk fusion ────────────────────────────────────────────
    final (riskLevel, rationale) = _fuseRisk(graphResult, vectorResults);

    // ── Step 5: Format LLM context string ─────────────────────────────
    final contextString = _formatLlmContext(
      params: params,
      graphResult: graphResult,
      vectorResults: vectorResults,
      riskLevel: riskLevel,
    );

    // ── Step 6: Assemble and emit the report ───────────────────────────
    final report = DiscrepancyReport(
      graphResult: graphResult,
      vectorResults: vectorResults,
      riskLevel: riskLevel,
      riskRationale: rationale,
      generatedAt: DateTime.now().toIso8601String(),
      llmContextString: contextString,
    );

    _reportController.add(report);
    return report;
  }

  // ── Risk Fusion Algorithm ─────────────────────────────────────

  /// Combines the graph and vector engine outputs into a single
  /// [RiskLevel] using a deterministic rule table.
  ///
  /// Rule table (priority order):
  ///   1. Graph: impersonation detected           → HIGH (always)
  ///   2. Graph: verified + vector fraud advisory → MEDIUM (cross-signal)
  ///   3. Graph: verified + normal vector hits    → LOW
  ///   4. Graph: unknown caller + fraud advisory  → HIGH
  ///   5. Graph: unknown caller + no hits         → MEDIUM (unknown = cautious)
  ///   6. Graph: unknown institution              → MEDIUM
  ///   7. Default                                 → LOW
  (RiskLevel, String) _fuseRisk(
    GraphVerificationResult graphResult,
    List<SemanticSearchResult> vectorResults,
  ) {
    final hasFraudSignal = vectorResults.any(
      (r) =>
          r.score > 0.60 &&
          r.chunk.sourceType == 5, // DocumentSourceType.fraudAdvisory
    );
    final hasSemanticMatch = vectorResults.any((r) => r.score > 0.50);

    return switch (graphResult.status) {
      VerificationStatus.impersonationDetected => (
          RiskLevel.high,
          'Graph engine confirmed structural identity mismatch. '
              'Phone number does not belong to the claimed institution.',
        ),
      VerificationStatus.verified when hasFraudSignal => (
          RiskLevel.medium,
          'Structural identity verified, but vector store found matching '
              'fraud advisory content. Monitor closely.',
        ),
      VerificationStatus.verified => (
          RiskLevel.low,
          'Structural identity verified by graph. '
              'Semantic content within expected parameters.',
        ),
      VerificationStatus.unknownCaller when hasFraudSignal => (
          RiskLevel.high,
          'Caller is unknown to local graph AND semantic content matches '
              'known fraud advisory patterns.',
        ),
      VerificationStatus.unknownCaller when hasSemanticMatch => (
          RiskLevel.medium,
          'Caller is unknown to local graph. Semantic content has partial '
              'match with stored documents. Treat with caution.',
        ),
      VerificationStatus.unknownCaller => (
          RiskLevel.medium,
          'Caller is not registered in the local knowledge graph. '
              'Cannot verify identity.',
        ),
      VerificationStatus.unknownInstitution when hasFraudSignal => (
          RiskLevel.high,
          'Claimed institution is unknown AND semantic content matches known fraud advisory patterns. High likelihood of vishing.',
        ),
      VerificationStatus.unknownInstitution => (
          RiskLevel.medium,
          'Claimed institution "${graphResult.claimedEntity?.name ?? "Unknown"}" '
              'is not recognised in the local knowledge graph.',
        ),
    };
  }

  // ── LLM Context Formatter ──────────────────────────────────────

  /// Produces the plain-text prompt injection block consumed by the
  /// local LLM (Llama 3.1 8B or equivalent).
  ///
  /// Format agreed with the LLM team:
  ///   `[SYSTEM_TRUTH_CONTEXT]: <structured text>`
  String _formatLlmContext({
    required CallQueryParams params,
    required GraphVerificationResult graphResult,
    required List<SemanticSearchResult> vectorResults,
    required RiskLevel riskLevel,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('[SYSTEM_TRUTH_CONTEXT]:');
    buffer.writeln(
      'Risk Assessment: ${riskLevel.name.toUpperCase()} | '
      'Graph: ${graphResult.status.name} | '
      'Vector Evidence: ${vectorResults.length} chunk(s)',
    );
    buffer.writeln();

    // ── Graph section ──────────────────────────────────────────
    buffer.writeln('--- STRUCTURAL GRAPH ANALYSIS ---');
    buffer.writeln(graphResult.structuralSummary);

    if (graphResult.callerRelationships.isNotEmpty) {
      buffer.writeln('Known relationships for resolved entity:');
      for (final edge in graphResult.callerRelationships) {
        buffer.writeln(
          '  • ${edge.relationshipType} '
          '→ entity#${edge.targetEntityId}',
        );
      }
    }
    buffer.writeln();

    // ── Vector section ─────────────────────────────────────────
    buffer.writeln('--- SEMANTIC VECTOR EVIDENCE ---');
    if (vectorResults.isEmpty) {
      buffer.writeln('No semantically relevant documents found in local store.');
    } else {
      for (var i = 0; i < vectorResults.length; i++) {
        final hit = vectorResults[i];
        buffer.writeln(
          '[Doc ${i + 1}] '
          'Score=${hit.score.toStringAsFixed(3)} '
          '| Source: ${hit.chunk.sourceTitle ?? hit.chunk.sourceDocumentId}',
        );
        // Include up to 300 chars of the matching chunk.
        final preview = hit.chunk.textContent.length > 300
            ? '${hit.chunk.textContent.substring(0, 300)}…'
            : hit.chunk.textContent;
        buffer.writeln('  "$preview"');
        buffer.writeln();
      }
    }

    // ── Instruction for the LLM ────────────────────────────────
    buffer.writeln('--- ANALYSIS DIRECTIVE ---');
    buffer.writeln(
      'The caller claims to be from "${params.institutionClaimed}". '
      'Using only the STRUCTURAL GRAPH ANALYSIS and SEMANTIC VECTOR EVIDENCE '
      'above, determine if the caller\'s claim is credible. '
      'Do NOT rely on any external knowledge — base your assessment '
      'solely on the provided local truth context. '
      'Flag any inconsistencies as potential vishing indicators.',
    );

    return buffer.toString();
  }

  // ── Lifecycle cleanup ──────────────────────────────────────────

  /// Disposes the report stream.
  ///
  /// Call from [WidgetsBindingObserver.didChangeAppLifecycleState]
  /// when the app is fully terminated, NOT when a single call ends.
  /// Per-call cleanup is handled by [CallSessionManager].
  void dispose() {
    _reportController.close();
  }
}
