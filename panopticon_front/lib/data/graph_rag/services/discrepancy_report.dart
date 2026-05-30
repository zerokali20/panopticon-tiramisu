// ============================================================
// panopticon/data/graph_rag/services/discrepancy_report.dart
//
// Shared data model representing the engine's consolidated verdict.
//
// This type is the primary API surface shared with:
//   • The Flutter UI team  (drives the Reasoning Tree overlay)
//   • The LLM team         (provides the prompt injection string)
//
// It must remain a plain Dart class with NO framework imports.
// ============================================================

import '../models/graph_query_result.dart';
import '../objectbox/vector_search_service.dart';

/// Unified risk classification across both engines.
enum RiskLevel {
  /// Both engines agree: caller identity is structurally valid.
  low,

  /// One engine raised a soft signal; human verification advisable.
  medium,

  /// At least one engine produced a hard discrepancy signal.
  high,

  /// An unexpected error prevented a complete analysis.
  error,
}

/// Consolidated output of the [ContextRetrievalService] for a single
/// query cycle during a live call.
///
/// Consumed by:
///   • Flutter UI: `Stream<DiscrepancyReport>` drives the Reasoning Tree.
///   • LLM prompt builder: uses [llmContextString] directly.
class DiscrepancyReport {
  // ── Graph Engine Result ────────────────────────────────────────

  /// Structural verdict from the SQLite Knowledge Graph.
  final GraphVerificationResult graphResult;

  // ── Vector Engine Result ───────────────────────────────────────

  /// Semantic matches from the ObjectBox vector store.
  final List<SemanticSearchResult> vectorResults;

  // ── Consolidated Verdict ──────────────────────────────────────

  /// Combined risk level derived from both engines.
  final RiskLevel riskLevel;

  /// Human-readable explanation of how the risk level was determined.
  final String riskRationale;

  /// ISO-8601 timestamp of when this report was generated.
  final String generatedAt;

  /// Pre-formatted context string for injection into the LLM prompt.
  ///
  /// Format contract agreed with the LLM team:
  ///   `[SYSTEM_TRUTH_CONTEXT]: <content>`
  final String llmContextString;

  const DiscrepancyReport({
    required this.graphResult,
    required this.vectorResults,
    required this.riskLevel,
    required this.riskRationale,
    required this.generatedAt,
    required this.llmContextString,
  });

  /// Whether this report should trigger a visible warning in the UI.
  bool get requiresUserAttention =>
      riskLevel == RiskLevel.high || riskLevel == RiskLevel.medium;

  /// Convenience: number of vector evidence chunks retrieved.
  int get vectorEvidenceCount => vectorResults.length;

  @override
  String toString() =>
      'DiscrepancyReport('
      'risk=${riskLevel.name}, '
      'graph=${graphResult.status.name}, '
      'vectorHits=$vectorEvidenceCount)';
}
