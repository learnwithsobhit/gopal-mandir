import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_succession_edit_screen.dart';

/// Admin management for the temple's lineage (परम्परा). Mirrors the pattern
/// used by [AdminSevaItemsListScreen] — simple list + FAB + per-row edit /
/// delete. Cache invalidation happens server-side on every mutation.
class AdminSuccessionsScreen extends StatefulWidget {
  const AdminSuccessionsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminSuccessionsScreen> createState() =>
      _AdminSuccessionsScreenState();
}

class _AdminSuccessionsScreenState extends State<AdminSuccessionsScreen> {
  final ApiService _api = ApiService();
  List<Succession> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminListSuccessions(widget.token);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(Succession item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete succession entry?'),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.adminDeleteSuccession(widget.token, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Deleted' : 'Delete failed')),
    );
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminSuccessions),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.templeGoldDark,
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AdminSuccessionEditScreen(token: widget.token),
            ),
          );
          if (changed == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.templeGoldDark),
            )
          : _items.isEmpty
              ? Center(child: Text(s.successionsEmpty))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.templeGoldDark,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: _AdminSuccessionThumb(
                            photoUrl: item.photoUrl,
                            position: item.position,
                          ),
                          title: Text(
                            item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              if ((item.title ?? '').isNotEmpty) item.title!,
                              if ((item.tenureText ?? '').isNotEmpty)
                                item.tenureText!,
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute<bool>(
                                      builder: (_) =>
                                          AdminSuccessionEditScreen(
                                        token: widget.token,
                                        existing: item,
                                      ),
                                    ),
                                  );
                                  if (changed == true) _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Small circular thumbnail for the admin list. Falls back to a position
/// badge when no photo is set — and shows the same badge while the image
/// is still loading / errors out so admins can visually verify that the
/// upload produced a usable `photo_url`.
class _AdminSuccessionThumb extends StatelessWidget {
  const _AdminSuccessionThumb({
    required this.photoUrl,
    required this.position,
  });

  final String? photoUrl;
  final int position;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').trim().isNotEmpty;
    if (!hasPhoto) {
      return CircleAvatar(
        backgroundColor: AppColors.templeGold.withAlpha(40),
        child: Text(
          '$position',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.templeGoldDark,
          ),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CachedNetworkImage(
          imageUrl: ApiService.galleryProxyUrl(
            photoUrl!,
            width: 160,
            quality: 78,
          ),
          fit: BoxFit.cover,
          memCacheWidth: 160,
          placeholder: (_, __) => Container(
            color: AppColors.templeGold.withAlpha(20),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.templeGold.withAlpha(40),
            alignment: Alignment.center,
            child: Text(
              '$position',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.templeGoldDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
