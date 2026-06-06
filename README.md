
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- 🌊  HEADER BANNER                                                      -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:3a8296,50:1a5276,100:091519&height=200&text=Panopticon%20Aurora%202026&fontSize=48&fontColor=61DAFB&fontAlignY=35&animation=twinkling&section=header&desc=Tira%20Miss%20%U%20%&descSize=16&descColor=88C0D0&descAlignY=55" width="100%" />
</p>

## **Track:** Undergraduate Competition  

Panopticon is an on-device, multi-agent artificial intelligence system designed to combat the escalating threat of voice phishing (vishing) and deepfake audio manipulation. It integrates real-time audio perception, autonomous reasoning, and proactive user intervention to neutralize social engineering attacks by acting as an objective, logical evaluator during high-stress communications.

## Architecture

Panopticon runs locally with 100% on-device data sovereignty (zero cloud egress). It features a dual-model Multi-Agent Router:
- **Sentry Agent:** A lightweight model (Phi-3) that monitors the live STT transcript for threats.
- **Context Agent:** A larger 8B model (Llama 3.1) deployed dynamically via GraphRAG (ObjectBox + Drift) when the Sentry Agent triggers high confidence in a threat.

## Local LLM Setup & Deployment

To keep the application binary lightweight, the large `.gguf` language models are NOT bundled in the app repository. 

1. **On First Launch**: The app will launch into a `BootScreen` that streams the multi-gigabyte models directly into the device's `ApplicationSupportDirectory`.
2. **Local Testing**: During development, you must host the `.gguf` models on a local HTTP server.
   - Run `python -m http.server 8000` in your models directory.
   - Update `_baseUrl` in `lib/core/services/model_manager.dart` to match your local IP.

## Building the App

This project uses Flutter with a C++ native backend bridge (`llama.cpp`) connected via Dart FFI.
```bash
# Build native inference backend
cd panopticon_front/native/libllama_bridge
cmake -S . -B build_host
cmake --build build_host --config Release --parallel

# Run flutter application
cd panopticon_front
flutter run
```
