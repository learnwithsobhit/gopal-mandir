import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Horizontal wrap of selectable amount chips (₹ presets + optional custom).
class AppAmountChips extends StatelessWidget {
  const AppAmountChips({
    super.key,
    required this.amounts,
    required this.selectedAmount,
    required this.onSelect,
    this.enabled = true,
    this.spacing = 10,
    this.runSpacing = 10,
    this.labelBuilder,
  });

  final List<int> amounts;
  final int selectedAmount;
  final ValueChanged<int> onSelect;
  final bool enabled;
  final double spacing;
  final double runSpacing;
  final String Function(int amount)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: amounts.map((amount) {
        final selected = selectedAmount == amount;
        return FilterChip(
          label: Text(
            labelBuilder?.call(amount) ?? '₹$amount',
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? Colors.white : cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: selected,
          onSelected: enabled
              ? (_) => onSelect(amount)
              : null,
          showCheckmark: false,
          selectedColor: cs.primary,
          backgroundColor: cs.surfaceContainerHigh,
          side: BorderSide(
            color: selected ? cs.primary : cs.outline.withAlpha(120),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          ),
        );
      }).toList(),
    );
  }
}
