/// ContextAgent
/// ─────────────────────────────────────────────────────────────────────────────
/// The lazily-evaluated heavy model agent (Llama 3.1 8B / GGUF INT4).
///
/// Activated ONLY when [AgentRouter] determines the Sentry confidence has
/// crossed the high-confidence threshold. This agent:
///   1. Extracts the specific claim from the transcript.
///   2. Queries the RAG layer (ObjectBox Vector) for local context.
///   3. Queries the Graph layer (SQLite/Drift) for entity relationships.
///   4. Runs a deep-dive forensic prompt and returns a [RiskAssessment].
///
/// The Context Agent is NOT kept alive between activations; the Isolate
/// is spun up, runs its inference, then the native context is freed
/// automatically by [LlamaIsolateManager] upon Isolate disposal.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import '../llm/llama_isolate.dart';
import '../rag/rag_interface.dart';
import '../graph/graph_interface.dart';
import 'models/risk_assessment.dart';
import 'models/transcript_segment.dart';
import 'prompt_builder.dart';

class ContextAgent {
  final String modelPath;
  final String? grammarString;
  final String? callerNumber;

  final RagInterface _rag;
  final GraphInterface _graph;

  ContextAgent({
    required this.modelPath,
    required RagInterface rag,
    required GraphInterface graph,
    this.grammarString,
    this.callerNumber,
  })  : _rag = rag,
        _graph = graph;

  /// Run a deep forensic analysis on the current [segments] window.
  ///
  /// [claimExtract] — the flagged claim string extracted from the Sentry output
  ///                  reasoning field (or the latest caller segment text).
  ///
  /// Returns a high-fidelity [RiskAssessment] from the heavier 8B model.
  Future<RiskAssessment> analyse({
    required List<TranscriptSegment> segments,
    required String claimExtract,
    required int timestampMs,
  }) async {
    // Run RAG and Graph lookups in parallel — both are local, fast I/O.
    final results = await Future.wait([
      _rag.query(claimExtract),
      if (callerNumber != null)
        _graph.getCallerContext(callerNumber!)
      else
        Future.value(null),
    ]);

    final ragContext   = results[0] as String?;
    final graphContext = callerNumber != null ? results[1] as String? : null;

    final prompt = PromptBuilder.buildContextPrompt(
      segments: segments,
      claimExtract: claimExtract,
      ragContext: ragContext,
      graphContext: graphContext,
      callerNumber: callerNumber,
    );

    final result = await LlamaIsolateManager.runInferenceAsync(
      modelPath,
      prompt,
      grammar: grammarString,
    );

    return RiskAssessment.fromJson(
      result,
      sourceAgent: 'context',
      timestampMs: timestampMs,
    );
  }
}
