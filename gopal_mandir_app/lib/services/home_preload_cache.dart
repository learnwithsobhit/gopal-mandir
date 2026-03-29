import '../models/models.dart';
import 'api_service.dart';

/// In-memory warm-up cache for [HomeScreen]. Session-only; not persisted.
class HomePreloadSnapshot {
  const HomePreloadSnapshot({
    required this.quote,
    required this.announcements,
    required this.events,
    required this.loadedAt,
  });

  final DailyQuote quote;
  final List<Announcement> announcements;
  final List<Event> events;
  final DateTime loadedAt;
}

class HomePreloadCache {
  HomePreloadCache._();

  static final HomePreloadCache instance = HomePreloadCache._();

  static const maxAge = Duration(seconds: 120);

  HomePreloadSnapshot? _snapshot;

  /// Parallel fetch of the same endpoints as [HomeScreen] `_loadData`.
  /// Safe to fire-and-forget from the landing screen.
  Future<void> warmUp(ApiService api) async {
    try {
      final results = await Future.wait<Object>([
        api.getDailyQuote(),
        api.getAnnouncements(),
        api.getEvents().catchError((_, __) => <Event>[]),
      ]);
      _snapshot = HomePreloadSnapshot(
        quote: results[0] as DailyQuote,
        announcements: results[1] as List<Announcement>,
        events: results[2] as List<Event>,
        loadedAt: DateTime.now(),
      );
    } catch (_) {
      // Home will load as usual.
    }
  }

  /// Returns cached data if present and younger than [maxAge].
  HomePreloadSnapshot? peekIfFresh() {
    final s = _snapshot;
    if (s == null) return null;
    if (DateTime.now().difference(s.loadedAt) > maxAge) return null;
    return s;
  }
}
