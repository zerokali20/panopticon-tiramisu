import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:io';

// Type definitions for C functions
typedef InitModelC = ffi.Pointer<ffi.Opaque> Function(ffi.Pointer<Utf8> modelPath);
typedef InitModelDart = ffi.Pointer<ffi.Opaque> Function(ffi.Pointer<Utf8> modelPath);

typedef RunInferenceC = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Opaque> handle, ffi.Pointer<Utf8> prompt, ffi.Pointer<Utf8> grammar);
typedef RunInferenceDart = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Opaque> handle, ffi.Pointer<Utf8> prompt, ffi.Pointer<Utf8> grammar);

typedef FreeStringC = ffi.Void Function(ffi.Pointer<Utf8> str);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8> str);

typedef FreeContextC = ffi.Void Function(ffi.Pointer<ffi.Opaque> handle);
typedef FreeContextDart = void Function(ffi.Pointer<ffi.Opaque> handle);

class LlamaFFI {
  late ffi.DynamicLibrary _lib;
  late InitModelDart _initModel;
  late RunInferenceDart _runInference;
  late FreeStringDart _freeString;
  late FreeContextDart _freeContext;

  LlamaFFI() {
    if (Platform.isAndroid) {
      _lib = ffi.DynamicLibrary.open('libllama_bridge.so');
    } else if (Platform.isIOS) {
      _lib = ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('llama_bridge.dll');
    } else if (Platform.isMacOS) {
      _lib = ffi.DynamicLibrary.process();
    } else if (Platform.isLinux) {
      _lib = ffi.DynamicLibrary.open('libllama_bridge.so');
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    _initModel = _lib.lookupFunction<InitModelC, InitModelDart>('init_model');
    _runInference = _lib.lookupFunction<RunInferenceC, RunInferenceDart>('run_inference');
    _freeString = _lib.lookupFunction<FreeStringC, FreeStringDart>('free_string');
    _freeContext = _lib.lookupFunction<FreeContextC, FreeContextDart>('free_context');
  }

  ffi.Pointer<ffi.Opaque> initModel(String modelPath) {
    final pathPtr = modelPath.toNativeUtf8();
    final handle = _initModel(pathPtr);
    calloc.free(pathPtr);
    return handle;
  }

  String runInference(ffi.Pointer<ffi.Opaque> handle, String prompt, String? grammar) {
    final promptPtr = prompt.toNativeUtf8();
    final grammarPtr = grammar != null ? grammar.toNativeUtf8() : ffi.nullptr;
    
    final resultPtr = _runInference(handle, promptPtr, grammarPtr);
    
    final result = resultPtr.toDartString();
    
    _freeString(resultPtr);
    calloc.free(promptPtr);
    if (grammarPtr != ffi.nullptr) {
      calloc.free(grammarPtr);
    }
    
    return result;
  }

  void freeContext(ffi.Pointer<ffi.Opaque> handle) {
    if (handle != ffi.nullptr) {
      _freeContext(handle);
    }
  }
}
