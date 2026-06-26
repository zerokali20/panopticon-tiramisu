/**
 * test_bridge_lifecycle.cpp
 * ─────────────────────────────────────────────────────────────────────────────
 * Unit tests for the init_model / free_context lifecycle.
 *
 * These tests do NOT require a real .gguf model on disk:
 *   - In STUB mode (LLAMA_REAL=0) they exercise the stub allocator/deallocator.
 *   - In REAL mode (LLAMA_REAL=1) they verify guard-rail behaviour (null path,
 *     missing file) without requiring a model to be present.
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include "test_framework.h"
#include "../llama_bridge.h"

#include <cstdlib>
#include <cstring>

void run_lifecycle_tests() {

    // ── T-LC-01: null path returns null handle ────────────────────────────────
    test::run_test("T-LC-01  init_model(null) -> returns nullptr", []() {
        LlamaContextHandle h = init_model(nullptr);
        EXPECT(h == nullptr);
        // Nothing was allocated so no free_context needed
    });

    // ── T-LC-02: empty path returns null handle ───────────────────────────────
    test::run_test("T-LC-02  init_model(\"\") -> returns nullptr", []() {
        LlamaContextHandle h = init_model("");
        EXPECT(h == nullptr);
    });

    // ── T-LC-03: non-existent path behaviour ──────────────────────────────────
    // STUB mode: path validity is not checked, returns a valid handle.
    // REAL mode: llama.cpp fails to open the file, returns nullptr.
    test::run_test("T-LC-03  init_model(bad_path) -> defined behaviour", []() {
        LlamaContextHandle h = init_model("/nonexistent/path/model.gguf");
#if LLAMA_REAL
        EXPECT(h == nullptr);
#else
        // Stub always succeeds — it never touches the filesystem
        EXPECT(h != nullptr);
        free_context(h);
#endif
    });

    // ── T-LC-04: valid (stub) path returns non-null ────────────────────────────
    test::run_test("T-LC-04  init_model(stub_path) -> non-null handle", []() {
        LlamaContextHandle h = init_model("C:/tmp/sentry.gguf");
#if LLAMA_REAL
        // In real mode this only passes if the file exists on the host.
        // On CI it is expected to return nullptr; we skip gracefully.
        (void)h;
        if (h) free_context(h);
#else
        EXPECT(h != nullptr);
        free_context(h);
#endif
    });

    // ── T-LC-05: free_context(null) does not crash ───────────────────────────
    test::run_test("T-LC-05  free_context(nullptr) -> no crash", []() {
        free_context(nullptr);  // must be a no-op
        EXPECT(true);           // reaching here = success
    });

    // ── T-LC-06: two independent handles from two init calls ──────────────────
    test::run_test("T-LC-06  two init_model calls -> distinct non-null handles", []() {
        LlamaContextHandle h1 = init_model("C:/tmp/model_a.gguf");
        LlamaContextHandle h2 = init_model("C:/tmp/model_b.gguf");
#if !LLAMA_REAL
        EXPECT(h1 != nullptr);
        EXPECT(h2 != nullptr);
        EXPECT(h1 != h2);  // distinct heap allocations
#endif
        free_context(h1);
        free_context(h2);
        EXPECT(true);
    });
}
