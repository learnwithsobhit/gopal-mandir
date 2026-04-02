import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../l10n/locale_scope.dart';
import '../l10n/app_language.dart';
import 'admin_shell.dart';
import 'bookings_screen.dart';
import 'membership_screen.dart';
import 'rate_us_screen.dart';
import 'settings_screen.dart';
import 'volunteer_screen.dart';
import 'pooja_appointment_screen.dart';
import 'about_temple_screen.dart';
import '../widgets/vrindavan_background.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final ApiService _api = ApiService();
  TempleInfo? _info;

  // Share link used across platforms (web + mobile fallback).
  static const String _shareUrl = 'https://gopal-mandir-app.web.app/';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getTempleInfo();
    if (mounted) setState(() => _info = data);
  }

  Future<void> _openMapsUrl(BuildContext context) async {
    final info = _info;
    final s = AppLocaleScope.of(context).strings;
    final url = info?.mapsUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.viewOnMap),
          backgroundColor: AppColors.krishnaBlue,
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.viewOnMap),
          backgroundColor: AppColors.krishnaBlue,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _buildShareText(AppStrings s) {
    // Keep it simple and localized: message + link on a new line.
    return '${s.shareAppSub}\n$_shareUrl';
  }

  Future<void> _launchShareUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      final s = AppLocaleScope.of(context).strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.shareLinkOpenError),
          backgroundColor: AppColors.krishnaBlue,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyShareLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _shareUrl));
    if (!mounted) return;
    final s = AppLocaleScope.of(context).strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.shareLinkCopied),
        backgroundColor: AppColors.krishnaBlue,
      ),
    );
  }

  Future<void> _shareApp() async {
    final s = AppLocaleScope.of(context).strings;
    final shareText = _buildShareText(s);

    // Pre-built endpoints so each platform receives the right payload.
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
    final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_shareUrl)}';
    final xUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
    final telegramUrl =
        'https://t.me/share/url?url=${Uri.encodeComponent(_shareUrl)}&text=${Uri.encodeComponent(shareText)}';

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetS = AppLocaleScope.of(sheetContext).strings;
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.message),
                title: Text(sheetS.shareWhatsAppLabel),
                subtitle: Text(sheetS.shareWhatsAppSub),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _launchShareUrl(context, whatsappUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(sheetS.shareFacebookLabel),
                subtitle: Text(sheetS.shareFacebookSub),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _launchShareUrl(context, facebookUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(sheetS.shareXLabel),
                subtitle: Text(sheetS.shareXSub),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _launchShareUrl(context, xUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: Text(sheetS.shareTelegramLabel),
                subtitle: Text(sheetS.shareTelegramSub),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _launchShareUrl(context, telegramUrl);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(sheetS.shareCopyLinkLabel),
                subtitle: Text(sheetS.shareCopyLinkSub),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _copyShareLink(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.more)),
      body: ListView(
        padding: AppSpacing.screenInsets,
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
          _menuItem(
            context,
            Icons.event_available,
            s.poojaMenuTitle,
            s.poojaMenuSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: PoojaAppointmentScreen()),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.info_outline,
            s.aboutTemple,
            s.aboutTempleSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const VrindavanBackground(child: AboutTempleScreen()),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.location_on,
            s.locationMap,
            _info?.address ?? s.viewOnMap,
            onTap: () => _openMapsUrl(context),
          ),
          _menuItem(context, Icons.phone, s.contactUs, _info?.phone ?? s.callTempleOffice),
          _menuItem(context, Icons.email, s.email, _info?.email ?? s.emailSub),
          _menuItem(
            context,
            Icons.people,
            s.volunteer,
            s.volunteerSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: VolunteerScreen()),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.card_membership,
            s.membership,
            s.membershipSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: MembershipScreen()),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.admin_panel_settings,
            'Temple staff',
            'Gallery, live darshan, prasad orders (authorized phones only)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VrindavanBackground(child: AdminShell()),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.share,
            s.shareApp,
            s.shareAppSub,
            onTap: _shareApp,
          ),
          _menuItem(
            context,
            Icons.star,
            s.rateUs,
            s.rateUsSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RateUsScreen(),
                ),
              );
            },
          ),
          _menuItem(
            context,
            Icons.settings,
            s.settings,
            s.settingsSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
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
