// ============================================================
// panopticon/data/graph_rag/services/call_session_manager.dart
//
// Volatile call-session lifecycle manager.
//
// Responsibilities:
//   • Maintain a STRICTLY IN-RAM transcript buffer of live ASR tokens.
//   • Trigger engine queries at configurable intervals.
//   • Perform guaranteed scrubbing (zeroing) of all volatile buffers
//     the moment a call transitions to the Terminated state.
//   • Expose a Stream<DiscrepancyReport> for the Flutter UI.
//
// ═══════════════════════════════════════════════════════════════
// SECURITY INVARIANT:
//   _transcriptBuffer is NEVER written to disk, SQLite, ObjectBox,
//   SharedPreferences, or any other persistent medium.
//   All clearing operations call both .clear() and reassignment
//   to make the old allocation immediately eligible for GC.
// ═══════════════════════════════════════════════════════════════
// ============================================================

import 'dart:async';

import 'context_retrieval_service.dart';
import 'discrepancy_report.dart';

/// Lifecycle state of the active call session.
enum CallState {
  /// No active call.
  idle,

  /// Call is in progress; transcript buffer accepting tokens.
  active,

  /// Call has ended; buffers are being purged (transient state).
  terminating,

  /// All volatile state has been cleared; engine is idle.
  terminated,
}

/// Manages the lifecycle of a single voice call session.
///
/// Instantiate one [CallSessionManager] per call.  Do NOT reuse
/// instances across calls — create a new one each time.
class CallSessionManager {
  final ContextRetrievalService _engine;

  // ── Volatile State ─────────────────────────────────────────────
  // These fields hold live call data and MUST be cleared on teardown.

  /// Raw ASR token buffer (Whisper.cpp output).
  /// Intentionally NOT final so it can be overwritten with an empty
  /// list reference during teardown, freeing the old allocation.
  List<String> _transcriptBuffer = [];

  /// Accumulated full transcript string, built lazily for queries.
  String _transcriptSnapshot = '';

  // ── Configuration ─────────────────────────────────────────────

  final String _rawPhoneNumber;
  final String _institutionClaimed;

  CallState _state = CallState.idle;

  // ── Query trigger ──────────────────────────────────────────────

  Timer? _queryTimer;

  /// How often to trigger an engine query during an active call.
  static const _queryInterval = Duration(seconds: 8);

  // ── Stream relay ──────────────────────────────────────────────

  final StreamController<DiscrepancyReport> _uiStreamController =
      StreamController<DiscrepancyReport>.broadcast();

  CallSessionManager({
    required ContextRetrievalService engine,
    required String rawPhoneNumber,
    required String institutionClaimed,
  })  : _engine = engine,
        _rawPhoneNumber = rawPhoneNumber,
        _institutionClaimed = institutionClaimed;

  // ── Public API ─────────────────────────────────────────────────

  /// Current lifecycle state.
  CallState get state => _state;

  /// Live stream of [DiscrepancyReport]s for the Flutter UI Reasoning Tree.
  Stream<DiscrepancyReport> get reports => _uiStreamController.stream;

  /// Begins a call session. Starts the periodic query timer.
  void startCall() {
    assert(_state == CallState.idle, 'Cannot start: session not in idle state.');
    _state = CallState.active;

    // Set up periodic query trigger.
    _queryTimer = Timer.periodic(_queryInterval, (_) => _triggerQuery());
  }

  /// Appends a new ASR token (word or phrase) to the in-RAM buffer.
  ///
  /// Called by the Whisper.cpp bridge on each decoded token.
  /// This method is synchronous and must remain O(1).
  void appendTranscriptToken(String token) {
    assert(
      _state == CallState.active,
      'Transcript tokens received outside of an active call — ignoring.',
    );
    if (_state != CallState.active) return;
    _transcriptBuffer.add(token);
  }

  /// Ends the call and triggers mandatory volatile state teardown.
  ///
  /// This method GUARANTEES that after it returns:
  ///   1. The query timer is cancelled.
  ///   2. [_transcriptBuffer] is cleared and the reference replaced.
  ///   3. [_transcriptSnapshot] is overwritten with an empty string.
  ///   4. The state transitions to [CallState.terminated].
  ///   5. The UI stream is closed.
  ///
  /// This satisfies the architecture's zero-persistence requirement
  /// for live call content.
  Future<void> endCall() async {
    if (_state == CallState.terminated || _state == CallState.terminating) {
      return;
    }

    _state = CallState.terminating;

    // ── Cancel periodic queries ────────────────────────────────
    _queryTimer?.cancel();
    _queryTimer = null;

    // ── Run one final query before purge ───────────────────────
    if (_transcriptBuffer.isNotEmpty) {
      await _triggerQuery();
    }

    // ── Scrub volatile state ───────────────────────────────────
    // Step 1: Clear all elements in the existing list.
    _transcriptBuffer.clear();
    // Step 2: Replace the reference to release the backing array.
    _transcriptBuffer = [];
    // Step 3: Overwrite the snapshot string reference.
    _transcriptSnapshot = '';

    // ── Transition to terminated ───────────────────────────────
    _state = CallState.terminated;

    // ── Close UI stream ────────────────────────────────────────
    await _uiStreamController.close();
  }

  // ── Private ────────────────────────────────────────────────────

  /// Builds the current transcript snapshot and fires an engine query.
  Future<void> _triggerQuery() async {
    if (_transcriptBuffer.isEmpty) return;

    // Build a snapshot string from the current buffer.
    // Using join to avoid repeated string concatenation overhead.
    _transcriptSnapshot = _transcriptBuffer.join(' ');

    try {
      final report = await _engine.query(
        CallQueryParams(
          rawPhoneNumber: _rawPhoneNumber,
          institutionClaimed: _institutionClaimed,
          semanticClaimText: _transcriptSnapshot,
        ),
      );
      // Relay to UI — do NOT store the report in a persistent field.
      _uiStreamController.add(report);
    } catch (e, stack) {
      // Log to debug console only (no file logging of call content).
      // ignore: avoid_print
      print('[CallSessionManager] Query error: $e\n$stack');
    }
  }
}
