<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- 🌊  HEADER BANNER                                                      -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:3a8296,50:1a5276,100:091519&height=200&text=Panopticon%20Aurora%202026&fontSize=48&fontColor=61DAFB&fontAlignY=35&animation=twinkling&section=header&desc=Tira%20Miss%20%U%20%&descSize=16&descColor=88C0D0&descAlignY=55" width="100%" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Android-API%2036-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
  <img src="https://img.shields.io/badge/AI-On--Device%20Only-FF6B6B?style=for-the-badge&logo=openai&logoColor=white"/>
  <img src="https://img.shields.io/badge/Privacy-Zero%20Egress-6BCB77?style=for-the-badge&logo=shield&logoColor=white"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge"/>
</p>

<p align="center">
  <strong>Real-time, zero-egress voice phishing & deepfake audio defense — two local LLMs analyze your live calls without sending a single byte to any server.</strong>
</p>

---

## 📋 Table of Contents

- [What is Panopticon?](#-what-is-panopticon)
- [The Problem](#-the-problem)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
  - [Dual-Model Multi-Agent Pipeline](#dual-model-multi-agent-pipeline)
  - [GraphRAG Knowledge Subsystem](#graphrag-knowledge-subsystem)
  - [Audio Processing Pipeline](#audio-processing-pipeline)
- [App Screens & Workflows](#-app-screens--workflows)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Build the Native Library](#build-the-native-library)
  - [Run Code Generators](#run-code-generators)
  - [Serving Models Locally](#serving-models-locally)
  - [Run on Android](#run-on-android)
- [Model Files](#-model-files)
- [Testing](#-testing)
- [Key Design Decisions](#-key-design-decisions)
- [Roadmap](#-roadmap)
- [Competition Track](#-competition-track)

---

## 🔭 What is Panopticon?

**Panopticon** is a fully **on-device, multi-agent AI system** for Android that acts as an objective, logical co-pilot during phone calls. It intercepts live call audio, transcribes it using Whisper.cpp STT, and passes the diarized transcript through a dual-LLM agent pipeline that detects voice phishing (vishing), deepfake audio impersonation, and social engineering attacks — all with **100% data sovereignty**.

### What to Expect

When you install and run Panopticon on your Android device:
1. **First Launch (Model Setup)**: The app will authenticate you (via biometric Face ID/PIN) and immediately begin a **one-time download** of the required AI models (~8.8 GB total) directly to your device's internal storage. **Models are NOT preloaded in the APK to keep the app size small.**
2. **Background Monitoring**: Once initialized, Panopticon runs silently in the background. It listens to incoming phone calls locally using the device microphone/call audio.
3. **Live Threat Overlay**: During a call, if suspicious patterns are detected (e.g., someone asking for an OTP, urgency, claiming to be a bank), a floating UI overlay appears over your call screen. It displays a real-time transcript and a color-coded risk indicator (🟢 Safe, 🟡 Suspicious, 🔴 Threat).
4. **Zero-Egress**: Absolutely **no audio or transcripts are sent to the cloud**. All processing, including speech-to-text and LLM reasoning, happens entirely on your phone's processor.

> _"An objective evaluator that never panics, never doubts, and never leaves your device."_

---

## 🚨 The Problem

Voice phishing (vishing) and AI-generated deepfake audio have emerged as one of the fastest-growing cybersecurity threats of 2024–2026:

- **Victims under psychological stress** cannot objectively evaluate suspicious calls in real time
- **Deepfake voice cloning** makes caller impersonation trivially easy and increasingly convincing
- **Existing solutions are cloud-based** — they require sending private call audio to remote servers, creating serious privacy risks and regulatory conflicts
- **No real-time, on-device AI defense** existed for ordinary mobile users — until now

Panopticon solves this by bringing the AI directly onto the device, monitoring every word in real time, and intervening before the victim can be manipulated.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🧠 **Dual-Model AI Router** | Lightweight Sentry Agent runs always-on; heavy Context Agent activates only on threat detection |
| 🔒 **Zero Cloud Egress** | All AI inference, vector search, and graph traversal runs entirely on-device |
| 🎙️ **Real-Time STT** | Whisper.cpp transcribes live call audio with speaker diarization (caller vs. user) |
| 📊 **GraphRAG Knowledge** | ObjectBox HNSW vector store + Drift/SQLite knowledge graph of fraud patterns & financial entities |
| 🔕 **Audio Denoising** | RNNoise C++ library suppresses background noise before transcription |
| 🟢🟡🔴 **Risk Overlay** | Live call UI shows color-coded risk indicator (green/amber/red) updated in real time |
| 📱 **Lazy Loading** | Heavy 8B model never loads unless Sentry confidence ≥ 0.75 — stays responsive on mid-range devices |
| 🔐 **Grammar-Constrained Output** | GBNF grammar ensures LLMs always emit valid, parseable JSON — no hallucinated formats |
| 🌐 **OTA Model Download** | App binary is lightweight; GGUF model files stream to device on first launch |
| 📂 **Call History** | Persistent log of all analyzed calls with threat scores and reasoning |

---

## 🏗️ System Architecture

### Dual-Model Multi-Agent Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│                          INCOMING CALL                            │
└─────────────────────┬──────────────────────────────────────────-─┘
                       │
                       ▼
        ┌────────────────────────┐
        │  Audio Capture Layer   │  ← Android InCallService / Telecom API
        │  RNNoise Denoising     │  ← C++ noise suppression (rnnoise-0.2)
        │  PCM → 16kHz mono      │  ← Resampling for Whisper
        └────────────┬───────────┘
                      │
                      ▼
        ┌────────────────────────┐
        │  Whisper.cpp STT       │  ← On-device Speech-to-Text
        │  Speaker Diarization   │  ← Tags each segment: caller / user
        └────────────┬───────────┘
                      │ TranscriptSegment stream
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AGENT ROUTER                              │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  SENTRY AGENT (Always-On)                                  │   │
│  │  Model  : Phi-3-mini-4k-instruct (Q4_K_M, ~2.2 GB)         │   │
│  │  Runs   : Every 2 caller transcript segments               │   │
│  │  Detects: Authority claims, Urgency pressure, PII probes   │   │
│  │  Output : RiskAssessment { threat, confidence, reason }    │   │
│  └──────────────────────┬───────────────────────────────────┘    │
│                          │                                         │
│                          │ confidence ≥ 0.75?                      │
│                          │                                         │
│                          ▼                                         │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  CONTEXT AGENT (On-Demand)                                 │   │
│  │  Model  : Llama-3.1-8B-Instruct (Q6_K, ~6.6 GB)            │   │
│  │  RAG    : Semantic search → ObjectBox (HNSW vectors)       │   │
│  │  Graph  : Entity lookup → Drift/SQLite knowledge graph     │   │
│  │  Output : Deep forensic RiskAssessment with evidence       │   │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────────-┘
                           │
                           ▼
              ┌────────────────────────────────┐
              │      CallOverlayScreen UI       │
              │  🟢 Safe  🟡 Suspicious  🔴 Threat │
              │  Real-time transcript display   │
              │  Reasoning panel on threat       │
              └────────────────────────────────┘
```

### GraphRAG Knowledge Subsystem

The Context Agent is grounded by a dual-database knowledge system seeded on first launch:

```
GraphRAG
├── ObjectBox (Vector Store)
│   ├── 384-dimensional HNSW index
│   ├── Fraud advisory documents
│   ├── Bank SMS templates & patterns
│   ├── Known vishing script fragments
│   └── Semantic similarity search for Context Agent RAG lookup
│
└── Drift / SQLite (Knowledge Graph)
    ├── Financial institution entities
    ├── Official bank hotline numbers (Sri Lanka)
    ├── Entity-relationship graph (bank → branches → hotlines)
    └── Caller ID cross-referencing against known legitimate numbers
```

**Ingestion Pipeline:**
- `DocumentChunkingPipeline` — sliding-window text chunker
- `VectorSeeder` — embeds and indexes fraud advisories into ObjectBox
- `GraphSeeder` — populates Drift SQLite with institution & relationship data
- SHA-256 deterministic document IDs for safe re-ingestion without duplication

### Audio Processing Pipeline

```
Phone Call Audio (raw PCM)
        │
        ▼
C++ / JNI RNNoise (rnnoise-0.2)   ← Recurrent neural network noise suppression
        │
        ▼
16kHz Mono Resampler              ← Whisper.cpp requires 16kHz, mono channel
        │
        ▼
Whisper.cpp STT Engine            ← On-device automatic speech recognition
        │
        ▼
Speaker Diarizer                  ← Labels: "CALLER:" / "USER:"
        │
        ▼
TranscriptSegment                 ← Typed Dart object fed to AgentRouter
```

**Native Bridge:** All C++ components are compiled via CMake into `libllama_bridge.so` (Android) and accessed from Dart through the `ffi` package via `llama_ffi.dart`.

---

## 📱 App Screens & Workflows

### 1. 🚀 Boot Screen
**First-launch only.** Streams the GGUF model files (Phi-3 ~2.2GB + Llama 3.1 ~6.6GB) from a configurable HTTP server into `ApplicationSupportDirectory`. Shows live download progress with percentage and speed indicator. Once complete, never shown again.

### 2. 🔐 Auth Screen
User authentication and onboarding. Sets up the user profile and grants required system permissions (microphone, phone state, notification access).

### 3. 🏠 Home Screen
Main dashboard showing:
- System readiness status (models loaded, databases seeded)
- Recent threat activity summary
- Quick access to call history
- Agent status indicators (Sentry active, Context Agent standby)
- Navigation to all app sections

### 4. 📞 Call Overlay Screen *(Core Feature)*
The live call monitoring experience:
- **Real-time transcript** scrolling as the call progresses
- **Risk indicator** color band (🟢 green → 🟡 amber → 🔴 red) updates per analysis cycle
- **Sentry status bar** showing current scan cycle
- **Context Agent activation panel** — appears when confidence ≥ 0.75 with detailed reasoning
- **Evidence panel** — shows which GraphRAG documents were retrieved
- **Threat breakdown** — Authority / Urgency / PII signal scores

### 5. 📋 Calls Screen
Historical log of all analyzed calls:
- Timeline view of past calls with risk level badge
- Full transcript replay
- Per-call RiskAssessment details (threat score, agent reasoning, GraphRAG evidence)
- Filter by risk level (All / Threats / Safe)

### 6. ⚙️ Settings Screen
Configuration options:
- Model server URL (for local development / custom hosting)
- Sentry confidence threshold (default: 0.75)
- Context Agent sensitivity
- Notification preferences
- Database reset / re-seed option

### 7. 👤 Profile Screen
User account management and preferences.

### 8. 🔬 Audio Test Screen *(Developer Tool)*
Internal screen for testing the audio pipeline in isolation — feed recorded audio files through the STT + agent pipeline without a live call.

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter (Dart) | Cross-platform app UI |
| **Routing** | go_router 14.x | Declarative app navigation |
| **Animations** | flutter_animate | Micro-animations & transitions |
| **Fonts** | Google Fonts (Inter) | Typography |
| **AI Runtime** | llama.cpp (C++) | On-device LLM inference |
| **FFI Bridge** | Dart `ffi` package | Dart ↔ C++ interop |
| **STT Engine** | Whisper.cpp | On-device speech-to-text |
| **Audio Denoising** | RNNoise 0.2 | Recurrent neural network noise suppression |
| **Audio I/O** | Oboe (C++) | Low-latency Android audio |
| **Vector Store** | ObjectBox 5.0 | HNSW vector similarity search |
| **Relational DB** | Drift 2.18 (SQLite) | Type-safe ORM & knowledge graph |
| **Build System** | CMake 3.22.1 | Native C++ library compilation |
| **Android NDK** | 28.2.13676358 (or 30.x) | Native code compilation |
| **Target Platform** | Android API 36, arm64-v8a | Primary deployment target |
| **HTTP Client** | Dio 5.x | Model file download |
| **Permissions** | permission_handler | Microphone, phone state |
| **Hashing** | crypto (SHA-256) | Deterministic document IDs |
| **Code Generation** | build_runner, drift_dev, objectbox_generator | Schema & binding generation |

---

## 📁 Project Structure

```
panopticon-tiramisu/                  ← Repository root
├── README.md                         ← This file
├── docs/
│   └── tira-miss-u/                  ← Project documentation assets
└── panopticon_front/                 ← Flutter application
    ├── pubspec.yaml                  ← Dart dependencies & assets
    ├── analysis_options.yaml         ← Linting rules
    ├── android/                      ← Android platform project
    │   ├── app/
    │   │   ├── build.gradle.kts      ← App-level Gradle (smart NDK resolution)
    │   │   └── src/main/cpp/
    │   │       ├── CMakeLists.txt    ← C++ build config (Oboe, RNNoise bridge)
    │   │       └── whisper/          ← Whisper.cpp STT engine source
    │   ├── build.gradle.kts          ← Root Gradle config
    │   ├── gradle.properties         ← Global Gradle props (NDK override)
    │   └── local.properties          ← Per-machine SDK paths (git-ignored)
    ├── native/
    │   └── libllama_bridge/          ← C++ llama.cpp wrapper library
    │       ├── CMakeLists.txt        ← CMake build definition
    │       ├── llama_bridge.cpp      ← C API wrapping llama.cpp
    │       ├── llama_bridge.h        ← Public C header
    │       └── build_host/Release/   ← Pre-built Windows DLL (local testing)
    ├── rnnoise-0.2/                  ← RNNoise noise suppression source
    ├── lib/
    │   ├── main.dart                 ← App entry point & async bootstrap
    │   ├── objectbox-model.json      ← ObjectBox entity schema
    │   ├── objectbox.g.dart          ← ObjectBox generated bindings
    │   │
    │   ├── core/                     ← Business logic & AI pipeline
    │   │   ├── ffi/                  ← Dart FFI native bindings
    │   │   │   ├── llama_ffi.dart        ← FFI bindings to libllama_bridge
    │   │   │   └── llama_isolate.dart    ← Background Isolate for non-blocking inference
    │   │   └── services/
    │   │       └── model_manager.dart    ← OTA model download & path management
    │   │
    │   ├── data/                     ← Data layer & knowledge bases
    │   │   ├── mock_data.dart        ← Dev/test mock data
    │   │   └── graph_rag/
    │   │       ├── db/               ← Drift schema & DAOs (SQLite graph)
    │   │       ├── objectbox/        ← ObjectBox store & vector search service
    │   │       ├── ingestion/
    │   │       │   ├── graph_seeder.dart             ← Seeds financial institution graph
    │   │       │   ├── vector_seeder.dart            ← Seeds fraud advisory vectors
    │   │       │   ├── embedding_bridge.dart         ← Embedding interface
    │   │       │   └── document_chunking_pipeline.dart ← Sliding-window chunker
    │   │       └── graph_rag.dart    ← GraphRAG facade / main service
    │   │
    │   ├── screens/                  ← UI screens
    │   │   ├── auth_screen.dart          ← Login & onboarding
    │   │   ├── boot_screen.dart          ← First-launch model downloader
    │   │   ├── home_screen.dart          ← Main dashboard
    │   │   ├── call_overlay_screen.dart  ← Live call monitoring UI ⭐
    │   │   ├── calls_screen.dart         ← Call history & logs
    │   │   ├── settings_screen.dart      ← App configuration
    │   │   └── profile_screen.dart       ← User profile
    │   │
    │   ├── ui/
    │   │   └── audio_test_screen.dart    ← Developer audio pipeline test tool
    │   │
    │   ├── widgets/                  ← Reusable UI components
    │   │   └── bottom_nav.dart           ← Bottom navigation bar
    │   │
    │   ├── services/                 ← App-level services
    │   │
    │   └── theme/
    │       └── app_colors.dart           ← Design system color tokens
    │
    ├── assets/
    │   └── grammars/                 ← GBNF grammar files for constrained LLM output
    │       └── sentry_grammar.gbnf       ← JSON output grammar for both agents
    │
    ├── models/                       ← GGUF model files (git-ignored, ~8.8 GB total)
    │   ├── sentry.gguf               ← Phi-3-mini-4k-instruct-q4
    │   └── context.gguf              ← Meta-Llama-3.1-8B-Instruct-Q6_K
    │
    └── test/
        ├── agent_integration_test.dart   ← Pipeline unit tests (no model needed)
        └── live_inference_test.dart      ← End-to-end inference tests (requires models)
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Flutter SDK | ≥ 3.24 | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| Dart SDK | ≥ 3.3.0 | Bundled with Flutter |
| Android Studio | Latest | For SDK Manager & emulator |
| Android SDK | API 36 | Install via SDK Manager |
| Android Build-Tools | 35.0.0 | Install via SDK Manager |
| Android NDK | 28.2.13676358 or 30.x | Install via SDK Manager |
| CMake | 3.22.1 | Install via SDK Manager Tools |
| Python 3 | Any | For local model HTTP server |

---

### Build the Native Library

The C++ `libllama_bridge` must be compiled before running the app:

```bash
# Navigate to the native library directory
cd panopticon_front/native/libllama_bridge

# Configure CMake build
cmake -S . -B build_host

# Build in Release mode (use all CPU cores)
cmake --build build_host --config Release --parallel
```


### Run Code Generators

```bash
cd panopticon_front

# Install all Dart/Flutter dependencies
flutter pub get

# Run all code generators (ObjectBox bindings + Drift DAOs)
dart run build_runner build --delete-conflicting-outputs
```

---

### Serving Models Locally (For Development)

On first launch the app downloads the GGUF model files (~8.8 GB). During development, serve them from your local machine to avoid slow repeated downloads over the internet:

```bash
#Step 1: Place the GGUF files in the models directory
#   panopticon_front/models/sentry.gguf   (~2.2 GB)
#   panopticon_front/models/context.gguf  (~6.6 GB)

#Step 2: Start the file server (keep this terminal open while testing)
cd panopticon_front/models
python -m http.server 8000
```

Then update `_baseUrl` in `lib/core/services/model_manager.dart`:

```dart
// For Android Emulator:
static const _baseUrl = 'http://10.0.2.2:8000';

// For physical device on same LAN (replace with your PC's IP):
static const _baseUrl = 'http://192.168.x.x:8000';
```

---

### Run on Android

```bash
cd panopticon_front

# See all connected devices
flutter devices

# Run in debug mode on a specific device
flutter run -d <device-id>

# Run in release mode (recommended for performance testing)
flutter run --release -d <device-id>
```

> **Installation Workflow**: When you run the app on your device for the very first time, you will be greeted by the **Boot Screen**. This screen streams the required model files (listed below) directly to your device's internal storage and saves them. This is a one-time step. Once downloaded, the models remain on your device permanently.

---

## 🤖 Model Files

To keep the initial APK install size small and comply with App Store size limits, the GGUF model files are **not bundled** inside the APK. They are downloaded directly to the device during the first app launch:

| Agent | File | Size | Quantization | Source |
|---|---|---|---|---|
| Sentry (Phi-3-mini) | `sentry.gguf` | ~2.2 GB | Q4_K_M | [HuggingFace ↗](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf) |
| Context (Llama 3.1 8B) | `context.gguf` | ~6.6 GB | Q6_K | [HuggingFace ↗](https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K.gguf) |

> Both files are listed in `.gitignore` and must be obtained separately. Keep them in `panopticon_front/models/` for local development.

---

## 🧪 Testing

### Unit Tests *(No model files required — completes in seconds)*

```bash
flutter test test/agent_integration_test.dart --reporter=expanded
```

Covers: prompt construction, transcript windowing, RAG/graph injection, speaker diarization handling, `RiskAssessment` JSON parsing, and grammar constraint validation.

---

### Live Inference Tests *(Requires model files — ~5–10 min)*

```bash
flutter test test/live_inference_test.dart --reporter=expanded --timeout=600s
```

Feeds scripted call transcripts through the full `AgentRouter` pipeline and asserts correct outputs:

| Test Scenario | Expected Result |
|---|---|
| OTP-harvesting vishing call | `threat=true`, `confidence ≥ 0.70` — Sentry activates |
| Benign doctor appointment call | `threat=false` or `confidence < 0.40` |
| Safe-account transfer scam | Context Agent activates, `confidence ≥ 0.75` |

> Tests are automatically **skipped** if GGUF model files are not present — CI never breaks.

---

### Native C++ Bridge Tests *(No Flutter required)*

```bash
# Windows
.\native\libllama_bridge\build_host\Release\llama_bridge_tests.exe
```

22 tests covering: model lifecycle management, inference output schema, grammar enforcement, and memory safety. All passing ✅

---

## 🧠 Key Design Decisions

### 🔒 Zero-Egress Privacy
All inference, vector search, and graph traversal runs on-device. Panopticon has no backend, no analytics SDK, and no telemetry. The **only** network call ever made is the one-time OTA model download on first launch. Every call is analyzed inside a fully private, local sandbox.

### 🚀 Non-Blocking Startup
`runApp()` is called immediately on app launch so the screen is never blank. GraphRAG initialization (ObjectBox + Drift) bootstraps asynchronously via `FutureBuilder` inside `_AppRoot`, keeping the UI visible and interactive from the very first frame.

### 💤 Lazy Context Agent
The heavy 8B Llama model is **never loaded** at call start. It activates only when the Sentry Agent reports `confidence ≥ 0.75`. This keeps RAM usage to ~2.2 GB during normal benign calls, with the full 8.8 GB inference pipeline consuming resources only when a genuine threat is suspected — making Panopticon viable on mid-range Android devices.

### 📐 Grammar-Constrained LLM Output
Both agents use a **GBNF grammar file** (`assets/grammars/sentry_grammar.gbnf`) loaded directly into llama.cpp's sampler. This guarantees the model **always** emits valid, parseable JSON — even under adversarial prompt injection:

```json
{
  "threat_detected": true,
  "confidence_score": 0.87,
  "reasoning": "Caller claimed to be a bank official and demanded OTP within 5 minutes."
}
```

No hallucinated output formats. No broken JSON. Guaranteed schema compliance.

### 🗄️ Dual-Database GraphRAG
Two complementary technologies serve different retrieval needs:

- **ObjectBox HNSW** → *"Which fraud patterns are semantically similar to what I'm hearing?"* — vector similarity search
- **Drift / SQLite** → *"Is this caller's number registered to a known bank hotline?"* — exact entity lookup

Together they give the Context Agent both semantic depth and structured factual grounding.

### 🎵 arm64-v8a Only Build
The Android build targets `arm64-v8a` ABI exclusively (enforced via `abiFilters` in `build.gradle.kts`). This avoids x86 SIMD header conflicts in RNNoise and Whisper, halves build time, and matches the real-world deployment target — all modern Android phones are arm64.

### 🧵 Background Isolate Inference
LLM inference runs inside a dedicated **Dart Isolate** (`llama_isolate.dart`). This ensures the main UI thread and audio capture thread are never blocked by token generation — the call overlay UI stays perfectly responsive even while the 8B model is actively running.

---

## 🗺️ Roadmap

-  **Real InCallService Integration** — Connect live Android call audio stream directly to the pipeline via `InCallService` API
-  **iOS Support** — Port `libllama_bridge` with Metal GPU acceleration for Apple Silicon
-  **Real On-Device Embedding Model** — Replace deterministic embedding stub with a local sentence-transformer
-  **Whisper Multi-Language STT** — Support Sinhala, Tamil, and other regional languages
-  **Federated Threat Updates** — Privacy-preserving OTA updates to the fraud advisory vector store
-  **Wearable Alert Integration** — Haptic notification to a paired smartwatch on threat detection
-  **Continuous Knowledge Graph Updates** — Versioned OTA updates to the financial institution entity graph
-  **Ablation Dashboard** — In-app comparison view: Sentry-only vs. full pipeline accuracy

---

## 🏆 Competition Track

**Track:** Undergraduate Competition — *Panopticon Aurora 2026*

This project was developed as an undergraduate competition entry demonstrating that enterprise-grade, real-time AI security systems can be deployed entirely on consumer mobile hardware without compromising user privacy. Panopticon integrates real-time audio perception, autonomous multi-agent reasoning, and proactive user intervention to neutralize social engineering attacks — acting as an objective, logical evaluator during high-stress communications.

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:091519,50:1a3a4a,100:0d1f2d&height=120&section=footer&animation=twinkling" width="100%" />
</p>

<p align="center">
  <sub>Tira-miss-u&nbsp;©&nbsp; Panopticon Aurora 2026</sub>
</p>

