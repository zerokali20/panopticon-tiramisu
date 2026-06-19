import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Signatures for C++ functions
typedef _InitializeDartApiC = IntPtr Function(Pointer<Void> data);
typedef _InitializeDartApiDart = int Function(Pointer<Void> data);

typedef _RegisterSendPortC = Void Function(Int64 port);
typedef _RegisterSendPortDart = void Function(int port);

typedef _InitializeWhisperC = Bool Function(Pointer<Utf8> modelPath);
typedef _InitializeWhisperDart = bool Function(Pointer<Utf8> modelPath);

typedef _StartAudioPipelineC = Bool Function();
typedef _StartAudioPipelineDart = bool Function();

typedef _StopAudioPipelineC = Void Function();
typedef _StopAudioPipelineDart = void Function();

class OboeFfiBindings {
  static final DynamicLibrary _lib = Platform.isAndroid
      ? DynamicLibrary.open('libpanopticon_audio.so')
      : DynamicLibrary.process();

  static final _InitializeDartApiDart initializeDartApi = _lib
      .lookup<NativeFunction<_InitializeDartApiC>>('InitializeDartApi')
      .asFunction();

  static final _RegisterSendPortDart registerSendPort = _lib
      .lookup<NativeFunction<_RegisterSendPortC>>('RegisterSendPort')
      .asFunction();

  static final _InitializeWhisperDart initializeWhisper = _lib
      .lookup<NativeFunction<_InitializeWhisperC>>('InitializeWhisper')
      .asFunction();

  static final _StartAudioPipelineDart startAudioPipeline = _lib
      .lookup<NativeFunction<_StartAudioPipelineC>>('StartAudioPipeline')
      .asFunction();

  static final _StopAudioPipelineDart stopAudioPipeline = _lib
      .lookup<NativeFunction<_StopAudioPipelineC>>('StopAudioPipeline')
      .asFunction();
}
