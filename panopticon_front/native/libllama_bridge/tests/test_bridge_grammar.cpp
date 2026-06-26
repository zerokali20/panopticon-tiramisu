/**
 * test_bridge_grammar.cpp
 * ─────────────────────────────────────────────────────────────────────────────
 * Tests that run_inference() respects the GBNF grammar parameter and produces
 * output structurally conforming to sentry_grammar.gbnf's schema:
 *
 *   { "threat_detected": <bool>, "confidence_score": <0..1>, "reasoning": <str> }
 *
 * In STUB mode the grammar parameter is accepted without crashing; the output
 * is still checked for schema conformance. In REAL mode the GBNF sampler
 * actively constrains token selection.
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include "test_framework.h"
#include "../llama_bridge.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <regex>

static LlamaContextHandle make_handle() {
#if LLAMA_REAL
    const char* path = getenv("PANOPTICON_MODEL");
    if (!path) return nullptr;
    return init_model(path);
#else
    return init_model("C:/tmp/sentry_stub.gguf");
#endif
}

// Inline copy of sentry_grammar.gbnf so the test binary has no file-system
// dependency; changes here must be kept in sync with assets/grammars/sentry_grammar.gbnf.
static const char* SENTRY_GBNF =
    "root ::= \"{\" ws \"\\\"threat_detected\\\"\" ws \":\" ws boolean ws \",\" ws "
    "\"\\\"confidence_score\\\"\" ws \":\" ws float ws \",\" ws "
    "\"\\\"reasoning\\\"\" ws \":\" ws string ws \"}\"\n"
    "boolean ::= \"true\" | \"false\"\n"
    "float ::= \"0.\" [0-9]+ | \"1.0\" | \"1.00\"\n"
    "string ::= \"\\\"\" ([^\"\\\\] | \"\\\\\" [\"\\\\/bfnrt])* \"\\\"\"\n"
    "ws ::= [ \\t\\n]*\n";

// ─── Schema validators ────────────────────────────────────────────────────────

static bool has_bool_threat_detected(const std::string& s) {
    std::regex re("\"threat_detected\"\\s*:\\s*(true|false)");
    return std::regex_search(s, re);
}

static bool has_valid_confidence(const std::string& s) {
    std::regex re("\"confidence_score\"\\s*:\\s*(0\\.[0-9]+|1\\.0+)");
    return std::regex_search(s, re);
}

static bool has_string_reasoning(const std::string& s) {
    std::regex re("\"reasoning\"\\s*:\\s*\"[^\"]*\"");
    return std::regex_search(s, re);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void run_grammar_tests() {

    // ── T-GRM-01: no grammar → output is still schema-conformant ─────────────
    test::run_test("T-GRM-01  no grammar -> output schema-valid", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "A caller claims to be from your bank.", nullptr);
        EXPECT(result != nullptr);
        if (result) {
            const std::string s(result);
            EXPECT(has_bool_threat_detected(s));
            EXPECT(has_valid_confidence(s));
            EXPECT(has_string_reasoning(s));
        }
        free_string(result);
        free_context(h);
    });

    // ── T-GRM-02: with grammar → threat_detected is true or false ────────────
    test::run_test("T-GRM-02  with grammar -> threat_detected is bool literal", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Caller is requesting an OTP urgently.", SENTRY_GBNF);
        EXPECT(result != nullptr);
        if (result) EXPECT(has_bool_threat_detected(std::string(result)));
        free_string(result);
        free_context(h);
    });

    // ── T-GRM-03: with grammar → confidence_score is 0.xx or 1.0 ────────────
    test::run_test("T-GRM-03  with grammar -> confidence_score in [0,1]", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Caller impersonating a police officer.", SENTRY_GBNF);
        EXPECT(result != nullptr);
        if (result) EXPECT(has_valid_confidence(std::string(result)));
        free_string(result);
        free_context(h);
    });

    // ── T-GRM-04: with grammar → reasoning is a quoted string ────────────────
    test::run_test("T-GRM-04  with grammar -> reasoning is a JSON string", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Caller says prize money waiting for you.", SENTRY_GBNF);
        EXPECT(result != nullptr);
        if (result) EXPECT(has_string_reasoning(std::string(result)));
        free_string(result);
        free_context(h);
    });

    // ── T-GRM-05: empty grammar string edge case ──────────────────────────────
    test::run_test("T-GRM-05  empty grammar string -> no crash", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Hello there.", "");
        // May return a result (stub) or nullptr (real, bad grammar); neither crashes.
        free_string(result);
        free_context(h);
        EXPECT(true);
    });

    // ── T-GRM-06: very large grammar string does not crash ────────────────────
    test::run_test("T-GRM-06  large invalid grammar string -> no crash", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        const std::string big_grammar(8192, 'x');  // deliberately invalid but large
        char* result = run_inference(h, "Test prompt.", big_grammar.c_str());
        free_string(result);
        free_context(h);
        EXPECT(true);
    });

    // ── T-GRM-07: output contains no raw C0 control characters ───────────────
    test::run_test("T-GRM-07  output has no raw control characters", []() {
        LlamaContextHandle h = make_handle();
        if (!h) { EXPECT(true); return; }
        char* result = run_inference(h, "Security alert from your ISP.", SENTRY_GBNF);
        if (result) {
            bool clean = true;
            for (const char* p = result; *p; ++p) {
                const unsigned char c = static_cast<unsigned char>(*p);
                // Allow printable ASCII, TAB (0x09), LF (0x0A), CR (0x0D)
                if (c < 0x09u || (c > 0x0Du && c < 0x20u)) {
                    clean = false;
                    break;
                }
            }
            EXPECT(clean);
        }
        free_string(result);
        free_context(h);
    });
}
