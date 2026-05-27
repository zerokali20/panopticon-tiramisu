import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small colored dot indicating call risk level.
/// Matches the React RiskDot component.
class RiskDot extends StatelessWidget {
  final String risk; // 'high' | 'med' | 'safe'

  const RiskDot({super.key, required this.risk});

  Color get _color => switch (risk) {
        'high' => AppColors.riskHigh,
        'med' => AppColors.riskMed,
        _ => AppColors.riskSafe,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
      ),
    );
  }
}
