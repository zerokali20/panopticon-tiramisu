/**
 * llama_bridge.cpp
 * ─────────────────────────────────────────────────────────────────────────────
 * Low-level C-ABI wrapper over llama.cpp exposing exactly the three functions
 * declared in llama_bridge.h:
 *
 *   init_model()    – load a GGUF model off disk into an opaque handle
 *   run_inference() – tokenise a prompt, apply a GBNF grammar sampler, decode
 *                     tokens in a loop, return heap-allocated JSON string
 *   free_context()  – tear down every llama_* object, delete the wrapper heap
 *
 * Compile-time modes (set by CMake):
 *   LLAMA_REAL=1  → links against llama.cpp; full inference pipeline active.
 *   LLAMA_REAL=0  → stub mode; returns deterministic mock JSON so that
 *                   Dart FFI / Isolate layers can be tested independently.
 *
 * Memory contract:
 *   - The caller owns nothing inside LlamaWrapper; it is heap-allocated
 *     here and freed by free_context().
 *   - Strings returned by run_inference() are malloc'd; the caller must
 *     call free_string() — never plain free() or delete — to remain
 *     ABI-safe across compiler boundaries on Android.
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include "llama_bridge.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <stdexcept>

#if defined(ANDROID) || defined(__ANDROID__)
#  include <android/log.h>
#  define LOG_TAG "llama_bridge"
#  define BRIDGE_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#  define BRIDGE_LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#else
#  define BRIDGE_LOGE(...) fprintf(stderr, "[llama_bridge ERR] " __VA_ARGS__); fprintf(stderr, "\n")
#  define BRIDGE_LOGI(...) fprintf(stdout, "[llama_bridge INF] " __VA_ARGS__); fprintf(stdout, "\n")
#endif

// ─── Real llama.cpp path ─────────────────────────────────────────────────────
#if LLAMA_REAL

#include "llama.h"   // from vendor/llama.cpp/include/

/**
 * LlamaWrapper
 * Owns all llama.cpp objects for a single model session.
 * Freed exclusively through free_context().
 */
struct LlamaWrapper {
    llama_model*   model   = nullptr;
    llama_context* ctx     = nullptr;
    llama_sampler* sampler = nullptr;

    ~LlamaWrapper() {
        // Tear down in reverse-dependency order.
        if (sampler) { llama_sampler_free(sampler); sampler = nullptr; }
        if (ctx)     { llama_free(ctx);             ctx     = nullptr; }
        if (model)   { llama_model_free(model);     model   = nullptr; }
    }
};

// ─── init_model ──────────────────────────────────────────────────────────────
LlamaContextHandle init_model(const char* model_path) {
    if (!model_path || model_path[0] == '\0') {
        BRIDGE_LOGE("init_model: model_path is null or empty");
        return nullptr;
    }

    llama_model_params mparams = llama_model_default_params();
    // Keep memory footprint low on mobile: use mmap and limit GPU layers.
    mparams.use_mmap    = true;
    mparams.n_gpu_layers = 0;  // CPU-only; set higher if Vulkan backend available

    llama_model* model = llama_model_load_from_file(model_path, mparams);
    if (!model) {
        BRIDGE_LOGE("init_model: failed to load model from '%s'", model_path);
        return nullptr;
    }

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx    = 2048;   // context window (tokens)
    cparams.n_batch  = 512;    // prompt processing batch size
    cparams.n_threads = 4;     // physical cores; tune for device

    llama_context* ctx = llama_new_context_with_model(model, cparams);
    if (!ctx) {
        BRIDGE_LOGE("init_model: failed to create context");
        llama_model_free(model);
        return nullptr;
    }

    LlamaWrapper* wrapper = new LlamaWrapper();
    wrapper->model = model;
    wrapper->ctx   = ctx;
    // sampler is built lazily per-call inside run_inference so grammar can vary

    BRIDGE_LOGI("init_model: loaded '%s' successfully", model_path);
    return static_cast<LlamaContextHandle>(wrapper);
}

