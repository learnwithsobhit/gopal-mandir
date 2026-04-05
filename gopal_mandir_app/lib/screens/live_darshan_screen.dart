import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/default_images.dart';
import 'festival_web_video_view.dart';

bool _isYouTubeUrl(String raw) {
  final u = Uri.tryParse(raw.trim());
  if (u == null) return false;
  final h = u.host.toLowerCase();
  return h.contains('youtube.com') || h.contains('youtu.be');
}

/// In-app [VideoPlayer] / web video element for direct HLS/MP4-style URLs only (not YouTube).
bool _shouldEmbedDirectStream(String raw) {
  if (raw.trim().isEmpty) return false;
  if (_isYouTubeUrl(raw)) return false;
  final u = Uri.tryParse(raw.trim());
  if (u == null || u.scheme != 'https') return false;
  final p = u.path.toLowerCase();
  return p.endsWith('.m3u8') ||
      p.endsWith('.mp4') ||
      p.endsWith('.webm') ||
      p.endsWith('.mov') ||
      p.contains('.m3u8');
}

class LiveDarshanScreen extends StatefulWidget {
  const LiveDarshanScreen({super.key});

  @override
  State<LiveDarshanScreen> createState() => _LiveDarshanScreenState();
}

class _LiveDarshanScreenState extends State<LiveDarshanScreen> {
  final ApiService _api = ApiService();
  LiveDarshanConfig? _cfg;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final c = await _api.getLiveDarshanConfig();
      if (!mounted) return;
      setState(() {
        _cfg = c;
        _loadFailed = c == null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cfg = null;
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _openStream(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;
    final uri = Uri.tryParse(u);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocaleScope.of(context).strings.liveDarshanCannotOpenStream)),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final cfg = _cfg;
    final live = cfg != null && cfg.isLive && cfg.streamUrl.trim().isNotEmpty;
    final String headline;
    if (!live) {
      headline = s.liveDarshanComingSoonHeadline;
    } else {
      final c = cfg;
      headline = c.title.trim().isNotEmpty ? c.title : s.liveDarshanScreenTitle;
    }
    // When not live, always show localized default so DB seed placeholders
    // (e.g. "update via admin") do not override Hindi/English app copy.
    final String bodyText;
    if (live) {
      final c = cfg;
      bodyText = c.description.trim().isNotEmpty ? c.description : s.liveDarshanDefaultDescription;
    } else {
      bodyText = s.liveDarshanDefaultDescription;
    }
    final appBarTitle =
        cfg != null && cfg.title.trim().isNotEmpty ? cfg.title : s.liveDarshanScreenTitle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : _loadFailed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.liveDarshanLoadError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.warmGrey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(backgroundColor: AppColors.krishnaBlue),
                          child: Text(s.liveDarshanRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _LiveStreamHero(
                        streamUrl: cfg?.streamUrl ?? '',
                        live: live,
                        onOpenExternal: () => _openStream(cfg?.streamUrl ?? ''),
                        liveBadge: s.liveDarshanLiveBadge,
                        soonBadge: s.liveDarshanSoonBadge,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.softWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.krishnaBlue.withAlpha(10),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.temple_hindu, size: 40, color: AppColors.templeGold),
                            const SizedBox(height: 12),
                            Text(
                              headline,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bodyText,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.warmGrey,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!live) ...[
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: AppColors.krishnaBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.liveDarshanStaffHint,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        height: 1.45,
                                        color: AppColors.krishnaBlueDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (live) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _openStream(cfg.streamUrl),
                                icon: const Icon(Icons.live_tv),
                                label: Text(s.liveDarshanWatchLive),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.peacockGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              if (_shouldEmbedDirectStream(cfg.streamUrl)) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _openStream(cfg.streamUrl),
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: Text(s.liveDarshanOpenExternally),
                                ),
                              ],
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.templeGold.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.liveDarshanJaiGopal,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: AppColors.templeGoldDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  DefaultImages.darshan3,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  DefaultImages.darshan4,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _LiveStreamHero extends StatefulWidget {
  const _LiveStreamHero({
    required this.streamUrl,
    required this.live,
    required this.onOpenExternal,
    required this.liveBadge,
    required this.soonBadge,
  });

  final String streamUrl;
  final bool live;
  final VoidCallback onOpenExternal;
  final String liveBadge;
  final String soonBadge;

  @override
  State<_LiveStreamHero> createState() => _LiveStreamHeroState();
}

class _LiveStreamHeroState extends State<_LiveStreamHero> {
  VideoPlayerController? _controller;
  bool _embedLoading = false;
  bool _embedFailed = false;

  @override
  void initState() {
    super.initState();
    _tryInitEmbed();
  }

  @override
  void didUpdateWidget(covariant _LiveStreamHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl || oldWidget.live != widget.live) {
      _disposeController();
      _embedFailed = false;
      _tryInitEmbed();
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _tryInitEmbed() async {
    if (!widget.live || !_shouldEmbedDirectStream(widget.streamUrl)) {
      return;
    }
    if (kIsWeb) {
      setState(() => _embedFailed = false);
      return;
    }
    final uri = Uri.tryParse(widget.streamUrl.trim());
    if (uri == null) return;

    setState(() {
      _embedLoading = true;
      _embedFailed = false;
    });
    try {
      final c = VideoPlayerController.networkUrl(uri);
      await c.initialize();
      await c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _embedLoading = false;
      });
      unawaited(c.play());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _embedLoading = false;
        _embedFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showEmbed = widget.live &&
        _shouldEmbedDirectStream(widget.streamUrl) &&
        (!kIsWeb ? (_controller != null && !_embedFailed) : !_embedFailed);

    return Container(
      width: double.infinity,
      height: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.krishnaBlue.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showEmbed && kIsWeb)
              buildFestivalWebVideoView(widget.streamUrl.trim())
            else if (showEmbed && _controller != null)
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(DefaultImages.darshan2),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_embedLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  Center(
                    child: GestureDetector(
                      onTap: widget.live ? widget.onOpenExternal : null,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(100),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 40,
                          color: widget.live ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.live ? AppColors.peacockGreen : AppColors.templeGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.live ? widget.liveBadge : widget.soonBadge,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
