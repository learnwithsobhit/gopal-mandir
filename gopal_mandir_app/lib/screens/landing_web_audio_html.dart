// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// HTML5 audio for landing only. `just_audio`'s [play] awaits [AudioSession] first,
/// which schedules a microtask and breaks mobile Safari user-activation for `play()`.
class LandingWebAudio {
  html.AudioElement? _el;

  Future<void> prepare(String url, {required double volume, required bool loop}) async {
    _el = html.AudioElement()
      ..src = url
      ..loop = loop
      ..volume = volume
      ..preload = 'auto';
  }

  /// Must be invoked synchronously from the pointer/click handler (no `await` before this).
  void playFromUserGesture([void Function(Object? e)? onPlayFailed]) {
    final el = _el;
    if (el == null) return;
    el.play().catchError((e) {
      onPlayFailed?.call(e);
    });
  }

  void pause() {
    _el?.pause();
  }

  void dispose() {
    _el?.pause();
    _el?.src = '';
    _el = null;
  }
}
