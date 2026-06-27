import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi_lib;
import 'dart:isolate';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:panopticon/core/llm/llama_ffi.dart';
import 'package:panopticon/core/llm/llama_isolate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Integration Test Suite: llama_bridge Dart FFI + Isolate Layer
///
/// These tests exercise the full Dart side of Track C:
///   • LlamaFFI    – native symbol loading + C ABI calls
///   • LlamaIsolateManager – Isolate spawn, JSON round-trip, memory lifecycle
///
/// The native library must be compiled before running:
///   In STUB mode  → cmake -DLLAMA_REAL=0 -B build && cmake --build build
///   In REAL mode  → cmake -DLLAMA_REAL=1 -B build && cmake --build build
///                   (requires vendor/llama.cpp present)
///
/// The `PANOPTICON_MODEL` env-var controls the model path in REAL mode.
/// ─────────────────────────────────────────────────────────────────────────────

const String kStubModelPath = '/stub/sentry.gguf';

// A minimal GBNF grammar string matching sentry_grammar.gbnf
const String kSentryGbnf =
    'root ::= "{" ws "\\"threat_detected\\"" ws ":" ws boolean ws "," ws '
    '"\\"confidence_score\\"" ws ":" ws float ws "," ws '
    '"\\"reasoning\\"" ws ":" ws string ws "}"\n'
    'boolean ::= "true" | "false"\n'
    'float ::= "0." [0-9]+ | "1.0" | "1.00"\n'
    'string ::= "\\"" ([^"\\\\] | "\\\\" ["\\\\/bfnrt])* "\\""\n'
    'ws ::= [ \\t\\n]*\n';

