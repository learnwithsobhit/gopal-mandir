import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../l10n/locale_scope.dart';
import 'bookings_screen.dart';
import '../widgets/vrindavan_background.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final ApiService _api = ApiService();
  TempleInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getTempleInfo();
    if (mounted) setState(() => _info = data);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.more),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Temple info card
          if (_info != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.krishnaBlue, AppColors.krishnaBlueDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.temple_hindu, size: 48, color: AppColors.templeGold),
                  const SizedBox(height: 12),
                  Text(
                    _info!.name,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _info!.city,
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withAlpha(200)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_info!.openingTime} — ${_info!.closingTime}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.templeGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Menu items
          _menuItem(
            context,
            Icons.receipt_long,
            s.myBookings,
            s.myBookingsSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: BookingsScreen()),
                ),
              );
            },
          ),
          _menuItem(context, Icons.info_outline, s.aboutTemple, s.aboutTempleSub),
          _menuItem(context, Icons.location_on, s.locationMap, _info?.address ?? s.viewOnMap),
          _menuItem(context, Icons.phone, s.contactUs, _info?.phone ?? s.callTempleOffice),
          _menuItem(context, Icons.email, s.email, _info?.email ?? s.emailSub),
          _menuItem(context, Icons.people, s.volunteer, s.volunteerSub),
          _menuItem(context, Icons.card_membership, s.membership, s.membershipSub),
          _menuItem(context, Icons.share, s.shareApp, s.shareAppSub),
          _menuItem(context, Icons.star, s.rateUs, s.rateUsSub),
          _menuItem(context, Icons.settings, s.settings, s.settingsSub),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final s = AppLocaleScope.of(context).strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.krishnaBlue.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.krishnaBlue.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.krishnaBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.warmGrey),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warmGrey),
        onTap: () {
          if (onTap != null) return onTap();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title — ${s.comingSoon}'),
              backgroundColor: AppColors.krishnaBlue,
            ),
          );
        },
      ),
    );
  }
}
