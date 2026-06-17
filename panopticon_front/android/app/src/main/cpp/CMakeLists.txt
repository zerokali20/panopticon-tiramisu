cmake_minimum_required(VERSION 3.14.1)
project(panopticon_audio)

# ─── Whisper.cpp (local copy, no network download) ───────────────────────────
set(WHISPER_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER   OFF CACHE BOOL "" FORCE)

add_subdirectory(whisper)

# ─── Oboe (via prefab) ───────────────────────────────────────────────────────
find_package(oboe REQUIRED CONFIG)

# ─── RNNoise sources (core inference only, no training tools) ─────────────────
# rnnoise/src is needed so x86/x86cpu.h can resolve #include "common.h"
include_directories(rnnoise/include rnnoise/src)

set(RNNOISE_SOURCES
    rnnoise/src/celt_lpc.c
    rnnoise/src/denoise.c
    rnnoise/src/kiss_fft.c
    rnnoise/src/pitch.c
    rnnoise/src/rnn.c
    rnnoise/src/rnnoise_tables.c
    rnnoise/src/rnnoise_data.c
    rnnoise/src/nnet.c
    rnnoise/src/nnet_default.c
    rnnoise/src/parse_lpcnet_weights.c
)

# ─── Main shared library ──────────────────────────────────────────────────────
# dart_api_dl.c is the Dart VM native API glue code.
# It provides Dart_InitializeApiDL and Dart_PostCObject_DL at link time.
add_library(panopticon_audio SHARED
    audio_pipeline.cpp
    audio_engine.cpp
    dart_api_integration.cpp
    dart_api_dl.c
    ${RNNOISE_SOURCES}
)

target_include_directories(panopticon_audio PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/internal
    ${CMAKE_CURRENT_SOURCE_DIR}/rnnoise/src
    ${CMAKE_CURRENT_SOURCE_DIR}/whisper/include
    ${CMAKE_CURRENT_SOURCE_DIR}/whisper/src
)

target_link_libraries(panopticon_audio
    PRIVATE
    oboe::oboe
    whisper
    log
)