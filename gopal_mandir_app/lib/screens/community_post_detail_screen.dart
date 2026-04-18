import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final ApiService _api = ApiService();

  CommunityPostDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail = await _api.getCommunityPostDetail(widget.postId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _detail = detail;
      if (detail == null) _error = 'Could not load question.';
    });
  }

  Future<void> _likePost() async {
    final d = _detail;
    if (d == null) return;
    setState(() {
      _detail = CommunityPostDetail(
        post: d.post.copyWith(likesCount: d.post.likesCount + 1),
        answers: d.answers,
      );
    });
    final count = await _api.likeCommunityPost(d.post.id);
    if (!mounted || count == null) return;
    setState(() {
      final cur = _detail!;
      _detail = CommunityPostDetail(
        post: cur.post.copyWith(likesCount: count),
        answers: cur.answers,
      );
    });
  }

  Future<void> _likeAnswer(int answerId) async {
    final d = _detail;
    if (d == null) return;
    final idx = d.answers.indexWhere((a) => a.id == answerId);
    if (idx < 0) return;
    setState(() {
      final answers = List<CommunityAnswer>.from(d.answers);
      answers[idx] = answers[idx]
          .copyWith(likesCount: answers[idx].likesCount + 1);
      _detail = CommunityPostDetail(post: d.post, answers: answers);
    });
    final count = await _api.likeCommunityAnswer(answerId);
    if (!mounted || count == null) return;
    setState(() {
      final cur = _detail!;
      final answers = List<CommunityAnswer>.from(cur.answers);
      final i = answers.indexWhere((a) => a.id == answerId);
      if (i >= 0) {
        answers[i] = answers[i].copyWith(likesCount: count);
      }
      _detail = CommunityPostDetail(post: cur.post, answers: answers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _detail;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, detail?.post);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Question')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : detail == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error ?? 'Something went wrong.',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _QuestionCard(
                          post: detail.post,
                          onLike: _likePost,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Text(
                              '${detail.answers.length} Answer${detail.answers.length == 1 ? '' : 's'}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (detail.answers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              'No answers yet. Our temple team will respond soon.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        else
                          ...detail.answers.map(
                            (a) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _AnswerCard(
                                answer: a,
                                onLike: () => _likeAnswer(a.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.post, required this.onLike});

  final CommunityPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
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
                Chip(
                  label: Text(post.category),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                Text(
                  post.authorName,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.warmGrey),
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
                OutlinedButton.icon(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: Text('Like  ${post.likesCount}'),
                ),
                const SizedBox(width: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.warmGrey),
                    const SizedBox(width: 4),
                    Text('${post.answersCount}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.onLike});

  final CommunityAnswer answer;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.krishnaBlue.withAlpha(24),
                  child: Icon(Icons.temple_hindu,
                      size: 16, color: AppColors.krishnaBlue),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  answer.authorName,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.krishnaBlue.withAlpha(24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Temple',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.krishnaBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(answer.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 16),
                        const SizedBox(width: 4),
                        Text('${answer.likesCount}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.reply, size: 16, color: AppColors.warmGrey),
                const SizedBox(width: 4),
                Text('${answer.commentsCount}'),
              ],
            ),
            if (answer.comments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.krishnaBlue.withAlpha(8),
                  borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in answer.comments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text: '${c.authorName}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: c.body),
                            ],
                          ),
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
