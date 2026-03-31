import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class FestivalVideoPlayerScreen extends StatefulWidget {
  const FestivalVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
  });

  final String videoUrl;
  final String? title;

  @override
  State<FestivalVideoPlayerScreen> createState() => _FestivalVideoPlayerScreenState();
}

class _FestivalVideoPlayerScreenState extends State<FestivalVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final raw = widget.videoUrl.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed == null || (!parsed.hasScheme || parsed.host.isEmpty)) {
      setState(() {
        _loading = false;
        _error = 'Invalid video URL';
      });
      return;
    }

    try {
      final c = VideoPlayerController.networkUrl(parsed);
      await c.initialize();
      await c.setLooping(false);
      setState(() {
        _controller = c;
        _loading = false;
      });
      unawaited(c.play());
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Unable to load this video';
      });
    }
  }

  Future<void> _openExternally() async {
    final ok = await launchUrl(
      Uri.parse(widget.videoUrl),
      mode: LaunchMode.externalApplication,
    );
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open video externally')),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title?.trim().isNotEmpty == true ? widget.title! : 'Festival Video')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || c == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error ?? 'Unable to play video'),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open externally'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    AspectRatio(
                      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                    const SizedBox(height: 8),
                    VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (!mounted) return;
                            if (c.value.isPlaying) {
                              c.pause();
                            } else {
                              c.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        Text(
                          c.value.isPlaying ? 'Playing' : 'Paused',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open externally'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
