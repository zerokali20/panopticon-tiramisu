import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TextStyle constants matching the font sizes and weights in the React design.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle label10 = GoogleFonts.inter(
    fontSize: 10,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static TextStyle label11 = GoogleFonts.inter(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static TextStyle label12 = GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static TextStyle body13 = GoogleFonts.inter(
    fontSize: 13,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static TextStyle body14 = GoogleFonts.inter(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static TextStyle body15 = GoogleFonts.inter(
    fontSize: 15,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static TextStyle heading22 = GoogleFonts.inter(
    fontSize: 22,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  static TextStyle heading28 = GoogleFonts.inter(
    fontSize: 28,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle statValue = GoogleFonts.inter(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  static TextStyle capsLabel = GoogleFonts.inter(
    fontSize: 11,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
    fontWeight: FontWeight.w500,
  );
}
