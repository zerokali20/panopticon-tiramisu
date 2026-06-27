/// SentryAgent
/// ─────────────────────────────────────────────────────────────────────────────
/// The continuously-running lightweight model agent (Phi-3-Mini / ~1B GGUF INT4).
///
/// Lifecycle:
///   1. Instantiated at call start with [SentryAgent.start()].
///   2. Caller-side transcript segments are pushed via [addSegment()].
///   3. Every [inferenceIntervalSegments] caller segments the agent runs
///      inference on the rolling context window.
///   4. Results are emitted as [RiskAssessment] on the [assessments] stream.
///   5. [dispose()] must be called when the call ends to free native memory.
///
/// Thread safety:
///   All LLM inference is offloaded to a Dart Isolate via [LlamaIsolateManager].
///   [addSegment()] is safe to call from the Flutter UI isolate.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import '../llm/llama_isolate.dart';
import 'models/risk_assessment.dart';
import 'models/transcript_segment.dart';
import 'prompt_builder.dart';

class SentryAgent {
  // ─── Configuration ────────────────────────────────────────────────────────
  /// Path to the Phi-3-Mini / ~1B GGUF INT4 model on device storage.
  final String modelPath;

  /// Path to the sentry_grammar.gbnf asset (loaded as a string at startup).
  final String? grammarString;

  /// Caller ID string forwarded from the telephony layer.
  final String? callerNumber;

  /// How many new *caller* segments must arrive before another inference fires.
  /// Lower = more responsive but heavier CPU. Default 2 (≈ one sentence).
  final int inferenceIntervalSegments;

  // ─── State ────────────────────────────────────────────────────────────────
  final List<TranscriptSegment> _segments = [];
  final StreamController<RiskAssessment> _controller =
      StreamController.broadcast();

  int _callerSegmentsSinceLastInference = 0;
  bool _disposed = false;
  bool _inferenceInFlight = false;

  // Call start time used for assessment timestamps
  final int _callStartMs =
      DateTime.now().millisecondsSinceEpoch;

  // ─── Public surface ───────────────────────────────────────────────────────

  SentryAgent({
    required this.modelPath,
    this.grammarString,
    this.callerNumber,
    this.inferenceIntervalSegments = 1,
  });

  /// Live stream of [RiskAssessment] objects. Subscribe in the UI widget.
  Stream<RiskAssessment> get assessments => _controller.stream;

  /// Push a new transcript segment from the STT pipeline.
  /// Triggers an inference run when the caller-segment count crosses the threshold.
  void addSegment(TranscriptSegment segment) {
    if (_disposed) return;
    _segments.add(segment);

    if (segment.speaker == 'caller' && segment.isFinal) {
      _callerSegmentsSinceLastInference++;
      if (_callerSegmentsSinceLastInference >= inferenceIntervalSegments &&
          !_inferenceInFlight) {
        _callerSegmentsSinceLastInference = 0;
        _runInference();
      }
    }
  }

  /// Force an inference run immediately (e.g. call-end flush).
  Future<void> flush() async {
    if (_disposed || _segments.isEmpty) return;
    await _runInference();
  }

  /// Dispose the agent and free native memory.
  /// Must be called when the call ends to avoid memory leaks.
  Future<void> dispose() async {
    _disposed = true;
    await _controller.close();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _runInference() async {
    if (_inferenceInFlight || _disposed) return;
    _inferenceInFlight = true;

    final prompt = PromptBuilder.buildSentryPrompt(
      segments: List.unmodifiable(_segments),
      callerNumber: callerNumber,
    );

    final nowMs =
        DateTime.now().millisecondsSinceEpoch - _callStartMs;

    try {
      final result = await LlamaIsolateManager.runInferenceAsync(
        modelPath,
        prompt,
        grammar: grammarString,
      );

      if (!_disposed) {
        final assessment = RiskAssessment.fromJson(
          result,
          sourceAgent: 'sentry',
          timestampMs: nowMs,
        );
        _controller.add(assessment);
      }
    } catch (e) {
      // Emit a safe fallback on any parse/inference failure rather than crash.
      if (!_disposed) {
        _controller.add(RiskAssessment(
          threatDetected: false,
          confidenceScore: 0.0,
          reasoning: 'Sentry inference error: $e',
          sourceAgent: 'sentry',
          timestampMs: nowMs,
        ));
      }
    } finally {
      _inferenceInFlight = false;
    }
  }
}
