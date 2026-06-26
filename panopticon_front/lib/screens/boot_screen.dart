import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/services/model_manager.dart';
import '../main.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final ModelManager _modelManager = ModelManager();
  
  String _currentModel = 'Initializing...';
  double _progress = 0.0;
  bool _isDownloading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _checkAndDownloadModels();
  }

  Future<void> _checkAndDownloadModels() async {
    try {
      final exists = await _modelManager.areModelsDownloaded();
      if (exists) {
        _navigateToApp();
        return;
      }

      setState(() {
        _isDownloading = true;
        _currentModel = 'Connecting to server...';
      });

      await for (final progress in _modelManager.downloadModels()) {
        if (mounted) {
          setState(() {
            _currentModel = 'Downloading ${progress.modelName}...';
            _progress = progress.progress;
          });
        }
      }

      _navigateToApp();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to download models: $e';
        });
      }
    }
  }

  void _navigateToApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek dark slate
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: Color(0xFF38BDF8), // Light blue accent
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, color: Colors.white24)
              .scaleXY(begin: 0.9, end: 1.0, duration: 1.seconds, curve: Curves.easeInOutSine)
              .then()
              .scaleXY(begin: 1.0, end: 0.9, duration: 1.seconds, curve: Curves.easeInOutSine),
              
              const SizedBox(height: 32),
              
              Text(
                'Panopticon Core',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0.0),
              
              const SizedBox(height: 16),
              
              if (_errorMsg.isNotEmpty) ...[
                Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ).animate().fadeIn(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMsg = '';
                    });
                    _checkAndDownloadModels();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry Download'),
                ),
              ] else if (_isDownloading) ...[
                Text(
                  _currentModel,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 16),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ] else ...[
                const Text(
                  'Loading local models...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
