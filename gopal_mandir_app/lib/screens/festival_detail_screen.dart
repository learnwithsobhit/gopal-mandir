import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'festival_video_player_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
    final displayUrl = _FestivalMediaImage.effectiveUrl(imageUrl);
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

  Future<void> _openVideoUrl(String url) async {
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
                                      _FestivalMediaImage.effectiveUrl(_festival!.iconUrl!),
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
                                          InkWell(
                                            onTap: () => _openVideoUrl(m.videoUrl),
                                            child: Container(
                                              height: 150,
                                              width: double.infinity,
                                              color: Colors.black12,
                                              child: const Icon(Icons.play_circle, size: 42),
                                            ),
                                          )
                                        else if (m.imageUrl.isNotEmpty)
                                          InkWell(
                                            onTap: () => _openImageViewer(m.imageUrl, m.title),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                height: 150,
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

/// Same CDN resize + web proxy pattern as [GalleryScreen] (allowed hosts on API).
class _FestivalMediaImage extends StatefulWidget {
  const _FestivalMediaImage({required this.imageUrl});

  final String imageUrl;

  static String thumbUrl(String imageUrl) {
    final sep = imageUrl.contains('?') ? '&' : '?';
    return '$imageUrl${sep}w=400';
  }

  static String effectiveUrl(String imageUrl) {
    if (kIsWeb) {
      return '${ApiService.baseUrl}/api/gallery/proxy?url=${Uri.encodeComponent(imageUrl)}';
    }
    return imageUrl;
  }

  @override
  State<_FestivalMediaImage> createState() => _FestivalMediaImageState();
}

class _FestivalMediaImageState extends State<_FestivalMediaImage> {
  bool _useOriginal = false;
  bool _originalFailed = false;

  @override
  Widget build(BuildContext context) {
    final original = _FestivalMediaImage.effectiveUrl(widget.imageUrl);
    final thumb = _FestivalMediaImage.effectiveUrl(_FestivalMediaImage.thumbUrl(widget.imageUrl));
    final url = _useOriginal ? original : thumb;

    if (_originalFailed && _useOriginal) {
      return const Center(child: Icon(Icons.image_not_supported, color: AppColors.warmGrey));
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.black12),
      errorWidget: (_, __, ___) {
        if (!_useOriginal) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useOriginal = true);
          });
          return Container(color: Colors.black12);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _originalFailed = true);
        });
        return const Center(child: Icon(Icons.image_not_supported, color: AppColors.warmGrey));
      },
    );
  }
}

class _FestivalHeaderImage extends StatefulWidget {
  const _FestivalHeaderImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  State<_FestivalHeaderImage> createState() => _FestivalHeaderImageState();
}

class _FestivalHeaderImageState extends State<_FestivalHeaderImage> {
  bool _useOriginal = false;
  bool _originalFailed = false;

  @override
  Widget build(BuildContext context) {
    final sep = widget.imageUrl.contains('?') ? '&' : '?';
    final thumbRaw = '${widget.imageUrl}${sep}w=800';
    final original = _FestivalMediaImage.effectiveUrl(widget.imageUrl);
    final thumb = _FestivalMediaImage.effectiveUrl(thumbRaw);
    final url = _useOriginal ? original : thumb;

    if (_originalFailed && _useOriginal) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Icon(Icons.image_not_supported, color: AppColors.warmGrey)),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(height: widget.height, color: Colors.black12),
      errorWidget: (_, __, ___) {
        if (!_useOriginal) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useOriginal = true);
          });
          return Container(height: widget.height, color: Colors.black12);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _originalFailed = true);
        });
        return Container(
          height: widget.height,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: AppColors.warmGrey),
        );
      },
    );
  }
}
