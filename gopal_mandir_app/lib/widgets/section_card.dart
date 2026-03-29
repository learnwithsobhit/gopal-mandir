import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onViewAll;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.accentColor,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(24),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: accentColor != null
            ? Border(left: BorderSide(color: accentColor!, width: 3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'View All',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DefaultTextStyle.merge(
              style: TextStyle(color: cs.onSurface),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
