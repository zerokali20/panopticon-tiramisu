import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../core/ffi/audio_bindings.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ModelDownloadScreen({super.key, required this.onComplete});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Select an AI model to run on your device.';

  final List<Map<String, dynamic>> _models = [
    {
      'name': 'Tiny',
      'size': '~75 MB',
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
      'desc': 'Fastest, lowest accuracy. Recommended for older phones.',
      'color': AppColors.blue,
    },
    {
      'name': 'Base',
      'size': '~142 MB',
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      'desc': 'Balanced speed and accuracy. Recommended for most users.',
      'color': AppColors.emerald,
    },
    {
      'name': 'Small',
      'size': '~466 MB',
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
      'desc': 'High accuracy, slower. Recommended for powerful phones.',
      'color': AppColors.indigo,
    },
  ];

  Future<void> _downloadModel(String url, String name) async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Downloading $name model...';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/ggml-${name.toLowerCase()}.bin';

      final file = File(savePath);
      if (await file.exists()) {
        setState(() => _statusMessage = 'Model already exists. Loading...');
        // Initialize C++ engine with this path
        final success = AudioPipelineBridge.loadWhisperModel(savePath);
        if (success) {
          widget.onComplete();
        } else {
          setState(() {
            _isDownloading = false;
            _statusMessage = 'Failed to initialize Whisper Engine.';
          });
        }
        return;
      }

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() => _statusMessage = 'Download complete. Initializing...');
      
      final success = AudioPipelineBridge.loadWhisperModel(savePath);
      if (success) {
        widget.onComplete();
      } else {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Failed to initialize Whisper Engine.';
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error downloading model: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(28, top + 60, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Engine Setup',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            if (!_isDownloading)
              ..._models.map((model) => _ModelCard(
                    name: model['name'],
                    size: model['size'],
                    desc: model['desc'],
                    color: model['color'],
                    onTap: () => _downloadModel(model['url'], model['name']),
                  )),
            if (_isDownloading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 60),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 8,
                            color: AppColors.emerald,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Please keep the app open.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String name;
  final String size;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _ModelCard({
    required this.name,
    required this.size,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_rounded, size: 20, color: color),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    size,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
