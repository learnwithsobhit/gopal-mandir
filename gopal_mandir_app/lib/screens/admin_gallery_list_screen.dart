import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_gallery_edit_screen.dart';

class AdminGalleryListScreen extends StatefulWidget {
  const AdminGalleryListScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminGalleryListScreen> createState() => _AdminGalleryListScreenState();
}

class _AdminGalleryListScreenState extends State<AdminGalleryListScreen> {
  final ApiService _api = ApiService();
  List<GalleryItem> _items = [];
  String? _landingAudioUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListGallery(widget.token, perPage: 100);
    final landing = await _api.getLandingAudioUrl();
    if (!mounted) return;
    setState(() {
      _items = list;
      _landingAudioUrl = landing;
      _loading = false;
    });
  }

  Future<void> _setLandingAudio(GalleryItem item) async {
    final url = item.videoUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item has no audio URL')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Landing page audio'),
        content: Text(
          'Use this track for the welcome screen?\n\n${item.title}\n$url',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Set')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await _api.adminPatchLandingAudio(widget.token, url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
    _load();
  }

  Future<void> _clearLandingAudio() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear landing audio?'),
        content: const Text(
          'The app will fall back to the default welcome MP3 when the API returns no URL.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await _api.adminPatchLandingAudio(widget.token, '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
    _load();
  }

  Future<void> _delete(GalleryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(item.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.adminDeleteGallery(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Deleted' : 'Delete failed')),
    );
    if (success) _load();
  }

  Future<void> _edit(GalleryItem item) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AdminGalleryEditScreen(
          token: widget.token,
          existing: item,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final landing = _landingAudioUrl?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery (admin)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminGalleryEditScreen(token: widget.token),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.krishnaBlue,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home_filled, color: AppColors.krishnaBlue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Landing page audio',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          landing.isEmpty
                              ? 'Not set in database — app uses built-in default MP3.'
                              : landing,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warmGrey,
                            height: 1.35,
                          ),
                          maxLines: landing.isEmpty ? 2 : 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (landing.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _clearLandingAudio,
                              child: const Text('Clear (use default)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('No gallery items'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return ListTile(
                              leading: Icon(
                                item.isAudio
                                    ? Icons.audiotrack
                                    : item.isVideo
                                        ? Icons.videocam
                                        : Icons.image,
                                color: AppColors.krishnaBlue,
                              ),
                              title: Text(item.title),
                              subtitle: Text('${item.category} · ${item.mediaType}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'landing') await _setLandingAudio(item);
                                  if (v == 'edit') await _edit(item);
                                  if (v == 'delete') await _delete(item);
                                },
                                itemBuilder: (context) => [
                                  if (item.isAudio)
                                    const PopupMenuItem(
                                      value: 'landing',
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.home_outlined),
                                        title: Text('Set as landing page audio'),
                                        dense: true,
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Edit'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Delete'),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
