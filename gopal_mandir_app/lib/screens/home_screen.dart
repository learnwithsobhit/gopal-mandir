import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/vrindavan_background.dart';
import '../widgets/darshan_banner.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/section_card.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import 'aarti_screen.dart';
import 'events_screen.dart';
import 'donate_screen.dart';
import 'prasad_screen.dart';
import 'seva_screen.dart';
import 'gallery_screen.dart';
import 'announcements_screen.dart';
import 'live_darshan_screen.dart';
import 'hindu_panchang_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final quote = await _api.getDailyQuote();
    final announcements = await _api.getAnnouncements();
    List<Event> events = [];
    try {
      events = await _api.getEvents();
    } catch (_) {
      // Events screen shows error + retry; home shows empty section
    }
    if (mounted) {
      setState(() {
        _quote = quote;
        _announcements = announcements;
        _events = events;
      });
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VrindavanBackground(child: screen)),
    );
  }

  Widget _langChip(BuildContext context, AppLocaleScope scope, AppLanguage lang, String label) {
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
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppColors.krishnaBlue,
              title: Row(
                children: [
                  Icon(Icons.temple_hindu, color: AppColors.templeGold, size: 24),
                  const SizedBox(width: 8),
                  Text(s.templeName),
                ],
              ),
              actions: [
                // Language toggle: हि | EN
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
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
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _navigateTo(context, const AnnouncementsScreen()),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Darshan Banner
                  const DarshanBanner(),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                      children: [
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
                          icon: Icons.volunteer_activism,
                          label: s.quickDonate,
                          color: AppColors.peacockGreen,
                          onTap: () => _navigateTo(context, const DonateScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.card_giftcard,
                          label: s.quickBookPrasad,
                          color: AppColors.templeGoldDark,
                          onTap: () => _navigateTo(context, const PrasadScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.event,
                          label: s.quickEvents,
                          color: AppColors.krishnaBlue,
                          onTap: () => _navigateTo(context, const EventsScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.self_improvement,
                          label: s.quickSeva,
                          color: AppColors.peacockGreen,
                          onTap: () => _navigateTo(context, const SevaScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.photo_library,
                          label: s.quickGallery,
                          color: AppColors.templeGold,
                          onTap: () => _navigateTo(context, const GalleryScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.live_tv,
                          label: s.quickLiveDarshan,
                          color: AppColors.urgentRed,
                          onTap: () => _navigateTo(context, const LiveDarshanScreen()),
                        ),
                        QuickActionButton(
                          icon: Icons.calendar_month,
                          label: s.quickPanchang,
                          color: AppColors.templeGoldDark,
                          onTap: () => _navigateTo(context, const HinduPanchangScreen()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Today in Mandir / Announcements
                  if (_announcements.isNotEmpty)
                    SectionCard(
                      title: s.todayInTemple,
                      accentColor: AppColors.templeGold,
                      onViewAll: () => _navigateTo(context, const AnnouncementsScreen()),
                      child: Column(
                        children: _announcements.take(2).map((a) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  a.isUrgent ? Icons.priority_high : Icons.info_outline,
                                  color: a.isUrgent ? AppColors.urgentRed : AppColors.krishnaBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.title,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        a.message,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.warmGrey,
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
                        }).toList(),
                      ),
                    ),

                  // Upcoming Events
                  if (_events.isNotEmpty)
                    SectionCard(
                      title: s.upcomingEvents,
                      accentColor: AppColors.peacockGreen,
                      onViewAll: () => _navigateTo(context, const EventsScreen()),
                      child: Column(
                        children: _events.where((e) => e.isFeatured).take(3).map((e) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.sandalCream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.peacockGreen.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.celebration, color: AppColors.peacockGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        e.date,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.warmGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warmGrey),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Daily Shlok
                  if (_quote != null)
                    SectionCard(
                      title: s.dailyShlok,
                      accentColor: AppColors.krishnaBlue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.krishnaBlue.withAlpha(10),
                                  AppColors.templeGold.withAlpha(10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.templeGold.withAlpha(40),
                              ),
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
                                  style: TextStyle(
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
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.templeGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
