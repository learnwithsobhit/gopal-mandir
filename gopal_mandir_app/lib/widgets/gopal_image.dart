import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/default_images.dart';

/// A smart image widget that tries to load from network first,
/// and falls back to a local asset if the network image fails
/// or the URL is null/empty.
class GopalImage extends StatelessWidget {
  final String? imageUrl;
  final int fallbackIndex;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GopalImage({
    super.key,
    this.imageUrl,
    this.fallbackIndex = 0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _buildImage() {
    // If no URL or empty URL, use local fallback asset
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Image.asset(
        DefaultImages.byIndex(fallbackIndex),
        fit: fit,
        width: width,
        height: height,
      );
    }

    // Try network image with local fallback on error
    return Image.network(
      imageUrl!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.krishnaBlue.withAlpha(10),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.krishnaBlue,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        // Network failed — show local asset instead
        return Image.asset(
          DefaultImages.byIndex(fallbackIndex),
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }
}
