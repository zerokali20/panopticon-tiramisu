// ============================================================
// panopticon/lib/services/transcription/transcription_service.dart
//
// Modular abstract interface for Speech-to-Text (ASR) engines.
// ============================================================

/// An abstract interface representing a speech transcription service.
///
/// Decoupling this from Whisper.cpp allows swapping or combining the ASR engine
/// with other local/on-device pipelines (such as FFI, ONNX, or platform-specific APIs)
/// without breaking downstream audio processors.
abstract class TranscriptionService {
  /// Transcribes a local audio file.
  ///
  /// Takes [audioFilePath] as input, runs the transcription process,
  /// and returns the complete text transcription.
  ///
  /// Throws a [FormatException] if the audio file is corrupted or unsupported.
  /// Throws an [Exception] if the transcription engine encounters a failure.
  Future<String> transcribe(String audioFilePath);
}
