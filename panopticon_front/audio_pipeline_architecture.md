# Panopticon Audio Pipeline Architecture

## Overview
Panopticon employs a dual-path audio ingestion pipeline designed for real-time voice phishing (vishing) detection. The architecture guarantees low-latency capture of both the local user's microphone and the remote caller's system audio (VoIP loopback), seamlessly multiplexing them into an on-device C++ inference engine.

## Step-by-Step Architecture

### 1. The Trigger (Dart / Flutter UI)
The pipeline is initiated from the Flutter frontend. When the user activates the loopback monitor:
- The UI binds to a platform-specific `MethodChannel` (`com.panopticon/audio_loopback`).
- A `startLoopbackCapture` method is invoked.
- Ensure the Whisper isolate is booted: `WhisperAudioIsolate.start(_modelPath)` fires up the background Dart thread, initializing the C++ Whisper model via `Dart_PostCObject_DL`.

### 2. Android Permission & Media Projection (Kotlin Native)
The Android `MainActivity` intercepts the `MethodChannel` call and requests a `MediaProjection` token by launching a Screen Capture Intent.
- Once the user grants permission, `onActivityResult` triggers the `AudioCaptureService`, passing the projection token.

### 3. Background Audio Capture Service (Kotlin Foreground Service)
The `AudioCaptureService` runs persistently in the background, bound to a Foreground Notification to prevent OS termination.
- **AudioPlaybackCaptureConfiguration**: It configures an `AudioRecord` to capture system audio matching `USAGE_MEDIA`, `USAGE_UNKNOWN`, and `USAGE_VOICE_COMMUNICATION` (VoIP).
- **Format**: It records in `ENCODING_PCM_FLOAT` at 16kHz, perfectly aligning with Whisper's ingestion requirements.
- **Buffer Loop**: A background thread continuously reads chunks of exactly 480 floats (matching the RNNoise frame size) and passes them to C++ via a JNI bridge (`pushAudioDataToCpp`).

### 4. JNI Bridge (C++ / Android NDK)
The `dart_api_integration.cpp` file exposes a `JNIEXPORT` function.
- It receives the Java `FloatArray`, extracts the raw C++ pointer array (`jfloat*`), and pushes the frames directly into the global `g_AudioEngine.pushExternalAudio()` method.

### 5. Thread-Safe Multiplexing (C++ Audio Engine)
Since the app can receive audio from both the local microphone (via Oboe) and the system loopback (via JNI) concurrently:
- `AudioEngine::process_oboe_splashes` is guarded by a `std::mutex mCupMutex`.
- Both streams safely dump their `float` PCM data into a shared `measuring_cup` `std::vector<float>`.

### 6. Denoising (RNNoise)
Once the `measuring_cup` accumulates 480 frames, the chunks are extracted and cleaned using the RNNoise neural network library to eliminate background static and improve transcription accuracy.

### 7. Inference (Whisper.cpp)
Cleaned audio is appended to a 3-second `mAudioBuffer`.
- Once full, a `std::condition_variable` wakes up the C++ Worker Thread.
- Whisper processes the 3-second PCM array and generates a text transcription.
- The transcribed string is serialized and sent back to Dart via `Dart_PostCObject_DL`.

### 8. Dart Isolate Stream (Flutter)
The background Dart isolate receives the C++ message through its `ReceivePort` and broadcasts it to the main Flutter UI thread via a `StreamController`, completing the loop in under 500ms.

---

## Initiation Code Snippets

### Flutter Initiation
```dart
// Ensure Whisper isolate is running first
await _audioIsolate.start(modelPath);

// Trigger loopback capture
const platform = MethodChannel('com.panopticon/audio_loopback');
await platform.invokeMethod('startLoopbackCapture');
```

### JNI Definition
```cpp
JNIEXPORT void JNICALL
Java_com_example_panopticon_AudioCaptureService_pushAudioDataToCpp(JNIEnv *env, jobject thiz, jfloatArray audioData, jint numFrames) {
    jfloat *elements = env->GetFloatArrayElements(audioData, 0);
    g_AudioEngine.pushExternalAudio(elements, numFrames);
    env->ReleaseFloatArrayElements(audioData, elements, 0);
}
```

### Kotlin Capture Loop
```kotlin
thread {
    val floatBuffer = FloatArray(480)
    while (isRecording) {
        val readStatus = audioRecord?.read(floatBuffer, 0, floatBuffer.size, AudioRecord.READ_BLOCKING) ?: 0
        if (readStatus > 0) {
            pushAudioDataToCpp(floatBuffer, readStatus)
        }
    }
}
```
