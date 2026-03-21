import 'package:flutter/material.dart';
import 'app.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SettingsService().init();
  } catch (_) {
    // Settings storage unavailable -- app runs with defaults.
  }
  runApp(const GopalMandirApp());
}
