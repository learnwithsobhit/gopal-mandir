import 'package:flutter/material.dart';

import '../main_shell.dart';
import '../services/api_service.dart';
import '../services/home_preload_cache.dart';
import '../theme/default_images.dart';
import '../widgets/vrindavan_background.dart';

/// Root widget after the user leaves the landing screen (e.g. swap for auth later).
Widget buildPostLandingRoot() => const MainShell();

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    HomePreloadCache.instance.warmUp(ApiService());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final path in DefaultImages.all) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => buildPostLandingRoot()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VrindavanBackground(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enter,
              customBorder: const CircleBorder(),
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