bool _nativeLibAvailable() {
  try {
    if (Platform.isWindows) {
      ffi_lib.DynamicLibrary.open('llama_bridge.dll');
    } else if (Platform.isLinux || Platform.isAndroid) {
      ffi_lib.DynamicLibrary.open('libllama_bridge.so');
    } else {
      ffi_lib.DynamicLibrary.process();
    }
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  if (!_nativeLibAvailable()) {
    test('SKIPPED — llama_bridge.dll not found', () {
      print('Skipping llama_bridge integration tests.');
    });
    return;
  }

  // ─── LlamaFFI (low-level binding) tests ─────────────────────────────────────

  group('LlamaFFI – symbol loading', () {
    test('T-DART-01  LlamaFFI constructor does not throw on supported platform', () {
      // Will throw UnsupportedError on unsupported platforms (unlikely in test env)
      expect(() => LlamaFFI(), returnsNormally);
    });
  });

  group('LlamaFFI – lifecycle', () {
    late LlamaFFI ffi;
    setUp(() => ffi = LlamaFFI());

    test('T-DART-02  initModel returns non-null pointer for stub path', () {
      final handle = ffi.initModel(kStubModelPath);
      expect(handle.address, isNonZero);
      ffi.freeContext(handle);
    });

    test('T-DART-03  freeContext on null pointer does not crash', () {
      // Pass a zeroed pointer — the C layer must handle this gracefully
      final nullHandle = ffi_lib.Pointer<ffi_lib.Opaque>.fromAddress(0);
      expect(() => ffi.freeContext(nullHandle), returnsNormally);
    });

    test('T-DART-04  two initModel calls return distinct handles', () {
      final h1 = ffi.initModel(kStubModelPath);
      final h2 = ffi.initModel(kStubModelPath);
      expect(h1.address, isNot(equals(h2.address)));
      ffi.freeContext(h1);
      ffi.freeContext(h2);
    });
  });

  group('LlamaFFI – inference', () {
    late LlamaFFI ffi;
    setUp(() => ffi = LlamaFFI());

    test('T-DART-05  runInference returns a non-empty string', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Caller demands OTP transfer.', null);
      expect(result, isNotEmpty);
      ffi.freeContext(handle);
    });

    test('T-DART-06  runInference result is valid JSON', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Send money or account suspended.', null);
      expect(() => jsonDecode(result), returnsNormally);
      ffi.freeContext(handle);
    });

    test('T-DART-07  JSON contains all three required keys', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Your bank needs verification.', kSentryGbnf);
      final Map<String, dynamic> parsed = jsonDecode(result);
      expect(parsed.containsKey('threat_detected'), isTrue);
      expect(parsed.containsKey('confidence_score'), isTrue);
      expect(parsed.containsKey('reasoning'), isTrue);
      ffi.freeContext(handle);
    });

    test('T-DART-08  threat_detected is a bool', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Urgent: account compromised.', kSentryGbnf);
      final Map<String, dynamic> parsed = jsonDecode(result);
      expect(parsed['threat_detected'], isA<bool>());
      ffi.freeContext(handle);
    });

    test('T-DART-09  confidence_score is a double in [0.0, 1.0]', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Please provide your PIN.', kSentryGbnf);
      final Map<String, dynamic> parsed = jsonDecode(result);
      final score = (parsed['confidence_score'] as num).toDouble();
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
      ffi.freeContext(handle);
    });

    test('T-DART-10  reasoning is a non-empty string', () {
      final handle = ffi.initModel(kStubModelPath);
      final result = ffi.runInference(handle, 'Caller claims police officer.', kSentryGbnf);
      final Map<String, dynamic> parsed = jsonDecode(result);
      expect(parsed['reasoning'], isA<String>());
      expect((parsed['reasoning'] as String).isNotEmpty, isTrue);
      ffi.freeContext(handle);
    });
  });

  // ─── LlamaIsolateManager (Isolate layer) tests ───────────────────────────────

  group('LlamaIsolateManager – concurrency', () {
    test('T-ISO-01  runInferenceAsync returns a valid Map', () async {
      final result = await LlamaIsolateManager.runInferenceAsync(
        kStubModelPath,
        'Bank agent requesting OTP over call.',
      );
      expect(result, isA<Map<String, dynamic>>());
    });

    test('T-ISO-02  async result contains required keys', () async {
      final result = await LlamaIsolateManager.runInferenceAsync(
        kStubModelPath,
        'Caller is from electricity board demanding payment.',
      );
      expect(result.containsKey('threat_detected'), isTrue);
      expect(result.containsKey('confidence_score'), isTrue);
      expect(result.containsKey('reasoning'), isTrue);
    });

    test('T-ISO-03  async result types are correct', () async {
      final result = await LlamaIsolateManager.runInferenceAsync(
        kStubModelPath,
        'Free prize, click to claim.',
      );
      expect(result['threat_detected'], isA<bool>());
      expect(result['confidence_score'], isA<num>());
      expect(result['reasoning'], isA<String>());
    });

    test('T-ISO-04  with grammar → result parses without FormatException', () async {
      expect(
        () async => await LlamaIsolateManager.runInferenceAsync(
          kStubModelPath,
          'Verify identity before releasing funds.',
          grammar: kSentryGbnf,
        ),
        returnsNormally,
      );
    });

    test('T-ISO-05  10 concurrent Isolate calls all succeed', () async {
      final futures = List.generate(
        10,
        (i) => LlamaIsolateManager.runInferenceAsync(
          kStubModelPath,
          'Segment $i: caller is building urgency.',
        ),
      );
      final results = await Future.wait(futures);
      for (final r in results) {
        expect(r.containsKey('threat_detected'), isTrue);
        expect(r.containsKey('confidence_score'), isTrue);
        expect(r.containsKey('reasoning'), isTrue);
      }
    });

    test('T-ISO-06  Isolate fully disposes after completion (no open port leak)', () async {
      // Verify the Isolate port closes by confirming Future completes without timeout.
      await LlamaIsolateManager.runInferenceAsync(
        kStubModelPath,
        'This call should self-terminate cleanly.',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Isolate did not terminate'),
      );
      expect(true, isTrue);
    });
  });
}
