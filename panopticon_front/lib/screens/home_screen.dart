import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/logo.dart';
import '../widgets/risk_dot.dart';
import '../data/mock_data.dart';

/// Home screen — status card, quick stats, recent calls list.
/// Port of React HomeScreen component.
class HomeScreen extends StatelessWidget {
  final VoidCallback onCall;

  const HomeScreen({super.key, required this.onCall});

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.white.withOpacity(0.40),
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
              _IconBtn(icon: Icons.search_rounded),
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
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // Calls list
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.05)),
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
                              color: Colors.white.withOpacity(0.04),
                              indent: 16,
                              endIndent: 16),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'End of activity · Updated just now',
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.35),
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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                            color: AppColors.emerald.withOpacity(0.9),
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
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.70)),
                      ],
                    ),
                  ],
                ),
              ),
              const PanopticonLogo(size: 36),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),
          Row(
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
                  Icon(Icons.chevron_right_rounded,
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
              color: Colors.white.withOpacity(0.40),
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
                    color: Colors.white.withOpacity(0.40),
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
              color: Colors.white.withOpacity(0.35),
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
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.60)),
    );
  }
}
