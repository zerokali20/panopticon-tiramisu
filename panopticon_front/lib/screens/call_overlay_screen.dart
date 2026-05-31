import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/toggle_switch.dart';
import '../core/agents/agent_router.dart';
import '../core/agents/models/risk_assessment.dart';
import '../core/agents/models/transcript_segment.dart';

/// Live call overlay screen.
/// ─────────────────────────────────────────────────────────────────────────────
/// Subscribes to [AgentRouter.assessments] for live [RiskAssessment] updates.
/// The UI state (analyzing / elevated / high-risk) is fully driven by the
/// LLM output, not a hardcoded timer.
///
/// Demo mode: when [agentRouter] is null (no model files present on device)
/// the screen falls back to a simulated auto-escalation after 4.5 s to allow
/// UI previewing without native binaries.
/// ─────────────────────────────────────────────────────────────────────────────
class CallOverlayScreen extends StatefulWidget {
  final VoidCallback onBack;

  /// Live router from the telephony layer. Null = demo/preview mode.
  final AgentRouter? agentRouter;

  final String callerNumber;
  final String callerLocation;

  const CallOverlayScreen({
    super.key,
    required this.onBack,
    this.agentRouter,
    this.callerNumber = '+1 (415) 555-0117',
    this.callerLocation = 'San Francisco, CA',
  });

  @override
  State<CallOverlayScreen> createState() => _CallOverlayScreenState();
}

class _CallOverlayScreenState extends State<CallOverlayScreen> {
  // ── UI State ────────────────────────────────────────────────────────────────
  RiskAssessment _assessment = RiskAssessment.initial();
  bool _scriptOpen = false;
  bool _honey = false;

  // ── Call timer ──────────────────────────────────────────────────────────────
  late final Stopwatch _callTimer;
  Timer? _clockTick;
  String _callDuration = '00:00';

  // ── Agent subscription ──────────────────────────────────────────────────────
  StreamSubscription<RiskAssessment>? _agentSub;

