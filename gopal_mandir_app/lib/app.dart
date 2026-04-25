import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'l10n/app_language.dart';
import 'l10n/locale_scope.dart';
import 'screens/landing_screen.dart';
import 'services/analytics_route_observer.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

/// Root widget. Owns the live app-level settings (language, theme, text
/// scale) and rebuilds [MaterialApp] whenever they change.
///
/// Also listens to [SettingsService.ready] so that if the very first frame
/// shipped with defaults (because `SharedPreferences.getInstance()` was
/// still warming up), we re-read persisted values the instant storage
/// becomes available. This closes the race that used to make the
/// `Large` font choice appear to "reset" on reload.
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
    _readFromSettings();
    _settings.ready.addListener(_onSettingsReady);
  }

  @override
  void dispose() {
    _settings.ready.removeListener(_onSettingsReady);
    super.dispose();
  }

  void _readFromSettings() {
    _language = _settings.language == 'en' ? AppLanguage.en : AppLanguage.hi;
    _themeMode = _settings.themeMode;
    _textScale = _settings.textScale;
  }

  void _onSettingsReady() {
    if (!mounted || !_settings.ready.value) return;
    setState(_readFromSettings);
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

  /// Invoked by the settings screen's "Reset to defaults" action. After
  /// wiping keys we push the defaults back into the live state so the UI
  /// reflects the reset immediately.
  Future<void> resetSettingsToDefaults() async {
    await _settings.resetToDefaults();
    if (!mounted) return;
    setState(() {
      _language = AppLanguage.hi;
      _themeMode = ThemeMode.light;
      _textScale = SettingsService.defaultTextScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppController(
      updateThemeMode: updateThemeMode,
      updateTextScale: updateTextScale,
      resetToDefaults: resetSettingsToDefaults,
      child: AppLocaleScope(
        language: _language,
        onLanguageChanged: _onLanguageChanged,
        child: MaterialApp(
          title: 'Shri Gopal Mandir',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [AnalyticsRouteObserver()],
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'landing'),
              builder: (_) => const LandingScreen(),
            ),
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          // Always apply the current textScale via MediaQuery. Previously
          // we skipped the wrapper when scale == 1.0, but now that the
          // default is 1.15 (and users can pick smaller/larger values) we
          // must unconditionally propagate the user's choice so first paint
          // and every subsequent frame honour it.
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mq = MediaQuery.maybeOf(context);
            if (mq == null) return child;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(_textScale),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
