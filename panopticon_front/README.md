# Panopticon — On-Device AI Vishing Detection

> **Real-time, zero-egress social engineering detection for Android.**  
> Two on-device LLMs analyse live call transcripts and alert users to vishing, deepfake impersonation, and financial fraud — without sending a single byte off the device.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Running on Android](#running-on-android)
  - [Serving Models Locally](#serving-models-locally)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Key Design Decisions](#key-design-decisions)

---

## Overview

Panopticon intercepts live phone call audio, transcribes it on-device via Whisper.cpp, and passes the diarized transcript through a dual-LLM agent pipeline:

| Agent | Model | Role |
|---|---|---|
| **Sentry** | Phi-3-mini-4k-instruct (Q4, ~2.2 GB) | Lightweight, always-on fast scanner. Runs every 2 caller segments. |
| **Context** | Llama-3.1-8B-Instruct (Q6_K, ~6.6 GB) | Deep forensic analyser. Lazy — only activates when Sentry confidence ≥ 0.75. |

Both models run entirely on-device via a custom **llama.cpp FFI bridge** (`libllama_bridge.so` / `llama_bridge.dll`). No API keys. No cloud calls. No data leaves the phone.

---

## Architecture

```
Incoming Call Audio
        │
        ▼
  Whisper.cpp STT  ──► TranscriptSegment stream
        │
        ▼
   AgentRouter
   ┌────────────────────────────────────────┐
   │  SentryAgent (Phi-3-mini)              │
   │  • Runs every 2 caller segments        │
   │  • Detects: Authority + Urgency + PII  │
   │  • Emits RiskAssessment (JSON)         │
   │          │                             │
   │   confidence ≥ 0.75?                   │
   │          │                             │
   │          ▼                             │
   │  ContextAgent (Llama-3.1-8B)          │
   │  • RAG lookup  → ObjectBox vectors     │
   │  • Graph query → SQLite/Drift graph    │
   │  • Deep forensic prompt               │
   │  • Emits final RiskAssessment          │
   └────────────────────────────────────────┘
        │
        ▼
  CallOverlayScreen UI
  (green / amber / red risk indicator)
```

### Audio Pipeline (To Be Integrated)

To connect real phone calls to the `AgentRouter`, the following audio processing pipeline needs to be implemented and wired up:

1. **Audio Capture**: Intercept the incoming call audio stream (and the user's microphone) using Android's `InCallService` or a telecom API wrapper.
2. **Audio Resampling**: Downsample the raw PCM audio to 16kHz, mono-channel, which is required by Whisper.
3. **On-Device STT (Whisper.cpp)**: Feed the audio chunks into the local Whisper.cpp engine to generate text transcriptions in real-time.
4. **Diarization**: Tag each transcribed chunk with the correct speaker (`caller` or `user`).
5. **Routing**: Wrap each tagged chunk in a `TranscriptSegment` object and feed it to `AgentRouter.addSegment(segment)`.

### GraphRAG Layer

On first launch, two local databases are seeded with verified Sri Lankan financial institution data:

- **ObjectBox** — Vector store (384-dim HNSW index) of fraud advisories, bank SMS templates, and vishing script patterns. Used for semantic retrieval by the Context Agent.
- **Drift / SQLite** — Knowledge graph of banks, hotlines, and entity relationships. Used to cross-reference caller IDs against known legitimate numbers.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.24
- Android SDK with NDK **28.2.13676358**
- A standard Android emulator (API 34+) or physical Android device  
  ⚠️ The 16KB page-size emulator (`gphone16k`) is **not supported** — use the standard `gphone64` image.
- Python 3 (to serve models locally during development)

### Running on Android

```bash
# From panopticon_front/
flutter run -d <device-id>
```

On first launch the app downloads the two GGUF model files. For local development, serve them from your machine instead (see below).

### Serving Models Locally

If you already have the GGUF files on your PC, serve them over the emulator's host alias (`10.0.2.2`) instead of downloading from HuggingFace:

```bash
# Place models in panopticon_front/models/
#   models/sentry.gguf   — Phi-3-mini-4k-instruct-q4
#   models/context.gguf  — Meta-Llama-3.1-8B-Instruct-Q6_K

# Start the file server (keep this terminal open while testing)
cd panopticon_front/models
python -m http.server 8000
```

The app is pre-configured to fetch from `http://10.0.2.2:8000` when running on an emulator. Model files from HuggingFace:

| File | Source |
|---|---|
| `sentry.gguf` | [Phi-3-mini-4k-instruct-q4](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf) |
| `context.gguf` | [Meta-Llama-3.1-8B-Instruct-Q6_K](https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K.gguf) |

---

## Project Structure

```
panopticon_front/
├── lib/
│   ├── main.dart                          # App entry point & async GraphRAG bootstrap
│   ├── core/
│   │   ├── agents/
│   │   │   ├── agent_router.dart          # Dual-agent orchestrator (main entry point)
│   │   │   ├── sentry_agent.dart          # Phi-3-mini continuous scanner
│   │   │   ├── context_agent.dart         # Llama-3.1-8B forensic analyser
│   │   │   ├── prompt_builder.dart        # Structured prompt construction
│   │   │   └── models/
│   │   │       ├── risk_assessment.dart   # Typed LLM output (threat + confidence + reasoning)
│   │   │       └── transcript_segment.dart
│   │   ├── llm/
│   │   │   ├── llama_ffi.dart             # Dart FFI bindings to llama_bridge native lib
│   │   │   └── llama_isolate.dart         # Background Dart Isolate for non-blocking inference
│   │   ├── rag/                           # RAG interface + stub
│   │   ├── graph/                         # Graph interface + stub
│   │   └── services/
│   │       └── model_manager.dart         # OTA model download & path management
│   ├── data/
│   │   └── graph_rag/
│   │       ├── db/                        # Drift schema & DAOs (SQLite knowledge graph)
│   │       ├── objectbox/                 # ObjectBox store & vector search service
│   │       └── ingestion/
│   │           ├── graph_seeder.dart      # Seeds financial institution knowledge graph
│   │           ├── vector_seeder.dart     # Seeds fraud advisory vector store
│   │           ├── embedding_bridge.dart  # EmbeddingBridge interface + deterministic stub
│   │           └── document_chunking_pipeline.dart  # Sliding-window text chunker
│   └── screens/
│       ├── boot_screen.dart               # Model download progress UI
│       └── call_overlay_screen.dart       # Live call risk indicator (green/amber/red)
├── native/
│   └── libllama_bridge/                   # C++ llama.cpp wrapper
│       └── build_host/Release/            # Pre-built Windows DLLs for local testing
├── models/                                # GGUF model files (git-ignored)
│   ├── sentry.gguf
│   └── context.gguf
└── test/
    ├── agent_integration_test.dart        # Prompt structure & pipeline unit tests (no model)
    └── live_inference_test.dart           # End-to-end inference tests with real GGUF models
```

---

## Testing

### Unit Tests (no model files required — runs in seconds)

```bash
flutter test test/agent_integration_test.dart --reporter=expanded
```

Tests prompt construction, transcript windowing, RAG/graph injection, speaker diarization, and `RiskAssessment` JSON parsing.

### Live Inference Tests (requires model files — takes ~5–10 min)

```bash
flutter test test/live_inference_test.dart --reporter=expanded --timeout=600s
```

Feeds three scripted transcripts through the full `AgentRouter` pipeline and asserts correct `RiskAssessment` outputs:

| Scenario | Expected result |
|---|---|
| OTP-harvesting vishing call | `threat=true`, `confidence ≥ 0.70` (Sentry) |
| Benign doctor appointment call | `threat=false` or `confidence < 0.40` |
| Safe-account transfer scam | Context Agent activates, `confidence ≥ 0.75` |

Tests are automatically **skipped** if model files are not present on disk, so they never break CI.

### Native C++ Bridge Tests (no Flutter required)

```bash
.\native\libllama_bridge\build_host\Release\llama_bridge_tests.exe
```

22 tests covering model lifecycle, inference output schema, grammar enforcement, and memory safety. All passing.

---

## Key Design Decisions

### Zero-Egress Privacy
All inference, vector search, and graph traversal runs on-device. The app has no backend, no analytics, no telemetry. The only network call is the one-time OTA model download.

### Non-Blocking Startup
`runApp()` is called immediately on launch. GraphRAG database initialisation (ObjectBox + Drift) happens asynchronously inside an `AppStartup` widget using a `FutureBuilder`, so the user sees the Panopticon splash screen instantly rather than a blank white screen.

### Lazy Context Agent
The heavy 8B model is never loaded at call start. It only activates when the Sentry agent exceeds a 0.75 confidence threshold — keeping the app responsive on mid-range devices throughout normal calls.

### Grammar-Constrained Output
Both agents use a GBNF grammar file (`sentry_grammar.gbnf`) to constrain llama.cpp's sampler, guaranteeing the model always emits valid `{"threat_detected": bool, "confidence_score": float, "reasoning": string}` JSON — even under adversarial prompt conditions.

### Dual-Database GraphRAG
- **ObjectBox** (HNSW vector index) handles semantic similarity search over fraud advisory documents.  
- **Drift/SQLite** handles structured entity lookups — e.g. resolving a caller's phone number against known bank hotlines.  
Both are seeded once on first launch and never require a network connection thereafter.
