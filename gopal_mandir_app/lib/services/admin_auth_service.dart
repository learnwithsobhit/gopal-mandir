import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists admin CRM bearer token (separate from membership).
class AdminAuthService {
  AdminAuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'admin_token';

  static Future<String?> readToken() async {
    String? secureToken;
    try {
      secureToken = await _storage.read(key: _tokenKey);
      if (secureToken != null && secureToken.trim().isNotEmpty) return secureToken;
    } catch (_) {}
    if (!kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      final prefToken = prefs.getString(_tokenKey);
      if (prefToken != null && prefToken.trim().isNotEmpty) {
        // Heal secure storage if web secure storage was unavailable earlier.
        try {
          await _storage.write(key: _tokenKey, value: prefToken);
        } catch (_) {}
        return prefToken;
      }
      return null;
    } catch (_) {
      return secureToken;
    }
  }

  static Future<void> writeToken(String token) async {
    // Always try secure storage first.
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}

    // On web, mirror token in shared prefs as a resilient fallback.
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setString(_tokenKey, token).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.remove(_tokenKey).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
