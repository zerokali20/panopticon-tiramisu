import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/logo.dart';

/// Auth screen — Face ID button + 6-digit PIN pad.
/// Port of the React AuthScreen component.
class AuthScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const AuthScreen({super.key, required this.onUnlock});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _pin = '';

  void _onKey(String k) {
    if (k == '←') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 6) return;
    final next = _pin + k;
    setState(() => _pin = next);
    if (next.length == 6) {
      Future.delayed(const Duration(milliseconds: 250), widget.onUnlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, top + 60, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + wordmark
              Row(
                children: [
                  const PanopticonLogo(size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Panopticon',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // Greeting
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              Text(
                'Alex.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to continue. Your data never leaves this device.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // Face ID button
              GestureDetector(
                onTap: widget.onUnlock,
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Face ID',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Recommended sign-in',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // PIN divider
              Text(
                'Or enter your PIN',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // PIN dots
              Row(
                children: List.generate(6, (i) {
                  final filled = _pin.length > i;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 5 ? 10 : 0),
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: filled
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.02),
                        border: Border.all(
                          color: filled
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: filled
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Numpad
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  '1','2','3','4','5','6','7','8','9','','0','←'
                ].map((k) {
                  if (k.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => _onKey(k),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          k,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(width: 6),
                  Text(
                    'Zero-egress · 100% on-device',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
