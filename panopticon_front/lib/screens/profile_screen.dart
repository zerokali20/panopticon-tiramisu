import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Profile screen — user card with stats + account rows + sign out.
/// Port of React ProfileScreen component.
class ProfileScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const ProfileScreen({super.key, required this.onSignOut});

  static const _stats = [
    ('47', 'Blocked'),
    ('312', 'Analyzed'),
    ('98%', 'Avg. accuracy'),
  ];

  static const _rows = [
    ('Edit personal info', 'Name, email, photo'),
    ('Trusted contacts', '5 contacts allow-listed'),
    ('Subscription', 'Panopticon Pro · Renews Jun 14'),
    ('Export data', 'Download local activity log'),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 12)),
              const SizedBox(height: 2),
              Text('Your account',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            children: [
              // Avatar card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x66818CF8), // indigo-400/40
                                Color(0x663B82F6), // blue-500/40
                              ],
                            ),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: Center(
                            child: Text('A',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emerald,
                              border: Border.all(
                                  color: AppColors.background, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Alex Morgan',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('alex.morgan@proton.me',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12)),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                    const SizedBox(height: 16),
                    Row(
                      children: _stats
                          .map((s) => Expanded(
                                child: Column(
                                  children: [
                                    Text(s.$1,
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFeatures: [
                                              const FontFeature.tabularFigures()
                                            ])),
                                    const SizedBox(height: 2),
                                    Text(s.$2,
                                        style: GoogleFonts.inter(
                                            color: Colors.white.withValues(alpha: 0.40),
                                            fontSize: 10.5)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account rows
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: List.generate(_rows.length, (i) {
                    final r = _rows[i];
                    final isLast = i == _rows.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(r.$1,
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(r.$2,
                                        style: GoogleFonts.inter(
                                            color: Colors.white
                                                .withValues(alpha: 0.40),
                                            fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.30)),
                            ],
                          ),
                        ),
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

              const SizedBox(height: 20),

              // Sign out
              GestureDetector(
                onTap: onSignOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 16,
                          color: AppColors.riskHigh.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Text('Sign out',
                          style: GoogleFonts.inter(
                              color: AppColors.riskHigh.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
