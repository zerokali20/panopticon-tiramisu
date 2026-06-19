# Whisper.cpp On-Device Transcription Setup Guide (Windows)

This document provides step-by-step instructions to get **Whisper.cpp** running locally on Windows and integrates it with the Panopticon project.

---

## 1. Obtain Whisper.cpp Executable (`main.exe`)

Whisper.cpp can be run either via pre-compiled binaries or by compiling it from source.

### Option A: Download Pre-compiled Binaries (Recommended)
1. Go to the official [Whisper.cpp GitHub Releases Page](https://github.com/ggerganov/whisper.cpp/releases).
2. Download the latest release zip file targeting Windows (e.g., `whisper-cublas-...` or standard CPU/OpenCL build).
3. Extract the contents to a local directory (e.g., `C:\whisper\`).
4. Ensure the directory contains `main.exe` (or `whisper-cli.exe` in newer releases).

### Option B: Build from Source
If you have Git and Visual Studio (with C++ build tools) installed:
```powershell
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
cmake -B build
cmake --build build --config Release
```
This builds `main.exe` under `build\bin\Release\main.exe`.

---

## 2. Download GGML Models

Whisper.cpp uses quantized models in the GGML `.bin` format. You will need a model file to run inference.

1. Go to the official HuggingFace model repository: [ggerganov/whisper.cpp at HuggingFace](https://huggingface.co/ggerganov/whisper.cpp/tree/main).
2. Download your preferred model (e.g. `ggml-tiny.en.bin` or `ggml-base.en.bin` for English-only; `ggml-tiny.bin` for multi-language).
3. Save the model in a local directory (e.g., `C:\whisper\models\ggml-tiny.bin`).

---

## 3. Audio Format Constraints

> [!WARNING]
> **Audio Constraint**: Whisper.cpp strictly requires input audio files to be in **16-bit, 16kHz mono PCM WAV** format. Using any other format (like stereo, 44.1kHz, MP3, or MP4) will cause Whisper.cpp to fail or return garbage transcripts.

### Converting Audio Files with FFmpeg
If your input audio file is in another format, you can easily convert it using FFmpeg:
```powershell
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```
- `-ar 16000`: Sets the audio sample rate to 16kHz.
- `-ac 1`: Downmixes audio to a single channel (mono).
- `-c:a pcm_s16le`: Encodes audio as 16-bit little-endian PCM.

---

## 4. How to Use the Transcription Module in Dart

Here is a quick snippet on how to instantiate and call the transcription service in your Dart/Flutter application:

```dart
import 'package:panopticon/services/transcription/transcription_service.dart';
import 'package:panopticon/services/transcription/whisper_transcription_service.dart';

void main() async {
  // 1. Define configuration
  final config = WhisperConfig(
    executablePath: r'C:\whisper\main.exe',
    modelPath: r'C:\whisper\models\ggml-tiny.bin',
    language: 'en',
    threads: 4,
  );

  // 2. Instantiate the service
  final TranscriptionService transcriptionService = WhisperTranscriptionService(config: config);

  try {
    // 3. Transcribe audio file
    print("Transcribing...");
    final String transcript = await transcriptionService.transcribe(r'C:\whisper\sample.wav');
    
    print("Transcription Result:\n$transcript");
  } catch (e) {
    print("Transcription failed: $e");
  }
}
```
