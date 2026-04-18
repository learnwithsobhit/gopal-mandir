import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_community_post_detail_screen.dart';

class AdminCommunityPostsScreen extends StatefulWidget {
  const AdminCommunityPostsScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminCommunityPostsScreen> createState() =>
      _AdminCommunityPostsScreenState();
}

class _AdminCommunityPostsScreenState extends State<AdminCommunityPostsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<CommunityPost> _items = [];
  bool _loading = true;
  CommunityPostSort _sort = CommunityPostSort.newest;
  bool _includeHidden = true;
  String? _search;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.adminListCommunityPosts(
      widget.token,
      sort: _sort,
      search: _search,
      includeHidden: _includeHidden,
    );
    if (mounted) {
      setState(() {
        _items = data;
        _loading = false;
      });
    }
  }

  Future<void> _toggleHide(CommunityPost p) async {
    final nextStatus = p.status == 'visible' ? 'hidden' : 'visible';
    final ok = await _api.adminPatchCommunityPostStatus(
      widget.token,
      p.id,
      nextStatus,
    );
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update post')),
      );
    }
  }

  Future<void> _deletePost(CommunityPost p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('Permanently delete "${p.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _api.adminDeleteCommunityPost(widget.token, p.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete')),
      );
    }
  }

  Future<void> _openDetail(CommunityPost p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCommunityPostDetailScreen(
          token: widget.token,
          postId: p.id,
        ),
      ),
    );
    if (changed == true) _load();
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Q&A')),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _search = v.trim().isEmpty ? null : v.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Search title / body / phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search = null;
                          _load();
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Sort: '),
                DropdownButton<CommunityPostSort>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                        value: CommunityPostSort.newest, child: Text('Newest')),
                    DropdownMenuItem(
                        value: CommunityPostSort.mostLiked,
                        child: Text('Most Liked')),
                    DropdownMenuItem(
                        value: CommunityPostSort.mostAnswered,
                        child: Text('Most Answered')),
                    DropdownMenuItem(
                        value: CommunityPostSort.popular,
                        child: Text('Popular')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sort = v);
                    _load();
                  },
                ),
                const Spacer(),
                const Text('Show hidden'),
                Switch(
                  value: _includeHidden,
                  onChanged: (v) {
                    setState(() => _includeHidden = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No posts found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(CommunityPost p) {
    final hidden = p.status != 'visible';
    return Card(
      child: InkWell(
        onTap: () => _openDetail(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: hidden ? AppColors.warmGrey : null,
                        decoration:
                            hidden ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (hidden)
                    const Chip(
                      label: Text('Hidden',
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                p.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.warmGrey),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 2,
                children: [
                  _meta(Icons.person, p.authorName),
                  if (p.authorPhone != null && p.authorPhone!.isNotEmpty)
                    _meta(Icons.phone, p.authorPhone!),
                  _meta(Icons.category_outlined, p.category),
                  _meta(Icons.favorite_border, '${p.likesCount}'),
                  _meta(Icons.question_answer, '${p.answersCount}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _fmtDate(p.createdAt),
                style: TextStyle(fontSize: 11, color: AppColors.warmGrey),
              ),
              const Divider(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleHide(p),
                    icon: Icon(
                      hidden ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                    ),
                    label: Text(hidden ? 'Unhide' : 'Hide'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _deletePost(p),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.urgentRed),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.warmGrey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
