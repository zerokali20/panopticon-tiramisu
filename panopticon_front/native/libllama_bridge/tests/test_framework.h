/**
 * test_framework.h
 * ─────────────────────────────────────────────────────────────────────────────
 * Shared single-header test harness for all llama_bridge native unit tests.
 *
 * Include this header in every test_bridge_*.cpp file.  It provides:
 *   • test::run_test(name, lambda) — registers and runs one test case
 *   • test::expect(cond, expr, file, line) — records a failure
 *   • EXPECT(cond) macro — shorthand that fills file/line automatically
 *   • test::summarise() — prints the final pass/fail table
 *
 * All functions are `inline` so they can be included in multiple TUs
 * without ODR violations; state is kept in a single translation unit
 * (test_main.cpp) via the extern declarations below.
 * ─────────────────────────────────────────────────────────────────────────────
 */

#pragma once

#include <cstdio>
#include <cstdlib>
#include <functional>
#include <stdexcept>
#include <string>
#include <vector>

namespace test {

struct Result {
    std::string name;
    bool        passed;
    std::string message;
};

// Defined once in test_main.cpp; declared extern here so every TU shares it.
extern std::vector<Result> g_results;

inline void expect(bool cond, const char* expr, const char* file, int line) {
    if (!cond) {
        char buf[512];
        snprintf(buf, sizeof(buf), "FAIL at %s:%d  ->  %s", file, line, expr);
        if (!g_results.empty()) {
            g_results.back().passed  = false;
            g_results.back().message = buf;
        }
    }
}

inline void run_test(const char* name, std::function<void()> fn) {
    g_results.push_back({name, true, ""});
    printf("  %-62s ... ", name);
    fflush(stdout);
    try {
        fn();
    } catch (const std::exception& e) {
        char buf[256];
        snprintf(buf, sizeof(buf), "EXCEPTION: %s", e.what());
        g_results.back().passed  = false;
        g_results.back().message = buf;
    } catch (...) {
        g_results.back().passed  = false;
        g_results.back().message = "UNKNOWN EXCEPTION";
    }
    printf("%s\n", g_results.back().passed ? "PASS" : g_results.back().message.c_str());
}

inline int summarise() {
    int passed = 0, failed = 0;
    for (const auto& r : g_results) {
        r.passed ? ++passed : ++failed;
    }
    printf("\n==============================================\n");
    printf("  Total: %zu   PASSED: %d   FAILED: %d\n",
           g_results.size(), passed, failed);
    printf("==============================================\n");
    return (failed == 0) ? 0 : 1;
}

}  // namespace test

// Convenience macro — fills __FILE__ and __LINE__ automatically.
#define EXPECT(cond) test::expect((cond), #cond, __FILE__, __LINE__)
