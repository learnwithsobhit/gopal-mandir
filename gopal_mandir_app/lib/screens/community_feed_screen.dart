import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/vrindavan_background.dart';
import 'community_new_post_screen.dart';
import 'community_post_detail_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const int _pageSize = 20;

  CommunityPostSort _sort = CommunityPostSort.newest;
  String? _category;
  String? _search;

  final List<CommunityPost> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  static const List<_CategoryOption> _categories = [
    _CategoryOption(null, 'All'),
    _CategoryOption('general', 'General'),
    _CategoryOption('bhajans', 'Bhajans'),
    _CategoryOption('scriptures', 'Scriptures'),
    _CategoryOption('mantras', 'Mantras'),
    _CategoryOption('festivals', 'Festivals'),
    _CategoryOption('seva', 'Seva'),
    _CategoryOption('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await _api.listCommunityPosts(
      sort: _sort,
      category: _category,
      search: _search,
      limit: _pageSize,
      offset: _items.length,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(page);
      if (page.length < _pageSize) _hasMore = false;
      _loading = false;
    });
  }

  Future<void> _openDetail(CommunityPost post) async {
    final result = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(
        builder: (_) => VrindavanBackground(
          child: CommunityPostDetailScreen(postId: post.id),
        ),
      ),
    );
    if (result != null && mounted) {
      final idx = _items.indexWhere((p) => p.id == result.id);
      if (idx >= 0) {
        setState(() => _items[idx] = result);
      }
    }
  }

  Future<void> _openNewPost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const VrindavanBackground(
          child: CommunityNewPostScreen(),
        ),
      ),
    );
    if (created == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _likePost(CommunityPost post) async {
    final idx = _items.indexWhere((p) => p.id == post.id);
    if (idx < 0) return;
    setState(() => _items[idx] =
        post.copyWith(likesCount: post.likesCount + 1));
    final newCount = await _api.likeCommunityPost(post.id);
    if (!mounted) return;
    if (newCount != null) {
      setState(() => _items[idx] = _items[idx].copyWith(likesCount: newCount));
    }
  }

  void _applySort(CommunityPostSort next) {
    if (next == _sort) return;
    setState(() => _sort = next);
    _refresh();
  }

  void _applyCategory(String? next) {
    if (next == _category) return;
    setState(() => _category = next);
    _refresh();
  }

  void _applySearch() {
    final text = _searchCtrl.text.trim();
    setState(() => _search = text.isEmpty ? null : text);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Community Q&A')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPost,
        icon: const Icon(Icons.add),
        label: const Text('Ask'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search questions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch();
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _sortChip('Newest', CommunityPostSort.newest),
                const SizedBox(width: AppSpacing.sm),
                _sortChip('Most Liked', CommunityPostSort.mostLiked),
                const SizedBox(width: AppSpacing.sm),
                _sortChip('Most Answered', CommunityPostSort.mostAnswered),
                const SizedBox(width: AppSpacing.sm),
                _sortChip('Popular', CommunityPostSort.popular),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = c.id == _category;
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: selected,
                    onSelected: (_) => _applyCategory(c.id),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.urgentRed),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl * 3,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  if (i == _items.length) {
                    if (_loading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (_items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                        ),
                        child: Center(
                          child: Text(
                            'No questions yet. Be the first to ask!',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  final post = _items[i];
                  return _PostCard(
                    post: post,
                    onTap: () => _openDetail(post),
                    onLike: () => _likePost(post),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, CommunityPostSort value) {
    return ChoiceChip(
      label: Text(label),
      selected: _sort == value,
      onSelected: (_) => _applySort(value),
    );
  }
}

class _CategoryOption {
  final String? id;
  final String label;
  const _CategoryOption(this.id, this.label);
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.warmGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                post.body,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 18),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.warmGrey),
                  const SizedBox(width: 4),
                  Text('${post.answersCount}'),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.warmGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
