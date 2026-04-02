import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';

const _prefLastCategory = 'daily_upasana_last_category';
const _prefLastItemId = 'daily_upasana_last_item_id';

Future<void> saveDailyUpasanaLastRead(String categoryKey, int itemId) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_prefLastCategory, categoryKey);
  await sp.setInt(_prefLastItemId, itemId);
}

Future<({String categoryKey, int itemId})?> loadDailyUpasanaLastRead() async {
  final sp = await SharedPreferences.getInstance();
  if (!sp.containsKey(_prefLastItemId)) return null;
  final id = sp.getInt(_prefLastItemId);
  if (id == null) return null;
  return (categoryKey: sp.getString(_prefLastCategory) ?? '', itemId: id);
}

String _categoryDbKey(DailyUpasanaItem item) => item.category.trim();

Map<String, List<DailyUpasanaItem>> _groupByCategory(List<DailyUpasanaItem> items) {
  final m = <String, List<DailyUpasanaItem>>{};
  for (final i in items) {
    final k = _categoryDbKey(i);
    m.putIfAbsent(k, () => []).add(i);
  }
  for (final list in m.values) {
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }
  return m;
}

List<String> _orderedTopicKeys(Map<String, List<DailyUpasanaItem>> grouped) {
  final keys = grouped.keys.toList();
  keys.sort((a, b) {
    if (a.isEmpty && b.isNotEmpty) return 1;
    if (a.isNotEmpty && b.isEmpty) return -1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return keys;
}

String _displayCategory(String key, AppStrings s) =>
    key.isEmpty ? s.dailyUpasanaTopicGeneral : key;

class DailyUpasanaScreen extends StatefulWidget {
  const DailyUpasanaScreen({super.key});

  @override
  State<DailyUpasanaScreen> createState() => _DailyUpasanaScreenState();
}

class _DailyUpasanaScreenState extends State<DailyUpasanaScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<DailyUpasanaItem> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  DailyUpasanaItem? _resumeItem;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getDailyUpasana();
    final last = await loadDailyUpasanaLastRead();
    DailyUpasanaItem? resume;
    if (last != null) {
      try {
        resume = data.firstWhere((e) => e.id == last.itemId);
      } catch (_) {
        resume = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _items = data;
      _resumeItem = resume;
      _loading = false;
    });
  }

  List<String> _filteredTopicKeys(Map<String, List<DailyUpasanaItem>> grouped, AppStrings s) {
    final keys = _orderedTopicKeys(grouped);
    if (_searchQuery.isEmpty) return keys;
    return keys.where((k) {
      final display = _displayCategory(k, s).toLowerCase();
      return display.contains(_searchQuery) || k.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openTopic(BuildContext context, String categoryKey, AppStrings s) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DailyUpasanaChapterListScreen(
          categoryKey: categoryKey,
          displayTitle: _displayCategory(categoryKey, s),
        ),
      ),
    );
  }

  void _continueReading(BuildContext context, DailyUpasanaItem item, AppStrings s) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DailyUpasanaChapterListScreen(
          categoryKey: _categoryDbKey(item),
          displayTitle: _displayCategory(_categoryDbKey(item), s),
          openAtItemId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final grouped = _groupByCategory(_items);
    final topicKeys = _filteredTopicKeys(grouped, s);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.dailyUpasanaTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.krishnaBlue,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            s.dailyUpasanaEmpty,
                            style: const TextStyle(color: AppColors.warmGrey),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (_resumeItem != null) ...[
                          Material(
                            color: AppColors.krishnaBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => _continueReading(context, _resumeItem!, s),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bookmark_added_rounded,
                                        color: AppColors.krishnaBlue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.dailyUpasanaContinueReading,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.krishnaBlueDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _resumeItem!.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.darkBrown,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.warmGrey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: s.dailyUpasanaSearchTopicsHint,
                            prefixIcon: const Icon(Icons.search, color: AppColors.warmGrey),
                            filled: true,
                            fillColor: AppColors.softWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (topicKeys.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Center(
                              child: Text(
                                s.dailyUpasanaEmpty,
                                style: const TextStyle(color: AppColors.warmGrey),
                              ),
                            ),
                          )
                        else
                          ...topicKeys.map((key) {
                            final list = grouped[key]!;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(
                                  _displayCategory(key, s),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  s.dailyUpasanaTopicEntryCount(list.length),
                                  style: const TextStyle(
                                    color: AppColors.templeGoldDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openTopic(context, key, s),
                              ),
                            );
                          }),
                      ],
                    ),
            ),
    );
  }
}

class DailyUpasanaChapterListScreen extends StatefulWidget {
  const DailyUpasanaChapterListScreen({
    super.key,
    required this.categoryKey,
    required this.displayTitle,
    this.openAtItemId,
  });

  final String categoryKey;
  final String displayTitle;
  final int? openAtItemId;

  @override
  State<DailyUpasanaChapterListScreen> createState() =>
      _DailyUpasanaChapterListScreenState();
}

class _DailyUpasanaChapterListScreenState extends State<DailyUpasanaChapterListScreen> {
  final ApiService _api = ApiService();
  List<DailyUpasanaItem> _items = [];
  bool _loading = true;
  bool _autoOpenedReader = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getDailyUpasana(category: widget.categoryKey);
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
    if (!_autoOpenedReader && widget.openAtItemId != null && data.isNotEmpty) {
      final idx = data.indexWhere((e) => e.id == widget.openAtItemId);
      if (idx >= 0) {
        _autoOpenedReader = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openReader(idx);
        });
      }
    }
  }

  void _openReader(int initialIndex) {
    if (_items.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DailyUpasanaReaderScreen(
          items: List<DailyUpasanaItem>.from(_items),
          initialIndex: initialIndex.clamp(0, _items.length - 1),
          categoryKey: widget.categoryKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.displayTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : _items.isEmpty
              ? Center(
                  child: Text(
                    s.dailyUpasanaEmpty,
                    style: const TextStyle(color: AppColors.warmGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.menu_book_outlined, color: AppColors.krishnaBlue),
                        onTap: () => _openReader(index),
                      ),
                    );
                  },
                ),
    );
  }
}

class DailyUpasanaReaderScreen extends StatefulWidget {
  const DailyUpasanaReaderScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.categoryKey,
  });

  final List<DailyUpasanaItem> items;
  final int initialIndex;
  final String categoryKey;

  @override
  State<DailyUpasanaReaderScreen> createState() => _DailyUpasanaReaderScreenState();
}

class _DailyUpasanaReaderScreenState extends State<DailyUpasanaReaderScreen> {
  late final PageController _pageController;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistCurrent();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _persistCurrent() {
    if (widget.items.isEmpty) return;
    final item = widget.items[_pageIndex];
    saveDailyUpasanaLastRead(widget.categoryKey, item.id);
  }

  void _onPageChanged(int i) {
    setState(() => _pageIndex = i);
    _persistCurrent();
  }

  void _goPrev() {
    if (_pageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goNext() {
    if (_pageIndex < widget.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final item = widget.items[_pageIndex];

    return Scaffold(
      backgroundColor: AppColors.sandalCream,
      appBar: AppBar(
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final it = widget.items[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      if (it.category.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          it.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.templeGoldDark,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        it.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.65,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Material(
            elevation: 8,
            color: AppColors.softWhite,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pageIndex > 0 ? _goPrev : null,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(s.dailyUpasanaPrevious),
                    ),
                    Expanded(
                      child: Text(
                        '${_pageIndex + 1} / ${widget.items.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmGrey,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pageIndex < widget.items.length - 1 ? _goNext : null,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(s.dailyUpasanaNext),
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
