#include <stdint.h>
#include <string>
#include <jni.h>
#include "dart_api_dl.h"
#include "audio_engine.h"

// Global Audio Engine instance
AudioEngine g_AudioEngine;

extern "C" {

    // Initialize Dart API (required to use Dart_PostCObject_DL)
    intptr_t InitializeDartApi(void* data) {
        return Dart_InitializeApiDL(data);
    }

    // Register the SendPort from Dart
    void RegisterSendPort(int64_t port) {
        g_AudioEngine.setDartSendPort(port);
    }

    // Initialize the Whisper Model
    bool InitializeWhisper(const char* modelPath) {
        if (modelPath == nullptr) return false;
        return g_AudioEngine.initWhisper(std::string(modelPath));
    }

    // Start Oboe Audio Pipeline
    bool StartAudioPipeline() {
        return g_AudioEngine.start();
    }

    // Stop Audio Pipeline
    void StopAudioPipeline() {
        g_AudioEngine.stop();
    }
    JNIEXPORT void JNICALL
    Java_com_example_panopticon_AudioCaptureService_pushAudioDataToCpp(JNIEnv *env, jobject thiz, jfloatArray audioData, jint numFrames) {
        jfloat *elements = env->GetFloatArrayElements(audioData, 0);
        g_AudioEngine.pushExternalAudio(elements, numFrames);
        env->ReleaseFloatArrayElements(audioData, elements, 0);
    }
}
