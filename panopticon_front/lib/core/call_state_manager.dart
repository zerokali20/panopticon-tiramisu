import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:panopticon/core/ffi/audio_bindings.dart';
import 'package:panopticon/data/graph_rag/services/context_retrieval_service.dart';
import 'package:panopticon/data/graph_rag/services/discrepancy_report.dart';

class CallStateManager extends ChangeNotifier {
  final ContextRetrievalService contextService;
  final _channel = const MethodChannel('com.panopticon/audio_loopback');
  
  String fullTranscript = '';
  DiscrepancyReport? latestReport;
  bool isMonitoring = false;
  
  CallStateManager(this.contextService) {
    AudioPipelineBridge.transcriptStream.listen((text) {
      if (text.trim().isEmpty) return;
      if (text.contains('[BLANK_AUDIO]')) return;
      
      fullTranscript += '$text ';
      notifyListeners();
      
      _analyzeTranscript(text);
    });
  }

  Future<void> startLoopback() async {
    isMonitoring = true;
    notifyListeners();
    try {
      await _channel.invokeMethod('startLoopbackCapture');
    } catch (e) {
      isMonitoring = false;
      notifyListeners();
    }
  }

  Future<void> stopLoopback() async {
    isMonitoring = false;
    fullTranscript = '';
    latestReport = null;
    notifyListeners();
    try {
      await _channel.invokeMethod('stopLoopbackCapture');
    } catch (e) {}
  }
  
  Future<void> _analyzeTranscript(String newText) async {
    final report = await contextService.query(CallQueryParams(
      rawPhoneNumber: 'Unknown',
      institutionClaimed: 'Unknown',
      semanticClaimText: newText,
    ));
    
    latestReport = report;
    notifyListeners();
  }
}

class CallStateProvider extends InheritedNotifier<CallStateManager> {
  const CallStateProvider({
    super.key,
    required CallStateManager manager,
    required super.child,
  }) : super(notifier: manager);

  static CallStateManager of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CallStateProvider>()!.notifier!;
  }
}