// ─── run_inference ────────────────────────────────────────────────────────────
char* run_inference(LlamaContextHandle handle,
                    const char*        prompt,
                    const char*        gbnf_grammar) {
    if (!handle) {
        BRIDGE_LOGE("run_inference: null handle");
        return nullptr;
    }
    if (!prompt || prompt[0] == '\0') {
        BRIDGE_LOGE("run_inference: prompt is null or empty");
        return nullptr;
    }

    LlamaWrapper* w = static_cast<LlamaWrapper*>(handle);

    // ── 1. Build sampler chain ────────────────────────────────────────────────
    // Destroy any sampler left from a previous call so we can apply a fresh grammar.
    if (w->sampler) {
        llama_sampler_free(w->sampler);
        w->sampler = nullptr;
    }

    llama_sampler_chain_params sparams = llama_sampler_chain_default_params();
    w->sampler = llama_sampler_chain_init(sparams);

    // Grammar constraint (GBNF): applied first so it masks invalid logits
    // before temperature / top-p operate on the remaining distribution.
    if (gbnf_grammar && gbnf_grammar[0] != '\0') {
        const llama_vocab* vocab = llama_model_get_vocab(w->model);
        llama_sampler* grammar_sampler =
            llama_sampler_init_grammar(vocab, gbnf_grammar, "root");
        if (grammar_sampler) {
            llama_sampler_chain_add(w->sampler, grammar_sampler);
            BRIDGE_LOGI("run_inference: GBNF grammar applied (%zu bytes)", strlen(gbnf_grammar));
        } else {
            BRIDGE_LOGE("run_inference: failed to compile GBNF grammar — proceeding without constraint");
        }
    }

    // Temperature → greedy-ish but still stochastic for the reasoning field
    llama_sampler_chain_add(w->sampler, llama_sampler_init_temp(0.1f));
    // Greedy argmax as the final selector
    llama_sampler_chain_add(w->sampler, llama_sampler_init_greedy());

    // ── 2. Tokenise prompt ───────────────────────────────────────────────────
    const llama_vocab* vocab      = llama_model_get_vocab(w->model);
    const int          prompt_len = static_cast<int>(strlen(prompt));

    // Pre-size: worst case is one token per byte + BOS
    std::vector<llama_token> tokens(prompt_len + 4);
    int n_tokens = llama_tokenize(vocab,
                                  prompt, prompt_len,
                                  tokens.data(),
                                  static_cast<int>(tokens.size()),
                                  /* add_special= */ true,
                                  /* parse_special= */ true);
    if (n_tokens < 0) {
        // Buffer was too small; resize and retry
        tokens.resize(-n_tokens + 4);
        n_tokens = llama_tokenize(vocab,
                                  prompt, prompt_len,
                                  tokens.data(),
                                  static_cast<int>(tokens.size()),
                                  true, true);
    }
    if (n_tokens < 0) {
        BRIDGE_LOGE("run_inference: tokenisation failed");
        return nullptr;
    }
    tokens.resize(n_tokens);

    // ── 3. Decode the prompt (prefill) ────────────────────────────────────────
    llama_memory_seq_rm(llama_get_memory(w->ctx), -1, -1, -1);

    llama_batch batch = llama_batch_get_one(tokens.data(), n_tokens);
    if (llama_decode(w->ctx, batch) != 0) {
        BRIDGE_LOGE("run_inference: llama_decode (prefill) failed");
        return nullptr;
    }

    // ── 4. Autoregressive sampling loop ──────────────────────────────────────
    const int max_new_tokens = 512;
    std::string output;
    output.reserve(256);

    char  piece_buf[256];
    int   n_generated = 0;
    const llama_token eos = llama_vocab_eos(vocab);

    while (n_generated < max_new_tokens) {
        llama_token token_id = llama_sampler_sample(w->sampler, w->ctx, /* idx= */ -1);

        if (token_id == eos) {
            break;
        }

        // Convert token id → UTF-8 piece
        int piece_len = llama_token_to_piece(vocab,
                                             token_id,
                                             piece_buf,
                                             sizeof(piece_buf),
                                             /* lstrip= */ 0,
                                             /* special= */ false);
        if (piece_len < 0) {
            // Buffer too small for this piece; skip gracefully
            ++n_generated;
            continue;
        }

        output.append(piece_buf, static_cast<size_t>(piece_len));

        // Feed the chosen token back for the next step
        llama_batch next_batch = llama_batch_get_one(&token_id, 1);
        if (llama_decode(w->ctx, next_batch) != 0) {
            BRIDGE_LOGE("run_inference: llama_decode (generation step %d) failed", n_generated);
            break;
        }

        ++n_generated;
    }

    BRIDGE_LOGI("run_inference: generated %d tokens", n_generated);

    // ── 5. Return heap-allocated C-string ────────────────────────────────────
    char* result = static_cast<char*>(malloc(output.size() + 1));
    if (!result) {
        BRIDGE_LOGE("run_inference: malloc failed for result string");
        return nullptr;
    }
    memcpy(result, output.c_str(), output.size() + 1);
    return result;
}

