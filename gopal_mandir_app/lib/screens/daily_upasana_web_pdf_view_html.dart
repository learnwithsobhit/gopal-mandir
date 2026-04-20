// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Flutter Web bridge that renders a PDF via the bundled Mozilla PDF.js
/// viewer (under `web/pdfjs/`).
///
/// We don't just point an `<iframe>` at the raw PDF because:
///   - Syncfusion's `SfPdfViewer` on web often throws "There was an error
///     opening this document" on PDFs with compression filters / embedded
///     Devanagari fonts it can't handle.
///   - Mobile browsers (iOS Safari and Chrome Android in particular) have
///     a well-known limitation: PDFs embedded inline in `<iframe>` only
///     render the first page, then stop. Desktop browsers cope fine, but
///     mobile users were stuck on page 1.
///
/// PDF.js is pure JavaScript so it renders every page identically on every
/// browser, including iOS Safari and Chrome Android. The viewer is bundled
/// under `/pdfjs/web/viewer.html` and loaded with `?file=<pdf_url>#<pageN>`.
Widget buildDailyUpasanaWebPdfView(String url, {int? initialPage}) {
  // Unique view type per URL + page so a rebuild with a different PDF or a
  // jump-to-page doesn't reuse the previous iframe. Registering the same
  // factory twice for the same key is a no-op (Flutter caches per lifetime).
  final viewType =
      'daily-upasana-pdf-${url.hashCode}-${initialPage ?? 0}';
  // Hash params:
  //   `page=N`                    — resume on the user's last-read page.
  //   `annotationEditorMode=-1`   — fully disables PDF.js's annotation /
  //                                 stamp / highlight / draw tools, both in
  //                                 the UI and via keyboard shortcuts. The
  //                                 CSS in `reading-mode.css` already hides
  //                                 the buttons; this also neutralises the
  //                                 underlying feature so nothing sneaks
  //                                 back in through hotkeys (H, S, D, etc.)
  //                                 or the browser's right-click menu.
  //   `pagemode=none`             — start with the thumbnails sidebar
  //                                 collapsed (cleaner on mobile).
  final hashParts = <String>[
    'annotationEditorMode=-1',
    'pagemode=none',
    if (initialPage != null && initialPage > 1) 'page=$initialPage',
  ];
  final src = Uri(
    path: 'pdfjs/web/viewer.html',
    queryParameters: {'file': url},
    fragment: hashParts.join('&'),
  ).toString();

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final frame = html.IFrameElement()
      ..src = src
      ..allowFullscreen = true
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#FFFFFF';
    return frame;
  });

  return HtmlElementView(viewType: viewType);
}
