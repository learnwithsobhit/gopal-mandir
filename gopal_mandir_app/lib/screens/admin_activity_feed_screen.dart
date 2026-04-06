import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'admin_prasad_orders_screen.dart';
import 'admin_seva_bookings_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_event_donations_screen.dart';
import 'admin_members_screen.dart';
import 'admin_volunteers_screen.dart';
import 'admin_feedback_list_screen.dart';
import 'admin_event_participations_screen.dart';
import 'admin_pooja_bookings_screen.dart';

class AdminActivityFeedScreen extends StatefulWidget {
  const AdminActivityFeedScreen({super.key, required this.token});

  final String token;

  @override
  State<AdminActivityFeedScreen> createState() => _AdminActivityFeedScreenState();
}

class _AdminActivityFeedScreenState extends State<AdminActivityFeedScreen> {
  final ApiService _api = ApiService();
  List<AdminActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminGetActivityFeed(widget.token, limit: 50);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _relativeTime(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.isNegative || diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().add_jm().format(local);
  }

  (IconData, Color) _iconForKind(String kind) {
    switch (kind) {
      case 'prasad_order':
        return (Icons.restaurant_menu, AppColors.krishnaBlue);
      case 'seva_booking':
        return (Icons.book_online, AppColors.krishnaBlue);
      case 'donation':
        return (Icons.favorite, Colors.red.shade400);
      case 'event_donation':
        return (Icons.volunteer_activism, Colors.deepOrange.shade400);
      case 'membership':
        return (Icons.person_add_alt_1, Colors.teal.shade600);
      case 'volunteer_request':
        return (Icons.hail_rounded, Colors.indigo.shade400);
      case 'feedback':
        return (Icons.feedback_rounded, Colors.purple.shade400);
      case 'event_participation':
        return (Icons.event_seat, Colors.blueGrey.shade600);
      case 'pooja_booking':
        return (Icons.calendar_today, AppColors.krishnaBlue);
      default:
        return (Icons.notifications_none_rounded, AppColors.warmGrey);
    }
  }

  void _openForKind(BuildContext context, String kind) {
    final t = widget.token;
    Widget screen;
    switch (kind) {
      case 'prasad_order':
        screen = AdminPrasadOrdersScreen(token: t);
        break;
      case 'seva_booking':
        screen = AdminSevaBookingsScreen(token: t);
        break;
      case 'donation':
        screen = AdminDonationsScreen(token: t);
        break;
      case 'event_donation':
        screen = AdminEventDonationsScreen(token: t);
        break;
      case 'membership':
        screen = AdminMembersScreen(token: t);
        break;
      case 'volunteer_request':
        screen = AdminVolunteersScreen(token: t);
        break;
      case 'feedback':
        screen = AdminFeedbackListScreen(token: t);
        break;
      case 'event_participation':
        screen = AdminEventParticipationsScreen(token: t);
        break;
      case 'pooja_booking':
        screen = AdminPoojaBookingsScreen(token: t);
        break;
      default:
        return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent activity'),
      ),
      body: RefreshIndicator(
        color: AppColors.krishnaBlue,
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue)),
                ],
              )
            : _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                      const Icon(Icons.inbox_outlined, size: 56, color: AppColors.warmGrey),
                      const SizedBox(height: 16),
                      const Text(
                        'No recent activity in this window.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.warmGrey, fontSize: 15),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final (icon, color) = _iconForKind(item.kind);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha(36),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.warmGrey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _relativeTime(item.occurredAt),
                                style: TextStyle(fontSize: 11, color: AppColors.warmGrey.withAlpha(200)),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _openForKind(context, item.kind),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
