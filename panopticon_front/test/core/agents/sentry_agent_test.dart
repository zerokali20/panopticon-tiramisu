import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/core/agents/sentry_agent.dart';
import 'package:panopticon/core/agents/models/risk_assessment.dart';
import 'package:panopticon/core/agents/models/transcript_segment.dart';

/// SentryAgent tests.
///
/// These tests do NOT load a real GGUF model. They rely on:
///   - The STUB mode of llama_bridge.dll returning valid JSON on every call.
///   - The SentryAgent's internal buffering, throttling, and stream mechanics.
///
/// Pre-condition: llama_bridge.dll (STUB mode) must be present in the
/// test binary's DLL search path OR flutter test must be run from
/// panopticon_front/ with the stub compiled.
/// For CI/host without the DLL, the tests that touch FFI are skipped via
/// the [skip] flag pattern.
void main() {
  // Stub model path accepted by the STUB native library
  const kStubModel = 'C:/tmp/sentry_stub.gguf';

  // ─── Stream and state mechanics (no FFI required) ──────────────────────────
  group('SentryAgent – stream mechanics', () {
    test('SA-01  assessments stream is a broadcast stream', () {
      final agent = SentryAgent(modelPath: kStubModel);
      expect(agent.assessments.isBroadcast, isTrue);
      agent.dispose();
    });

    test('SA-02  multiple listeners can subscribe simultaneously', () async {
      final agent = SentryAgent(modelPath: kStubModel);
      final s1 = agent.assessments.listen((_) {});
      final s2 = agent.assessments.listen((_) {});
      // Two subscriptions on broadcast stream must not throw
      await Future.delayed(const Duration(milliseconds: 10));
      await s1.cancel();
      await s2.cancel();
      await agent.dispose();
    });

    test('SA-03  dispose() closes the stream without error', () async {
      final agent = SentryAgent(modelPath: kStubModel);
      final completer = Completer<void>();
      agent.assessments.listen(null, onDone: completer.complete);
      await agent.dispose();
      await completer.future.timeout(const Duration(seconds: 2));
    });

    test('SA-04  addSegment after dispose is a no-op', () async {
      final agent = SentryAgent(modelPath: kStubModel);
      await agent.dispose();
      // Must not throw
      expect(
        () => agent.addSegment(TranscriptSegment.caller('Test')),
        returnsNormally,
      );
    });
  });

  // ─── Inference triggering logic ────────────────────────────────────────────
  group('SentryAgent – inference triggering', () {
    test('SA-05  user-only segments do NOT trigger inference', () async {
      final agent = SentryAgent(
        modelPath: kStubModel,
        inferenceIntervalSegments: 1,
      );
      final received = <RiskAssessment>[];
      final sub = agent.assessments.listen(received.add);

      agent.addSegment(TranscriptSegment.user('Hello there.'));
      agent.addSegment(TranscriptSegment.user('Yes I understand.'));

      await Future.delayed(const Duration(milliseconds: 200));
      // No caller segments → no inference
      expect(received.isEmpty, isTrue);

      await sub.cancel();
      await agent.dispose();
    });

    test('SA-06  non-final caller segments do NOT trigger inference', () async {
      final agent = SentryAgent(
        modelPath: kStubModel,
        inferenceIntervalSegments: 1,
      );
      final received = <RiskAssessment>[];
      final sub = agent.assessments.listen(received.add);

      agent.addSegment(TranscriptSegment(
          speaker: 'caller', text: 'Streaming…', timestampMs: 0, isFinal: false));

      await Future.delayed(const Duration(milliseconds: 200));
      expect(received.isEmpty, isTrue);

      await sub.cancel();
      await agent.dispose();
    });

    test('SA-07  N caller segments trigger exactly one inference', () async {
      final agent = SentryAgent(
        modelPath: kStubModel,
        inferenceIntervalSegments: 2,
      );
      final received = <RiskAssessment>[];
      final sub = agent.assessments.listen(received.add);

      agent.addSegment(TranscriptSegment.caller('Segment one.'));
      agent.addSegment(TranscriptSegment.caller('Segment two — trigger.'));

      // Wait for Isolate to complete (generous timeout for slow CI)
      await Future.delayed(const Duration(seconds: 3));

      expect(received.length, equals(1));
      await sub.cancel();
      await agent.dispose();
    },
        skip: !_nativeLibAvailable(),
        timeout: const Timeout(Duration(seconds: 10)));
  });

  // ─── Assessment content (requires native stub DLL) ─────────────────────────
  group('SentryAgent – assessment content', () {
    test('SA-08  emitted assessment has all required fields', () async {
      final agent = SentryAgent(
        modelPath: kStubModel,
        inferenceIntervalSegments: 1,
      );
      final assessments = <RiskAssessment>[];
      final sub = agent.assessments.listen(assessments.add);

      agent.addSegment(TranscriptSegment.caller('Please provide your OTP.'));

      await Future.delayed(const Duration(seconds: 3));

      expect(assessments.isNotEmpty, isTrue);
      final a = assessments.first;
      expect(a.sourceAgent, equals('sentry'));
      expect(a.confidenceScore, inInclusiveRange(0.0, 1.0));
      expect(a.reasoning.isNotEmpty, isTrue);

      await sub.cancel();
      await agent.dispose();
    },
        skip: !_nativeLibAvailable(),
        timeout: const Timeout(Duration(seconds: 10)));

    test('SA-09  flush() emits result even without interval trigger', () async {
      final agent = SentryAgent(
        modelPath: kStubModel,
        inferenceIntervalSegments: 99, // very high threshold
      );
      final assessments = <RiskAssessment>[];
      final sub = agent.assessments.listen(assessments.add);

      agent.addSegment(TranscriptSegment.caller('Single segment.'));
      await agent.flush();

      await Future.delayed(const Duration(seconds: 3));
      expect(assessments.isNotEmpty, isTrue);

      await sub.cancel();
      await agent.dispose();
    },
        skip: !_nativeLibAvailable(),
        timeout: const Timeout(Duration(seconds: 10)));
  });
}

/// Lightweight check for whether the native stub DLL is loadable.
/// Returns false on hosts where the DLL has not been compiled, allowing
/// FFI-dependent tests to be skipped gracefully instead of crashing.
bool _nativeLibAvailable() {
  try {
    if (Platform.isWindows) {
      ffi.DynamicLibrary.open('llama_bridge.dll');
    } else if (Platform.isLinux || Platform.isAndroid) {
      ffi.DynamicLibrary.open('libllama_bridge.so');
    } else {
      ffi.DynamicLibrary.process();
    }
    return true;
  } catch (_) {
    return false;
  }
}
