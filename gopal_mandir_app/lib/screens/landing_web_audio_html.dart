// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// HTML5 audio for web where `just_audio` cannot call `play()` in the user-gesture turn.
class LandingWebAudio {
  html.AudioElement? _el;
  final List<StreamSubscription<html.Event>> _subs = [];

  final ValueNotifier<bool> playing = ValueNotifier(false);

  void _updatePlaying() {
    playing.value = _el != null && !_el!.paused;
  }

  Future<void> prepare(String url, {required double volume, required bool loop}) async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _el?.pause();
    _el = html.AudioElement()
      ..src = url
      ..loop = loop
      ..volume = volume
      ..preload = 'auto';
    _subs.add(_el!.onPlay.listen((_) => _updatePlaying()));
    _subs.add(_el!.onPause.listen((_) => _updatePlaying()));
    _subs.add(_el!.onEnded.listen((_) => _updatePlaying()));
    _updatePlaying();
  }

  /// Must be invoked synchronously from the pointer/click handler (no `await` before this).
  void playFromUserGesture([void Function(Object? e)? onPlayFailed]) {
    final el = _el;
    if (el == null) return;
    el.play().catchError((e) {
      onPlayFailed?.call(e);
      _updatePlaying();
    });
    _updatePlaying();
  }

  void pause() {
    _el?.pause();
    _updatePlaying();
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _el?.pause();
    _el?.src = '';
    _el = null;
    playing.dispose();
  }
}
