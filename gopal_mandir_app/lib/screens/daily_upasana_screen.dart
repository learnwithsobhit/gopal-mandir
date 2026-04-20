import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';
import 'daily_upasana_web_pdf_view.dart';

// ── Persistence keys ────────────────────────────────────────────────────────
const _prefLastCategory = 'daily_upasana_last_category';
const _prefLastItemId = 'daily_upasana_last_item_id';
const _prefTextScale = 'daily_upasana_text_scale';
const _prefReaderDark = 'daily_upasana_reader_dark';
String _prefPdfPage(int itemId) => 'daily_upasana_pdf_page_$itemId';
String _prefPdfBookmarks(int itemId) => 'daily_upasana_pdf_bookmarks_$itemId';

Future<void> saveDailyUpasanaLastRead(String categoryKey, int itemId) async {
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefLastCategory, categoryKey);
    await sp.setInt(_prefLastItemId, itemId);
  } catch (_) {
    // Web: localStorage blocked / plugin failure — ignore so reader still works.
  }
}

Future<({String categoryKey, int itemId})?> loadDailyUpasanaLastRead() async {
  try {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey(_prefLastItemId)) return null;
    final id = sp.getInt(_prefLastItemId);
    if (id == null) return null;
    return (categoryKey: sp.getString(_prefLastCategory) ?? '', itemId: id);
  } catch (_) {
    return null;
  }
}

String _categoryDbKey(DailyUpasanaItem item) => item.category.trim();

Map<String, List<DailyUpasanaItem>> _groupByCategory(
    List<DailyUpasanaItem> items) {
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

IconData _iconForCategory(String key) {
  final k = key.toLowerCase();
  if (k.contains('आरती') || k.contains('arti') || k.contains('aarti')) {
    return Icons.local_fire_department_outlined;
  }
  if (k.contains('भजन') || k.contains('bhajan')) return Icons.music_note;
  if (k.contains('मंत्र') || k.contains('mantra')) {
    return Icons.record_voice_over_outlined;
  }
  if (k.contains('कथा') || k.contains('katha') || k.contains('story')) {
    return Icons.auto_stories_outlined;
  }
  if (k.contains('श्लोक') || k.contains('shlok') || k.contains('verse')) {
    return Icons.format_quote;
  }
  return Icons.menu_book_outlined;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hub: Today's reading card + grouped category grid
// ─────────────────────────────────────────────────────────────────────────────

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
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      List<DailyUpasanaItem> data;
      try {
        data = await _api.getDailyUpasana();
      } catch (_) {
        data = [];
      }
      final last = await loadDailyUpasanaLastRead();
      DailyUpasanaItem? resume;
      if (last != null) {
        try {
          resume = data.firstWhere((e) => e.id == last.itemId);
        } catch (_) {
          resume = null;
        }
      }
      // Fallback hero item: first published item (list is already filtered by
      // is_published on the server).
      resume ??= data.isNotEmpty ? data.first : null;
      if (!mounted) return;
      setState(() {
        _items = data;
        _resumeItem = resume;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _resumeItem = null;
        _loading = false;
      });
    }
  }

  List<String> _filteredTopicKeys(
      Map<String, List<DailyUpasanaItem>> grouped, AppStrings s) {
    final keys = _orderedTopicKeys(grouped);
    if (_searchQuery.isEmpty) return keys;
    return keys.where((k) {
      final display = _displayCategory(k, s).toLowerCase();
      if (display.contains(_searchQuery) ||
          k.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      // Also match topic if any of its item titles matches.
      final any = grouped[k]!
          .any((it) => it.title.toLowerCase().contains(_searchQuery));
      return any;
    }).toList();
  }

  void _openTopic(BuildContext context, String categoryKey, AppStrings s) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DailyUpasanaChapterListScreen(
          categoryKey: categoryKey,
          displayTitle: _displayCategory(categoryKey, s),
        ),
      ),
    );
  }

  void _continueReading(BuildContext context, DailyUpasanaItem item) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DailyUpasanaChapterListScreen(
          categoryKey: _categoryDbKey(item),
          displayTitle: _displayCategory(
            _categoryDbKey(item),
            AppLocaleScope.of(ctx).strings,
          ),
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
    final resume = _resumeItem;
    final isResumeFallback = resume != null &&
        (_items.isEmpty || _items.first.id == resume.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.dailyUpasanaTitle)),
      body: RefreshIndicator(
        color: AppColors.krishnaBlue,
        onRefresh: _load,
        child: _loading
            ? _loadingState()
            : _items.isEmpty
                ? _emptyState(s)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (resume != null)
                        _HeroTodayCard(
                          item: resume,
                          isResume: !isResumeFallback,
                          onTap: () => _continueReading(context, resume),
                        ),
                      const SizedBox(height: 16),
                      _searchField(s),
                      const SizedBox(height: 8),
                      if (topicKeys.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              s.dailyUpasanaEmpty,
                              style: const TextStyle(
                                  color: AppColors.warmGrey),
                            ),
                          ),
                        )
                      else ...[
                        SectionHeader(
                          title: s.dailyUpasanaTitle,
                          icon: Icons.menu_book_outlined,
                          padding:
                              const EdgeInsets.fromLTRB(4, 12, 4, 8),
                        ),
                        _categoryGrid(context, grouped, topicKeys, s),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _loadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SkeletonCard(height: 128, radius: 18),
        const SizedBox(height: 16),
        const SkeletonBox(height: 46, radius: 12),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: List.generate(
              6, (_) => const SkeletonCard(height: 120, radius: 16)),
        ),
      ],
    );
  }

  Widget _emptyState(AppStrings s) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text(
            s.dailyUpasanaEmptyHub,
            style: const TextStyle(color: AppColors.warmGrey),
          ),
        ),
      ],
    );
  }

  Widget _searchField(AppStrings s) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: s.dailyUpasanaSearchHint,
        prefixIcon:
            const Icon(Icons.search, color: AppColors.warmGrey),
        filled: true,
        fillColor: AppColors.softWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _categoryGrid(
    BuildContext context,
    Map<String, List<DailyUpasanaItem>> grouped,
    List<String> topicKeys,
    AppStrings s,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: topicKeys.map((key) {
        final list = grouped[key]!;
        final hasPdf = list.any((i) => i.isPdf);
        return _CategoryTile(
          title: _displayCategory(key, s),
          icon: _iconForCategory(key),
          count: list.length,
          hasPdf: hasPdf,
          onTap: () => _openTopic(context, key, s),
          countLabel: s.dailyUpasanaTopicEntryCount(list.length),
          pdfBadge: s.dailyUpasanaPdfBadge,
        );
      }).toList(),
    );
  }
}

