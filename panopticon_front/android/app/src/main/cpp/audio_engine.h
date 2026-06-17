#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

#include <oboe/Oboe.h>
#include <memory>
#include <vector>
#include <mutex>
#include <string>
#include <thread>
#include <condition_variable>
#include <atomic>
#include "rnnoise.h"

class AudioEngine : public oboe::AudioStreamCallback {
public:
    AudioEngine();
    ~AudioEngine();

    bool start();
    void stop();
    bool initWhisper(const std::string& modelPath);
    
    // External audio loopback bridge
    void pushExternalAudio(float* audioData, int numFrames);

    // From oboe::AudioStreamCallback
    oboe::DataCallbackResult onAudioReady(oboe::AudioStream *oboeStream, void *audioData, int32_t numFrames) override;

    void setDartSendPort(int64_t port);

private:
    std::shared_ptr<oboe::AudioStream> mStream;
    int64_t mDartSendPort = -1;
    
    // Audio buffer for 16kHz float32 data (Whisper 3-second bucket)
    std::vector<float> mAudioBuffer;
    std::vector<float> mProcessingBuffer;
    std::mutex mBufferMutex;
    
    // Worker thread for Whisper
    std::thread mWorkerThread;
    std::condition_variable mWorkerCv;
    std::atomic<bool> mWorkerRunning{false};
    bool mHasAudioToProcess = false;

    void workerThreadLoop();
    
    // RNNoise measuring cup
    std::vector<float> measuring_cup;
    std::mutex mCupMutex;
    const int RNNOISE_FRAME_SIZE = 480;

    void process_oboe_splashes(float* oboe_water, int num_drops);
    void clean_with_rnnoise(float* scoop);
    void pour_into_whisper_bucket(const std::vector<float>& scoop);

    // Whisper context
    struct whisper_context *mWhisperCtx = nullptr;
    
    // RNNoise context
    DenoiseState *rnnoise_state = nullptr;
    
    void processAudioForWhisper(const std::vector<float>& buffer);
};

#endif // AUDIO_ENGINE_H
