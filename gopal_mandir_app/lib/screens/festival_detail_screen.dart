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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fest = await _api.getFestivalDetail(widget.festivalId);
    final media = await _api.getFestivalMedia(widget.festivalId);
    for (final item in media) {
      _likes[item.id] = await _api.getFestivalMediaLikes(item.id);
    }
    if (!mounted) return;
    setState(() {
      _festival = fest;
      _media = media;
      _loading = false;
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
              child: Image.network(imageUrl, fit: BoxFit.contain),
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
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if ((_festival!.bannerUrl ?? '').isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_festival!.bannerUrl!, height: 170, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if ((_festival!.iconUrl ?? '').isNotEmpty)
                          CircleAvatar(backgroundImage: NetworkImage(_festival!.iconUrl!), radius: 24),
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
                    ..._media.map(
                      (m) => Card(
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
                                    child: Image.network(m.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
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
                                    label: const Text('Comments'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
