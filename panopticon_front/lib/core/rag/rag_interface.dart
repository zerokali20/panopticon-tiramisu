/// RagInterface
/// ─────────────────────────────────────────────────────────────────────────────
/// Abstract interface for the ObjectBox Vector semantic search layer.
///
/// The Context Agent calls [query] to retrieve semantically similar facts
/// from the user's local knowledge base (saved corporate emails, contact
/// details, past call notes) before running the deep-dive LLM prompt.
///
/// Implementations:
///   StubRagInterface   — used when ObjectBox is not yet wired up (test/demo)
///   ObjectBoxRagInterface — (Track D/E) wires real ObjectBox Vector queries
/// ─────────────────────────────────────────────────────────────────────────────
library;

abstract class RagInterface {
  /// Returns a plain-text context snippet relevant to [query], or null if
  /// no sufficiently similar document is found above [minScore].
  Future<String?> query(String query, {double minScore = 0.70});

  /// Release any resources (open file handles, native memory, etc.).
  Future<void> dispose();
}

/// Stub implementation — returns a pre-written context string for any query.
/// Sufficient for UI demos and agent unit tests without ObjectBox present.
class StubRagInterface implements RagInterface {
  @override
  Future<String?> query(String query, {double minScore = 0.70}) async {
    // Simulate a ~80ms vector search round-trip
    await Future.delayed(const Duration(milliseconds: 80));

    // A plausible local knowledge-base hit about the user's real bank
    return 'The user banks with Commercial Bank of Ceylon. '
        'Their saved contact number is +94 11 2480480. '
        'No pending fraud alerts are recorded in local transaction logs. '
        'The last legitimate call from their bank was 14 days ago from a verified number.';
  }

  @override
  Future<void> dispose() async {}
}
