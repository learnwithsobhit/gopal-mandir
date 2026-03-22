import 'package:flutter/material.dart';
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
import 'admin_events_list_screen.dart';
import 'admin_event_participations_screen.dart';
import 'admin_event_donations_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_aarti_list_screen.dart';
import 'admin_members_screen.dart';
import 'admin_volunteers_screen.dart';
import 'admin_feedback_list_screen.dart';
import 'admin_feedback_analytics_screen.dart';

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
        title: Text(_admin?.name.trim().isNotEmpty == true ? _admin!.name : 'Admin'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            Icons.photo_library,
            'Gallery',
            'Upload & manage images and videos',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminGalleryListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.live_tv,
            'Live Darshan',
            'Stream URL and on-air flag',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminLiveDarshanScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.restaurant_menu,
            'Prasad orders',
            'Filter and update order status',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPrasadOrdersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.calendar_month,
            'Panchang',
            'Add & edit daily Hindu Panchang',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPanchangListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism,
            'Seva Items',
            'Add, edit & remove seva offerings',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminSevaItemsListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.book_online,
            'Seva Bookings',
            'View & update seva booking status',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminSevaBookingsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.event,
            'Events',
            'Add, edit & remove temple events',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventsListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.group,
            'Event Participations',
            'View who joined each event',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventParticipationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism,
            'Event Donations',
            'View all event donations',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminEventDonationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.favorite,
            'General Donations',
            'Payment status, failures, and donor contact',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminDonationsScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.access_time_rounded,
            'Aarti Schedule',
            'Add, edit & remove aarti timings',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminAartiListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.people_rounded,
            'Members',
            'View & manage temple members',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminMembersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.volunteer_activism_rounded,
            'Volunteer Requests',
            'Review & manage volunteer applications',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminVolunteersScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.feedback_rounded,
            'Feedback Queue',
            'Triage and respond to user feedback',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminFeedbackListScreen(token: _token!),
              ),
            ),
          ),
          _tile(
            Icons.analytics_rounded,
            'Feedback Analytics',
            'Ratings, trends and closure metrics',
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
