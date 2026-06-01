// ============================================================
// panopticon/test/transcribe_audio_test.dart
//
// Command-line verification tool for local Whisper.cpp.
// ============================================================

import 'dart:io';
import 'package:panopticon/services/transcription/transcription.dart';

void main(List<String> args) async {
  print('==================================================');
  print(' Whisper.cpp Transcription Verification Tool');
  print('==================================================\n');

  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  String? executablePath;
  String? modelPath;
  String? audioPath;
  int threads = 4;
  String language = 'en';

  // Manual argument parsing to keep this test script lightweight
  for (final arg in args) {
    if (arg.startsWith('--executable=')) {
      executablePath = arg.substring('--executable='.length);
    } else if (arg.startsWith('--model=')) {
      modelPath = arg.substring('--model='.length);
    } else if (arg.startsWith('--audio=')) {
      audioPath = arg.substring('--audio='.length);
    } else if (arg.startsWith('--threads=')) {
      threads = int.tryParse(arg.substring('--threads='.length)) ?? 4;
    } else if (arg.startsWith('--lang=')) {
      language = arg.substring('--lang='.length);
    }
  }

  if (executablePath == null || modelPath == null || audioPath == null) {
    print('Error: Missing required arguments.');
    _printUsage();
    exit(1);
  }

  print('Configuration:');
  print('  Executable: $executablePath');
  print('  Model:      $modelPath');
  print('  Audio File: $audioPath');
  print('  Threads:    $threads');
  print('  Language:   $language\n');

  final config = WhisperConfig(
    executablePath: executablePath,
    modelPath: modelPath,
    threads: threads,
    language: language,
  );

  final service = WhisperTranscriptionService(config: config);

  try {
    print('Starting transcription inference (this may take a few seconds)...');
    final stopwatch = Stopwatch()..start();
    final transcript = await service.transcribe(audioPath);
    stopwatch.stop();

    print('\n------------------- RESULT -------------------');
    print(transcript.isEmpty ? '(Empty transcript returned)' : transcript);
    print('----------------------------------------------');
    print('Transcription completed successfully in ${stopwatch.elapsedMilliseconds} ms.');
  } catch (e) {
    print('\n[Failure] Error during transcription: $e');
    exit(1);
  }
}

void _printUsage() {
  print('Usage:');
  print('  dart run test/transcribe_audio_test.dart \\');
  print('    --executable="<path_to_whisper_executable>" \\');
  print('    --model="<path_to_ggml_model>" \\');
  print('    --audio="<path_to_16khz_wav_file>" \\');
  print('    [--threads=<number_of_threads>] \\');
  print('    [--lang=<language_code>]');
  print('');
  print('Example:');
  print('  dart run test/transcribe_audio_test.dart --executable="C:\\whisper\\main.exe" --model="C:\\whisper\\models\\ggml-tiny.bin" --audio="C:\\whisper\\sample.wav"');
}
