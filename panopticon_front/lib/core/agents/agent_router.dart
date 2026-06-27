/// AgentRouter
/// ─────────────────────────────────────────────────────────────────────────────
/// The dual-model orchestrator. Single entry point for the rest of the
/// application — the UI, audio pipeline, and STT layer all interact with
/// Panopticon's AI through this class.
///
/// Architecture:
///   ┌──────────────┐     addSegment()      ┌──────────────┐
///   │  STT Layer   │ ─────────────────────▶│  AgentRouter │
///   │ (Whisper FFI)│                        │              │
///   └──────────────┘                        │  SentryAgent │ (always running)
///                                           │      │       │
///                                           │  confidence ≥ threshold?
///                                           │      ↓       │
///                                           │  ContextAgent│ (lazy activation)
///                                           │              │
///                                           │  Stream<RiskAssessment>
///                                           └──────┬───────┘
///                                                  │
///                                           ┌──────▼───────┐
///                                           │  Flutter UI  │
///                                           │ (CallOverlay)│
///                                           └──────────────┘
///
/// Usage:
///   final router = AgentRouter.create(
///     sentryModelPath: '/data/sentry.gguf',
///     contextModelPath: '/data/context.gguf',
///     callerNumber: '+1 415 555 0117',
///   );
///   router.assessments.listen((assessment) => updateUI(assessment));
///   router.addSegment(TranscriptSegment.caller('Please provide your PIN.'));
///   ...
///   await router.dispose(); // on call end
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import '../rag/rag_interface.dart';
import '../graph/graph_interface.dart';
import 'context_agent.dart';
import 'sentry_agent.dart';
import 'models/risk_assessment.dart';
import 'models/transcript_segment.dart';

class AgentRouter {
  // ─── Configuration ────────────────────────────────────────────────────────

  /// Sentry confidence score at or above which the Context Agent is triggered.
  final double contextActivationThreshold;

  // ─── Internal state ───────────────────────────────────────────────────────

  final SentryAgent _sentry;
  final ContextAgent _context;

  final StreamController<RiskAssessment> _outputController =
      StreamController.broadcast();
  StreamSubscription<RiskAssessment>? _sentrySub;

  // Tracks all segments received for the Context Agent's window
  final List<TranscriptSegment> _allSegments = [];

  RiskAssessment _lastAssessment = RiskAssessment.initial();
  bool _contextInFlight = false;
  bool _disposed = false;
  int _callStartMs = 0;

  // ─── Constructor (private) — use factory [create()] ──────────────────────

  AgentRouter._({
    required SentryAgent sentry,
    required ContextAgent context,
    required this.contextActivationThreshold,
  })  : _sentry = sentry,
        _context = context {
    _callStartMs = DateTime.now().millisecondsSinceEpoch;
    _wire();
  }

  // ─── Factory ──────────────────────────────────────────────────────────────

  /// Creates and starts an [AgentRouter] for a new call session.
  ///
  /// [sentryModelPath]   — path to the ~1B GGUF model (Phi-3-Mini INT4).
  /// [contextModelPath]  — path to the 8B GGUF model (Llama 3.1 INT4).
  /// [callerNumber]      — raw caller ID from the telephony layer.
  /// [grammarString]     — content of sentry_grammar.gbnf (loaded by caller).
  /// [rag]               — RAG interface instance; defaults to [StubRagInterface].
  /// [graph]             — Graph interface; defaults to [StubGraphInterface].
  factory AgentRouter.create({
    required String sentryModelPath,
    required String contextModelPath,
    String? callerNumber,
    String? grammarString,
    RagInterface? rag,
    GraphInterface? graph,
    double contextActivationThreshold = 0.75,
    int inferenceIntervalSegments = 1,
  }) {
    final sentry = SentryAgent(
      modelPath: sentryModelPath,
      grammarString: grammarString,
      callerNumber: callerNumber,
      inferenceIntervalSegments: inferenceIntervalSegments,
    );

    final context = ContextAgent(
      modelPath: contextModelPath,
      rag: rag ?? StubRagInterface(),
      graph: graph ?? StubGraphInterface(),
      grammarString: grammarString,
      callerNumber: callerNumber,
    );

    return AgentRouter._(
      sentry: sentry,
      context: context,
      contextActivationThreshold: contextActivationThreshold,
    );
  }

  // ─── Public surface ───────────────────────────────────────────────────────

  /// Merged stream of risk assessments from both Sentry and Context agents.
  /// Subscribe to this in the Flutter UI widget.
  Stream<RiskAssessment> get assessments => _outputController.stream;

  /// The most recent assessment, suitable for polling.
  RiskAssessment get latestAssessment => _lastAssessment;

  /// Push a new segment from the STT layer into the routing pipeline.
  void addSegment(TranscriptSegment segment) {
    if (_disposed) return;
    _allSegments.add(segment);
    _sentry.addSegment(segment);
  }

  /// Flush remaining segments through Sentry at call end.
  Future<void> flush() => _sentry.flush();

  /// Dispose both agents and release all native resources.
  /// MUST be called when the call ends.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _sentrySub?.cancel();
    await _sentry.dispose();

    await _outputController.close();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _wire() {
    _outputController.add(_lastAssessment);  // emit initial safe state

    _sentrySub = _sentry.assessments.listen((assessment) {
      _lastAssessment = assessment;
      _outputController.add(assessment);

      // Lazy Context Agent activation
      if (assessment.threatDetected &&
          assessment.confidenceScore >= contextActivationThreshold &&
          !_contextInFlight) {
        _activateContextAgent(assessment);
      }
    });
  }

  Future<void> _activateContextAgent(RiskAssessment sentryResult) async {
    _contextInFlight = true;
    final nowMs =
        DateTime.now().millisecondsSinceEpoch - _callStartMs;

    try {
      final contextAssessment = await _context.analyse(
        segments: List.unmodifiable(_allSegments),
        claimExtract: sentryResult.reasoning,
        timestampMs: nowMs,
      );

      if (!_disposed) {
        _lastAssessment = contextAssessment;
        _outputController.add(contextAssessment);
      }
    } catch (e) {
      // Context Agent failure is non-fatal; log and keep Sentry result active.
      if (!_disposed) {
        _outputController.add(RiskAssessment(
          threatDetected: sentryResult.threatDetected,
          confidenceScore: sentryResult.confidenceScore,
          reasoning:
              '${sentryResult.reasoning} [Context Agent error: $e]',
          sourceAgent: 'context_error',
          timestampMs: nowMs,
        ));
      }
    } finally {
      _contextInFlight = false;
    }
  }
}
