import 'dart:ffi';
import 'dart:io';

class AudioPipelineBridge {
  // 1. Open the dynamic library that CMake built
  static final DynamicLibrary _lib = Platform.isAndroid
      ? DynamicLibrary.open('libpanopticon_audio.so')
      : DynamicLibrary.process(); // iOS uses process()

  // 2. Define the C++ function signature (Int32 taking an Int32)
  static final int Function(int) testBridge = _lib
      .lookup<NativeFunction<Int32 Function(Int32)>>('test_audio_bridge')
      .asFunction();
}
