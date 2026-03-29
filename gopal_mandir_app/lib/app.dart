import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'l10n/app_language.dart';
import 'l10n/locale_scope.dart';
import 'screens/landing_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

class GopalMandirApp extends StatefulWidget {
  const GopalMandirApp({super.key});

  @override
  State<GopalMandirApp> createState() => GopalMandirAppState();
}

class GopalMandirAppState extends State<GopalMandirApp> {
  final SettingsService _settings = SettingsService();
  late AppLanguage _language;
  late ThemeMode _themeMode;
  late double _textScale;

  @override
  void initState() {
    super.initState();
    _language = _settings.language == 'en' ? AppLanguage.en : AppLanguage.hi;
    _themeMode = _settings.themeMode;
    _textScale = _settings.textScale;
  }

  void _onLanguageChanged(AppLanguage l) {
    setState(() => _language = l);
    _settings.setLanguage(l == AppLanguage.en ? 'en' : 'hi');
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _settings.setThemeMode(mode);
  }

  void updateTextScale(double scale) {
    setState(() => _textScale = scale);
    _settings.setTextScale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return AppController(
      updateThemeMode: updateThemeMode,
      updateTextScale: updateTextScale,
      child: AppLocaleScope(
        language: _language,
        onLanguageChanged: _onLanguageChanged,
        child: MaterialApp(
          title: 'Shri Gopal Mandir',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          builder: _textScale == 1.0
              ? null
              : (context, child) {
                  final mq = MediaQuery.maybeOf(context);
                  if (mq == null || child == null) {
                    return child ?? const SizedBox.shrink();
                  }
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaler: TextScaler.linear(_textScale),
                    ),
                    child: child,
                  );
                },
          home: const LandingScreen(),
        ),
      ),
    );
  }
}
