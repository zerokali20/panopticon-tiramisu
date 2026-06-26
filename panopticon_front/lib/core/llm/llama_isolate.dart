import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'llama_ffi.dart';

class IsolateRequest {
  final SendPort sendPort;
  final String modelPath;
  final String prompt;
  final String? grammar;

  IsolateRequest({
    required this.sendPort,
    required this.modelPath,
    required this.prompt,
    this.grammar,
  });
}

class LlamaIsolateManager {
  /// Runs the LLM inference in a background isolate to ensure the UI thread is never blocked.
  /// This fulfills the strict UI stutter constraints for the Panopticon project.
  static Future<Map<String, dynamic>> runInferenceAsync(
    String modelPath, 
    String prompt, 
    {String? grammar}
  ) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateEntryPoint, 
      IsolateRequest(
        sendPort: receivePort.sendPort,
        modelPath: modelPath,
        prompt: prompt,
        grammar: grammar,
      ),
    );

    final response = await receivePort.first as String;
    
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Failed to parse LLM output: $response');
    }
  }

  static void _isolateEntryPoint(IsolateRequest request) {
    final ffiLayer = LlamaFFI();
    ffi.Pointer<ffi.Opaque>? handle;
    
    try {
      handle = ffiLayer.initModel(request.modelPath);
      if (handle == ffi.nullptr) {
        throw Exception('Failed to initialize model at ${request.modelPath}');
      }
      
      final result = ffiLayer.runInference(handle, request.prompt, request.grammar);
      request.sendPort.send(result);
    } catch (e) {
      request.sendPort.send('{"threat_detected": false, "confidence_score": 0.0, "reasoning": "Error: ${e.toString().replaceAll('"', '\\"')}"}');
    } finally {
      if (handle != null && handle != ffi.nullptr) {
        // Enforce deterministic cleanup to prevent native memory leaks
        ffiLayer.freeContext(handle);
      }
    }
  }
}
