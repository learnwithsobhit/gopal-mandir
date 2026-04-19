import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/inline_web_video.dart';
import 'festival_video_player_screen.dart';

/// Thin wrapper kept for readability — delegates to the shared helper on
/// [ApiService] so both festival and gallery screens use one implementation.
String _festivalProxyUrl(String imageUrl, {int? width}) =>
    ApiService.galleryProxyUrl(imageUrl, width: width);

class FestivalDetailScreen extends StatefulWidget {
  const FestivalDetailScreen({super.key, required this.festivalId});

  final int festivalId;

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  final ApiService _api = ApiService();
  FestivalEntry? _festival;
  List<FestivalMediaItem> _media = [];
  final Map<int, int> _likes = {};
  bool _loading = true;
  /// True while gallery API is still in flight (header may already be visible).
  bool _mediaLoading = false;

  /// Which media tile currently has an initialized inline video controller.
  /// Ensures only one inline video is alive at a time so scrolling stays cheap.
  final ValueNotifier<int?> _activeMediaId = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _activeMediaId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _mediaLoading = false;
    });
    final fest = await _api.getFestivalDetail(widget.festivalId);
    if (!mounted) return;
    if (fest == null) {
      setState(() {
        _festival = null;
        _media = [];
        _likes.clear();
        _loading = false;
        _mediaLoading = false;
      });
      return;
    }
    setState(() {
      _festival = fest;
      _loading = false;
      _mediaLoading = true;
      _media = [];
      _likes.clear();
    });
    final media = await _api.getFestivalMedia(widget.festivalId);
    if (!mounted) return;
    setState(() {
      _media = media;
      _likes.clear();
      for (final m in media) {
        _likes[m.id] = m.likeCount;
      }
      _mediaLoading = false;
    });
  }

  Future<void> _like(FestivalMediaItem item) async {
    final count = await _api.likeFestivalMedia(item.id);
    if (!mounted) return;
    setState(() => _likes[item.id] = count);
  }

  Future<void> _openComments(FestivalMediaItem item) async {
    final comments = await _api.getFestivalMediaComments(item.id);
    if (!mounted) return;
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 10),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(child: Text('No comments yet'))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text(comments[i].name),
                            subtitle: Text(comments[i].comment),
                          ),
                        ),
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'Comment'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim().isEmpty ? 'Devotee' : nameCtrl.text.trim();
                      final text = commentCtrl.text.trim();
                      if (text.isEmpty) return;
                      await _api.addFestivalMediaComment(item.id, NewCommentRequest(name: name, comment: text));
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openImageViewer(String imageUrl, String title) async {
    final displayUrl = _festivalProxyUrl(imageUrl);
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: displayUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white54),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFullscreenVideo(String url) async {
    final raw = url.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed == null || (!parsed.hasScheme || parsed.host.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid video URL')),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FestivalVideoPlayerScreen(videoUrl: raw, title: 'Festival Video'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Festival Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _festival == null
              ? const Center(child: Text('Festival not found'))
              : RefreshIndicator(
                  color: AppColors.krishnaBlue,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((_festival!.bannerUrl ?? '').isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _FestivalHeaderImage(
                                  imageUrl: _festival!.bannerUrl!,
                                  height: 170,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if ((_festival!.iconUrl ?? '').isNotEmpty)
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: CachedNetworkImageProvider(
                                      _festivalProxyUrl(_festival!.iconUrl!, width: 128),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _festival!.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      ),
                                      Text(_festival!.forDate, style: const TextStyle(color: AppColors.warmGrey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(_festival!.description),
                            const SizedBox(height: 14),
                            const Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    if (_mediaLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.krishnaBlue),
                            ),
                          ),
                        ),
                      )
                    else if (_media.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Text(
                            'No photos or videos yet.',
                            style: TextStyle(color: AppColors.warmGrey, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final m = _media[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (m.isVideo)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: _InlineFestivalVideo(
                                              media: m,
                                              activeMediaId: _activeMediaId,
                                              onOpenFullscreen: () => _openFullscreenVideo(m.videoUrl),
                                            ),
                                          )
                                        else if (m.imageUrl.isNotEmpty)
                                          InkWell(
                                            onTap: () => _openImageViewer(m.imageUrl, m.title),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                height: 200,
                                                width: double.infinity,
                                                child: _FestivalMediaImage(imageUrl: m.imageUrl),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _like(m),
                                              icon: const Icon(Icons.favorite_border),
                                              label: Text('${_likes[m.id] ?? 0}'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _openComments(m),
                                              icon: const Icon(Icons.mode_comment_outlined),
                                              label: Text(
                                                m.commentCount > 0 ? 'Comments (${m.commentCount})' : 'Comments',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _media.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

Widget _buildMediaShimmer({double? height}) {
  return Shimmer.fromColors(
    baseColor: AppColors.warmGrey.withAlpha(80),
    highlightColor: AppColors.warmGrey.withAlpha(40),
    child: Container(
      height: height,
      width: double.infinity,
      color: Colors.white24,
    ),
  );
}

class _FestivalMediaImage extends StatelessWidget {
  const _FestivalMediaImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _festivalProxyUrl(imageUrl, width: 600),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      memCacheWidth: 800,
      placeholder: (_, __) => _buildMediaShimmer(height: 200),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.image_not_supported, color: AppColors.warmGrey),
      ),
    );
  }
}

class _FestivalHeaderImage extends StatelessWidget {
  const _FestivalHeaderImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _festivalProxyUrl(imageUrl, width: 800),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 1200,
      placeholder: (_, __) => _buildMediaShimmer(height: height),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: AppColors.warmGrey),
      ),
    );
  }
}

/// Inline festival video player.
///
/// Behavior:
/// - Poster state: shows the media's [FestivalMediaItem.imageUrl] as a
///   thumbnail (via the resize proxy) with a centered play button, so the
///   list stays cheap while scrolling.
/// - On tap: lazily initializes a `VideoPlayerController`, registers itself
///   as the single active video via [activeMediaId], and plays in place.
/// - A fullscreen icon pushes [FestivalVideoPlayerScreen] using the raw URL
///   so existing behavior is preserved.
///
/// Only one inline controller is ever alive at a time: tapping a second
/// video sets [activeMediaId] to the new id, which tells the previous
/// instance to tear its controller down.
class _InlineFestivalVideo extends StatefulWidget {
  const _InlineFestivalVideo({
    required this.media,
    required this.activeMediaId,
    required this.onOpenFullscreen,
  });

  final FestivalMediaItem media;
  final ValueNotifier<int?> activeMediaId;
  final VoidCallback onOpenFullscreen;

  @override
  State<_InlineFestivalVideo> createState() => _InlineFestivalVideoState();
}

class _InlineFestivalVideoState extends State<_InlineFestivalVideo> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  String? _error;
  late final String _playableUrl;

  @override
  void initState() {
    super.initState();
    _playableUrl = normalizePlayableVideoUrl(widget.media.videoUrl);
    widget.activeMediaId.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    widget.activeMediaId.removeListener(_onActiveChanged);
    _teardownController();
    super.dispose();
  }

  void _onActiveChanged() {
    if (widget.activeMediaId.value != widget.media.id && _controller != null) {
      setState(_teardownController);
    }
  }

  void _teardownController() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      unawaited(c.pause());
      unawaited(c.dispose());
    }
  }

  Future<void> _startPlayback() async {
    if (_initializing || _controller != null) return;

    final parsed = Uri.tryParse(_playableUrl);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      setState(() => _error = 'Invalid video URL');
      return;
    }

    widget.activeMediaId.value = widget.media.id;

    if (kIsWeb) {
      setState(() {
        _initializing = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final c = VideoPlayerController.networkUrl(parsed);
      await c.initialize();
      await c.setLooping(false);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _initializing = false;
      });
      unawaited(c.play());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Unable to load this video';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeMediaId.value == widget.media.id;

    if (kIsWeb && active && _error == null) {
      return InlineWebVideo(
        playableUrl: _playableUrl,
        onOpenFullscreen: widget.onOpenFullscreen,
      );
    }

    final c = _controller;
    if (c != null && c.value.isInitialized) {
      final aspect = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;
      return Column(
        children: [
          AspectRatio(
            aspectRatio: aspect,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(c),
                  AnimatedOpacity(
                    opacity: c.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          VideoProgressIndicator(
            c,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                }),
                icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Fullscreen',
                onPressed: widget.onOpenFullscreen,
                icon: const Icon(Icons.fullscreen),
              ),
            ],
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.media.imageUrl.trim().isNotEmpty)
            CachedNetworkImage(
              imageUrl: _festivalProxyUrl(widget.media.imageUrl, width: 600),
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => _buildMediaShimmer(),
              errorWidget: (_, __, ___) => Container(color: Colors.black26),
            )
          else
            Container(color: Colors.black54),
          Container(color: Colors.black.withAlpha(40)),
          Center(
            child: _initializing
                ? const CircularProgressIndicator(color: Colors.white)
                : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: widget.onOpenFullscreen,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open'),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: _startPlayback,
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withAlpha(90),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Fullscreen',
                onPressed: widget.onOpenFullscreen,
                icon: const Icon(Icons.fullscreen, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

