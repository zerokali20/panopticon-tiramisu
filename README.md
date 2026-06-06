panopticon-tiramisu


## Audio Recognition Setup (Whisper.cpp)

This document explains the local speech-to-text setup for the Panopticon / Vocal Sentinel audio subsystem.

## Purpose

The audio subsystem converts speech audio into text locally using Whisper.cpp. This transcript can then be passed to the local reasoning pipeline for scam/vishing detection.

## Current Pipeline

```
Audio File
↓
Whisper.cpp CLI
↓
GGML Base Model
↓
Dart Transcription Service
↓
Transcript Output

```
First create a local `tools` directory in the repository root and clone Whisper.cpp into it:

```
mkdir tools
cd tools
git clone https://github.com/ggml-org/whisper.cpp.git
```

This creates:

```
panopticon-tiramisu/tools/whisper.cpp
```

## Folder Structure

```
panopticon-tiramisu/
├── panopticon_front/
│   └── lib/services/transcription/
│       ├── transcription_service.dart
│       ├── whisper_transcription_service.dart
│       └── transcription.dart
└── tools/
    └── whisper.cpp/
```

## Whisper.cpp Setup

Whisper.cpp is stored under:

```
tools/whisper.cpp
```

Build command:

```
cmake -B build
cmake --build build --config Release
```

The generated executable is:

```
tools/whisper.cpp/build/bin/Release/whisper-cli.exe
```

## Model Setup

The current model used is Whisper Base:

```
.\models\download-ggml-model.cmd base
```

This creates:

```
tools/whisper.cpp/ggml-base.bin
```

Model files are ignored by Git because they are large.

## Direct Whisper Test

```
.\build\bin\Release\whisper-cli.exe -m .\ggml-base.bin -f .\samples\jfk.wav
```

## Dart Wrapper Test

From `panopticon_front`:
Run this inside the `panopticon_front` folder, not the root folder of the project

```
dart run test/transcribe_audio_test.dart --executable="C:\Users\Exam\Desktop\Projects\AUrora\GIT\panopticon-tiramisu\tools\whisper.cpp\build\bin\Release\whisper-cli.exe" --model="C:\Users\Exam\Desktop\Projects\AUrora\GIT\panopticon-tiramisu\tools\whisper.cpp\ggml-base.bin" --audio="C:\Users\Exam\Desktop\Projects\AUrora\GIT\panopticon-tiramisu\tools\whisper.cpp\samples\jfk.wav"
```

Verified result:

```
Transcription completed successfully.
```

## Notes

* Whisper.cpp build files should not be committed.
* Whisper model files should not be committed.
* The current implementation uses `Process.run()` from Dart to call the Whisper.cpp CLI.
* Future work may include real-time audio streaming, microphone/call audio capture, noise reduction, and speaker verification.
