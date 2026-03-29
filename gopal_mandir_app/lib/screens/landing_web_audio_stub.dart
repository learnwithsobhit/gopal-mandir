/// Stub when not compiling for web (see [LandingWebAudio] export).
class LandingWebAudio {
  Future<void> prepare(String url, {required double volume, required bool loop}) async {}

  void playFromUserGesture([void Function(Object? e)? onPlayFailed]) {}

  void pause() {}

  void dispose() {}
}
