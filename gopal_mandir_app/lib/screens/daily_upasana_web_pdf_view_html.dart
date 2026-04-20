// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Flutter Web bridge that renders a PDF via the browser's native PDF viewer
/// (PDF.js in Chrome/Firefox/Edge, built-in viewer in Safari) inside an
/// `<iframe>`. We delegate to the browser because Syncfusion's
/// `SfPdfViewer` on web sometimes throws "There was an error opening this
/// document" for PDFs that use compression filters or custom fonts that its
/// parser doesn't handle, even when the same file opens fine in the
/// browser. The iframe gives us page-wise reading, zoom, search, and
/// selection out of the box, for free, on every modern browser.
Widget buildDailyUpasanaWebPdfView(String url) {
  // Unique view type per URL so a rebuild with a different PDF doesn't reuse
  // the previous iframe. The viewType is a stable string so Flutter's element
  // recycling works; registering the same factory twice for the same key is
  // a no-op (Flutter caches view factories per app lifetime).
  final viewType = 'daily-upasana-pdf-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final frame = html.IFrameElement()
      ..src = url
      ..allowFullscreen = true
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#FFFFFF';
    return frame;
  });

  return HtmlElementView(viewType: viewType);
}
