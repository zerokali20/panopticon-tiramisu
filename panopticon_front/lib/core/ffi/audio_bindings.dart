import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:ffi/ffi.dart';

class AudioPipelineBridge {
  static final DynamicLibrary _lib = Platform.isAndroid
      ? DynamicLibrary.open('libpanopticon_audio.so')
      : DynamicLibrary.process();

  static final int Function(int) testBridge = _lib
      .lookup<NativeFunction<Int32 Function(Int32)>>('test_audio_bridge')
      .asFunction();

  // FFI bindings for Dart API DL (for Dart_PostCObject_DL)
  static final int Function(Pointer<Void>) _initializeDartApi = _lib
      .lookup<NativeFunction<IntPtr Function(Pointer<Void>)>>('InitializeDartApi')
      .asFunction();

  static final void Function(int) _registerSendPort = _lib
      .lookup<NativeFunction<Void Function(Int64)>>('RegisterSendPort')
      .asFunction();

  static final bool Function(Pointer<Utf8>) _initializeWhisper = _lib
      .lookup<NativeFunction<Bool Function(Pointer<Utf8>)>>('InitializeWhisper')
      .asFunction();

  // Stream controller to broadcast transcripts to the UI
  static final StreamController<String> _transcriptController = StreamController<String>.broadcast();
  static Stream<String> get transcriptStream => _transcriptController.stream;

  static ReceivePort? _receivePort;

  /// Call this once at app startup
  static void initialize() {
    // 1. Initialize Dart API DL on the C++ side
    _initializeDartApi(NativeApi.initializeApiDLData);

    // 2. Set up the ReceivePort
    _receivePort = ReceivePort();
    _receivePort!.listen((message) {
      if (message is String) {
        _transcriptController.add(message);
      }
    });

    // 3. Register the native port with C++
    _registerSendPort(_receivePort!.sendPort.nativePort);
  }

  /// Load the Whisper model
  static bool loadWhisperModel(String modelPath) {
    final pointer = modelPath.toNativeUtf8();
    final success = _initializeWhisper(pointer);
    malloc.free(pointer);
    return success;
  }
}
