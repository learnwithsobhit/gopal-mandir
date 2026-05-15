import 'package:flutter/material.dart';

/// Stub: non-web platforms use [SfPdfViewer] instead.
class DailyUpasanaWebPdfReader extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
