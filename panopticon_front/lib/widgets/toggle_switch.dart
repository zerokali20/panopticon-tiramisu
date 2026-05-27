import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Spring-animated toggle switch.
/// Replicates the React Toggle component (framer-motion spring → AnimatedPositioned).
class ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: value ? activeColor : AppColors.white15,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: 2,
              left: value ? 18 : 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
