import 'package:flutter/material.dart';
import '../l10n/locale_scope.dart';
import '../services/api_service.dart';
import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import 'admin_login_screen.dart';
import 'admin_gallery_list_screen.dart';
import 'admin_live_darshan_screen.dart';
import 'admin_prasad_orders_screen.dart';
import 'admin_panchang_list_screen.dart';
import 'admin_seva_items_list_screen.dart';
import 'admin_seva_bookings_screen.dart';
import 'admin_pooja_offerings_screen.dart';
import 'admin_pooja_availability_screen.dart';
import 'admin_pooja_bookings_screen.dart';
import 'admin_events_list_screen.dart';
import 'admin_event_participations_screen.dart';
import 'admin_event_donations_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_aarti_list_screen.dart';
import 'admin_dainik_shlok_screen.dart';
import 'admin_temple_about_screen.dart';
import 'admin_daily_upasana_list_screen.dart';
import 'admin_members_screen.dart';
import 'admin_volunteers_screen.dart';
import 'admin_feedback_list_screen.dart';
import 'admin_feedback_analytics_screen.dart';
import 'admin_festivals_list_screen.dart';
import 'admin_activity_feed_screen.dart';
import 'admin_owner_access_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final ApiService _api = ApiService();
  String? _token;
  AdminProfile? _admin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final t = await AdminAuthService.readToken();
    if (t == null || t.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _token = null;
      });
      return;
    }
    final meResult = await _api.adminMeResult(t);
    if (!mounted) return;
    final me = meResult.admin;
    final statusCode = meResult.statusCode;
    final isUnauthorized = statusCode == 401 || statusCode == 403;
    if (me == null && isUnauthorized) {
      await AdminAuthService.deleteToken();
      setState(() {
        _loading = false;
        _token = null;
      });
      return;
    }
    setState(() {
      _token = t;
      _admin = me;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final t = _token;
    if (t != null) await _api.adminLogout(t);
    await AdminAuthService.deleteToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue)),
      );
    }
    if (_token == null) {
      return const AdminLoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_admin?.name.trim().isNotEmpty == true ? _admin!.name : s.adminHomeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: s.logoutLabel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_admin?.role == 'owner')
            _tile(
              Icons.admin_panel_settings_rounded,
              s.adminOwnerAccess,
              s.adminOwnerAccessSub,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AdminOwnerAccessScreen(token: _token!),
                ),
              ),
            ),
          _tile(
            Icons.notifications_active_rounded,
            s.adminRecentActivity,
            s.adminRecentActivitySub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminActivityFeedScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.photo_library,
            s.adminGallery,
            s.adminGallerySub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminGalleryListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.live_tv,
            s.adminLiveDarshan,
            s.adminLiveDarshanSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminLiveDarshanScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.restaurant_menu,
            s.adminPrasadOrders,
            s.adminPrasadOrdersSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPrasadOrdersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.calendar_month,
            s.adminPanchang,
            s.adminPanchangSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPanchangListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.celebration,
            s.adminFestivals,
            s.adminFestivalsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminFestivalsListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism,
            s.adminSevaItems,
            s.adminSevaItemsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminSevaItemsListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.book_online,
            s.adminSevaBookings,
            s.adminSevaBookingsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminSevaBookingsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.event_available,
            s.adminPoojaOfferings,
            s.adminPoojaOfferingsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPoojaOfferingsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.schedule,
            s.adminPoojaAvailability,
            s.adminPoojaAvailabilitySub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPoojaAvailabilityScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.calendar_today,
            s.adminPoojaBookings,
            s.adminPoojaBookingsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPoojaBookingsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.event,
            s.adminEvents,
            s.adminEventsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventsListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.group,
            s.adminEventParticipations,
            s.adminEventParticipationsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventParticipationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism,
            s.adminEventDonations,
            s.adminEventDonationsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventDonationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.favorite,
            s.adminGeneralDonations,
            s.adminGeneralDonationsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminDonationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.access_time_rounded,
            s.adminAartiSchedule,
            s.adminAartiScheduleSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminAartiListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.menu_book_rounded,
            s.adminDainikShlok,
            s.adminDainikShlokSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminDainikShlokScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.info_outline_rounded,
            s.adminAboutTemple,
            s.adminAboutTempleSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminTempleAboutScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.auto_stories_rounded,
            s.adminDailyUpasana,
            s.adminDailyUpasanaSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminDailyUpasanaListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.people_rounded,
            s.adminMembers,
            s.adminMembersSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminMembersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism_rounded,
            s.adminVolunteerRequests,
            s.adminVolunteerRequestsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminVolunteersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.feedback_rounded,
            s.adminFeedbackQueue,
            s.adminFeedbackQueueSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminFeedbackListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.analytics_rounded,
            s.adminFeedbackAnalytics,
            s.adminFeedbackAnalyticsSub,
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminFeedbackAnalyticsScreen(token: _token!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.krishnaBlue.withAlpha(24),
          child: Icon(icon, color: AppColors.krishnaBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: TextStyle(fontSize: 12, color: AppColors.warmGrey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
