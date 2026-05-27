import 'package:flutter/material.dart';

/// All color constants ported from the Tailwind/CSS design tokens in the
/// original React app.
class AppColors {
  AppColors._();

  // Base backgrounds
  static const Color background = Color(0xFF0A0D1C);
  static const Color surface = Color(0xFF0F1224);
  static const Color card = Color(0xFF0D1020);

  // Brand purples/indigo
  static const Color indigo = Color(0xFF6366F1);
  static const Color blue = Color(0xFF3B82F6);

  // Text
  static const Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withOpacity(0.45);
  static Color textMuted = Colors.white.withOpacity(0.30);

  // Borders / dividers
  static Color border = Colors.white.withOpacity(0.06);
  static Color divider = Colors.white.withOpacity(0.04);

  // Risk colours
  static const Color riskHigh = Color(0xFFFB7185);   // rose-400
  static const Color riskMed = Color(0xFFFBBF24);    // amber-400
  static const Color riskSafe = Color(0xFF34D399);   // emerald-400

  // High-risk card bg
  static const Color dangerBg = Color(0xFF2A1218);
  static const Color dangerSurface = Color(0xFF1A0A10);

  // Overlays
  static Color white04 = Colors.white.withOpacity(0.04);
  static Color white06 = Colors.white.withOpacity(0.06);
  static Color white08 = Colors.white.withOpacity(0.08);
  static Color white15 = Colors.white.withOpacity(0.15);

  // Utility
  static const Color rose = Color(0xFFF43F5E);
  static const Color emerald = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);
}
