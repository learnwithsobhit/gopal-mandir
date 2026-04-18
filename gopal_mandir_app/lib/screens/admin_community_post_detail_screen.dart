import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AdminCommunityPostDetailScreen extends StatefulWidget {
  const AdminCommunityPostDetailScreen({
    super.key,
    required this.token,
    required this.postId,
  });

  final String token;
  final int postId;

  @override
  State<AdminCommunityPostDetailScreen> createState() =>
      _AdminCommunityPostDetailScreenState();
}

class _AdminCommunityPostDetailScreenState
    extends State<AdminCommunityPostDetailScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _answerCtrl = TextEditingController();

  CommunityPostDetail? _detail;
  bool _loading = true;
  bool _sending = false;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final d = await _api.getCommunityPostDetail(widget.postId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _detail = d;
      if (d == null) _error = 'Could not load post.';
    });
  }

  Future<void> _postAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final r = await _api.adminCreateCommunityAnswer(
      widget.token,
      widget.postId,
      text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.success) {
      _answerCtrl.clear();
      _dirty = true;
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    }
  }

  Future<void> _deleteAnswer(int answerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete answer?'),
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
    final ok = await _api.adminDeleteCommunityAnswer(widget.token, answerId);
    if (!mounted) return;
    if (ok) {
      _dirty = true;
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete answer')),
      );
    }
  }

  Future<void> _postComment(int answerId) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comment on answer'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    final r = await _api.adminCreateCommunityAnswerComment(
      widget.token,
      answerId,
      text,
    );
    if (!mounted) return;
    if (r.success) {
      _dirty = true;
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
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
    final ok =
        await _api.adminDeleteCommunityAnswerComment(widget.token, commentId);
    if (!mounted) return;
    if (ok) {
      _dirty = true;
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete')),
      );
    }
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dirty);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _detail == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(_error ?? 'Not found'),
                    ),
                  )
                : _body(_detail!),
        bottomNavigationBar: _detail == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _answerCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Post an answer...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sending ? null : _postAnswer,
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _body(CommunityPostDetail detail) {
    final theme = Theme.of(context);
    final post = detail.post;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(post.category)),
                      const Spacer(),
                      Text(
                        _fmtDate(post.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: AppColors.warmGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(post.body, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14),
                      const SizedBox(width: 4),
                      Text(post.authorName),
                      if (post.authorPhone != null &&
                          post.authorPhone!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.phone, size: 14),
                        const SizedBox(width: 4),
                        Text(post.authorPhone!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${detail.answers.length} Answer${detail.answers.length == 1 ? '' : 's'}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (detail.answers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No answers yet. Post the first one below.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ...detail.answers.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _adminAnswerCard(a),
              ),
            ),
        ],
      ),
    );
  }

  Widget _adminAnswerCard(CommunityAnswer a) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(a.authorName,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(
                  _fmtDate(a.createdAt),
                  style:
                      TextStyle(fontSize: 11, color: AppColors.warmGrey),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteAnswer(a.id),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.favorite_border,
                    size: 16, color: AppColors.warmGrey),
                const SizedBox(width: 4),
                Text('${a.likesCount}'),
                const SizedBox(width: 12),
                Icon(Icons.reply, size: 16, color: AppColors.warmGrey),
                const SizedBox(width: 4),
                Text('${a.commentsCount}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _postComment(a.id),
                  icon: const Icon(Icons.add_comment, size: 18),
                  label: const Text('Comment'),
                ),
              ],
            ),
            if (a.comments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warmGrey.withAlpha(16),
                  borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                ),
                child: Column(
                  children: [
                    for (final c in a.comments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: '${c.authorName}: ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(text: c.body),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete comment',
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => _deleteComment(c.id),
                              icon: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
