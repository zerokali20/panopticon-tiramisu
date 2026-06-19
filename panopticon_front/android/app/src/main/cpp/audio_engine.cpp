#include "audio_engine.h"
#include <android/log.h>
#include "dart_api_dl.h"
#include "whisper.h"
#include "rnnoise.h"

#define LOG_TAG "PanopticonAudio"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

const int SAMPLE_RATE = 16000;
const int CHANNELS = 1;
// Wait for 3 seconds of audio before running whisper
const int BUFFER_SIZE_FRAMES = SAMPLE_RATE * 3;

AudioEngine::AudioEngine() {
    rnnoise_state = rnnoise_create(NULL);
    mWorkerRunning = true;
    mWorkerThread = std::thread(&AudioEngine::workerThreadLoop, this);
}

AudioEngine::~AudioEngine() {
    stop();
    
    mWorkerRunning = false;
    mWorkerCv.notify_one();
    if (mWorkerThread.joinable()) {
        mWorkerThread.join();
    }

    if (mWhisperCtx) {
        whisper_free(mWhisperCtx);
    }
    if (rnnoise_state) {
        rnnoise_destroy(rnnoise_state);
    }
}

bool AudioEngine::initWhisper(const std::string& modelPath) {
    struct whisper_context_params cparams = whisper_context_default_params();
    mWhisperCtx = whisper_init_from_file_with_params(modelPath.c_str(), cparams);
    if (mWhisperCtx == nullptr) {
        LOGE("Failed to initialize whisper context");
        return false;
    }
    LOGI("Whisper initialized successfully");
    return true;
}

void AudioEngine::setDartSendPort(int64_t port) {
    mDartSendPort = port;
}

bool AudioEngine::start() {
    oboe::AudioStreamBuilder builder;
    builder.setDirection(oboe::Direction::Input);
    builder.setPerformanceMode(oboe::PerformanceMode::LowLatency);
    builder.setSharingMode(oboe::SharingMode::Exclusive);
    builder.setFormat(oboe::AudioFormat::Float);
    builder.setChannelCount(CHANNELS);
    builder.setSampleRate(SAMPLE_RATE);
    builder.setCallback(this);

    oboe::Result result = builder.openStream(mStream);
    if (result != oboe::Result::OK) {
        LOGE("Failed to open stream. Error: %s", oboe::convertToText(result));
        return false;
    }

    result = mStream->requestStart();
    if (result != oboe::Result::OK) {
        LOGE("Failed to start stream. Error: %s", oboe::convertToText(result));
        return false;
    }

    LOGI("Audio stream started successfully");
    return true;
}

void AudioEngine::stop() {
    if (mStream) {
        mStream->requestStop();
        mStream->close();
        mStream.reset();
    }
}

oboe::DataCallbackResult AudioEngine::onAudioReady(oboe::AudioStream *oboeStream, void *audioData, int32_t numFrames) {
    float *floatData = static_cast<float *>(audioData);
    process_oboe_splashes(floatData, numFrames);
    return oboe::DataCallbackResult::Continue;
}

void AudioEngine::process_oboe_splashes(float* oboe_water, int num_drops) {
    std::lock_guard<std::mutex> lock(mCupMutex);
    
    // STEP 1: Pour the new water into our measuring cup
    measuring_cup.insert(measuring_cup.end(), oboe_water, oboe_water + num_drops);

    // STEP 2: Do we have at least 480 drops? 
    while (measuring_cup.size() >= RNNOISE_FRAME_SIZE) {
        // STEP 3: Scoop out exactly 480 drops from the front of the cup
        std::vector<float> scoop(measuring_cup.begin(), measuring_cup.begin() + RNNOISE_FRAME_SIZE);

        // STEP 4: Pour the scoop through the RNNoise filter to clean it
        clean_with_rnnoise(scoop.data()); 

        // STEP 5: Now the water is clean! Pour it into the big 3-second Whisper bucket
        pour_into_whisper_bucket(scoop); 

        // STEP 6: Remove the 480 drops we just processed from our measuring cup
        measuring_cup.erase(measuring_cup.begin(), measuring_cup.begin() + RNNOISE_FRAME_SIZE);
    }
}

void AudioEngine::pushExternalAudio(float* audioData, int numFrames) {
    if (mWorkerRunning) {
        process_oboe_splashes(audioData, numFrames);
    }
}

void AudioEngine::clean_with_rnnoise(float* scoop) {
    if (rnnoise_state) {
        // rnnoise_process_frame takes the State, the Output array, and the Input array.
        // Because we want to alter the audio "in-place", we put 'scoop' for both!
        rnnoise_process_frame(rnnoise_state, scoop, scoop);
    }
}

void AudioEngine::pour_into_whisper_bucket(const std::vector<float>& scoop) {
    std::lock_guard<std::mutex> lock(mBufferMutex);
    mAudioBuffer.insert(mAudioBuffer.end(), scoop.begin(), scoop.end());
    
    if (mAudioBuffer.size() >= BUFFER_SIZE_FRAMES && !mHasAudioToProcess) {
        mProcessingBuffer = std::move(mAudioBuffer);
        mAudioBuffer.clear();
        mHasAudioToProcess = true;
        mWorkerCv.notify_one();
    } else if (mAudioBuffer.size() >= BUFFER_SIZE_FRAMES * 2) {
        // Worker is too slow (model inference taking longer than 3 seconds)
        // Clear buffer to avoid memory leak and catch up to real-time audio
        mAudioBuffer.clear();
    }
}

void AudioEngine::workerThreadLoop() {
    while (mWorkerRunning) {
        std::unique_lock<std::mutex> lock(mBufferMutex);
        mWorkerCv.wait(lock, [this]() { return mHasAudioToProcess || !mWorkerRunning; });
        
        if (!mWorkerRunning) break;
        
        std::vector<float> localBuffer = std::move(mProcessingBuffer);
        mHasAudioToProcess = false;
        lock.unlock();

        if (!localBuffer.empty()) {
            processAudioForWhisper(localBuffer);
        }
    }
}

void AudioEngine::processAudioForWhisper(const std::vector<float>& buffer) {
    if (!mWhisperCtx) return;

    whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.print_progress = false;
    wparams.print_special = false;
    wparams.print_realtime = false;
    wparams.print_timestamps = false;
    wparams.translate = false;
    wparams.no_context = true;
    wparams.single_segment = true;
    wparams.language = "en";

    int ret = whisper_full(mWhisperCtx, wparams, buffer.data(), buffer.size());
    if (ret != 0) {
        LOGE("Failed to run whisper");
        return;
    }

    const int n_segments = whisper_full_n_segments(mWhisperCtx);
    std::string full_text = "";
    for (int i = 0; i < n_segments; ++i) {
        const char * text = whisper_full_get_segment_text(mWhisperCtx, i);
        full_text += text;
    }

    if (!full_text.empty() && mDartSendPort != -1) {
        Dart_CObject dart_object;
        dart_object.type = Dart_CObject_kString;
        dart_object.value.as_string = const_cast<char*>(full_text.c_str());
        
        Dart_PostCObject_DL(mDartSendPort, &dart_object);
    }
}
