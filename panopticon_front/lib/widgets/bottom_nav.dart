import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Animated pill bottom navigation bar.
/// Matches the React BottomNav — active tab shows a white pill with the label.
class BottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'Calls'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withOpacity(0),
            AppColors.background.withOpacity(0.92),
            AppColors.background,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = activeIndex == i;

            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 14 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 16,
                      color: isActive
                          ? AppColors.background
                          : Colors.white.withOpacity(0.5),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: isActive
                          ? Row(
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.background,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
