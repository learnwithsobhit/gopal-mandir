import 'package:flutter/material.dart';
import 'app_language.dart';

/// Provides current app language and localised strings to the subtree.
/// Use [AppLocaleScope.of(context)] to read and [setLanguage] to switch.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required super.child,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  AppStrings get strings => AppStrings(language);

  static AppLocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found. Wrap app with AppLocaleScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) {
    return oldWidget.language != language;
  }
}
