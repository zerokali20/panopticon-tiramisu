#include <stdint.h>

// This tells the compiler to keep the C-style naming convention
extern "C" {
    // A simple function to test our bridge
    // It takes an integer, multiplies it by 2, and returns it.
    int32_t test_audio_bridge(int32_t input) {
        return input * 2;
    }
}