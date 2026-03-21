import 'package:flutter/material.dart';

/// Exposes theme / text-scale updates to deep routes without importing [main.dart].
/// Placed above [MaterialApp] so pushed screens (e.g. Settings) can reach it.
class AppController extends InheritedWidget {
  const AppController({
    super.key,
    required this.updateThemeMode,
    required this.updateTextScale,
    required super.child,
  });

  final ValueChanged<ThemeMode> updateThemeMode;
  final ValueChanged<double> updateTextScale;

  static AppController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppController>();
  }

  static AppController of(BuildContext context) {
    final c = maybeOf(context);
    assert(c != null, 'AppController not found above MaterialApp');
    return c!;
  }

  @override
  bool updateShouldNotify(AppController oldWidget) => false;
}
