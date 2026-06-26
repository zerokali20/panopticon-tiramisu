import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/core/agents/prompt_builder.dart';
import 'package:panopticon/core/agents/models/transcript_segment.dart';

void main() {
  // ─── Fixture helpers ────────────────────────────────────────────────────────
  List<TranscriptSegment> _makeSegments() => [
        TranscriptSegment.caller('Hello, I am calling from Wells Fargo.', timestampMs: 1000),
        TranscriptSegment.user('Okay, how can I help?', timestampMs: 5000),
        TranscriptSegment.caller('Your account has been compromised. '
            'I need your OTP immediately to freeze the account.', timestampMs: 9000),
      ];

  // ─── buildSentryPrompt ──────────────────────────────────────────────────────
  group('PromptBuilder.buildSentryPrompt', () {
    test('PB-01  output is non-empty', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
      );
      expect(prompt.isNotEmpty, isTrue);
    });

    test('PB-02  output contains system role keywords', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
      );
      expect(prompt.contains('Panopticon Sentry'), isTrue);
      expect(prompt.contains('SOCIAL ENGINEERING LOGIC GATES'), isTrue);
      expect(prompt.contains('OUTPUT CONTRACT'), isTrue);
    });

    test('PB-03  CALLER segments labelled correctly', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
      );
      expect(prompt.contains('CALLER:'), isTrue);
      expect(prompt.contains('USER:'), isTrue);
    });

    test('PB-04  caller number injected when provided', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
        callerNumber: '+1 415 555 0117',
      );
      expect(prompt.contains('+1 415 555 0117'), isTrue);
    });

    test('PB-05  RAG context injected when provided', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
        ragContext: 'User banks with Commercial Bank of Ceylon.',
      );
      expect(prompt.contains('VERIFIED CONTEXT'), isTrue);
      expect(prompt.contains('Commercial Bank of Ceylon'), isTrue);
    });

    test('PB-06  RAG context omitted when null', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
      );
      expect(prompt.contains('VERIFIED CONTEXT'), isFalse);
    });

    test('PB-07  segment window capped at 30', () {
      final many = List.generate(
          50,
          (i) => TranscriptSegment.caller('Segment $i', timestampMs: i * 1000));
      final prompt = PromptBuilder.buildSentryPrompt(segments: many);
      // Segment 20 should NOT be in the window (only last 30 kept)
      expect(prompt.contains('Segment 19'), isFalse);
      expect(prompt.contains('Segment 49'), isTrue);
    });

    test('PB-08  timestamps formatted as MM:SS', () {
      final segs = [
        TranscriptSegment.caller('Hello', timestampMs: 65000),  // 01:05
      ];
      final prompt = PromptBuilder.buildSentryPrompt(segments: segs);
      expect(prompt.contains('01:05'), isTrue);
    });

    test('PB-09  empty segment list produces valid prompt', () {
      final prompt = PromptBuilder.buildSentryPrompt(segments: []);
      expect(prompt.isNotEmpty, isTrue);
      expect(prompt.contains('LIVE CALL TRANSCRIPT'), isTrue);
    });

    test('PB-10  prompt ends with ANALYSIS RESULT marker', () {
      final prompt = PromptBuilder.buildSentryPrompt(
        segments: _makeSegments(),
      );
      expect(prompt.trimRight().endsWith('ANALYSIS RESULT:'), isTrue);
    });
  });

  // ─── buildContextPrompt ─────────────────────────────────────────────────────
  group('PromptBuilder.buildContextPrompt', () {
    test('PB-11  context prompt contains forensic role header', () {
      final prompt = PromptBuilder.buildContextPrompt(
        segments: _makeSegments(),
        claimExtract: 'Your account has been compromised.',
      );
      expect(prompt.contains('Panopticon Context Agent'), isTrue);
      expect(prompt.contains('forensic analysis'), isTrue);
    });

    test('PB-12  flagged claim is embedded verbatim', () {
      const claim = 'Your account has been compromised.';
      final prompt = PromptBuilder.buildContextPrompt(
        segments: _makeSegments(),
        claimExtract: claim,
      );
      expect(prompt.contains(claim), isTrue);
    });

    test('PB-13  graph context injected when provided', () {
      final prompt = PromptBuilder.buildContextPrompt(
        segments: _makeSegments(),
        claimExtract: 'Caller claims to be from your bank.',
        graphContext: 'Number +1-415 not in institution graph.',
      );
      expect(prompt.contains('GRAPH-RESOLVED ENTITY CONTEXT'), isTrue);
      expect(prompt.contains('+1-415'), isTrue);
    });

    test('PB-14  context prompt ends with FORENSIC ANALYSIS marker', () {
      final prompt = PromptBuilder.buildContextPrompt(
        segments: _makeSegments(),
        claimExtract: 'test claim',
      );
      expect(prompt.trimRight().endsWith('FORENSIC ANALYSIS:'), isTrue);
    });
  });
}
