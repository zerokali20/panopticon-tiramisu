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
import 'package:url_launcher/url_launcher.dart';
import 'package:panopticon/data/graph_rag/services/discrepancy_report.dart';
import 'package:call_log/call_log.dart';

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
  List<CallRecord> _realCalls = [];

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    try {
      final entries = await CallLog.get();
      final List<CallRecord> loaded = [];
      for (var entry in entries.take(3)) {
        final risk = (entry.duration != null && entry.duration! > 0) ? 'safe' : 'med';
        final dt = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
        final dateStr = '${dt.month}/${dt.day}';
        final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        
        loaded.add(CallRecord(
          name: (entry.name != null && entry.name!.isNotEmpty) ? entry.name! : 'Unknown',
          number: entry.number ?? 'Private',
          date: dateStr,
          time: timeStr,
          duration: '${entry.duration}s',
          risk: risk,
          confidence: risk == 'safe' ? 95 : 60,
        ));
      }
      setState(() {
        _realCalls = loaded;
      });
    } catch (e) {
      // Ignore
    }
  }

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
              Row(
                children: [
                  const _DialerBtn(),
                  const SizedBox(width: 8),
                  const _IconBtn(icon: Icons.search_rounded),
                ],
              ),
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
                  children: List.generate(_realCalls.length, (i) {
                    final c = _realCalls[i];
                    final isLast = i == _realCalls.length - 1;
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
                  ],
                ),
              ),
              const PanopticonLogo(size: 36),
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
                    'Simulate call',
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

class _DialerBtn extends StatelessWidget {
  const _DialerBtn();

  Future<void> _launchDialer() async {
    final Uri url = Uri(scheme: 'tel', path: '');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchDialer,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(Icons.dialpad_rounded, size: 16, color: Colors.white.withValues(alpha: 0.60)),
      ),
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
