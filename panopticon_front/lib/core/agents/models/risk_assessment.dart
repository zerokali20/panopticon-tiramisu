/// RiskAssessment
/// ─────────────────────────────────────────────────────────────────────────────
/// Typed Dart representation of the JSON structure enforced by sentry_grammar.gbnf
/// and produced by every LLM inference call.
///
/// This is the single data type that flows from the AgentRouter into the UI.
library;

import 'dart:convert';

enum RiskLevel { safe, elevated, high }

class RiskAssessment {
  /// Whether the agent determined a social engineering threat is present.
  final bool threatDetected;

  /// Confidence score in [0.0, 1.0]. Maps to [RiskLevel] via [level].
  final double confidenceScore;

  /// Human-readable explanation string from the model's reasoning field.
  /// Populated into the "Why we flagged this" card in the UI.
  final String reasoning;

  /// The agent that produced this assessment ('sentry' | 'context').
  final String sourceAgent;

  /// Monotonic timestamp (milliseconds from call start) when this was emitted.
  final int timestampMs;

  const RiskAssessment({
    required this.threatDetected,
    required this.confidenceScore,
    required this.reasoning,
    required this.sourceAgent,
    required this.timestampMs,
  });

  /// Maps confidence → UI risk level bucket.
  RiskLevel get level {
    if (!threatDetected || confidenceScore < 0.40) return RiskLevel.safe;
    if (confidenceScore < 0.70) return RiskLevel.elevated;
    return RiskLevel.high;
  }

  /// Confidence as a display percentage string, e.g. "91%".
  String get confidenceLabel =>
      '${(confidenceScore * 100).toStringAsFixed(0)}%';

  /// Parse the raw JSON string returned by [LlamaIsolateManager.runInferenceAsync].
  /// Throws [FormatException] if the JSON is malformed or missing required keys.
  factory RiskAssessment.fromJson(
    Map<String, dynamic> json, {
    required String sourceAgent,
    required int timestampMs,
  }) {
    final threatDetected = json['threat_detected'];
    final confidenceScore = json['confidence_score'];
    final reasoning = json['reasoning'];

    if (threatDetected == null || confidenceScore == null || reasoning == null) {
      throw FormatException(
          'RiskAssessment.fromJson: missing required key in $json');
    }

    return RiskAssessment(
      threatDetected: threatDetected as bool,
      confidenceScore: (confidenceScore as num).toDouble().clamp(0.0, 1.0),
      reasoning: reasoning as String,
      sourceAgent: sourceAgent,
      timestampMs: timestampMs,
    );
  }

  /// Parse directly from a raw JSON string (convenience wrapper).
  factory RiskAssessment.fromJsonString(
    String raw, {
    required String sourceAgent,
    required int timestampMs,
  }) {
    final Map<String, dynamic> json =
        jsonDecode(raw) as Map<String, dynamic>;
    return RiskAssessment.fromJson(json,
        sourceAgent: sourceAgent, timestampMs: timestampMs);
  }

  /// Safe assessment — used as the initial state before first inference.
  factory RiskAssessment.initial() => const RiskAssessment(
        threatDetected: false,
        confidenceScore: 0.0,
        reasoning: 'Initialising Sentry Agent…',
        sourceAgent: 'none',
        timestampMs: 0,
      );

  Map<String, dynamic> toJson() => {
        'threat_detected': threatDetected,
        'confidence_score': confidenceScore,
        'reasoning': reasoning,
        'source_agent': sourceAgent,
        'timestamp_ms': timestampMs,
      };

  @override
  String toString() =>
      'RiskAssessment(level: $level, confidence: $confidenceLabel, '
      'agent: $sourceAgent, reasoning: "${reasoning.length > 60 ? '${reasoning.substring(0, 60)}…' : reasoning}")';
}
