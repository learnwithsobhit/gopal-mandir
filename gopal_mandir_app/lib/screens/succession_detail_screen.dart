import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Read-only detail screen for a single [Succession] entry. The list screen
/// already has the full object in memory, so we pass it in directly — no
/// extra network call.
///
/// Photo is rendered with [BoxFit.contain] inside a portrait-oriented
/// container so the whole profile image is always visible (no cropping).
/// Tap the photo to open a fullscreen [InteractiveViewer] where the user
/// can pinch/zoom and pan to inspect details. The rest of the content
/// flows below in a normal [SingleChildScrollView] so the page extends
/// naturally as more fields are present.
class SuccessionDetailScreen extends StatelessWidget {
  const SuccessionDetailScreen({super.key, required this.item});

  final Succession item;

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final hasPhoto = (item.photoUrl ?? '').trim().isNotEmpty;
    final hasTitle = (item.title ?? '').trim().isNotEmpty;
    final hasTenureText = (item.tenureText ?? '').trim().isNotEmpty;
    final hasDates = item.tenureStart != null || item.tenureEnd != null;
    final hasBio = (item.bio ?? '').trim().isNotEmpty;
    final hasQuote = (item.quote ?? '').trim().isNotEmpty;
    final hasExtraDetails =
        hasTenureText || hasDates || hasBio || hasQuote;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroPhoto(
              photoUrl: item.photoUrl,
              emptyLabel: s.successionNoPhoto,
              hasPhoto: hasPhoto,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.templeGold.withAlpha(40),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.title!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.templeGoldDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                      height: 1.25,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.templeGold.withAlpha(120),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  if (hasTenureText) ...[
                    const SizedBox(height: 14),
                    Text(
                      item.tenureText!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.warmGrey,
                      ),
                    ),
                  ],
                  if (hasDates) ...[
                    const SizedBox(height: 12),
                    _TenureDates(
                      label: s.successionTenureRange,
                      start: item.tenureStart,
                      end: item.tenureEnd,
                    ),
                  ],
                  if (hasBio) ...[
                    const SizedBox(height: 20),
                    Text(
                      item.bio!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ],
                  if (hasQuote) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                  if (!hasExtraDetails) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.templeGold.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.templeGold.withAlpha(40),
                        ),
                      ),
                      child: const Text(
                        'No additional details available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warmGrey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width hero photo. Uses [BoxFit.contain] inside a portrait-oriented
/// aspect box so the entire profile picture is visible regardless of the
/// source image's aspect ratio (tall portraits fit vertically; landscape
/// photos letterbox on the sides against the soft templeGold tint).
///
/// Tapping opens a fullscreen [InteractiveViewer] for pinch-to-zoom so the
/// user can inspect tiny details without the list screen being in the way.
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.photoUrl,
    required this.emptyLabel,
    required this.hasPhoto,
  });

  final String? photoUrl;
  final String emptyLabel;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    if (!hasPhoto) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _EmptyHero(label: emptyLabel),
      );
    }
    final proxied = ApiService.galleryProxyUrl(
      photoUrl!,
      width: 1200,
      quality: 85,
    );
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _FullscreenPhotoViewer(url: proxied),
        ),
      ),
      child: Container(
        width: double.infinity,
        color: AppColors.templeGold.withAlpha(25),
        child: AspectRatio(
          // 3:4 portrait slot — profile photos are usually portrait or
          // square, so this minimises side-letterboxing without cropping
          // tall images.
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: proxied,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  color: AppColors.templeGold.withAlpha(20),
                ),
                errorWidget: (_, __, ___) => _EmptyHero(label: emptyLabel),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(110),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.zoom_out_map,
                      size: 18,
                      color: Colors.white,
                    ),
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

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.templeGold.withAlpha(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: AppColors.templeGoldDark,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.templeGoldDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenPhotoViewer extends StatelessWidget {
  const _FullscreenPhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _TenureDates extends StatelessWidget {
  const _TenureDates({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime? start;
  final DateTime? end;

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final String value;
    if (start != null && end != null) {
      value = '${_fmt(start!)} → ${_fmt(end!)}';
    } else if (start != null) {
      value = '${_fmt(start!)} →';
    } else {
      value = '→ ${_fmt(end!)}';
    }
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: AppColors.warmGrey,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.warmGrey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    );
  }
}
