// ============================================================
// panopticon/lib/services/transcription/whisper_transcription_service.dart
//
// Whisper.cpp local process execution wrapper.
// ============================================================

import 'dart:io';
import 'package:path/path.dart' as p;
import 'transcription_service.dart';

/// Configuration options for the local Whisper.cpp inference engine.
class WhisperConfig {
  /// Path to the Whisper.cpp command line executable (e.g. `main.exe` or `whisper-cli.exe`).
  final String executablePath;

  /// Path to the Whisper model file in GGML format (e.g. `ggml-tiny.bin`).
  final String modelPath;

  /// Target language for transcription (e.g., 'en', 'es', 'fr').
  /// Use 'auto' to auto-detect the spoken language.
  final String? language;

  /// The number of CPU threads to allocate for inference.
  /// If null, Whisper.cpp defaults (typically 4 threads).
  final int? threads;

  /// Whether to suppress printing timestamps for each transcription segment.
  /// Defaults to `true` to return clean raw text.
  final bool noTimestamps;

  /// Whether to translate input audio into English (useful for non-English audio).
  /// Defaults to `false`.
  final bool translate;

  const WhisperConfig({
    required this.executablePath,
    required this.modelPath,
    this.language = 'en',
    this.threads = 4,
    this.noTimestamps = true,
    this.translate = false,
  });

  /// Creates a copy of this config with optional overridden parameters.
  WhisperConfig copyWith({
    String? executablePath,
    String? modelPath,
    String? language,
    int? threads,
    bool? noTimestamps,
    bool? translate,
  }) {
    return WhisperConfig(
      executablePath: executablePath ?? this.executablePath,
      modelPath: modelPath ?? this.modelPath,
      language: language ?? this.language,
      threads: threads ?? this.threads,
      noTimestamps: noTimestamps ?? this.noTimestamps,
      translate: translate ?? this.translate,
    );
  }

  @override
  String toString() {
    return 'WhisperConfig(executablePath: $executablePath, modelPath: $modelPath, language: $language, threads: $threads, noTimestamps: $noTimestamps, translate: $translate)';
  }
}

/// An implementation of [TranscriptionService] that executes a local Whisper.cpp binary.
///
/// Under the hood, this launches the `whisper.cpp` command-line utility via a subprocess
/// (`Process.run`), capturing stdout to construct the final transcription.
class WhisperTranscriptionService implements TranscriptionService {
  final WhisperConfig config;

  WhisperTranscriptionService({required this.config});

  @override
  Future<String> transcribe(String audioFilePath) async {
    // 1. Verify existence of executable
    final exeFile = File(config.executablePath);
    if (!await exeFile.exists()) {
      throw FileSystemException(
        'Whisper executable not found at specified path. Please check setup.',
        config.executablePath,
      );
    }

    // 2. Verify existence of model file
    final modelFile = File(config.modelPath);
    if (!await modelFile.exists()) {
      throw FileSystemException(
        'Whisper model file not found at specified path. Please check setup.',
        config.modelPath,
      );
    }

    // 3. Verify existence of input audio file
    final audioFile = File(audioFilePath);
    if (!await audioFile.exists()) {
      throw FileSystemException(
        'Input audio file not found. Ensure the path is correct.',
        audioFilePath,
      );
    }

    // 4. Assemble the execution arguments for whisper.cpp CLI
    final List<String> args = [
      '-m', config.modelPath,
      '-f', audioFilePath,
    ];

    if (config.language != null && config.language!.isNotEmpty) {
      args.addAll(['-l', config.language!]);
    }

    if (config.threads != null && config.threads! > 0) {
      args.addAll(['-t', config.threads!.toString()]);
    }

    if (config.noTimestamps) {
      // whisper.cpp supports '-nt' or '--no-timestamps' to omit printing timestamps in output segment
      args.add('-nt');
    }

    if (config.translate) {
      args.add('-tr');
    }

    // 5. Execute process locally
    try {
      final workingDir = p.dirname(config.executablePath);
      
      final ProcessResult result = await Process.run(
        config.executablePath,
        args,
        workingDirectory: workingDir,
      );

      if (result.exitCode != 0) {
        throw ProcessException(
          config.executablePath,
          args,
          'Whisper.cpp exited with error code ${result.exitCode}.\n'
          'Stderr: ${result.stderr}\n'
          'Stdout: ${result.stdout}',
          result.exitCode,
        );
      }

      // 6. Clean and parse stdout output
      return _parseStdout(result.stdout as String);
    } on ProcessException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during Whisper.cpp execution: $e');
    }
  }

  /// Parses Whisper.cpp stdout to clean up raw text segments.
  String _parseStdout(String stdout) {
    if (stdout.isEmpty) return '';

    final lines = stdout.split('\n');
    final cleaned = lines
        .map((line) => line.trim())
        // Remove empty lines
        .where((line) => line.isNotEmpty)
        // Filter out typical developer debugging headers if they slip into stdout
        .where((line) => !line.startsWith('whisper_') && !line.startsWith('llama_') && !line.startsWith('system_info:'))
        .toList();

    return cleaned.join(' ');
  }
}
