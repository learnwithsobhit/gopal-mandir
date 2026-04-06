import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-local "seen" keys for admin activity feed rows (`kind|entityId`).
/// Tapping a row marks it dismissed so it no longer appears in the list.
class AdminActivityDismissedService {
  AdminActivityDismissedService._();

  static const _prefsKey = 'admin_activity_dismissed_ids';
  static const _maxIds = 2000;

  static String itemKey(String kind, String entityId) => '$kind|$entityId';

  static Future<List<String>> _loadOrderedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Set<String>> loadDismissedSet() async {
    final list = await _loadOrderedIds();
    return list.toSet();
  }

  static Future<void> markDismissed(String kind, String entityId) async {
    final prefs = await SharedPreferences.getInstance();
    final k = itemKey(kind, entityId);
    var list = await _loadOrderedIds();
    if (!list.contains(k)) list = [...list, k];
    while (list.length > _maxIds) {
      list.removeAt(0);
    }
    await prefs.setString(_prefsKey, jsonEncode(list));
  }
}
