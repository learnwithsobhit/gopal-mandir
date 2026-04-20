import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Tappable tile used in the home-screen grids and the Seva & Offerings
/// hub. Larger than its predecessor (72-px icon slab, 34-px icon) so it
/// reads clearly at the new 1.15 default text scale, and now gives tactile
/// feedback: a light haptic tick and a subtle press-in scale animation.
///
/// The outer `FittedBox(scaleDown)` from the old version is intentionally
/// gone — at larger text scales it was shrinking the whole tile to fit
/// labels, defeating the point of bigger icons. Instead we rely on a
/// fixed-size icon slab plus a two-line label that can ellipsize if the
/// user's locale really needs it.
class QuickActionButton extends StatefulWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.color ?? AppColors.krishnaBlue;
    return Semantics(
      button: true,
      label: widget.label.replaceAll('\n', ' '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      btnColor.withAlpha(30),
                      btnColor.withAlpha(70),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: btnColor.withAlpha(55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: btnColor.withAlpha(_pressed ? 20 : 40),
                      blurRadius: _pressed ? 6 : 12,
                      offset: Offset(0, _pressed ? 2 : 5),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: btnColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
