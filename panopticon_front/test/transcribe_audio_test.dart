// This file is a CLI verification tool, not a Flutter test.
// Run it directly with: dart run test/transcribe_audio_test.dart --executable=... --model=... --audio=...
// It is skipped in the automated test suite.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Whisper transcription CLI tool — run manually with dart run', () {},
      skip: 'This is a CLI tool. Run with: dart run test/transcribe_audio_test.dart --executable=<path> --model=<path> --audio=<path>');
}