  // ── Demo mode (no model) ────────────────────────────────────────────────────
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _callTimer = Stopwatch()..start();
    _clockTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final elapsed = _callTimer.elapsed;
          final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
          final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
          _callDuration = '$m:$s';
        });
      }
    });

    if (widget.agentRouter != null) {
      _agentSub = widget.agentRouter!.assessments.listen((a) {
        if (mounted) setState(() => _assessment = a);
      });
    } else {
      // Demo escalation — simulates a real call without model files
      _demoTimer = Timer(const Duration(milliseconds: 4500), () {
        if (mounted) {
          setState(() {
            _assessment = const RiskAssessment(
              threatDetected: true,
              confidenceScore: 0.98,
              reasoning: 'Caller is pressuring an immediate transfer. '
                  'Claims to be Wells Fargo — number is not in their registry. '
                  'No recent account alerts on this device.',
              sourceAgent: 'demo',
              timestampMs: 4500,
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    _demoTimer?.cancel();
    _agentSub?.cancel();
    _callTimer.stop();
    super.dispose();
  }

  bool get _isHighRisk =>
      _assessment.threatDetected &&
      _assessment.level == RiskLevel.high;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Caller info behind overlay
        Positioned.fill(
          child: Column(
            children: [
              SizedBox(height: top + 80),
              Text('On call · $_callDuration',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
              const SizedBox(height: 12),
              Text(widget.callerNumber,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(widget.callerLocation,
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
              const SizedBox(height: 40),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Icon(Icons.person_outline_rounded,
                    size: 48, color: Colors.white.withValues(alpha: 0.30)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Mute', 'Keypad', 'Speaker'].map((l) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(l,
                              style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.40),
                                  fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Dimming overlay — darkens to red-tint on high-risk
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          color: _isHighRisk
              ? const Color(0x8C14050A)
              : const Color(0x400A0D1C),
        ),

        // Back button
        Positioned(
          top: top + 14,
          left: 20,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.chevron_left_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.70)),
                  Text('Back',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 11)),
                ],
              ),
            ),
          ),
        ),

        // Risk level badge (top-right)
        Positioned(
          top: top + 14,
          right: 20,
          child: _RiskBadge(assessment: _assessment),
        ),

        // Bottom card — live assessment data
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _isHighRisk
                ? _HighRiskCard(
                    key: const ValueKey('high'),
                    assessment: _assessment,
                    scriptOpen: _scriptOpen,
                    onScriptToggle: () =>
                        setState(() => _scriptOpen = !_scriptOpen),
                    honey: _honey,
                    onHoneyToggle: (v) => setState(() => _honey = v),
                    onHangup: widget.onBack,
                  )
                : _LowRiskCard(
                    key: const ValueKey('low'),
                    assessment: _assessment,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Risk badge (top right) ────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final RiskAssessment assessment;
  const _RiskBadge({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final isHigh = assessment.level == RiskLevel.high;
    final isElevated = assessment.level == RiskLevel.elevated;

    final Color badgeColor = isHigh
        ? AppColors.riskHigh
        : isElevated
            ? AppColors.amber
            : Colors.white.withValues(alpha: 0.55);

    final String label = isHigh
        ? 'High risk'
        : isElevated
            ? 'Elevated'
            : 'Analyzing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Low-risk / analyzing card ─────────────────────────────────────────────────

class _LowRiskCard extends StatelessWidget {
  final RiskAssessment assessment;
  const _LowRiskCard({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final isElevated = assessment.level == RiskLevel.elevated;
    final progressValue = assessment.confidenceScore.clamp(0.05, 1.0);
    final progressColor =
        isElevated ? AppColors.amber : AppColors.amber.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xD915182A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _WaveformBars(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isElevated
                            ? 'Elevated activity detected'
                            : "Verifying caller's claim",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assessment.sourceAgent == 'none'
                            ? 'Sentry Agent initialising…'
                            : 'Sentry · ${assessment.sourceAgent} model active',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  assessment.sourceAgent == 'none'
                      ? '—'
                      : assessment.confidenceLabel,
                  style: GoogleFonts.inter(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [const FontFeature.tabularFigures()]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformBars extends StatefulWidget {
  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(14, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900 + (i % 4) * 120),
      )..repeat(reverse: true);
      return c;
    });
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0.2, end: 0.9).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: List.generate(14, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Container(
              width: 2,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(1),
              ),
              height: 20 * _anims[i].value,
            ),
          );
        }),
      ),
    );
  }
}

// ── High-risk card ────────────────────────────────────────────────────────────

class _HighRiskCard extends StatelessWidget {
  final RiskAssessment assessment;
  final bool scriptOpen;
  final VoidCallback onScriptToggle;
  final bool honey;
  final ValueChanged<bool> onHoneyToggle;
  final VoidCallback onHangup;

  const _HighRiskCard({
    super.key,
    required this.assessment,
    required this.scriptOpen,
    required this.onScriptToggle,
    required this.honey,
    required this.onHoneyToggle,
    required this.onHangup,
  });

  // Safe verification questions generated from LLM reasoning context
  static const _safeQuestions = [
    '"Can I call you back at the number on my card?"',
    '"What was the last transaction on file?"',
    '"Please email me the request from an official address."',
  ];

  /// Split the reasoning into bullet points at sentence boundaries.
  List<String> get _reasoningBullets {
    return assessment.reasoning
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF22A1218), Color(0xF21A0A10)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.riskHigh.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 60,
            offset: const Offset(0, -20),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.riskHigh.withValues(alpha: 0.15),
                      border: Border.all(
                          color: AppColors.riskHigh.withValues(alpha: 0.20)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFFECACA)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('High risk detected',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'Confidence ${assessment.confidenceLabel} · ${assessment.sourceAgent == 'context' ? 'Context Agent' : 'Sentry Agent'}',
                          style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reasoning box — live LLM output
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why we flagged this',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11)),
                    const SizedBox(height: 10),
                    ..._reasoningBullets.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.riskHigh.withValues(alpha: 0.80),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(r,
                                    style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.80),
                                        fontSize: 12.5,
                                        height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Counter-script accordion
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: onScriptToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Safe questions to ask',
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('A short counter-script',
                                      style: GoogleFonts.inter(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: scriptOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.50)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.05)),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _safeQuestions
                                  .map((q) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(q,
                                            style: GoogleFonts.inter(
                                                color: Colors.white
                                                    .withValues(alpha: 0.80),
                                                fontSize: 12.5,
                                                height: 1.5)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      crossFadeState: scriptOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Honey-pot toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Honey-pot mode',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('Stall the caller with synthetic voice',
                              style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    ToggleSwitch(
                      value: honey,
                      onChanged: onHoneyToggle,
                      activeColor: AppColors.amber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disconnect button
              GestureDetector(
                onTap: onHangup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_disabled_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Disconnect call',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
