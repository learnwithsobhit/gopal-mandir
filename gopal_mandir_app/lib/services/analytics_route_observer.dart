import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'analytics_session_service.dart';
import 'api_service.dart';

String _analyticsPlatformLabel() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.fuchsia:
      return 'other';
  }
}

/// Logs named [RouteSettings] screens to the public analytics ingest (push + replace only).
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver() : _api = ApiService();

  final ApiService _api;
  final String _platform = _analyticsPlatformLabel();

  String? _lastSentScreen;
  DateTime? _lastSentAt;
  Future<void>? _contextWarmup;

  static const _debounceMs = 400;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _maybeReport(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _maybeReport(newRoute);
  }

  void _maybeReport(Route<dynamic> route) {
    if (route is! PageRoute<dynamic>) return;
    final name = route.settings.name;
    final screen = (name == null || name.isEmpty) ? 'unnamed_route' : name;
    if (screen == 'admin_shell') return;
    final now = DateTime.now();
    if (_lastSentScreen == screen &&
        _lastSentAt != null &&
        now.difference(_lastSentAt!).inMilliseconds < _debounceMs) {
      return;
    }
    _lastSentScreen = screen;
    _lastSentAt = now;
    unawaited(_send(screen));
  }

  Future<void> _ensureContext() async {
    _contextWarmup ??= _loadContext();
    await _contextWarmup;
  }

  Future<void> _loadContext() async {
    try {
      await AnalyticsSessionService.getOrCreate();
      final info = await PackageInfo.fromPlatform();
      _cachedVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('analytics context: $e');
    }
  }

  String? _cachedVersion;

  Future<void> _send(String screen) async {
    await _ensureContext();
    final session = await AnalyticsSessionService.getOrCreate();
    _api.postPageView(
      screen: screen,
      platform: _platform,
      sessionId: session,
      appVersion: _cachedVersion,
    );
  }
}
