import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  SharedPreferences? _prefs;

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLanguage = 'settings_language';
  static const _keyTextScale = 'settings_text_scale';
  static const _keyNotifications = 'settings_notifications';

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Storage unavailable (e.g. blocked on web) -- fall back to in-memory defaults.
    }
  }

  // ── Theme ──

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
    String v;
    switch (mode) {
      case ThemeMode.dark:
        v = 'dark';
        break;
      case ThemeMode.system:
        v = 'system';
        break;
      default:
        v = 'light';
    }
    try {
      await _prefs?.setString(_keyThemeMode, v);
    } catch (_) {}
  }

  // ── Language ──

  String get language => _prefs?.getString(_keyLanguage) ?? 'hi';

  Future<void> setLanguage(String lang) async {
    try {
      await _prefs?.setString(_keyLanguage, lang);
    } catch (_) {}
  }

  // ── Text Scale ──

  double get textScale => _prefs?.getDouble(_keyTextScale) ?? 1.0;

  Future<void> setTextScale(double scale) async {
    try {
      await _prefs?.setDouble(_keyTextScale, scale);
    } catch (_) {}
  }

  // ── Notifications ──

  bool get notificationsEnabled => _prefs?.getBool(_keyNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _prefs?.setBool(_keyNotifications, enabled);
    } catch (_) {}
  }
}
