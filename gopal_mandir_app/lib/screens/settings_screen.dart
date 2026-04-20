import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/locale_scope.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Refreshed settings screen. Each preference group now lives in a rounded
/// card with an icon-led header. The font-size row includes a live preview
/// that reflects the selected scale. A destructive "Reset to defaults"
/// button and an info row (shown only when persistence isn't available)
/// close the "settings don't stick" loop by telling the user what's going
/// on instead of silently dropping their choices.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  late ThemeMode _themeMode;
  late double _textScale;
  late AppLanguage _language;
  late bool _notificationsEnabled;

  static const _privacyUrl = 'https://gopal-mandir-app.web.app/privacy';
  static const _termsUrl = 'https://gopal-mandir-app.web.app/terms';

  @override
  void initState() {
    super.initState();
    _readFromSettings();
    _settings.ready.addListener(_onSettingsReady);
  }

  @override
  void dispose() {
    _settings.ready.removeListener(_onSettingsReady);
    super.dispose();
  }

  void _readFromSettings() {
    _themeMode = _settings.themeMode;
    _textScale = _settings.textScale;
    _language = _settings.language == 'en' ? AppLanguage.en : AppLanguage.hi;
    _notificationsEnabled = _settings.notificationsEnabled;
  }

  void _onSettingsReady() {
    if (!mounted) return;
    setState(_readFromSettings);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    AppController.maybeOf(context)?.updateThemeMode(mode);
  }

  void _setTextScale(double scale) {
    setState(() => _textScale = scale);
    AppController.maybeOf(context)?.updateTextScale(scale);
  }

  void _setLanguage(AppLanguage lang) {
    setState(() => _language = lang);
    AppLocaleScope.of(context).onLanguageChanged(lang);
  }

  void _setNotifications(bool v) {
    setState(() => _notificationsEnabled = v);
    _settings.setNotificationsEnabled(v);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _resetToDefaults() async {
    final controller = AppController.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final s = AppLocaleScope.of(context).strings;
    await controller?.resetToDefaults();
    if (!mounted) return;
    setState(_readFromSettings);
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.settingsResetDone),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final storageOk = _settings.isReady;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          if (!storageOk) _storageUnavailableBanner(s),
          _card(
            icon: Icons.palette_outlined,
            title: s.settingsAppearance,
            children: [
              _themeRow(s),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              _fontSizeRow(s),
            ],
          ),
          _card(
            icon: Icons.language,
            title: s.settingsLanguage,
            children: [_languageRow(s)],
          ),
          _card(
            icon: Icons.notifications_outlined,
            title: s.settingsNotifications,
            children: [_notificationToggle(s)],
          ),
          _card(
            icon: Icons.gavel_rounded,
            title: s.settingsLegal,
            children: [
              _tappableRow(
                icon: Icons.privacy_tip_outlined,
                title: s.settingsPrivacy,
                onTap: () => _openUrl(_privacyUrl),
              ),
              _tappableRow(
                icon: Icons.description_outlined,
                title: s.settingsTerms,
                onTap: () => _openUrl(_termsUrl),
              ),
            ],
          ),
          _card(
            icon: Icons.info_outline,
            title: s.settingsAbout,
            children: [
              _infoRow(Icons.tag, '${s.settingsVersion}: 1.0.0'),
              _infoRow(Icons.business,
                  '${s.settingsDeveloper}: Shri Gopal Mandir Trust'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
            child: OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restart_alt, color: AppColors.urgentRed),
              label: Text(
                s.settingsReset,
                style: const TextStyle(color: AppColors.urgentRed),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.urgentRed.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Building blocks ────────────────────────────────────────────────────

  Widget _storageUnavailableBanner(AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.urgentRed.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.urgentRed.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.urgentRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.settingsStorageUnavailable,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: AppColors.darkBrown,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.templeGold.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.templeGoldDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _themeRow(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.settingsTheme,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.warmGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _themeSwatch(
              mode: ThemeMode.light,
              label: s.settingsThemeLight,
              icon: Icons.light_mode_outlined,
            ),
            const SizedBox(width: 8),
            _themeSwatch(
              mode: ThemeMode.dark,
              label: s.settingsThemeDark,
              icon: Icons.dark_mode_outlined,
            ),
            const SizedBox(width: 8),
            _themeSwatch(
              mode: ThemeMode.system,
              label: s.settingsThemeSystem,
              icon: Icons.brightness_auto_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _themeSwatch({
    required ThemeMode mode,
    required String label,
    required IconData icon,
  }) {
    final selected = _themeMode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.krishnaBlue.withAlpha(24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.krishnaBlue
                  : AppColors.warmGrey.withAlpha(60),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? AppColors.krishnaBlue
                    : AppColors.warmGrey,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.krishnaBlueDark
                      : AppColors.darkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fontSizeRow(AppStrings s) {
    const steps = [0.85, 1.0, 1.15, 1.3];
    String label(double v) {
      if (v == 0.85) return s.settingsFontSmall;
      if (v == 1.0) return s.settingsFontNormal;
      if (v == 1.15) return s.settingsFontLarge;
      return s.settingsFontExtraLarge;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.settingsFontSize,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.warmGrey,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SegmentedButton<double>(
            segments: steps
                .map((v) => ButtonSegment(
                      value: v,
                      label: Text(label(v),
                          style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            selected: {_textScale},
            onSelectionChanged: (v) => _setTextScale(v.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sandalCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.templeGold.withAlpha(70)),
          ),
          // Wrapped in its own MediaQuery so the preview line accurately
          // reflects the chosen scale even before the top-level MaterialApp
          // rebuilds.
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScale),
            ),
            child: Text(
              s.settingsFontPreview,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.darkBrown,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _languageRow(AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: Text(
            s.settingsLanguage,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkBrown,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.hi,
                label: Text(s.settingsLanguageHindi,
                    style: const TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: AppLanguage.en,
                label: Text(s.settingsLanguageEnglish,
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_language},
            onSelectionChanged: (v) => _setLanguage(v.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationToggle(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            s.settingsNotifications,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkBrown,
            ),
          ),
          subtitle: Text(
            s.settingsNotificationsSub,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.warmGrey,
            ),
          ),
          value: _notificationsEnabled,
          onChanged: _setNotifications,
        ),
        Text(
          s.settingsNotificationsComingSoon,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: AppColors.warmGrey,
          ),
        ),
      ],
    );
  }

  Widget _tappableRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22, color: AppColors.krishnaBlue),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.darkBrown,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppColors.warmGrey),
      onTap: onTap,
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.warmGrey),
      title: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.darkBrown,
        ),
      ),
    );
  }
}