class _HeroTodayCard extends StatelessWidget {
  const _HeroTodayCard({
    required this.item,
    required this.isResume,
    required this.onTap,
  });

  final DailyUpasanaItem item;
  final bool isResume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.templeGold,
                AppColors.templeGoldDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.templeGoldDark.withAlpha(60),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.dailyUpasanaTodayReading,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(60),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isResume
                                ? s.dailyUpasanaContinueCta
                                : s.dailyUpasanaStartCta,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (item.isPdf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.dailyUpasanaPdfBadge,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.templeGoldDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.count,
    required this.hasPdf,
    required this.onTap,
    required this.countLabel,
    required this.pdfBadge,
  });

  final String title;
  final IconData icon;
  final int count;
  final bool hasPdf;
  final VoidCallback onTap;
  final String countLabel;
  final String pdfBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppColors.krishnaBlue.withAlpha(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.templeGold.withAlpha(45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(icon, color: AppColors.templeGoldDark, size: 22),
                  ),
                  const Spacer(),
                  if (hasPdf) _PdfPill(label: pdfBadge),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.templeGoldDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfPill extends StatelessWidget {
  const _PdfPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.krishnaBlue.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              size: 11, color: AppColors.krishnaBlueDark),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.krishnaBlueDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter list
// ─────────────────────────────────────────────────────────────────────────────

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

class _DailyUpasanaChapterListScreenState
    extends State<DailyUpasanaChapterListScreen> {
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
    if (!_autoOpenedReader &&
        widget.openAtItemId != null &&
        data.isNotEmpty) {
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
    HapticFeedback.selectionClick();
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
      appBar: AppBar(title: Text(widget.displayTitle)),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) =>
                  const SkeletonCard(height: 84, radius: 14),
            )
          : _items.isEmpty
              ? Center(
                  child: Text(
                    s.dailyUpasanaEmpty,
                    style: const TextStyle(color: AppColors.warmGrey),
                  ),
                )
              : FutureBuilder<int?>(
                  future: _loadResumeItemIdForCategory(),
                  builder: (context, snap) {
                    final resumeId = snap.data;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _ChapterCard(
                          item: item,
                          isResume: resumeId != null && resumeId == item.id,
                          onTap: () => _openReader(index),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Future<int?> _loadResumeItemIdForCategory() async {
    final last = await loadDailyUpasanaLastRead();
    if (last == null) return null;
    if (last.categoryKey != widget.categoryKey) return null;
    return last.itemId;
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.item,
    required this.isResume,
    required this.onTap,
  });

  final DailyUpasanaItem item;
  final bool isResume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Material(
      color: AppColors.softWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppColors.krishnaBlue.withAlpha(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.templeGold.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : _iconForCategory(item.category),
                  color: AppColors.templeGoldDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.category.trim().isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.templeGoldDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.isPdf)
                          _PdfPill(label: s.dailyUpasanaPdfBadge),
                        if (isResume) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.krishnaBlue.withAlpha(22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.dailyUpasanaContinueCta,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.krishnaBlueDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warmGrey),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reader chrome: hosts TextReader or PdfReader based on item.isPdf
// ─────────────────────────────────────────────────────────────────────────────

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
  State<DailyUpasanaReaderScreen> createState() =>
      _DailyUpasanaReaderScreenState();
}

class _DailyUpasanaReaderScreenState extends State<DailyUpasanaReaderScreen> {
  late int _pageIndex;
  // Shared prefs for text reader; PDF reader uses its own per-item keys.
  double _textScale = 1.0;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _persistCurrent();
    _loadTextPrefs();
  }

  Future<void> _loadTextPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _textScale = (sp.getDouble(_prefTextScale) ?? 1.0).clamp(0.8, 1.8);
        _darkMode = sp.getBool(_prefReaderDark) ?? false;
      });
    } catch (_) {/* ignore — reader still works with defaults */}
  }

  Future<void> _saveTextPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble(_prefTextScale, _textScale);
      await sp.setBool(_prefReaderDark, _darkMode);
    } catch (_) {}
  }

  void _persistCurrent() {
    if (widget.items.isEmpty) return;
    final item = widget.items[_pageIndex];
    saveDailyUpasanaLastRead(widget.categoryKey, item.id);
  }

  void _goPrev() {
    if (_pageIndex > 0) {
      setState(() => _pageIndex--);
      _persistCurrent();
    }
  }

  void _goNext() {
    if (_pageIndex < widget.items.length - 1) {
      setState(() => _pageIndex++);
      _persistCurrent();
    }
  }

  void _bumpFont(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(0.8, 1.8);
    });
    _saveTextPrefs();
  }

  void _toggleDark() {
    setState(() => _darkMode = !_darkMode);
    _saveTextPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final item = widget.items[_pageIndex];
    final isPdf = item.isPdf;
    final bg = isPdf
        ? AppColors.sandalCream
        : (_darkMode ? const Color(0xFF2A1F1A) : AppColors.sandalCream);
    final fg = isPdf
        ? AppColors.darkBrown
        : (_darkMode ? const Color(0xFFEFE6D8) : AppColors.darkBrown);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!isPdf) ...[
            IconButton(
              tooltip: s.readerFontSize,
              icon: const Icon(Icons.text_fields),
              onPressed: () => _bumpFont(0.1),
            ),
            IconButton(
              tooltip: s.readerFontSize,
              icon: const Icon(Icons.text_decrease),
              onPressed: () => _bumpFont(-0.1),
            ),
            IconButton(
              tooltip: s.readerBrightness,
              icon: Icon(_darkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              onPressed: _toggleDark,
            ),
          ],
        ],
      ),
      body: isPdf
          ? _DailyUpasanaPdfReader(
              key: ValueKey('pdf_${item.id}'),
              item: item,
            )
          : _TextReader(
              key: ValueKey('text_${item.id}'),
              item: item,
              textScale: _textScale,
              foreground: fg,
            ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: AppColors.softWhite,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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
                  onPressed:
                      _pageIndex < widget.items.length - 1 ? _goNext : null,
                  icon: const Icon(Icons.chevron_right),
                  label: Text(s.dailyUpasanaNext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextReader extends StatefulWidget {
  const _TextReader({
    super.key,
    required this.item,
    required this.textScale,
    required this.foreground,
  });

  final DailyUpasanaItem item;
  final double textScale;
  final Color foreground;

  @override
  State<_TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<_TextReader> {
  // A dedicated controller shared by the Scrollbar and SingleChildScrollView
  // below. Without this, on Flutter Web the Scrollbar falls back to
  // PrimaryScrollController and throws "ScrollController has no ScrollPosition
  // attached" on every mouse-wheel scroll.
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.notoSerifDevanagari(
      fontSize: 16 * widget.textScale,
      height: 1.75,
      color: widget.foreground,
    );
    return Scrollbar(
      controller: _scrollCtrl,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: GoogleFonts.notoSerifDevanagari(
                fontSize: 22 * widget.textScale,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: widget.foreground,
              ),
            ),
            if (widget.item.category.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.item.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.templeGoldDark,
                  letterSpacing: 0.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(widget.item.content, style: bodyStyle),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF reader: Syncfusion viewer with resume, bookmarks, jump-to-page
// ─────────────────────────────────────────────────────────────────────────────

class _DailyUpasanaPdfReader extends StatefulWidget {
  const _DailyUpasanaPdfReader({super.key, required this.item});

  final DailyUpasanaItem item;

  @override
  State<_DailyUpasanaPdfReader> createState() => _DailyUpasanaPdfReaderState();
}

class _DailyUpasanaPdfReaderState extends State<_DailyUpasanaPdfReader> {
  final PdfViewerController _pdfCtrl = PdfViewerController();
  int _totalPages = 0;
  int _currentPage = 1;
  int? _savedPage;
  List<int> _bookmarks = const [];
  bool _loaded = false;
  bool _failed = false;
  String? _failDescription;
  String? _failedUrl;
  int _reloadNonce = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _pdfCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getInt(_prefPdfPage(widget.item.id));
      final rawBm = sp.getStringList(_prefPdfBookmarks(widget.item.id)) ??
          const <String>[];
      final bm = <int>[];
      for (final e in rawBm) {
        final n = int.tryParse(e);
        if (n != null && n > 0) bm.add(n);
      }
      bm.sort();
      if (!mounted) return;
      setState(() {
        _savedPage = saved;
        _bookmarks = bm;
      });
    } catch (_) {/* ignore */}
  }

  Future<void> _persistPage(int page) async {
    _currentPage = page;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_prefPdfPage(widget.item.id), page);
    } catch (_) {}
  }

  Future<void> _persistBookmarks(List<int> bm) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(
          _prefPdfBookmarks(widget.item.id), bm.map((e) => '$e').toList());
    } catch (_) {}
  }

  void _toggleBookmarkCurrent() {
    final page = _currentPage;
    final next = List<int>.from(_bookmarks);
    if (next.contains(page)) {
      next.remove(page);
    } else {
      next.add(page);
      next.sort();
    }
    setState(() => _bookmarks = next);
    _persistBookmarks(next);
    final s = AppLocaleScope.of(context).strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          next.contains(page)
              ? '${s.readerBookmarkPage}: ${s.readerPageLabel} $page'
              : 'Removed bookmark: ${s.readerPageLabel} $page',
        ),
      ),
    );
  }

  void _showBookmarks() {
    final s = AppLocaleScope.of(context).strings;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (_bookmarks.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.readerNoBookmarks),
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _bookmarks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = _bookmarks[i];
              return ListTile(
                leading:
                    const Icon(Icons.bookmark, color: AppColors.templeGold),
                title: Text('${s.readerPageLabel} $p'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    final next = List<int>.from(_bookmarks)..remove(p);
                    setState(() => _bookmarks = next);
                    _persistBookmarks(next);
                    Navigator.pop(ctx);
                  },
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _jumpTo(p);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _jumpToPrompt() async {
    final s = AppLocaleScope.of(context).strings;
    final ctrl = TextEditingController(text: '$_currentPage');
    final v = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.readerJumpToPage),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText:
                '${s.readerPageLabel} (1 - ${_totalPages == 0 ? '?' : _totalPages})',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, n);
            },
            child: Text(s.readerGo),
          ),
        ],
      ),
    );
    if (v == null) return;
    _jumpTo(v);
  }

  void _jumpTo(int page) {
    if (_totalPages == 0) return;
    final clamped = page.clamp(1, _totalPages);
    _pdfCtrl.jumpToPage(clamped);
  }

  void _retry() {
    setState(() {
      _failed = false;
      _failDescription = null;
      _failedUrl = null;
      _loaded = false;
      _reloadNonce++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final rawUrl = widget.item.pdfUrl;
    if (rawUrl.trim().isEmpty) {
      return Center(child: Text(s.readerPdfLoadFailed));
    }
    if (_failed) {
      return _pdfErrorCard(s);
    }
    // Route through the backend PDF proxy: the proxy normalises Content-Type
    // to `application/pdf`, strips any weird upstream headers, and lives on
    // the same origin we already use for API calls, so PDF.js (used by
    // SfPdfViewer on web) fetches it cleanly with a long Cache-Control.
    final url = ApiService.dailyUpasanaPdfUrl(rawUrl);

    // On Flutter Web, Syncfusion's PDF parser sometimes fails ("There was an
    // error opening this document") on PDFs that use compression filters or
    // custom Devanagari fonts its own implementation doesn't handle — even
    // when the same file renders fine in the browser tab. So on web we
    // delegate to the browser's native PDF viewer via an `<iframe>`; on
    // mobile/desktop Syncfusion works well and gives us richer controls.
    if (kIsWeb) {
      return buildDailyUpasanaWebPdfView(url);
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          url,
          key: ValueKey('pdf_${widget.item.id}_$_reloadNonce'),
          controller: _pdfCtrl,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          onDocumentLoaded: (details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _loaded = true;
            });
            final saved = _savedPage ?? 1;
            if (saved > 1 && saved <= _totalPages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pdfCtrl.jumpToPage(saved);
              });
            }
          },
          onDocumentLoadFailed: (details) {
            // Surface the underlying reason (HTTP status, CORS, bad MIME, etc.)
            // both to the UI and the console so the viewer doesn't eat the
            // real error. Keeps diagnostics easy without shipping a debugger.
            final desc = details.description.isNotEmpty
                ? details.description
                : details.error;
            debugPrint('[DailyUpasanaPdf] load failed for $url: $desc');
            if (!mounted) return;
            setState(() {
              _failed = true;
              _failDescription = desc;
              _failedUrl = url;
            });
          },
          onPageChanged: (details) {
            _persistPage(details.newPageNumber);
          },
        ),
        if (!_loaded)
          const Center(
            child: CircularProgressIndicator(color: AppColors.krishnaBlue),
          ),
        if (_loaded)
          Positioned(
            right: 12,
            bottom: 12,
            child: _PdfQuickActions(
              currentPage: _currentPage,
              totalPages: _totalPages,
              bookmarkedHere: _bookmarks.contains(_currentPage),
              onJump: _jumpToPrompt,
              onToggleBookmark: _toggleBookmarkCurrent,
              onShowBookmarks: _showBookmarks,
              strings: s,
            ),
          ),
      ],
    );
  }

  Widget _pdfErrorCard(AppStrings s) {
    final desc = _failDescription;
    final url = _failedUrl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.warmGrey),
            const SizedBox(height: 12),
            Text(
              s.readerPdfLoadFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.warmGrey),
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.warmGrey,
                  fontSize: 12,
                ),
              ),
            ],
            if (url != null && url.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.warmGrey,
                  fontSize: 10,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(s.readerRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfQuickActions extends StatelessWidget {
  const _PdfQuickActions({
    required this.currentPage,
    required this.totalPages,
    required this.bookmarkedHere,
    required this.onJump,
    required this.onToggleBookmark,
    required this.onShowBookmarks,
    required this.strings,
  });

  final int currentPage;
  final int totalPages;
  final bool bookmarkedHere;
  final VoidCallback onJump;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShowBookmarks;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(180),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: strings.readerJumpToPage,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              onPressed: onJump,
            ),
            IconButton(
              tooltip: strings.readerBookmarkPage,
              icon: Icon(
                bookmarkedHere ? Icons.bookmark : Icons.bookmark_border,
                color: bookmarkedHere
                    ? AppColors.templeGold
                    : Colors.white,
              ),
              onPressed: onToggleBookmark,
            ),
            IconButton(
              tooltip: strings.readerBookmarks,
              icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
              onPressed: onShowBookmarks,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                totalPages == 0
                    ? '—'
                    : strings.readerPageOfTotal(currentPage, totalPages),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
