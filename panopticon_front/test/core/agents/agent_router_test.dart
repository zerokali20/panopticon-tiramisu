import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/core/agents/agent_router.dart';
import 'package:panopticon/core/agents/models/risk_assessment.dart';
import 'package:panopticon/core/agents/models/transcript_segment.dart';
import 'package:panopticon/core/rag/rag_interface.dart';
import 'package:panopticon/core/graph/graph_interface.dart';

void main() {
  const kStubSentry  = 'C:/tmp/sentry_stub.gguf';
  const kStubContext = 'C:/tmp/context_stub.gguf';

  AgentRouter _makeRouter({
    double threshold = 0.75,
    int interval = 2,
  }) =>
      AgentRouter.create(
        sentryModelPath:  kStubSentry,
        contextModelPath: kStubContext,
        callerNumber: '+1 415 555 0117',
        rag:   StubRagInterface(),
        graph: StubGraphInterface(),
        contextActivationThreshold: threshold,
        inferenceIntervalSegments: interval,
      );

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  group('AgentRouter – lifecycle', () {
    test('AR-01  creates successfully with stub model paths', () {
      expect(() => _makeRouter(), returnsNormally);
    });

    test('AR-02  assessments stream is broadcast', () async {
      final router = _makeRouter();
      expect(router.assessments.isBroadcast, isTrue);
      await router.dispose();
    });

    test('AR-03  emits initial safe assessment on subscribe', () async {
      final router = _makeRouter();
      final first = await router.assessments.first
          .timeout(const Duration(seconds: 2));
      expect(first.threatDetected, isFalse);
      expect(first.sourceAgent, equals('none'));
      await router.dispose();
    });

    test('AR-04  dispose() closes the output stream', () async {
      final router = _makeRouter();
      final done = Completer<void>();
      router.assessments.listen(null, onDone: done.complete);
      await router.dispose();
      await done.future.timeout(const Duration(seconds: 2));
    });

    test('AR-05  addSegment after dispose is a no-op', () async {
      final router = _makeRouter();
      await router.dispose();
      expect(
        () => router.addSegment(TranscriptSegment.caller('Hello')),
        returnsNormally,
      );
    });

    test('AR-06  latestAssessment starts as initial safe state', () {
      final router = _makeRouter();
      expect(router.latestAssessment.sourceAgent, equals('none'));
      expect(router.latestAssessment.threatDetected, isFalse);
      router.dispose();
    });
  });

  // ─── Segment routing ───────────────────────────────────────────────────────
  group('AgentRouter – segment routing', () {
    test('AR-07  router accepts TranscriptSegment without throwing', () {
      final router = _makeRouter();
      expect(
        () => router.addSegment(
            TranscriptSegment.caller('Please verify your account.')),
        returnsNormally,
      );
      router.dispose();
    });

    test('AR-08  multiple segments can be added sequentially', () {
      final router = _makeRouter(interval: 1);
      final segments = [
        TranscriptSegment.caller('Hello I am from the bank.', timestampMs: 0),
        TranscriptSegment.user('Okay', timestampMs: 2000),
        TranscriptSegment.caller('Your OTP is needed now.', timestampMs: 4000),
      ];
      expect(() {
        for (final s in segments) router.addSegment(s);
      }, returnsNormally);
      router.dispose();
    });
  });

  // ─── RiskAssessment model integration ──────────────────────────────────────
  group('RiskAssessment – model integration', () {
    test('AR-09  fromJson parses valid map correctly', () {
      final json = {
        'threat_detected': true,
        'confidence_score': 0.91,
        'reasoning': 'Caller is requesting an OTP under artificial urgency.',
      };
      final a = RiskAssessment.fromJson(json,
          sourceAgent: 'sentry', timestampMs: 1000);
      expect(a.threatDetected, isTrue);
      expect(a.confidenceScore, closeTo(0.91, 0.001));
      expect(a.reasoning, contains('OTP'));
      expect(a.level, equals(RiskLevel.high));
    });

    test('AR-10  confidenceScore is clamped to [0.0, 1.0]', () {
      final tooHigh = {
        'threat_detected': true,
        'confidence_score': 1.5,
        'reasoning': 'Over-confident model.',
      };
      final a = RiskAssessment.fromJson(tooHigh,
          sourceAgent: 'sentry', timestampMs: 0);
      expect(a.confidenceScore, equals(1.0));
    });

    test('AR-11  fromJson throws FormatException on missing key', () {
      final bad = {'threat_detected': true};
      expect(
        () => RiskAssessment.fromJson(bad,
            sourceAgent: 'sentry', timestampMs: 0),
        throwsA(isA<FormatException>()),
      );
    });

    test('AR-12  RiskLevel.safe when threat_detected is false', () {
      final a = RiskAssessment.fromJson(
        {'threat_detected': false, 'confidence_score': 0.30, 'reasoning': 'ok'},
        sourceAgent: 'sentry',
        timestampMs: 0,
      );
      expect(a.level, equals(RiskLevel.safe));
    });

    test('AR-13  RiskLevel.elevated for 0.40–0.70 confidence with threat', () {
      final a = RiskAssessment.fromJson(
        {'threat_detected': true, 'confidence_score': 0.55, 'reasoning': 'elevated'},
        sourceAgent: 'sentry',
        timestampMs: 0,
      );
      expect(a.level, equals(RiskLevel.elevated));
    });

    test('AR-14  confidenceLabel formats to % string', () {
      final a = RiskAssessment(
        threatDetected: true,
        confidenceScore: 0.91,
        reasoning: 'test',
        sourceAgent: 'sentry',
        timestampMs: 0,
      );
      expect(a.confidenceLabel, equals('91%'));
    });

    test('AR-15  toJson round-trip preserves values', () {
      final original = RiskAssessment(
        threatDetected: true,
        confidenceScore: 0.88,
        reasoning: 'Suspicious transfer request.',
        sourceAgent: 'context',
        timestampMs: 12000,
      );
      final json = original.toJson();
      expect(json['threat_detected'], isTrue);
      expect(json['confidence_score'], closeTo(0.88, 0.001));
      expect(json['source_agent'], equals('context'));
      expect(json['timestamp_ms'], equals(12000));
    });
  });

  // ─── Stub RAG / Graph interfaces ───────────────────────────────────────────
  group('StubRagInterface & StubGraphInterface', () {
    test('AR-16  StubRagInterface.query returns non-null string', () async {
      final rag = StubRagInterface();
      final result = await rag.query('bank fraud alert');
      expect(result, isNotNull);
      expect(result!.isNotEmpty, isTrue);
      await rag.dispose();
    });

    test('AR-17  StubGraphInterface resolves known number', () async {
      final graph = StubGraphInterface();
      final node = await graph.resolvePhoneNumber('+94112480480');
      expect(node, isNotNull);
      expect(node!.institution, contains('Commercial Bank'));
      expect(node.isVerifiedContact, isTrue);
      await graph.dispose();
    });

    test('AR-18  StubGraphInterface returns null for unknown number', () async {
      final graph = StubGraphInterface();
      final node = await graph.resolvePhoneNumber('+1 415 555 0117');
      expect(node, isNull);
      await graph.dispose();
    });

    test('AR-19  StubGraphInterface.getCallerContext for unknown → unknown message', () async {
      final graph = StubGraphInterface();
      final ctx = await graph.getCallerContext('+99999999999');
      expect(ctx, isNotNull);
      expect(ctx!.contains('NOT present'), isTrue);
      await graph.dispose();
    });
  });
}
