#ifndef LLAMA_BRIDGE_H
#define LLAMA_BRIDGE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for the context wrapper
typedef void* LlamaContextHandle;

// Initializes the model and returns a handle. Returns NULL on failure.
LlamaContextHandle init_model(const char* model_path);

// Runs inference and returns a heap-allocated string containing the JSON result.
// The caller is responsible for freeing the returned string using free_string().
// gbnf_grammar can be NULL if no grammar is used.
char* run_inference(LlamaContextHandle handle, const char* prompt, const char* gbnf_grammar);

// Frees a string returned by run_inference.
void free_string(char* str);

// Frees the context and model.
void free_context(LlamaContextHandle handle);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_BRIDGE_H
