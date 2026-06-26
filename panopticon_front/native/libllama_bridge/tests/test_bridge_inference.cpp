/**
 * test_bridge_inference.cpp
 * ─────────────────────────────────────────────────────────────────────────────
 * Unit tests for run_inference / free_string.
 *
 * In STUB mode all tests run on the host with no model file required.
 * In REAL mode set the PANOPTICON_MODEL env-var to the .gguf path; tests
 * that cannot find the model skip gracefully instead of hard-failing.
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include "test_framework.h"
#include "../llama_bridge.h"

#include <cstdlib>
#include <cstring>
#include <string>

// ─── Helpers ─────────────────────────────────────────────────────────────────

static LlamaContextHandle make_handle() {
#if LLAMA_REAL
    const char* path = getenv("PANOPTICON_MODEL");
    if (!path) return nullptr;
    return init_model(path);
#else
    return init_model("C:/tmp/sentry_stub.gguf");
#endif
}

/// Returns true if `str` is a JSON object containing the three required keys.
static bool json_has_required_keys(const char* str) {
    if (!str) return false;
    const std::string s(str);
    return s.find("\"threat_detected\"")  != std::string::npos
        && s.find("\"confidence_score\"") != std::string::npos
        && s.find("\"reasoning\"")        != std::string::npos
        && s.front() == '{'
        && s.back()  == '}';
}

/// Quick well-formedness check: brace depth never goes negative and ends at 0.
static bool braces_balanced(const char* str) {
    if (!str) return false;
    int depth = 0;
    for (const char* p = str; *p; ++p) {
        if (*p == '{') ++depth;
        if (*p == '}') --depth;
        if (depth < 0) return false;
    }
    return depth == 0;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void run_inference_tests() {

    // ── T-INF-01: null handle returns nullptr ────────────────────────────────
    test::run_test("T-INF-01  run_inference(null_handle) -> nullptr", []() {
        char* result = run_inference(nullptr, "some prompt", nullptr);
        EXPECT(result == nullptr);
        free_string(result);  // free_string(null) must also be safe
    });

    // ── T-INF-02: null prompt returns nullptr ────────────────────────────────
    test::run_test("T-INF-02  run_inference(valid, null_prompt) -> nullptr", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, nullptr, nullptr);
        EXPECT(result == nullptr);
        free_string(result);
        free_context(h);
    });

    // ── T-INF-03: empty prompt returns nullptr ────────────────────────────────
    test::run_test("T-INF-03  run_inference(valid, \"\") -> nullptr", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "", nullptr);
        EXPECT(result == nullptr);
        free_string(result);
        free_context(h);
    });

    // ── T-INF-04: valid call returns non-null ────────────────────────────────
    test::run_test("T-INF-04  run_inference(valid, prompt) -> non-null", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Caller says there is an unpaid Dialog Axiata bill.", nullptr);
        EXPECT(result != nullptr);
        free_string(result);
        free_context(h);
    });

    // ── T-INF-05: output contains all required JSON keys ─────────────────────
    test::run_test("T-INF-05  output has threat_detected + confidence_score + reasoning", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "The caller is demanding OTP urgently.", nullptr);
        EXPECT(json_has_required_keys(result));
        free_string(result);
        free_context(h);
    });

    // ── T-INF-06: braces are balanced ────────────────────────────────────────
    test::run_test("T-INF-06  output has balanced braces", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Your account will be suspended in 10 minutes.", nullptr);
        EXPECT(braces_balanced(result));
        free_string(result);
        free_context(h);
    });

    // ── T-INF-07: output starts with '{' and ends with '}' ───────────────────
    test::run_test("T-INF-07  output is a JSON object (starts { ends })", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Please transfer 50000 LKR immediately.", nullptr);
        if (result) {
            const std::string s(result);
            EXPECT(!s.empty() && s.front() == '{' && s.back() == '}');
        }
        free_string(result);
        free_context(h);
    });

    // ── T-INF-08: free_string(null) is a no-op ───────────────────────────────
    test::run_test("T-INF-08  free_string(nullptr) -> no crash", []() {
        free_string(nullptr);
        EXPECT(true);
    });

    // ── T-INF-09: [STUB] reasoning contains the prompt excerpt ───────────────
#if !LLAMA_REAL
    test::run_test("T-INF-09  [STUB] reasoning contains prompt excerpt", []() {
        LlamaContextHandle h = make_handle();
        EXPECT(h != nullptr);
        const char* prompt = "Bank of Ceylon fraud alert OTP required";
        char* result = run_inference(h, prompt, nullptr);
        EXPECT(result != nullptr);
        if (result) {
            const std::string s(result);
            // Stub inserts the first 80 chars of the prompt into reasoning
            EXPECT(s.find("Bank of Ceylon") != std::string::npos);
        }
        free_string(result);
        free_context(h);
    });
#endif

    // ── T-INF-10: two consecutive calls on same handle succeed ────────────────
    test::run_test("T-INF-10  two consecutive calls -> independent results", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* r1 = run_inference(h, "First segment: hello caller.", nullptr);
        char* r2 = run_inference(h, "Second segment: new claim appeared.", nullptr);
        EXPECT(r1 != nullptr && r2 != nullptr);
        EXPECT(r1 != r2);  // distinct heap allocations
        free_string(r1);
        free_string(r2);
        free_context(h);
    });
}
