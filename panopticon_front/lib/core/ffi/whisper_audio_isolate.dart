import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'oboe_ffi_bindings.dart';

class WhisperAudioIsolate {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  
  // Stream controller to broadcast transcribed text to the UI
  final _transcriptionController = StreamController<String>.broadcast();
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  Future<void> start(String modelPath) async {
    _receivePort = ReceivePort();

    // Listen for messages from C++ thread
    _receivePort!.listen((message) {
      if (message is String) {
        _transcriptionController.add(message);
      }
    });

    // Spawn a worker isolate to initialize the engine to prevent UI jank
    _isolate = await Isolate.spawn(_workerIsolateEntry, {
      'sendPort': _receivePort!.sendPort,
      'modelPath': modelPath,
      'nativePort': _receivePort!.sendPort.nativePort,
    });
  }

  void stop() {
    OboeFfiBindings.stopAudioPipeline();
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  static void _workerIsolateEntry(Map<String, dynamic> args) {
    final String modelPath = args['modelPath'];
    final int nativePort = args['nativePort'];

    // 1. Initialize Dart API for FFI callbacks
    final res = OboeFfiBindings.initializeDartApi(NativeApi.initializeApiDLData);
    if (res != 0) {
      print("Failed to initialize Dart API DL");
      return;
    }

    // 2. Register the ReceivePort's native port ID
    OboeFfiBindings.registerSendPort(nativePort);

    // 3. Initialize Whisper model
    final ptrModelPath = modelPath.toNativeUtf8();
    final initSuccess = OboeFfiBindings.initializeWhisper(ptrModelPath);
    malloc.free(ptrModelPath);

    if (!initSuccess) {
      print("Failed to initialize whisper in native pipeline");
      return;
    }

    // 4. Start the Oboe Audio stream
    final startSuccess = OboeFfiBindings.startAudioPipeline();
    if (!startSuccess) {
      print("Failed to start Oboe audio pipeline");
      return;
    }

    print("Native audio pipeline started successfully");
  }
}