// ─── free_string ─────────────────────────────────────────────────────────────
void free_string(char* str) {
    free(str);  // matched malloc in run_inference
}

// ─── free_context ─────────────────────────────────────────────────────────────
void free_context(LlamaContextHandle handle) {
    if (!handle) return;
    LlamaWrapper* w = static_cast<LlamaWrapper*>(handle);
    delete w;  // ~LlamaWrapper() frees sampler → ctx → model in order
    BRIDGE_LOGI("free_context: all resources released");
}

// ─── Stub / mock path ─────────────────────────────────────────────────────────
#else  // LLAMA_REAL == 0

/**
 * STUB MODE
 * ──────────
 * When llama.cpp is not yet vendored we still compile a fully functional
 * shared library whose returns are deterministic, grammar-valid JSON strings.
 * This lets the Dart FFI / Isolate / UI layers be developed and tested
 * independently before the ~4 GB model files are available on the device.
 *
 * The stub preserves the EXACT same memory contract as the real path:
 *   - init_model()    returns a non-null opaque pointer
 *   - run_inference() returns a malloc'd string the caller must free_string()
 *   - free_context()  deletes the wrapper with no leaks
 */
struct LlamaWrapper {
    char model_path[512];  // retained for logging / test assertions
};

LlamaContextHandle init_model(const char* model_path) {
    if (!model_path || model_path[0] == '\0') return nullptr;
    LlamaWrapper* w = new LlamaWrapper();
    snprintf(w->model_path, sizeof(w->model_path), "%s", model_path);
    BRIDGE_LOGI("init_model [STUB]: handle created for '%s'", model_path);
    return static_cast<LlamaContextHandle>(w);
}

char* run_inference(LlamaContextHandle handle,
                    const char*        prompt,
                    const char*        /*gbnf_grammar*/) {
    if (!handle || !prompt || prompt[0] == '\0') return nullptr;
    LlamaWrapper* w = static_cast<LlamaWrapper*>(handle);

    // Deterministic output that always satisfies sentry_grammar.gbnf.
    // The reasoning field contains the first 80 chars of the prompt so
    // integration tests can verify the prompt was received correctly.
    char reasoning_excerpt[81] = {0};
    strncpy(reasoning_excerpt, prompt, 80);

    // Escape any embedded double-quotes in the excerpt for valid JSON.
    std::string safe_excerpt;
    for (char c : std::string(reasoning_excerpt)) {
        if (c == '"')  safe_excerpt += "\\\"";
        else if (c == '\\') safe_excerpt += "\\\\";
        else safe_excerpt += c;
    }

    std::string json =
        "{"
        "\"threat_detected\":true,"
        "\"confidence_score\":0.91,"
        "\"reasoning\":\"[STUB] Received prompt: " + safe_excerpt + "\""
        "}";

    char* result = static_cast<char*>(malloc(json.size() + 1));
    if (!result) return nullptr;
    memcpy(result, json.c_str(), json.size() + 1);
    BRIDGE_LOGI("run_inference [STUB]: returned %zu bytes for model '%s'",
                json.size(), w->model_path);
    return result;
}

void free_string(char* str) {
    free(str);
}

void free_context(LlamaContextHandle handle) {
    if (!handle) return;
    LlamaWrapper* w = static_cast<LlamaWrapper*>(handle);
    BRIDGE_LOGI("free_context [STUB]: releasing handle for '%s'", w->model_path);
    delete w;
}

#endif  // LLAMA_REAL
