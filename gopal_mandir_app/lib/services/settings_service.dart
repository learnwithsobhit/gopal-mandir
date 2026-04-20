import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences (theme, language, font scale, notifications).
///
/// Persistence uses `shared_preferences`. Previously, [init] silently swallowed
/// any failure from `SharedPreferences.getInstance()`, which on flaky web
/// cold-starts or hot-reloads left `_prefs` as `null`. All reads then fell
/// back to defaults and every write (`_prefs?.setX(...)`) became a no-op —
/// exactly the "font size resets on reload" bug users were seeing.
///
/// The new [init] retries a few times with sensible backoff and exposes a
/// [ready] listenable so the app shell can re-read persisted values once
/// storage finally becomes available (closes the first-frame race).
class SettingsService {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  SharedPreferences? _prefs;

  /// Flips to `true` the moment [_prefs] is populated. Listeners (e.g. the
  /// top-level [GopalMandirApp]) can react to late initialisation by
  /// re-reading persisted values and rebuilding.
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLanguage = 'settings_language';
  static const _keyTextScale = 'settings_text_scale';
  static const _keyNotifications = 'settings_notifications';

  /// Default text scale for first-time users and for sessions where
  /// persistence is unavailable. 1.15 matches the "Large" preset.
  static const double defaultTextScale = 1.15;

  /// Retry up to [maxAttempts] times. We do NOT use `.timeout` — on web,
  /// `SharedPreferences.getInstance()` may take longer than a few seconds
  /// during cold start, and a timeout there was silently breaking persistence.
  Future<void> init({int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _prefs = await SharedPreferences.getInstance();
        ready.value = true;
        return;
      } catch (e, st) {
        debugPrint(
            'SettingsService.init attempt $attempt/$maxAttempts failed: $e');
        if (attempt == maxAttempts) {
          debugPrintStack(stackTrace: st);
        } else {
          await Future<void>.delayed(
            Duration(milliseconds: 200 * attempt),
          );
        }
      }
    }
  }

  /// True once persistent storage is available. When false, all reads return
  /// defaults and all writes are no-ops; the settings UI should surface that.
  bool get isReady => _prefs != null;

  // ── Theme ──────────────────────────────────────────────────────────────

  ThemeMode get themeMode {
    final v = _prefs?.getString(_keyThemeMode) ?? 'light';
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    try {
      await _prefs?.setString(_keyThemeMode, v);
    } catch (e) {
      debugPrint('SettingsService.setThemeMode failed: $e');
    }
  }

  // ── Language ───────────────────────────────────────────────────────────

  String get language => _prefs?.getString(_keyLanguage) ?? 'hi';

  Future<void> setLanguage(String lang) async {
    try {
      await _prefs?.setString(_keyLanguage, lang);
    } catch (e) {
      debugPrint('SettingsService.setLanguage failed: $e');
    }
  }

  // ── Text Scale ─────────────────────────────────────────────────────────

  double get textScale =>
      _prefs?.getDouble(_keyTextScale) ?? defaultTextScale;

  Future<void> setTextScale(double scale) async {
    try {
      await _prefs?.setDouble(_keyTextScale, scale);
    } catch (e) {
      debugPrint('SettingsService.setTextScale failed: $e');
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────

  bool get notificationsEnabled =>
      _prefs?.getBool(_keyNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _prefs?.setBool(_keyNotifications, enabled);
    } catch (e) {
      debugPrint('SettingsService.setNotificationsEnabled failed: $e');
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Wipes all settings keys. The caller is responsible for pushing the
  /// default values back into the running app (see [SettingsScreen]).
  Future<void> resetToDefaults() async {
    try {
      await _prefs?.remove(_keyThemeMode);
      await _prefs?.remove(_keyLanguage);
      await _prefs?.remove(_keyTextScale);
      await _prefs?.remove(_keyNotifications);
    } catch (e) {
      debugPrint('SettingsService.resetToDefaults failed: $e');
    }
  }
}
