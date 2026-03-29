import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_controller.dart';
import '../l10n/locale_scope.dart';
import '../l10n/app_language.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    _themeMode = _settings.themeMode;
    _textScale = _settings.textScale;
    _language = _settings.language == 'en' ? AppLanguage.en : AppLanguage.hi;
    _notificationsEnabled = _settings.notificationsEnabled;
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

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _sectionHeader(s.settingsAppearance),
          _themeSelector(s, isDark),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _fontSizeSelector(s),
          const SizedBox(height: 8),

          _sectionHeader(s.settingsLanguage),
          _languageSelector(s),
          const SizedBox(height: 8),

          _sectionHeader(s.settingsNotifications),
          _notificationToggle(s),
          const SizedBox(height: 8),

          _sectionHeader(s.settingsLegal),
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
          const SizedBox(height: 8),

          _sectionHeader(s.settingsAbout),
          _infoRow(Icons.info_outline, '${s.settingsVersion}: 1.0.0'),
          _infoRow(Icons.business, '${s.settingsDeveloper}: Shri Gopal Mandir Trust'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.krishnaBlue,
        ),
      ),
    );
  }

  Widget _themeSelector(AppStrings s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 22, color: isDark ? AppColors.krishnaBlueLight : AppColors.krishnaBlue),
              const SizedBox(width: 12),
              Text(s.settingsTheme, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(s.settingsThemeLight, style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: ThemeMode.dark, label: Text(s.settingsThemeDark, style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: ThemeMode.system, label: Text(s.settingsThemeSystem, style: const TextStyle(fontSize: 12))),
              ],
              selected: {_themeMode},
              onSelectionChanged: (v) => _setThemeMode(v.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fontSizeSelector(AppStrings s) {
    const steps = [0.85, 1.0, 1.15, 1.3];

    String label(double v) {
      if (v == 0.85) return s.settingsFontSmall;
      if (v == 1.0) return s.settingsFontNormal;
      if (v == 1.15) return s.settingsFontLarge;
      return s.settingsFontExtraLarge;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(s.settingsFontSize, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<double>(
              segments: steps.map((v) => ButtonSegment(
                value: v,
                label: Text(label(v), style: const TextStyle(fontSize: 11)),
              )).toList(),
              selected: {_textScale},
              onSelectionChanged: (v) => _setTextScale(v.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageSelector(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.language, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.settingsLanguage, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedButton<AppLanguage>(
              segments: [
                ButtonSegment(value: AppLanguage.hi, label: Text(s.settingsLanguageHindi, style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: AppLanguage.en, label: Text(s.settingsLanguageEnglish, style: const TextStyle(fontSize: 12))),
              ],
              selected: {_language},
              onSelectionChanged: (v) => _setLanguage(v.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationToggle(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.notifications_outlined, size: 22, color: Theme.of(context).colorScheme.primary),
            title: Text(s.settingsNotifications, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            subtitle: Text(s.settingsNotificationsSub, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text(
              s.settingsNotificationsComingSoon,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableRow({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
      onTap: onTap,
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      title: Text(text, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
      dense: true,
    );
  }
}
