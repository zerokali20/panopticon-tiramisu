import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/ffi/whisper_audio_isolate.dart';

class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final WhisperAudioIsolate _audioIsolate = WhisperAudioIsolate();
  bool _isListening = false;
  String _modelPath = '';
  final List<String> _transcriptions = [];

  @override
  void initState() {
    super.initState();
    _audioIsolate.transcriptionStream.listen((text) {
      if (text.trim().isNotEmpty) {
        setState(() {
          _transcriptions.add(text.trim());
        });
      }
    });
  }

  Future<void> _pickModel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _modelPath = result.files.single.path!;
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _audioIsolate.stop();
      setState(() => _isListening = false);
      return;
    }

    if (_modelPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Whisper model (.bin) first')),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required!')),
      );
      return;
    }

    try {
      await _audioIsolate.start(_modelPath);
      setState(() => _isListening = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting engine: $e')),
      );
    }
  }

  @override
  void dispose() {
    if (_isListening) _audioIsolate.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Whisper FFI Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isListening ? null : _pickModel,
              child: Text(_modelPath.isEmpty ? 'Select Model File (.bin)' : 'Model Loaded: ${_modelPath.split('/').last}'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
              onPressed: _toggleListening,
              child: Text(_isListening ? 'STOP OBOE ENGINE' : 'START OBOE ENGINE'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
              onPressed: () async {
                if (_modelPath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a Whisper model (.bin) first')),
                  );
                  return;
                }
                
                // Ensure Whisper and the C++ worker thread are initialized
                if (!_isListening) {
                  try {
                    await _audioIsolate.start(_modelPath);
                    setState(() => _isListening = true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting engine: $e')),
                    );
                    return;
                  }
                }

                const platform = MethodChannel('com.panopticon/audio_loopback');
                await platform.invokeMethod('startLoopbackCapture');
              },
              child: const Text('START SYSTEM AUDIO LOOPBACK'),
            ),
            const SizedBox(height: 20),
            const Text('Transcriptions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _transcriptions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('> ${_transcriptions[index]}', style: const TextStyle(fontSize: 16)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
