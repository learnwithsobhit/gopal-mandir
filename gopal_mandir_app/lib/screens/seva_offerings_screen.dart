import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/vrindavan_background.dart';
import 'donate_screen.dart';
import 'pooja_appointment_screen.dart';
import 'prasad_screen.dart';
import 'seva_screen.dart';

/// Hub screen that groups the four devotional/commerce flows — donate,
/// prasad booking, seva, and pooja booking — under one entry point. The
/// actual forms, payment integration, and admin management remain inside
/// the original target screens; this widget is just a router.
class SevaOfferingsScreen extends StatelessWidget {
  const SevaOfferingsScreen({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.sevaAndOfferingsTitle),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: VrindavanBackground(
        showTopDecor: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                QuickActionButton(
                  icon: Icons.volunteer_activism,
                  label: s.quickDonate,
                  color: AppColors.peacockGreen,
                  onTap: () => _go(context, const DonateScreen()),
                ),
                QuickActionButton(
                  icon: Icons.card_giftcard,
                  label: s.quickBookPrasad,
                  color: AppColors.templeGoldDark,
                  onTap: () => _go(context, const PrasadScreen()),
                ),
                QuickActionButton(
                  icon: Icons.self_improvement,
                  label: s.quickSeva,
                  color: AppColors.peacockGreen,
                  onTap: () => _go(context, const SevaScreen()),
                ),
                QuickActionButton(
                  icon: Icons.event_available,
                  label: s.quickPoojaAppointment,
                  color: AppColors.templeGoldDark,
                  onTap: () => _go(context, const PoojaAppointmentScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
