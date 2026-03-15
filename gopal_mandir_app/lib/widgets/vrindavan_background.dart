import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Vrindavan-themed background wrapper widget.
/// Adds a cultural pattern overlay with decorative elements
/// to give every screen a devotional Vrindavan feel.
class VrindavanBackground extends StatelessWidget {
  final Widget child;
  final bool showTopDecor;
  final bool showBottomDecor;

  const VrindavanBackground({
    super.key,
    required this.child,
    this.showTopDecor = true,
    this.showBottomDecor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Warm gradient background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8F0), // Warm cream top
            Color(0xFFF8F1E7), // Sandal cream
            Color(0xFFFFF5E8), // Warm glow bottom
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Tiled Vrindavan pattern background
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/vrindavan_bg_pattern.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                scale: 1.2,
              ),
            ),
          ),

          // Top decorative gold border
          if (showTopDecor)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.templeGold,
                      AppColors.templeGoldLight,
                      AppColors.templeGold,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Bottom decorative lotus border
          if (showBottomDecor)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.templeGold.withAlpha(80),
                      AppColors.templeGold.withAlpha(120),
                      AppColors.templeGold.withAlpha(80),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Subtle corner decorations (top-left)
          if (showTopDecor)
            Positioned(
              top: 8,
              left: 12,
              child: Text(
                '✿',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.templeGold.withAlpha(60),
                ),
              ),
            ),

          // Subtle corner decoration (top-right)
          if (showTopDecor)
            Positioned(
              top: 8,
              right: 12,
              child: Text(
                '✿',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.templeGold.withAlpha(60),
                ),
              ),
            ),

          // Main content
          child,
        ],
      ),
    );
  }
}
