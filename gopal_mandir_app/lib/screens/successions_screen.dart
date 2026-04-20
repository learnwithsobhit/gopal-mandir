import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'succession_detail_screen.dart';

/// Public read-only list of the temple's lineage (परम्परा) — mahants /
/// acharyas in chronological order. Data comes from `GET /api/successions`
/// which is Redis-cached (6 h TTL), so this screen is effectively static
/// after the first load.
class SuccessionsScreen extends StatefulWidget {
  const SuccessionsScreen({super.key});

  @override
  State<SuccessionsScreen> createState() => _SuccessionsScreenState();
}

class _SuccessionsScreenState extends State<SuccessionsScreen> {
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
    final data = await _api.getSuccessions();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.successionsScreenTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.templeGoldDark,
        child: _loading
            ? ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, __) => const _SuccessionShimmer(),
              )
            : _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
                        child: Text(
                          s.successionsEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: AppColors.warmGrey,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return _SuccessionCard(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SuccessionDetailScreen(item: item),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _SuccessionCard extends StatelessWidget {
  const _SuccessionCard({required this.item, required this.onTap});

  final Succession item;
  final VoidCallback onTap;

  static const int _collapsedBioLines = 6;

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Prefer the admin-supplied free-form tenure text; otherwise fall back to
  /// the structured start/end dates so the list always conveys *when* the
  /// lineage holder served, even if the admin only filled the date fields.
  String? _tenureDisplay() {
    final text = (item.tenureText ?? '').trim();
    if (text.isNotEmpty) return text;
    final start = item.tenureStart;
    final end = item.tenureEnd;
    if (start != null && end != null) {
      return '${_fmtDate(start)} → ${_fmtDate(end)}';
    }
    if (start != null) return '${_fmtDate(start)} →';
    if (end != null) return '→ ${_fmtDate(end)}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bio = item.bio;
    final tenure = _tenureDisplay();
    final hasTitle = (item.title ?? '').isNotEmpty;

    return Material(
      color: AppColors.softWhite,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.softWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(photoUrl: item.photoUrl, position: item.position),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _OrderBadge(position: item.position),
                            if (hasTitle)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.templeGold.withAlpha(40),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.title!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.templeGoldDark,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                            height: 1.25,
                          ),
                        ),
                        if (tenure != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: AppColors.warmGrey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tenure,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.warmGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmGrey,
                  ),
                ],
              ),
              if ((bio ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  bio!,
                  maxLines: _collapsedBioLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
              if ((item.quote ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.templeGold.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.templeGoldDark.withAlpha(140),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    item.quote!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill showing the lineage order (e.g. `#1`). Rendered alongside the
/// optional title pill so the chronological position is always visible on
/// the list — even when the avatar is occupied by a photo (which otherwise
/// hides the fallback numeric badge).
class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.krishnaBlue.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$position',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.krishnaBlueDark,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.position});

  final String? photoUrl;
  final int position;

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    if ((photoUrl ?? '').isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.templeGold.withAlpha(40),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.templeGoldDark.withAlpha(120),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$position',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.templeGoldDark,
          ),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: ApiService.galleryProxyUrl(
            photoUrl!,
            width: 200,
            quality: 78,
          ),
          fit: BoxFit.cover,
          memCacheWidth: 200,
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

class _SuccessionShimmer extends StatelessWidget {
  const _SuccessionShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmGrey.withAlpha(80),
      highlightColor: AppColors.warmGrey.withAlpha(40),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softWhite,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 200,
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
}
