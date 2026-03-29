import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _api = ApiService();
  static const int _perPage = 20;
  String _selectedCategory = 'All';
  List<GalleryItem> _items = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final Map<int, int> _likeCounts = {};
  final Map<int, int> _commentCounts = {};
  AudioPlayer? _galleryAudioPlayer;

  List<String> get _categories {
    final set = <String>{'All'};
    for (final item in _items) {
      set.add(item.category);
    }
    return set.toList();
  }

  List<GalleryItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  static const int _shimmerTileCount = 6;

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.warmGrey.withAlpha(80),
      highlightColor: AppColors.warmGrey.withAlpha(40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail URL for grid tiles (smaller bytes if CDN supports it).
  /// Many CDNs ignore unknown params; others return 404 — fallback to original on error.
  static String _gridImageUrl(String imageUrl) {
    final sep = imageUrl.contains('?') ? '&' : '?';
    return '$imageUrl${sep}w=300';
  }

  /// On web, load via backend proxy to avoid CORS; on mobile use direct URL.
  static String _effectiveImageUrl(String imageUrl) {
    if (kIsWeb) {
      return '${ApiService.baseUrl}/api/gallery/proxy?url=${Uri.encodeComponent(imageUrl)}';
    }
    return imageUrl;
  }

  static String _effectiveAudioUrl(String audioUrl) {
    final trimmed = audioUrl.trim();
    if (kIsWeb) {
      return '${ApiService.baseUrl}/api/gallery/proxy?url=${Uri.encodeComponent(trimmed)}';
    }
    return trimmed;
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.warmGrey.withAlpha(80),
      highlightColor: AppColors.warmGrey.withAlpha(40),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    unawaited(_galleryAudioPlayer?.dispose());
    _galleryAudioPlayer = null;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _load() async {
    final items = await _api.getGalleryPage(1, perPage: _perPage);
    if (!mounted) return;
    final likeCounts = <int, int>{};
    final commentCounts = <int, int>{};
    for (final item in items) {
      final likes = await _api.getGalleryLikes(item.id);
      final comments = await _api.getGalleryComments(item.id);
      likeCounts[item.id] = likes;
      commentCounts[item.id] = comments.length;
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _page = 1;
      _hasMore = items.length >= _perPage;
      _likeCounts.clear();
      _likeCounts.addAll(likeCounts);
      _commentCounts.clear();
      _commentCounts.addAll(commentCounts);
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final newItems = await _api.getGalleryPage(_page + 1, perPage: _perPage);
    if (!mounted) return;
    final likeCounts = <int, int>{};
    final commentCounts = <int, int>{};
    for (final item in newItems) {
      final likes = await _api.getGalleryLikes(item.id);
      final comments = await _api.getGalleryComments(item.id);
      likeCounts[item.id] = likes;
      commentCounts[item.id] = comments.length;
    }
    if (!mounted) return;
    setState(() {
      _items.addAll(newItems);
      _likeCounts.addAll(likeCounts);
      _commentCounts.addAll(commentCounts);
      _page++;
      _hasMore = newItems.length >= _perPage;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.galleryScreenTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _shimmerTileCount,
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.krishnaBlue,
              child: Column(
                children: [
                  // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.krishnaBlue : AppColors.softWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.krishnaBlue
                              : AppColors.krishnaBlue.withAlpha(30),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

                  // Grid
                  Expanded(
                    child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredItems.length + ((_hasMore && _loadingMore) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _filteredItems.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.krishnaBlue),
                    ),
                  );
                }
                final item = _filteredItems[index];
                return GestureDetector(
                  onTap: () {
                    if (item.isAudio) {
                      _openAudio(item);
                    } else if (item.isVideo) {
                      _openVideo(context, item);
                    } else {
                      _showFullImage(context, item);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.softWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.krishnaBlue.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: item.isVideo
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (item.imageUrl.trim().isNotEmpty)
                                        _GalleryGridImage(
                                          imageUrl: _effectiveImageUrl(item.imageUrl),
                                          gridImageUrl: _effectiveImageUrl(_gridImageUrl(item.imageUrl)),
                                          placeholder: _buildImageShimmer(),
                                        )
                                      else
                                        ColoredBox(
                                          color: AppColors.krishnaBlue.withAlpha(40),
                                          child: const Center(
                                            child: Icon(Icons.movie, size: 48, color: AppColors.krishnaBlue),
                                          ),
                                        ),
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          size: 52,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  )
                                : item.isAudio
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (item.imageUrl.trim().isNotEmpty)
                                            _GalleryGridImage(
                                              imageUrl: _effectiveImageUrl(item.imageUrl),
                                              gridImageUrl: _effectiveImageUrl(_gridImageUrl(item.imageUrl)),
                                              placeholder: _buildImageShimmer(),
                                            )
                                          else
                                            ColoredBox(
                                              color: AppColors.peacockGreen.withAlpha(50),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.audiotrack,
                                                  size: 52,
                                                  color: AppColors.krishnaBlue,
                                                ),
                                              ),
                                            ),
                                          const Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              size: 52,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      )
                                    : _GalleryGridImage(
                                        imageUrl: _effectiveImageUrl(item.imageUrl),
                                        gridImageUrl: _effectiveImageUrl(_gridImageUrl(item.imageUrl)),
                                        placeholder: _buildImageShimmer(),
                                      ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.krishnaBlue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.favorite, size: 18, color: AppColors.urgentRed),
                                    onPressed: () => _likeGallery(item.id),
                                  ),
                                  Text(
                                    '${_likeCounts[item.id] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.warmGrey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.krishnaBlue),
                                    onPressed: () => _showCommentsSheet(item),
                                  ),
                                  Text(
                                    '${_commentCounts[item.id] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.warmGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _openAudio(GalleryItem item) async {
    if (!mounted) return;
    final s = AppLocaleScope.of(context).strings;
    final raw = item.videoUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.galleryAudioUrlMissing)),
      );
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.galleryInvalidAudioUrl)));
      return;
    }

    await _galleryAudioPlayer?.stop();
    await _galleryAudioPlayer?.dispose();
    _galleryAudioPlayer = AudioPlayer();

    final url = _effectiveAudioUrl(raw);
    try {
      await _galleryAudioPlayer!.setUrl(url);
    } catch (e) {
      await _galleryAudioPlayer?.dispose();
      _galleryAudioPlayer = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.galleryCouldNotLoadAudio}: $e')),
      );
      return;
    }

    if (!mounted) return;
    final player = _galleryAudioPlayer!;
    unawaited(player.play());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewPadding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.audiotrack, color: AppColors.krishnaBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.krishnaBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snap) {
                  final playing = snap.data?.playing ?? false;
                  final processing = snap.data?.processingState ?? ProcessingState.idle;
                  final busy = processing == ProcessingState.loading || processing == ProcessingState.buffering;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 56,
                        onPressed: busy
                            ? null
                            : () {
                                if (playing) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 56,
                          color: AppColors.krishnaBlue,
                        ),
                      ),
                    ],
                  );
                },
              ),
              StreamBuilder<Duration?>(
                stream: player.durationStream,
                initialData: player.duration,
                builder: (context, durSnap) {
                  final total = durSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    initialData: player.position,
                    builder: (context, posSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final maxMs = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
                      final value = pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble();
                      return Slider(
                        value: value,
                        max: maxMs,
                        onChanged: total.inMilliseconds > 0
                            ? (v) {
                                player.seek(Duration(milliseconds: v.round()));
                              }
                            : null,
                        activeColor: AppColors.krishnaBlue,
                      );
                    },
                  );
                },
              ),
              StreamBuilder<Duration?>(
                stream: player.durationStream,
                initialData: player.duration,
                builder: (context, durSnap) {
                  final total = durSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    initialData: player.position,
                    builder: (context, posSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(pos),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
                          ),
                          Text(
                            _formatDuration(total),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    await player.stop();
    await player.dispose();
    if (identical(_galleryAudioPlayer, player)) {
      _galleryAudioPlayer = null;
    }
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final h = d.inHours.toString();
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  Future<void> _openVideo(BuildContext context, GalleryItem item) async {
    final raw = item.videoUrl.trim();
    if (raw.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL missing')),
      );
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid video URL')));
      return;
    }
    if (!await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open video URL')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFullImage(BuildContext context, GalleryItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: _effectiveImageUrl(item.imageUrl),
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.krishnaBlue),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported, color: AppColors.warmGrey, size: 48),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(120),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(150)],
                    ),
                  ),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _likeGallery(int id) async {
    final previous = _likeCounts[id] ?? 0;
    setState(() {
      _likeCounts[id] = previous + 1;
    });
    final count = await _api.likeGallery(id);
    if (!mounted) return;
    if (count != null) {
      setState(() => _likeCounts[id] = count);
    } else {
      setState(() => _likeCounts[id] = previous);
    }
  }

  Future<void> _showCommentsSheet(GalleryItem item) async {
    List<GalleryComment> comments = await _api.getGalleryComments(item.id);
    if (!mounted) return;
    _commentCounts[item.id] = comments.length;

    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (modalContext, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments for ${item.title}',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: comments.isEmpty
                        ? const Center(
                            child: Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.warmGrey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  c.comment,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.warmGrey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final text = commentCtrl.text.trim();
                        if (name.isEmpty || text.isEmpty) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter name and comment'),
                              backgroundColor: AppColors.urgentRed,
                            ),
                          );
                          return;
                        }
                        final count = await _api.addGalleryComment(
                          item.id,
                          NewCommentRequest(name: name, comment: text),
                        );
                        if (count == null) {
                          if (!modalContext.mounted) return;
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add comment'),
                              backgroundColor: AppColors.urgentRed,
                            ),
                          );
                          return;
                        }
                        comments = await _api.getGalleryComments(item.id);
                        setModalState(() {});
                        setState(() {
                          _commentCounts[item.id] = count;
                        });
                        nameCtrl.clear();
                        commentCtrl.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.krishnaBlue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Post Comment'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Loads grid image with thumbnail URL first; on failure falls back to original URL
/// so images still load when the CDN does not support resize params.
class _GalleryGridImage extends StatefulWidget {
  const _GalleryGridImage({
    required this.imageUrl,
    required this.gridImageUrl,
    required this.placeholder,
  });

  final String imageUrl;
  final String gridImageUrl;
  final Widget placeholder;

  @override
  State<_GalleryGridImage> createState() => _GalleryGridImageState();
}

class _GalleryGridImageState extends State<_GalleryGridImage> {
  bool _useOriginalUrl = false;
  bool _originalAlsoFailed = false;

  @override
  Widget build(BuildContext context) {
    final url = _useOriginalUrl ? widget.imageUrl : widget.gridImageUrl;
    if (_originalAlsoFailed && _useOriginalUrl) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: AppColors.warmGrey),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => widget.placeholder,
      errorWidget: (_, __, ___) {
        if (!_useOriginalUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useOriginalUrl = true);
          });
          return widget.placeholder;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _originalAlsoFailed = true);
        });
        return const Center(
          child: Icon(Icons.image_not_supported, color: AppColors.warmGrey),
        );
      },
    );
  }
}
