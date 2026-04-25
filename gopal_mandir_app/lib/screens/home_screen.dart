import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/home_preload_cache.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/darshan_banner.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';
import '../widgets/vrindavan_background.dart';
import 'aarti_screen.dart';
import 'about_temple_screen.dart';
import 'announcements_screen.dart';
import 'astro_consult_screen.dart';
import 'community_feed_screen.dart';
import 'daily_upasana_screen.dart';
import 'events_screen.dart';
import 'festivals_screen.dart';
import 'gallery_screen.dart';
import 'hindu_panchang_screen.dart';
import 'live_darshan_screen.dart';
import 'seva_offerings_screen.dart';
import 'successions_screen.dart';

/// Redesigned home screen. The top-to-bottom flow is now:
///
///   1. Slim app bar (unchanged)
///   2. Time-of-day hero greeting card
///   3. Live darshan banner
///   4. Grouped quick-action sections (Daily / Offerings / Community / …)
///   5. Featured announcements carousel
///   6. Horizontal upcoming-events rail
///   7. Daily shlok + SEO copy
///
/// Each section fades+slides in with a short stagger so the screen feels
/// alive on open. Quick-action tiles are the beefed-up [QuickActionButton]
/// (72x72 icon slab, haptic + scale feedback).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  DailyQuote? _quote;
  List<Announcement> _announcements = [];
  List<Event> _events = [];

  final PageController _announcementCtrl =
      PageController(viewportFraction: 0.92);
  Timer? _announcementTimer;
  int _announcementIndex = 0;

  @override
  void initState() {
    super.initState();
    final fresh = HomePreloadCache.instance.peekIfFresh();
    if (fresh != null) {
      _quote = fresh.quote;
      _announcements = fresh.announcements;
      _events = fresh.events;
    }
    _loadData();
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _announcementCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final quote = await _api.getDailyQuote();
    final announcements = await _api.getAnnouncements();
    List<Event> events = [];
    try {
      events = await _api.getEvents();
    } catch (_) {
      // Events screen shows error + retry; home shows empty section.
    }
    if (!mounted) return;
    setState(() {
      _quote = quote;
      _announcements = announcements;
      _events = events;
    });
    _scheduleAnnouncementAutoplay();
  }

  void _scheduleAnnouncementAutoplay() {
    _announcementTimer?.cancel();
    if (_announcements.length < 2) return;
    _announcementTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_announcementCtrl.hasClients) return;
      final next = (_announcementIndex + 1) % _announcements.length;
      _announcementCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
      );
    });
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VrindavanBackground(child: screen)),
    );
  }

  Future<void> _openSeoRoute(String path) async {
    final uri = Uri.parse('https://gopal-mandir-app.web.app$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _seoRouteChip(String label, String route) {
    return OutlinedButton(
      onPressed: () => _openSeoRoute(route),
      child: Text(label),
    );
  }

  Widget _langChip(BuildContext context, AppLocaleScope scope,
      AppLanguage lang, String label) {
    final isSelected = scope.language == lang;
    return Material(
      color: isSelected ? AppColors.templeGold.withAlpha(180) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => scope.onLanguageChanged(lang),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppLocaleScope.of(context);
    final s = scope.strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.krishnaBlue,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              title: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: ClipOval(
                      child: Image.asset(
                        'gopal_images/IMG_7120.JPG',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.28),
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s.templeName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _langChip(context, scope, AppLanguage.hi, s.langHindi),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.white54,
                            ),
                            _langChip(context, scope, AppLanguage.en, s.langEnglish),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () =>
                      _navigateTo(context, const AnnouncementsScreen()),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _staggered(0, _HeroGreeting(strings: s)),
                  _staggered(1, const DarshanBanner()),
                  _staggered(2, _buildDailyGroup(s)),
                  _staggered(3, _buildOfferingsGroup(s)),
                  _staggered(4, _buildCommunityGroup(s)),
                  _staggered(5, _buildEventsMediaGroup(s)),
                  _staggered(6, _buildTempleGroup(s)),
                  if (_announcements.isNotEmpty)
                    _staggered(7, _buildAnnouncementsCarousel(s)),
                  if (_events.isNotEmpty)
                    _staggered(8, _buildUpcomingEventsRail(s)),
                  if (_quote != null) _staggered(9, _buildDailyShlok(s)),
                  _staggered(10, _buildSeoCard(s)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Staggered entry animation ─────────────────────────────────────────

  /// Fade + slide-in for the section at [index]. A stateful wrapper
  /// kicks off the animation on first mount; stagger delay is 70 ms per
  /// index so ~10 sections settle in under 700 ms.
  Widget _staggered(int index, Widget child) {
    return _StaggeredEntry(
      delay: Duration(milliseconds: 70 * index),
      child: child,
    );
  }

  // ── Quick-action groups ───────────────────────────────────────────────

  Widget _buildDailyGroup(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.homeSectionDaily,
          icon: Icons.wb_sunny_outlined,
        ),
        _quickGrid([
          QuickActionButton(
            icon: Icons.remove_red_eye,
            label: s.quickDarshan,
            color: AppColors.krishnaBlue,
            onTap: () => _navigateTo(context, const LiveDarshanScreen()),
          ),
          QuickActionButton(
            icon: Icons.access_time_rounded,
            label: s.quickAartiTimings,
            color: AppColors.templeGold,
            onTap: () => _navigateTo(context, const AartiScreen()),
          ),
          QuickActionButton(
            icon: Icons.menu_book_rounded,
            label: s.quickDailyUpasana,
            color: AppColors.peacockGreen,
            onTap: () => _navigateTo(context, const DailyUpasanaScreen()),
          ),
          QuickActionButton(
            icon: Icons.calendar_month,
            label: s.quickPanchang,
            color: AppColors.krishnaBlueDark,
            onTap: () => _navigateTo(context, const HinduPanchangScreen()),
          ),
        ]),
      ],
    );
  }

  Widget _buildOfferingsGroup(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.homeSectionOfferings,
          icon: Icons.self_improvement_outlined,
        ),
        _quickGrid([
          QuickActionButton(
            icon: Icons.self_improvement,
            label: s.quickSevaAndOfferings,
            color: AppColors.templeGoldDark,
            onTap: () => _navigateTo(context, const SevaOfferingsScreen()),
          ),
        ]),
      ],
    );
  }

  Widget _buildCommunityGroup(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.homeSectionCommunity,
          icon: Icons.groups_outlined,
        ),
        _quickGrid([
          QuickActionButton(
            icon: Icons.auto_awesome,
            label: s.quickAskAstrologer,
            color: AppColors.krishnaBlue,
            onTap: () => _navigateTo(context, const AstroConsultScreen()),
          ),
          QuickActionButton(
            icon: Icons.forum,
            label: s.quickCommunityQA,
            color: AppColors.peacockGreen,
            onTap: () => _navigateTo(context, const CommunityFeedScreen()),
          ),
        ]),
      ],
    );
  }

  Widget _buildEventsMediaGroup(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.homeSectionEventsMedia,
          icon: Icons.event_available_outlined,
        ),
        _quickGrid([
          QuickActionButton(
            icon: Icons.event,
            label: s.quickEvents,
            color: AppColors.peacockGreen,
            onTap: () => _navigateTo(context, const EventsScreen()),
          ),
          QuickActionButton(
            icon: Icons.celebration,
            label: s.festivalsLabel,
            color: AppColors.templeGold,
            onTap: () => _navigateTo(context, const FestivalsScreen()),
          ),
          QuickActionButton(
            icon: Icons.photo_library,
            label: s.quickGallery,
            color: AppColors.krishnaBlue,
            onTap: () => _navigateTo(context, const GalleryScreen()),
          ),
        ]),
      ],
    );
  }

  Widget _buildTempleGroup(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.homeSectionTemple,
          icon: Icons.temple_hindu_outlined,
        ),
        _quickGrid([
          QuickActionButton(
            icon: Icons.info_outline,
            label: s.quickTempleInfo,
            color: AppColors.krishnaBlue,
            onTap: () => _navigateTo(context, const AboutTempleScreen()),
          ),
          QuickActionButton(
            icon: Icons.account_tree_outlined,
            label: s.quickSuccession,
            color: AppColors.templeGoldDark,
            onTap: () => _navigateTo(context, const SuccessionsScreen()),
          ),
        ]),
      ],
    );
  }

  /// Shared grid config for all quick-action groups. We use 4 columns on
  /// phones; the new tile is 72 px + label, so `childAspectRatio: 0.82`
  /// gives each tile just enough room at 1.15 text scale.
  Widget _quickGrid(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
        children: children,
      ),
    );
  }

  // ── Featured announcements carousel ───────────────────────────────────

  Widget _buildAnnouncementsCarousel(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.todayInTemple,
          icon: Icons.campaign_outlined,
          onViewAll: () =>
              _navigateTo(context, const AnnouncementsScreen()),
          viewAllLabel: s.homeViewAll,
        ),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _announcementCtrl,
            itemCount: _announcements.length,
            onPageChanged: (i) => setState(() => _announcementIndex = i),
            itemBuilder: (_, i) {
              final a = _announcements[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4),
                child: _AnnouncementCard(
                  announcement: a,
                  onTap: () =>
                      _navigateTo(context, const AnnouncementsScreen()),
                ),
              );
            },
          ),
        ),
        if (_announcements.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _announcements.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _announcementIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _announcementIndex
                      ? AppColors.templeGoldDark
                      : AppColors.templeGold.withAlpha(90),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Horizontal upcoming events rail ───────────────────────────────────

  Widget _buildUpcomingEventsRail(AppStrings s) {
    final featured = _events.where((e) => e.isFeatured).take(8).toList();
    final list = featured.isEmpty ? _events.take(8).toList() : featured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: s.upcomingEvents,
          icon: Icons.event_available_outlined,
          onViewAll: () => _navigateTo(context, const EventsScreen()),
          viewAllLabel: s.homeViewAll,
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _EventRailCard(
              event: list[i],
              onTap: () => _navigateTo(context, const EventsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Daily shlok + SEO (kept, wrapped in existing SectionCard) ─────────

  Widget _buildDailyShlok(AppStrings s) {
    return SectionCard(
      title: s.dailyShlok,
      accentColor: AppColors.krishnaBlue,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.krishnaBlue.withAlpha(10),
              AppColors.templeGold.withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.templeGold.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              _quote!.shlok,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _quote!.translation,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.warmGrey,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '— ${_quote!.source}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.templeGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeoCard(AppStrings s) {
    return SectionCard(
      title: s.seoHeading,
      accentColor: AppColors.templeGoldDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.seoIntro,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.darkBrown,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.seoMathuraTitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.seoMathuraBody,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.warmGrey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.seoLinksTitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _seoRouteChip(s.seoLinkMandir, '/gopal-mandir'),
              _seoRouteChip(s.seoLinkLaddu, '/laddu-gopal'),
              _seoRouteChip(s.seoLinkMathura, '/gopal-ji-mathura'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Private support widgets
// ─────────────────────────────────────────────────────────────────────────

/// Warm hero card at the top of the home screen. Shows a time-of-day
/// greeting ("Jai Shri Krishna" in the morning, "Radhe Radhe" after 5 pm)
/// over a templeGold → sandalCream gradient with a soft lotus glyph.
class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({required this.strings});

  final AppStrings strings;

  String _greeting() {
    final h = DateTime.now().hour;
    return (h >= 5 && h < 17) ? strings.greetMorning : strings.greetEvening;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.templeGoldLight,
            AppColors.sandalCream,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.templeGold.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.templeGold.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.templeGoldDark.withAlpha(90)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.brightness_7_outlined,
              size: 32,
              color: AppColors.templeGoldDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.greetSubtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: AppColors.warmGrey,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = announcement.isUrgent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.softWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(
                color: urgent ? AppColors.urgentRed : AppColors.krishnaBlue,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    urgent ? Icons.priority_high : Icons.campaign_outlined,
                    size: 18,
                    color: urgent
                        ? AppColors.urgentRed
                        : AppColors.krishnaBlueDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: AppColors.warmGrey,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventRailCard extends StatelessWidget {
  const _EventRailCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.softWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.peacockGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: AppColors.peacockGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                        event.date,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.warmGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with a one-shot fade + slide-in. Fires after [delay]
/// when the widget first appears on screen. Stateless after the first
/// build so subsequent setStates don't replay the animation.
class _StaggeredEntry extends StatefulWidget {
  const _StaggeredEntry({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
