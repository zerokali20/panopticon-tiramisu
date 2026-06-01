import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ModelDownloadProgress {
  final String modelName;
  final double progress; // 0.0 to 1.0

  ModelDownloadProgress(this.modelName, this.progress);
}

class ModelManager {
  // Local PC server via Android emulator host alias.
  // 10.0.2.2 always resolves to the host machine from inside the emulator.
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _sentryModelUrl = '$_baseUrl/sentry.gguf';
  static const String _contextModelUrl = '$_baseUrl/context.gguf';

  // HuggingFace fallback URLs
  static const String _sentryModelUrlHF = 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf?download=true';
  static const String _contextModelUrlHF = 'https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K.gguf?download=true';

  static const String sentryModelFilename = 'sentry.gguf';
  static const String contextModelFilename = 'context.gguf';

  final Dio _dio = Dio();

  Future<String> get _modelDirectory async {
    final docDir = await getApplicationSupportDirectory();
    final modelDir = Directory(p.join(docDir.path, 'models'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<String> get sentryModelPath async {
    final dir = await _modelDirectory;
    return p.join(dir, sentryModelFilename);
  }

  Future<String> get contextModelPath async {
    final dir = await _modelDirectory;
    return p.join(dir, contextModelFilename);
  }

  Future<bool> areModelsDownloaded() async {
    final sentry = File(await sentryModelPath);
    final context = File(await contextModelPath);
    return await sentry.exists() && await context.exists();
  }

  Stream<ModelDownloadProgress> downloadModels() async* {
    final sentryPath = await sentryModelPath;
    final contextPath = await contextModelPath;

    // Download Sentry (Phi-3-mini ~2.2 GB)
    if (!await File(sentryPath).exists()) {
      yield* _downloadFile(_sentryModelUrl, _sentryModelUrlHF, sentryPath, 'Sentry Agent');
    }

    // Download Context (Llama-3.1-8B ~6.6 GB)
    if (!await File(contextPath).exists()) {
      yield* _downloadFile(_contextModelUrl, _contextModelUrlHF, contextPath, 'Context Agent');
    }
  }

  Stream<ModelDownloadProgress> _downloadFile(String primaryUrl, String fallbackUrl, String savePath, String name) async* {
    final controller = StreamController<ModelDownloadProgress>();
    
    Future<void> performDownload() async {
      try {
        await _dio.download(
          primaryUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
                controller.add(ModelDownloadProgress(name, received / total));
            }
          },
        );
        controller.close();
      } catch (e) {
        print('Failed to download from primary URL ($primaryUrl), trying fallback ($fallbackUrl)...');
        try {
          await _dio.download(
            fallbackUrl,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                  controller.add(ModelDownloadProgress(name, received / total));
              }
            },
          );
          controller.close();
        } catch (e2) {
          controller.addError(e2);
          controller.close();
        }
      }
    }
    
    performDownload();
    yield* controller.stream;
  }
}
