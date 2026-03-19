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
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.trim().isNotEmpty) return token;
    } catch (_) {}
    if (!kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      return;
    } catch (_) {}
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setString(_tokenKey, token).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      return;
    } catch (_) {}
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.remove(_tokenKey).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
