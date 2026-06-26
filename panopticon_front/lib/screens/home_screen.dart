import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/logo.dart';
import '../widgets/risk_dot.dart';
import '../data/mock_data.dart';
import '../core/ffi/audio_bindings.dart';
import '../core/call_state_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:panopticon/data/graph_rag/services/discrepancy_report.dart';

/// Home screen — status card, quick stats, recent calls list.
/// Port of React HomeScreen component.
class HomeScreen extends StatefulWidget {
  final VoidCallback onCall;

  const HomeScreen({super.key, required this.onCall});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = not yet tested; int = result from C++ bridge
  int? _bridgeResult;
  bool _bridgeTesting = false;

  Future<void> _testBridge() async {
    setState(() => _bridgeTesting = true);
    await Future.delayed(Duration.zero); // yield so the spinner renders
    final result = AudioPipelineBridge.testBridge(10);
    // ignore: avoid_print
    print('C++ returned: $result');
    setState(() {
      _bridgeResult = result;
      _bridgeTesting = false;
    });
  }

  Widget _buildHighlightedTranscript(String text) {
    if (text.isEmpty) {
      return Text(
        'Listening for audio...',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final sensitiveTerms = [
      'otp', 'frozen', 'unauthorized', 'anydesk', 'safe account',
      'underwriting department', 'interest rate reduction', 'limited time offer'
    ];

    // Build regex to match any of the terms (case-insensitive)
    final pattern = sensitiveTerms.map((t) => RegExp.escape(t)).join('|');
    final regex = RegExp('($pattern)', caseSensitive: false);

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.inter(
          color: Colors.redAccent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Transcript: "',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          ...spans,
          TextSpan(
            text: '"',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onCall = widget.onCall;
    final top = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuesday, May 27',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hello, Alex',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const _IconBtn(icon: Icons.search_rounded),
            ],
          ),
        ),

        // Scrollable body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            children: [
              // Status card
              _StatusCard(onCall: onCall),
              const SizedBox(height: 28),

              // Live Call Widget
              Builder(
                builder: (context) {
                  try {
                    final state = CallStateProvider.of(context);
                    if (!state.isMonitoring) return const SizedBox.shrink();

                    final riskColor = state.latestReport?.riskLevel == RiskLevel.high
                        ? Colors.redAccent
                        : state.latestReport?.riskLevel == RiskLevel.medium
                            ? Colors.orangeAccent
                            : AppColors.emerald;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 28),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.record_voice_over, color: riskColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE CALL ANALYSIS',
                                style: GoogleFonts.inter(
                                  color: riskColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildHighlightedTranscript(state.fullTranscript),
                          if (state.latestReport != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'GraphRAG Verdict: ${state.latestReport!.riskLevel.name.toUpperCase()}',
                              style: GoogleFonts.inter(
                                color: riskColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.latestReport!.riskRationale,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              ),

              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent calls',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text('See all',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // Calls list
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: List.generate(recentCalls.length, (i) {
                    final c = recentCalls[i];
                    final isLast = i == recentCalls.length - 1;
                    return Column(
                      children: [
                        _RecentCallRow(call: c),
                        if (!isLast)
                          Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.04),
                              indent: 16,
                              endIndent: 16),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // ── C++ Bridge Test ──────────────────────────────────
              _BridgeTestCard(
                result: _bridgeResult,
                isTesting: _bridgeTesting,
                onTest: _testBridge,
              ),

              const SizedBox(height: 24),
              
              // ── Audio Loopback Control ────────────────────────────────
              const _LoopbackControlCard(),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'End of activity · Updated just now',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final VoidCallback onCall;
  const _StatusCard({required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active & monitoring',
                          style: GoogleFonts.inter(
                            color: AppColors.emerald.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your line\nis protected.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'View privacy center',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.70)),
                      ],
                    ),
                  ],
                ),
              ),
              const PanopticonLogo(size: 36),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          const Row(
            children: [
              _Stat(value: '47', label: 'Blocked'),
              _Stat(value: '312', label: 'Analyzed'),
              _Stat(value: '30d', label: 'Window'),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onCall,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Preview live call overlay',
                    style: GoogleFonts.inter(
                      color: AppColors.background,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.background),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCallRow extends StatelessWidget {
  final CallRecord call;
  const _RecentCallRow({required this.call});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          RiskDot(risk: call.risk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  call.sub ?? '',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            call.time,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.60)),
    );
  }
}

// ── Developer diagnostic: C++ FFI bridge test ──────────────────────────────
class _BridgeTestCard extends StatelessWidget {
  final int? result;
  final bool isTesting;
  final VoidCallback onTest;

  const _BridgeTestCard({
    required this.result,
    required this.isTesting,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    // success = bridge returned exactly 20 (double of input 10)
    final bool success = result == 20;
    final Color accentColor =
        result == null ? AppColors.indigo : (success ? AppColors.emerald : const Color(0xFFF59E0B));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: result == null
              ? Colors.white.withValues(alpha: 0.06)
              : accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  size: 14,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'C++ FFI Bridge',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Status chip
              if (result != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    success ? 'PASS' : 'UNEXPECTED',
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Calls testBridge(10) via dart:ffi → libpanopticon_audio.so.\n'
            'Expects the C++ side to return 20 (input × 2).',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Result row (only shown after test)
          if (result != null) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(
                    success
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      success
                          ? 'C++ returned: $result. Bridge is live!'
                          : 'C++ returned: $result (expected 20)',
                      style: GoogleFonts.jetBrainsMono(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Test button
          GestureDetector(
            onTap: isTesting ? null : onTest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isTesting
                    ? Colors.white.withValues(alpha: 0.04)
                    : accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isTesting
                        ? Colors.white.withValues(alpha: 0.06)
                        : accentColor.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isTesting) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Running…',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.play_arrow_rounded,
                        size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      result == null
                          ? 'Run bridge test'
                          : 'Run again',
                      style: GoogleFonts.inter(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Audio Loopback Control Card ───────────────────────────────────────
class _LoopbackControlCard extends StatelessWidget {
  const _LoopbackControlCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.screen_share_rounded,
                  size: 14,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'System Audio Monitor',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Captures system audio (like WhatsApp calls) in the background and streams it directly to the Whisper C++ engine.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final manager = CallStateProvider.of(context);
              final isRunning = manager.isMonitoring;

              return GestureDetector(
                onTap: () async {
                  if (isRunning) {
                    await manager.stopLoopback();
                  } else {
                    final status = await Permission.microphone.request();
                    if (status.isGranted) {
                      await manager.startLoopback();
                    } else {
                      debugPrint('Microphone permission denied');
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isRunning 
                        ? Colors.redAccent.withValues(alpha: 0.12)
                        : AppColors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRunning 
                          ? Colors.redAccent.withValues(alpha: 0.30)
                          : AppColors.blue.withValues(alpha: 0.30)
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 14, 
                        color: isRunning ? Colors.redAccent : AppColors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRunning ? 'Stop Loopback' : 'Start Background Loopback',
                        style: GoogleFonts.inter(
                          color: isRunning ? Colors.redAccent : AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
