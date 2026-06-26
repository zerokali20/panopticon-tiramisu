/// PromptBuilder
/// ─────────────────────────────────────────────────────────────────────────────
/// Constructs the structured prompt fed to the Sentry or Context Agent LLM.
///
/// The prompt format is engineered around the "Social Engineering Logic Gates"
/// described in the Panopticon proposal:
///   Authority Figure + Artificial Urgency + Request for Funds/PII
///
/// The builder consumes a rolling window of [TranscriptSegment] objects and
/// produces a prompt string that:
///   1. Sets the system role with the detection task and output schema.
///   2. Injects the diarized transcript in a structured caller/user format.
///   3. Optionally injects RAG context retrieved by the Context Agent.
///   4. Instructs the model to emit ONLY valid JSON per sentry_grammar.gbnf.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'models/transcript_segment.dart';

class PromptBuilder {
  static const int _maxWindowSegments = 30;

  // ─── System prompt (role + output contract) ─────────────────────────────────

  static const String _systemPrompt = '''
You are Panopticon Sentry, an expert social engineering detection agent.
Your task: analyse the live phone call transcript below and determine whether the CALLER is attempting a vishing (voice phishing) or deepfake impersonation attack.

SOCIAL ENGINEERING LOGIC GATES to detect:
- AUTHORITY CLAIM: Caller impersonates a bank, government, telco, police, or family member.
- ARTIFICIAL URGENCY: Caller creates time pressure ("now", "immediately", "suspended", "urgent").
- PII/FUND REQUEST: Caller requests OTPs, PINs, passwords, transfers, card numbers.
- THREAT: Caller threatens consequences (arrest, account suspension, legal action).
- PIVOT: Caller changes claim when questioned or avoids verification.

OUTPUT CONTRACT (you MUST return ONLY this JSON, no other text):
{"threat_detected": <bool>, "confidence_score": <0.0-1.0>, "reasoning": "<one sentence>"}
''';

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Builds the Sentry Agent prompt from a rolling [segments] window.
  ///
  /// [ragContext]   — optional snippet from ObjectBox semantic search result
  ///                  (injected by Context Agent pipeline).
  /// [callerNumber] — raw caller ID string for spoofing hints.
  static String buildSentryPrompt({
    required List<TranscriptSegment> segments,
    String? ragContext,
    String? callerNumber,
  }) {
    final buf = StringBuffer();

    // System block
    buf.writeln(_systemPrompt);

    // Call metadata
    if (callerNumber != null && callerNumber.isNotEmpty) {
      buf.writeln('CALL METADATA:');
      buf.writeln('  Caller number: $callerNumber');
      buf.writeln();
    }

    // RAG context injection
    if (ragContext != null && ragContext.isNotEmpty) {
      buf.writeln('VERIFIED CONTEXT FROM LOCAL KNOWLEDGE BASE:');
      buf.writeln('  $ragContext');
      buf.writeln();
    }

    // Diarized transcript window
    final window = segments.length > _maxWindowSegments
        ? segments.sublist(segments.length - _maxWindowSegments)
        : segments;

    buf.writeln('LIVE CALL TRANSCRIPT (most recent ${window.length} segments):');
    for (final seg in window) {
      final label = seg.speaker == 'caller' ? 'CALLER' : 'USER';
      final ts = _formatMs(seg.timestampMs);
      buf.writeln('  [$ts] $label: ${seg.text}');
    }
    buf.writeln();
    buf.writeln('ANALYSIS RESULT:');

    return buf.toString();
  }

  /// Builds the Context Agent deep-dive prompt, including graph-resolved
  /// entity relationships from the SQLite graph engine.
  static String buildContextPrompt({
    required List<TranscriptSegment> segments,
    required String claimExtract,
    String? graphContext,
    String? ragContext,
    String? callerNumber,
  }) {
    final buf = StringBuffer();

    buf.writeln('''
You are Panopticon Context Agent, performing a deep forensic analysis of a flagged call.
A Sentry Agent has already detected a probable vishing attempt. Your task:
  1. Evaluate the specific CLAIM extracted from the call.
  2. Cross-reference it with the user's verified local context below.
  3. Identify the LOGICAL FLAW or DISCREPANCY that exposes the attack.
  4. Produce a final risk confidence score.

OUTPUT CONTRACT (ONLY this JSON, no other text):
{"threat_detected": <bool>, "confidence_score": <0.0-1.0>, "reasoning": "<one to two sentences identifying the specific discrepancy>"}
''');

    if (callerNumber != null) {
      buf.writeln('CALLER ID: $callerNumber');
      buf.writeln();
    }

    buf.writeln('FLAGGED CLAIM FROM TRANSCRIPT:');
    buf.writeln('  "$claimExtract"');
    buf.writeln();

    if (graphContext != null && graphContext.isNotEmpty) {
      buf.writeln('GRAPH-RESOLVED ENTITY CONTEXT (from local SQLite graph):');
      buf.writeln('  $graphContext');
      buf.writeln();
    }

    if (ragContext != null && ragContext.isNotEmpty) {
      buf.writeln('SEMANTIC CONTEXT (from local ObjectBox vector search):');
      buf.writeln('  $ragContext');
      buf.writeln();
    }

    final window = segments.length > _maxWindowSegments
        ? segments.sublist(segments.length - _maxWindowSegments)
        : segments;

    buf.writeln('FULL TRANSCRIPT WINDOW:');
    for (final seg in window) {
      final label = seg.speaker == 'caller' ? 'CALLER' : 'USER';
      buf.writeln('  [${_formatMs(seg.timestampMs)}] $label: ${seg.text}');
    }
    buf.writeln();
    buf.writeln('FORENSIC ANALYSIS:');

    return buf.toString();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  static String _formatMs(int ms) {
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
