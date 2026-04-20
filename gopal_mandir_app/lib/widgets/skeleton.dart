import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Small reusable shimmer block used to stand in for loading content.
/// Keeps the visual language consistent (rounded corners, warm palette)
/// across events, gallery, lists etc.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmGrey.withAlpha(40),
      highlightColor: AppColors.warmGrey.withAlpha(18),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Convenience card-shaped skeleton for list/grid placeholders.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.height = 120,
    this.radius = 16,
    this.margin,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: SkeletonBox(
        height: height,
        radius: radius,
        width: double.infinity,
      ),
    );
  }
}
