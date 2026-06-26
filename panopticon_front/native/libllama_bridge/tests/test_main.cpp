/**
 * test_main.cpp
 * ─────────────────────────────────────────────────────────────────────────────
 * Entry point for the llama_bridge native test binary.
 *
 * This TU owns the single definition of test::g_results.
 * All logic lives in test_framework.h (included via the forward declarations).
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include "test_framework.h"

#include <cstdio>
#include <string>
#include <vector>

// ── Canonical definition of the shared result store ──────────────────────────
namespace test {
    std::vector<Result> g_results;
}

// ── Forward declarations of per-file test suites ─────────────────────────────
void run_lifecycle_tests();
void run_inference_tests();
void run_grammar_tests();

// ── Entry point ───────────────────────────────────────────────────────────────
int main() {
    printf("\n+================================================+\n");
    printf("|  Panopticon -- llama_bridge Native Test Suite  |\n");
    printf("+================================================+\n\n");

    printf("-- Lifecycle Tests ------------------------------------------\n");
    run_lifecycle_tests();

    printf("\n-- Inference Tests ------------------------------------------\n");
    run_inference_tests();

    printf("\n-- Grammar Tests --------------------------------------------\n");
    run_grammar_tests();

    return test::summarise();
}
