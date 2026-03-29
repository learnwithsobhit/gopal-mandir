import 'package:flutter/material.dart';

/// Shared layout constants for consistent rhythm across screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const double screenPadding = lg;
  static const double cardRadius = 16;
  static const double fieldRadius = 12;
  static const double buttonRadius = 12;

  static const EdgeInsets screenInsets = EdgeInsets.all(screenPadding);
}
