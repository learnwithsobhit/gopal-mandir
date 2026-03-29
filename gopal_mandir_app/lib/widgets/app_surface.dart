import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Theme-aware elevated surface for cards and panels (works in light/dark).
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.level = AppSurfaceLevel.low,
    this.borderRadius,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AppSurfaceLevel level;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  Color _background(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (level) {
      case AppSurfaceLevel.lowest:
        return cs.surfaceContainerLowest;
      case AppSurfaceLevel.low:
        return cs.surfaceContainerLow;
      case AppSurfaceLevel.mid:
        return cs.surfaceContainer;
      case AppSurfaceLevel.high:
        return cs.surfaceContainerHigh;
      case AppSurfaceLevel.highest:
        return cs.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _background(context),
        borderRadius: r,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

enum AppSurfaceLevel { lowest, low, mid, high, highest }

/// Thin wrapper around [Card] using theme [cardTheme] (prefer for list items).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? Theme.of(context).cardTheme.margin,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
