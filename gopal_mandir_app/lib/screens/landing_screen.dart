import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../main_shell.dart';
import '../services/api_service.dart';
import '../services/home_preload_cache.dart';
import '../theme/default_images.dart';
import '../widgets/vrindavan_background.dart';

/// Root widget after the user leaves the landing screen (e.g. swap for auth later).
Widget buildPostLandingRoot() => const MainShell();

/// Default MP3 when API returns empty or is unreachable (matches API migration seed).
const String kDefaultLandingAudioUrl =
    'https://mandir-s3-034035677610-ap-south-1-an.s3.ap-south-1.amazonaws.com/gallery/76f2e0d5-63d0-4041-a687-b1134aa3284a.mp3';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiService _api = ApiService();
  AudioPlayer? _player;

  static String _playbackUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    if (kIsWeb) {
      return '${ApiService.baseUrl}/api/gallery/proxy?url=${Uri.encodeComponent(trimmed)}';
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    HomePreloadCache.instance.warmUp(_api);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final path in DefaultImages.all) {
        precacheImage(AssetImage(path), context);
      }
    });
    unawaited(_startLandingAudio());
  }

  Future<void> _startLandingAudio() async {
    final fromApi = await _api.getLandingAudioUrl();
    final raw = (fromApi != null && fromApi.trim().isNotEmpty) ? fromApi.trim() : kDefaultLandingAudioUrl;
    if (raw.isEmpty || !mounted) return;

    final url = _playbackUrl(raw);
    if (url.isEmpty) return;

    try {
      final player = AudioPlayer();
      await player.setUrl(url);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0.85);
      if (!mounted) {
        await player.dispose();
        return;
      }
      _player = player;
      unawaited(player.play());
    } catch (e) {
      debugPrint('Landing audio failed: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  Future<void> _enter() async {
    await _stopAudio();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => buildPostLandingRoot()),
    );
  }

  @override
  void dispose() {
    unawaited(_stopAudio());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VrindavanBackground(
        child: Center(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _enter,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/images/laddu_gopal_landing.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Tap to enter',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
