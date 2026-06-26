/// TranscriptSegment
/// ─────────────────────────────────────────────────────────────────────────────
/// Immutable value object representing a single diarized STT output chunk
/// flowing downstream from the Whisper.cpp pipeline into the Agent layer.
///
/// [speaker]   — diarized label: 'caller' | 'user' | 'unknown'
/// [text]      — raw transcript for this segment
/// [timestamp] — monotonic offset from call start in milliseconds
/// [isFinal]   — false while ASR is still refining; true on final segment
library;

class TranscriptSegment {
  final String speaker;
  final String text;
  final int timestampMs;
  final bool isFinal;

  const TranscriptSegment({
    required this.speaker,
    required this.text,
    required this.timestampMs,
    this.isFinal = true,
  });

  /// Convenience factory for caller segments (most common from STT pipeline).
  factory TranscriptSegment.caller(String text, {int timestampMs = 0}) =>
      TranscriptSegment(
          speaker: 'caller', text: text, timestampMs: timestampMs);

  /// Convenience factory for user/microphone segments.
  factory TranscriptSegment.user(String text, {int timestampMs = 0}) =>
      TranscriptSegment(
          speaker: 'user', text: text, timestampMs: timestampMs);

  @override
  String toString() =>
      'TranscriptSegment(speaker: $speaker, ts: ${timestampMs}ms, '
      'final: $isFinal, text: "${text.length > 40 ? '${text.substring(0, 40)}…' : text}")';
}
