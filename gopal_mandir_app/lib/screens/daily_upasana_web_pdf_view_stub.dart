import 'package:flutter/material.dart';

/// No-op stub: on non-web platforms the Flutter Web iframe bridge is never
/// wired in (callers gate on `kIsWeb` and fall back to Syncfusion's
/// `SfPdfViewer`). Exists so that [buildDailyUpasanaWebPdfView] is importable
/// from any platform through the conditional export in
/// `daily_upasana_web_pdf_view.dart`.
Widget buildDailyUpasanaWebPdfView(String url, {int? initialPage}) {
  return const SizedBox.shrink();
}
