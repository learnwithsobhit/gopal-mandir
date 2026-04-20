import 'package:flutter/material.dart';

import '../l10n/locale_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/section_header.dart';
import '../widgets/vrindavan_background.dart';
import 'donate_screen.dart';
import 'pooja_appointment_screen.dart';
import 'prasad_screen.dart';
import 'seva_screen.dart';

/// Hub screen that groups the four devotional/commerce flows — donate,
/// prasad booking, seva, and pooja booking — under one entry point. The
/// actual forms, payment integration, and admin management remain inside
/// the original target screens; this widget is just a router.
///
/// The visual layout mirrors the redesigned home screen: a gentle
/// greeting banner + grouped section header + 2x2 [QuickActionButton]
/// grid with haptic + press animations.
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 8, AppSpacing.lg, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.templeGoldLight,
                      AppColors.sandalCream,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.templeGold.withAlpha(70),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_florist_outlined,
                        size: 26,
                        color: AppColors.templeGoldDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.sevaOfferingsIntro,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.darkBrown,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                title: s.sevaOfferingsChoose,
                icon: Icons.self_improvement_outlined,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                      color: AppColors.krishnaBlue,
                      onTap: () => _go(context, const SevaScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.event_available,
                      label: s.quickPoojaAppointment,
                      color: AppColors.templeGoldDark,
                      onTap: () =>
                          _go(context, const PoojaAppointmentScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
