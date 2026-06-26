cmake_minimum_required(VERSION 3.22.1)
project(llama_bridge VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ─── Build options ────────────────────────────────────────────────────────────
# LLAMA_REAL: set to ON to link against the vendored llama.cpp tree.
#             OFF (default) builds in stub mode with no model file required.
# Pass from the command line: cmake -DLLAMA_REAL=ON ...
# Android build.gradle.kts passes: -DLLAMA_REAL=0 (CMake treats 0 as OFF)
option(LLAMA_REAL   "Link against vendored llama.cpp (requires vendor dir)" OFF)
option(BUILD_TESTS  "Build native C++ unit tests (host only)"                ON)

# ─── Resolve llama.cpp vendor directory ──────────────────────────────────────
set(LLAMA_VENDOR_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../vendor/llama.cpp")

if(LLAMA_REAL)
    if(NOT EXISTS "${LLAMA_VENDOR_DIR}/CMakeLists.txt")
        message(FATAL_ERROR
            "[llama_bridge] LLAMA_REAL=ON but vendor dir not found at:\n"
            "  ${LLAMA_VENDOR_DIR}\n"
            "Run: cd native/vendor && git clone --depth 1 https://github.com/ggml-org/llama.cpp")
    endif()

    set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
    set(LLAMA_STATIC         ON  CACHE BOOL "" FORCE)

    if(ANDROID)
        # Enable ARM NEON / fp16 on mobile NPUs
        set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
        set(GGML_NEON   ON  CACHE BOOL "" FORCE)
    endif()

    add_subdirectory(${LLAMA_VENDOR_DIR} ${CMAKE_CURRENT_BINARY_DIR}/llama_vendor)
    message(STATUS "[llama_bridge] REAL mode — llama.cpp linked from ${LLAMA_VENDOR_DIR}")
else()
    message(STATUS "[llama_bridge] STUB mode — deterministic mock JSON, no model required.")
    message(STATUS "[llama_bridge] To enable real inference:")
    message(STATUS "[llama_bridge]   cd native/vendor && git clone --depth 1 https://github.com/ggml-org/llama.cpp")
    message(STATUS "[llama_bridge]   cmake -DLLAMA_REAL=ON ...")
endif()

# ─── Helper: apply compile defs + includes to a target ───────────────────────
function(llama_bridge_configure_target TARGET)
    if(LLAMA_REAL)
        target_compile_definitions(${TARGET} PRIVATE LLAMA_REAL=1)
        target_include_directories(${TARGET} PRIVATE "${LLAMA_VENDOR_DIR}/include")
        target_link_libraries(${TARGET} PRIVATE llama ggml)
    else()
        target_compile_definitions(${TARGET} PRIVATE LLAMA_REAL=0)
    endif()
    if(ANDROID)
        target_link_libraries(${TARGET} PRIVATE log android)
    endif()
endfunction()

# ─── Bridge shared library ────────────────────────────────────────────────────
add_library(llama_bridge SHARED llama_bridge.cpp)
target_include_directories(llama_bridge PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
llama_bridge_configure_target(llama_bridge)

# ─── Native unit tests (host only — not cross-compiled to Android/iOS) ────────
if(BUILD_TESTS AND NOT ANDROID AND NOT IOS)
    add_executable(llama_bridge_tests
        tests/test_main.cpp
        tests/test_bridge_lifecycle.cpp
        tests/test_bridge_inference.cpp
        tests/test_bridge_grammar.cpp
        llama_bridge.cpp
    )
    target_include_directories(llama_bridge_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    llama_bridge_configure_target(llama_bridge_tests)

    enable_testing()
    add_test(NAME BridgeTests COMMAND llama_bridge_tests)
    message(STATUS "[llama_bridge] Test binary: llama_bridge_tests")
endif()
