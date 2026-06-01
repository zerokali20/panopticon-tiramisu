/// live_inference_test.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// End-to-end integration test: loads real GGUF models from disk, runs
/// actual LLM inference through the full AgentRouter pipeline, and
/// validates the RiskAssessment output.
///
/// Prerequisites:
///   - models/sentry.gguf   must exist (Phi-3-mini)
///   - models/context.gguf  must exist (Llama-3.1-8B)
///   - llama_bridge.dll + ggml*.dll must be on PATH (or in cwd)
///
/// Run with (from panopticon_front/):
///   flutter test test/live_inference_test.dart --timeout=300s
///
/// These tests are intentionally SKIPPED if the model files are missing,
/// so they never block CI on machines without the GGUF files.
/// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:panopticon/core/agents/agent_router.dart';
import 'package:panopticon/core/agents/models/risk_assessment.dart';
import 'package:panopticon/core/agents/models/transcript_segment.dart';

// ── Model paths (absolute, local to the repo) ─────────────────────────────────

final _repoRoot =
    Directory.current.path.replaceAll(r'\', '/');

final _sentryModel = '$_repoRoot/models/sentry.gguf';
final _contextModel = '$_repoRoot/models/context.gguf';

bool get _modelsExist =>
    File(_sentryModel).existsSync() && File(_contextModel).existsSync();

// ── Sample transcripts ────────────────────────────────────────────────────────

/// Classic OTP-harvesting vishing script — should trigger Sentry at high confidence.
final _vishingTranscript = [
  TranscriptSegment.caller(
    'Hello, this is the fraud prevention team from Commercial Bank of Ceylon. '
    'We have detected an unauthorised transaction of Rs. 85,000 on your account.',
    timestampMs: 0,
  ),
  TranscriptSegment.user('Oh no, really?', timestampMs: 5000),
  TranscriptSegment.caller(
    'Yes. To stop the transfer you must verify your identity immediately. '
    'A one-time password has been sent to your phone. '
    'Please read it to me right now or the account will be permanently suspended.',
    timestampMs: 8000,
  ),
  TranscriptSegment.user('Um, I am not sure I should...', timestampMs: 13000),
  TranscriptSegment.caller(
    'This is urgent. You only have 60 seconds before we are forced to freeze '
    'your account permanently. What is the OTP?',
    timestampMs: 16000,
  ),
];

/// Benign doctor-appointment call — should NOT trigger Sentry.
final _benignTranscript = [
  TranscriptSegment.caller(
    'Hello, am I speaking with Priya? This is the Nawaloka receptionist.',
    timestampMs: 0,
  ),
  TranscriptSegment.user('Yes, speaking.', timestampMs: 3000),
  TranscriptSegment.caller(
    'I am calling to confirm your appointment with Dr. Fernando on Monday at 10 AM. '
    'Do you need to reschedule?',
    timestampMs: 5000,
  ),
  TranscriptSegment.user('No, Monday is fine, thank you.', timestampMs: 9000),
];

/// Safe-account transfer scam — should escalate to Context Agent.
final _transferScamTranscript = [
  TranscriptSegment.caller(
    'This is the security division of Bank of Ceylon. '
    'We have detected that your account is being accessed by a third party.',
    timestampMs: 0,
  ),
  TranscriptSegment.user('What? How?', timestampMs: 4000),
  TranscriptSegment.caller(
    'For your protection, we need you to transfer all your funds immediately '
    'to a temporary government-secured holding account. '
    'This is the only way to protect your money.',
    timestampMs: 6000,
  ),
  TranscriptSegment.user(
    'I don\'t know... how much should I transfer?',
    timestampMs: 12000,
  ),
  TranscriptSegment.caller(
    'All of it. Transfer everything and our agents will restore it once the '
    'investigation is complete. Please do this now — the fraudster is active.',
    timestampMs: 14000,
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Feeds all segments into [router] and collects all emitted assessments.
/// Waits up to [timeoutSeconds] for the last assessment.
Future<List<RiskAssessment>> _feedAndCollect(
  AgentRouter router,
  List<TranscriptSegment> segments, {
  int timeoutSeconds = 120,
}) async {
  final collected = <RiskAssessment>[];
  final done = Completer<void>();

  final sub = router.assessments.listen(
    (a) {
      collected.add(a);
      print('  [${a.sourceAgent.toUpperCase()}] '
          '${a.confidenceLabel} — ${a.reasoning}');
    },
    onDone: () => done.complete(),
  );

  // Feed segments with realistic inter-segment delays
  for (var i = 0; i < segments.length; i++) {
    router.addSegment(segments[i]);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Flush and wait for completion
  await router.flush();
  await Future.delayed(Duration(seconds: timeoutSeconds));

  await sub.cancel();
  await router.dispose();

  return collected;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // Guard: skip everything if models are not present on disk
  if (!_modelsExist) {
    test('SKIPPED — model files not found', () {
      print(
        '\n⚠  Skipping live inference tests.\n'
        '   Expected:\n'
        '     $_sentryModel\n'
        '     $_contextModel\n'
        '   Run the app first to download the models.\n',
      );
    }, skip: true);
    return;
  }

  group('Live Inference — Sentry Agent (Phi-3-mini)', () {
    test('Vishing call → threat_detected=true, confidence ≥ 0.70', () async {
      print('\n▶  Running VISHING inference on Sentry...');
      final router = AgentRouter.create(
        sentryModelPath: _sentryModel,
        contextModelPath: _contextModel,
        callerNumber: '+94771234567',
        inferenceIntervalSegments: 2,
      );

      final assessments =
          await _feedAndCollect(router, _vishingTranscript, timeoutSeconds: 120);

      expect(assessments, isNotEmpty,
          reason: 'No assessments emitted — model may have crashed');

      final lastSentry = assessments
          .where((a) => a.sourceAgent == 'sentry')
          .lastOrNull;

      expect(lastSentry, isNotNull,
          reason: 'No Sentry assessment received');

      print('  Final Sentry: ${lastSentry!}');

      expect(lastSentry.threatDetected, isTrue,
          reason: 'Sentry should flag OTP harvesting script as a threat');
      expect(lastSentry.confidenceScore, greaterThanOrEqualTo(0.70),
          reason: 'Confidence should be high for a clear vishing script');
      expect(lastSentry.reasoning, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('Benign call → threat_detected=false', () async {
      print('\n▶  Running BENIGN inference on Sentry...');
      final router = AgentRouter.create(
        sentryModelPath: _sentryModel,
        contextModelPath: _contextModel,
        callerNumber: '+94112678901',
        inferenceIntervalSegments: 2,
      );

      final assessments =
          await _feedAndCollect(router, _benignTranscript, timeoutSeconds: 120);

      final lastSentry = assessments
          .where((a) => a.sourceAgent == 'sentry')
          .lastOrNull;

      if (lastSentry != null) {
        print('  Final Sentry: ${lastSentry}');
        // For benign calls we expect no threat OR low confidence
        final isSafe = !lastSentry.threatDetected ||
            lastSentry.confidenceScore < 0.40;
        expect(isSafe, isTrue,
            reason: 'Sentry should not flag a doctor appointment call '
                '(got: threat=${lastSentry.threatDetected}, '
                'confidence=${lastSentry.confidenceLabel})');
      }
      // If no assessment emitted, that is also fine (no trigger segments)
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('Live Inference — Full Pipeline (Sentry → Context Agent)', () {
    test('Transfer scam → Context Agent activated, high confidence', () async {
      print('\n▶  Running TRANSFER SCAM inference — full dual-agent pipeline...');
      final router = AgentRouter.create(
        sentryModelPath: _sentryModel,
        contextModelPath: _contextModel,
        callerNumber: '+94711122334',
        contextActivationThreshold: 0.65, // slightly lower to ensure CA fires
        inferenceIntervalSegments: 2,
      );

      final assessments = await _feedAndCollect(
          router, _transferScamTranscript,
          timeoutSeconds: 180); // Llama-8B needs more time

      print('\n  All assessments:');
      for (final a in assessments) {
        print('    ${a.sourceAgent}: ${a.confidenceLabel} — ${a.reasoning}');
      }

      final contextAssessment = assessments
          .where((a) => a.sourceAgent == 'context')
          .lastOrNull;

      expect(contextAssessment, isNotNull,
          reason: 'Context Agent should have been activated by high-confidence '
              'Sentry flag on a transfer scam');

      print('  Final Context: $contextAssessment');

      expect(contextAssessment!.threatDetected, isTrue);
      expect(contextAssessment.confidenceScore, greaterThanOrEqualTo(0.75));
    }, timeout: const Timeout(Duration(minutes: 8)));
  });

  group('RiskAssessment JSON parsing', () {
    test('fromJson correctly maps all fields', () {
      final json = {
        'threat_detected': true,
        'confidence_score': 0.92,
        'reasoning': 'Caller requested OTP under artificial urgency.'
      };
      final assessment = RiskAssessment.fromJson(
        json,
        sourceAgent: 'sentry',
        timestampMs: 5000,
      );
      expect(assessment.threatDetected, isTrue);
      expect(assessment.confidenceScore, closeTo(0.92, 0.001));
      expect(assessment.level, RiskLevel.high);
      expect(assessment.confidenceLabel, '92%');
      expect(assessment.reasoning, contains('OTP'));
    });

    test('fromJson clamps confidence_score to [0, 1]', () {
      final over = RiskAssessment.fromJson(
        {'threat_detected': true, 'confidence_score': 1.5, 'reasoning': 'x'},
        sourceAgent: 'sentry',
        timestampMs: 0,
      );
      expect(over.confidenceScore, equals(1.0));

      final under = RiskAssessment.fromJson(
        {'threat_detected': false, 'confidence_score': -0.3, 'reasoning': 'x'},
        sourceAgent: 'sentry',
        timestampMs: 0,
      );
      expect(under.confidenceScore, equals(0.0));
    });

    test('fromJson throws on missing keys', () {
      expect(
        () => RiskAssessment.fromJson(
          {'threat_detected': true},
          sourceAgent: 'sentry',
          timestampMs: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('RiskLevel mapping is correct', () {
      RiskAssessment make(bool threat, double conf) => RiskAssessment(
            threatDetected: threat,
            confidenceScore: conf,
            reasoning: '',
            sourceAgent: 'sentry',
            timestampMs: 0,
          );

      expect(make(false, 0.95).level, RiskLevel.safe);   // no threat → safe
      expect(make(true, 0.35).level, RiskLevel.safe);    // threat but < 0.40
      expect(make(true, 0.55).level, RiskLevel.elevated);
      expect(make(true, 0.71).level, RiskLevel.high);
      expect(make(true, 1.00).level, RiskLevel.high);
    });
  });
}
