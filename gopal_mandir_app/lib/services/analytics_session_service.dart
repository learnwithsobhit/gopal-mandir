import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists a single UUID per install for loose session correlation in analytics.
class AnalyticsSessionService {
  AnalyticsSessionService._();

  static const _key = 'analytics_session_id_v1';
  static String? _cached;

  static Future<String> getOrCreate() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}
