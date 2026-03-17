import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('अधिक'),
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
            Icons.receipt_long,
            'My Bookings',
            'View & manage prasad/seva bookings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: BookingsScreen()),
                ),
              );
            },
          ),
          _menuItem(Icons.info_outline, 'About Temple', 'History and information'),
          _menuItem(Icons.location_on, 'Location & Map', _info?.address ?? 'View on map'),
          _menuItem(Icons.phone, 'Contact Us', _info?.phone ?? 'Call temple office'),
          _menuItem(Icons.email, 'Email', _info?.email ?? 'Send message'),
          _menuItem(Icons.people, 'Volunteer', 'Join our sevak team'),
          _menuItem(Icons.card_membership, 'Membership', 'Become a member'),
          _menuItem(Icons.share, 'Share App', 'Spread the devotion'),
          _menuItem(Icons.star, 'Rate Us', 'Your feedback matters'),
          _menuItem(Icons.settings, 'Settings', 'App preferences'),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
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
              content: Text('$title — Coming soon! 🙏'),
              backgroundColor: AppColors.krishnaBlue,
            ),
          );
        },
      ),
    );
  }
}
