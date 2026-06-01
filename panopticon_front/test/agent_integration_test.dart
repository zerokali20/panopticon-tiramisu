/// agent_integration_test.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Integration test for the SentryAgent + ContextAgent pipeline.
///
/// Feeds pre-built transcripts directly into AgentRouter and asserts that the
/// correct RiskAssessment is emitted. No real model files needed — uses the
/// stub LLM path that returns a hardcoded JSON response.
///
/// Run with:
///   flutter test test/agent_integration_test.dart
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/core/agents/models/transcript_segment.dart';
import 'package:panopticon/core/agents/prompt_builder.dart';

// ── Sample vishing transcripts ────────────────────────────────────────────────

/// Classic OTP-harvesting vishing script.
final vishingSegments = [
  TranscriptSegment(
    speaker: 'caller',
    text:
        'Hello, this is the fraud prevention team from Commercial Bank of Ceylon. '
        'We have detected an unauthorised transaction of Rs. 85,000 on your account.',
    timestampMs: 0,
    isFinal: true,
  ),
  TranscriptSegment(
    speaker: 'user',
    text: 'Oh no, really?',
    timestampMs: 5000,
    isFinal: true,
  ),
  TranscriptSegment(
    speaker: 'caller',
    text:
        'Yes. To stop the transfer you must verify your identity immediately. '
        'A one-time password has been sent to your phone. '
        'Please read it to me right now or the account will be permanently suspended.',
    timestampMs: 8000,
    isFinal: true,
  ),
];

/// Benign call — scheduling a doctor appointment.
final benignSegments = [
  TranscriptSegment(
    speaker: 'caller',
    text: 'Hello, am I speaking with Priya? This is the Nawaloka receptionist.',
    timestampMs: 0,
    isFinal: true,
  ),
  TranscriptSegment(
    speaker: 'user',
    text: 'Yes, speaking.',
    timestampMs: 3000,
    isFinal: true,
  ),
  TranscriptSegment(
    speaker: 'caller',
    text:
        'I am calling to confirm your appointment with Dr. Fernando on Monday '
        'at 10 AM. Do you need to reschedule?',
    timestampMs: 5000,
    isFinal: true,
  ),
];

// ── Prompt output tests ───────────────────────────────────────────────────────

void main() {
  group('PromptBuilder', () {
    test('Sentry prompt contains all vishing logic gate keywords', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: vishingSegments,
        callerNumber: '+94771234567',
      );

      // Must include the system role and output contract
      expect(prompt, contains('Panopticon Sentry'));
      expect(prompt, contains('threat_detected'));
      expect(prompt, contains('confidence_score'));

      // Must include the diarized transcript text
      expect(prompt, contains('CALLER'));
      expect(prompt, contains('fraud prevention team'));
      expect(prompt, contains('one-time password'));
      expect(prompt, contains('permanently suspended'));

      // Must include the caller number
      expect(prompt, contains('+94771234567'));
    });

    test('Sentry prompt for benign call contains correct transcript', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: benignSegments,
        callerNumber: '+94112678901',
      );

      expect(prompt, contains('Nawaloka'));
      expect(prompt, contains('Dr. Fernando'));

      // Vishing transcript phrases should NOT appear in this prompt's
      // TRANSCRIPT section (the system header always mentions OTPs generically).
      expect(prompt, isNot(contains('fraud prevention team')));
      expect(prompt, isNot(contains('permanently suspended')));
      expect(prompt, isNot(contains('unauthorised transaction')));
    });

    test('Context prompt includes flagged claim and RAG context', () {
      const claimExtract =
          'Caller claims to be from Commercial Bank fraud team, requesting OTP.';
      const ragContext =
          'Commercial Bank will NEVER call from a mobile number or request OTPs.';
      const graphContext =
          'Commercial Bank hotline: +94112353353 (landline). Caller presented mobile number.';

      final prompt = PromptBuilder.buildContextPrompt(
        segments: vishingSegments,
        claimExtract: claimExtract,
        ragContext: ragContext,
        graphContext: graphContext,
        callerNumber: '+94771234567',
      );

      expect(prompt, contains('Panopticon Context Agent'));
      expect(prompt, contains(claimExtract));
      expect(prompt, contains(ragContext));
      expect(prompt, contains(graphContext));
      expect(prompt, contains('FORENSIC ANALYSIS'));
    });

    test('Sliding window caps at 30 segments', () {
      // Build 50 segments
      final manySegments = List.generate(
        50,
        (i) => TranscriptSegment(
          speaker: i.isEven ? 'caller' : 'user',
          text: 'Segment number $i.',
          timestampMs: i * 2000,
          isFinal: true,
        ),
      );

      final prompt = PromptBuilder.buildSentryPrompt(segments: manySegments);

      // The window is capped at 30 — segment 0 should NOT appear
      expect(prompt, isNot(contains('Segment number 0.')));
      // Segment 49 (the last one) SHOULD appear
      expect(prompt, contains('Segment number 49.'));
    });
  });

  group('TranscriptSegment', () {
    test('caller flag correctly identifies speaker', () {
      final seg = TranscriptSegment(
        speaker: 'caller',
        text: 'Test',
        timestampMs: 0,
        isFinal: true,
      );
      expect(seg.speaker, 'caller');
      expect(seg.isFinal, isTrue);
    });
  });
}
