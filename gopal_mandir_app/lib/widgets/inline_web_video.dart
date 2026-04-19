import 'package:flutter/material.dart';

import '../screens/festival_web_video_view.dart';

/// Web inline video bridge shared by the gallery and festival screens.
///
/// On web, the `video_player` plugin is flaky for direct S3/Firebase MP4
/// streams, so we delegate to a plain HTML5 `<video>` element via
/// [buildFestivalWebVideoView] and show a small fullscreen button.
///
/// On non-web platforms this widget is never instantiated — callers gate on
/// `kIsWeb` and use [`VideoPlayerController`](https://pub.dev/documentation/video_player/latest/video_player/VideoPlayerController-class.html)
/// directly instead.
class InlineWebVideo extends StatelessWidget {
  const InlineWebVideo({
    super.key,
    required this.playableUrl,
    required this.onOpenFullscreen,
  });

  final String playableUrl;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: buildFestivalWebVideoView(playableUrl),
        ),
        Row(
          children: [
            const Spacer(),
            IconButton(
              tooltip: 'Fullscreen',
              onPressed: onOpenFullscreen,
              icon: const Icon(Icons.fullscreen),
            ),
          ],
        ),
      ],
    );
  }
}
