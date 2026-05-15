// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import 'daily_upasana_pdf_prefs.dart';

/// Flutter Web Daily Upasana PDF:
///
/// **Phones / touch-first browsers:** Default to opening the proxied PDF URL in
/// a **new browser tab**. Mobile Safari/Chrome use their native PDF surfaces,
/// which handle pinch-zoom without the freezes/crashes common when PDF.js runs
/// inside a Flutter [HtmlElementView] iframe stack.
///
/// **Desktop / fine pointer:** Keeps the bundled PDF.js viewer inline so resume
/// page + postMessage persistence continue to work.
///
/// Users can opt into the embedded viewer via "Read inside app instead".
class DailyUpasanaWebPdfReader extends StatefulWidget {
  const DailyUpasanaWebPdfReader({
    super.key,
    required this.url,
    this.initialPage,
    required this.itemId,
  });

  final String url;
  final int? initialPage;
  final int itemId;

  @override
  State<DailyUpasanaWebPdfReader> createState() =>
      _DailyUpasanaWebPdfReaderState();
}

class _DailyUpasanaWebPdfReaderState extends State<DailyUpasanaWebPdfReader> {
  StreamSubscription<html.MessageEvent>? _sub;
  Timer? _debounce;

  /// When true, show PDF.js iframe despite mobile heuristics (user override).
  bool _inlineFallback = false;

  @override
  void initState() {
    super.initState();
    _sub = html.window.onMessage.listen(_onMessage);
  }

  /// Prefer native browser PDF chrome on coarse pointers, narrow viewports, or
  /// small shortest-side layouts (phones / tablets / narrow desktop windows).
  bool _useNativePdfChrome(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final compact = mq.shortestSide < 640 || mq.width < 768;
    try {
      final coarse = html.window.matchMedia('(pointer: coarse)').matches;
      final narrowMq = html.window.matchMedia('(max-width: 767px)').matches;
      return coarse || narrowMq || compact;
    } catch (_) {
      return compact;
    }
  }

  /// Same PDF bytes the proxy already serves; optional `#page=` for viewers
  /// that honour fragment jumps.
  String _directPdfUrlForBrowserTab() {
    final base = widget.url.trim();
    final p = widget.initialPage;
    if (base.isEmpty) return base;
    if (p == null || p <= 1) return base;
    try {
      final uri = Uri.parse(base);
      return uri.replace(fragment: 'page=$p').toString();
    } catch (_) {
      return '$base#page=$p';
    }
  }

  void _onMessage(html.MessageEvent e) {
    if (e.origin != html.window.location.origin) return;
    final raw = e.data;
    if (raw is! String) return;
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    final src = decoded['source'];
    if (src != 'daily-upasana-pdf') return;
    final msgItem = decoded['itemId'];
    if (msgItem != widget.itemId) return;
    final pageVal = decoded['page'];
    final page = pageVal is int
        ? pageVal
        : (pageVal is num ? pageVal.toInt() : int.tryParse('$pageVal'));
    if (page == null || page < 1) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setInt(dailyUpasanaPdfPagePrefKey(widget.itemId), page);
      } catch (_) {/* ignore */}
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Widget _buildPdfJsInlineViewer() {
    final viewType =
        'daily-upasana-pdf-${widget.url.hashCode}-${widget.initialPage ?? 0}-${widget.itemId}';

    final hashParts = <String>[
      'annotationEditorMode=-1',
      'pagemode=none',
      'zoom=page-width',
      if (widget.initialPage != null && widget.initialPage! > 1)
        'page=${widget.initialPage}',
    ];
    final src = Uri(
      path: 'pdfjs/web/viewer.html',
      queryParameters: {
        'file': widget.url,
        'reading': '1',
        'itemId': '${widget.itemId}',
      },
      fragment: hashParts.join('&'),
    ).toString();

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = html.IFrameElement()
        ..src = src
        ..allowFullscreen = true
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#F5EFE6';
      return frame;
    });

    return HtmlElementView(viewType: viewType);
  }

  Widget _buildNativeTabLanding(AppStrings s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 52,
                color: AppColors.krishnaBlue.withOpacity(0.9),
              ),
              const SizedBox(height: 16),
              Text(
                s.readerPdfOpenNativeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.readerPdfOpenNativeBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.darkBrown.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.krishnaBlue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(s.readerPdfOpenNativeButton),
                  onPressed: () {
                    final target = _directPdfUrlForBrowserTab();
                    if (target.isEmpty) return;
                    html.window.open(target, '_blank', 'noopener,noreferrer');
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _inlineFallback = true),
                child: Text(s.readerPdfTryEmbeddedAnyway),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;

    if (widget.url.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.readerPdfLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.warmGrey),
          ),
        ),
      );
    }

    final nativeChrome = _useNativePdfChrome(context) && !_inlineFallback;

    if (nativeChrome) {
      return _buildNativeTabLanding(s);
    }

    return _buildPdfJsInlineViewer();
  }
}
