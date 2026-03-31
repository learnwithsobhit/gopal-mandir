// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildFestivalWebVideoView(String url) {
  final viewType = 'festival-video-${DateTime.now().microsecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final video = html.VideoElement()
      ..src = url
      ..controls = true
      ..autoplay = true
      ..preload = 'metadata'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000000';
    return video;
  });

  return AspectRatio(
    aspectRatio: 16 / 9,
    child: HtmlElementView(viewType: viewType),
  );
}
