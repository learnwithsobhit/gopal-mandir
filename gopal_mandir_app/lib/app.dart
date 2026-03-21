import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'l10n/app_language.dart';
import 'l10n/locale_scope.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_darshan_screen.dart';
import 'screens/more_screen.dart';
import 'screens/seva_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/vrindavan_background.dart';

class GopalMandirApp extends StatefulWidget {
  const GopalMandirApp({super.key});

  @override
  State<GopalMandirApp> createState() => GopalMandirAppState();
}

class GopalMandirAppState extends State<GopalMandirApp> {
  final SettingsService _settings = SettingsService();
  late AppLanguage _language;
  late ThemeMode _themeMode;
  late double _textScale;

  @override
  void initState() {
    super.initState();
    _language = _settings.language == 'en' ? AppLanguage.en : AppLanguage.hi;
    _themeMode = _settings.themeMode;
    _textScale = _settings.textScale;
  }

  void _onLanguageChanged(AppLanguage l) {
    setState(() => _language = l);
    _settings.setLanguage(l == AppLanguage.en ? 'en' : 'hi');
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _settings.setThemeMode(mode);
  }

  void updateTextScale(double scale) {
    setState(() => _textScale = scale);
    _settings.setTextScale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return AppController(
      updateThemeMode: updateThemeMode,
      updateTextScale: updateTextScale,
      child: AppLocaleScope(
        language: _language,
        onLanguageChanged: _onLanguageChanged,
        child: MaterialApp(
          title: 'Shri Gopal Mandir',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          builder: _textScale == 1.0
              ? null
              : (context, child) {
                  final mq = MediaQuery.maybeOf(context);
                  if (mq == null || child == null) {
                    return child ?? const SizedBox.shrink();
                  }
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaler: TextScaler.linear(_textScale),
                    ),
                    child: child,
                  );
                },
          home: const MainShell(),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _sevaKey = GlobalKey<SevaScreenState>();
  final _eventsKey = GlobalKey<EventsScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    SevaScreen(key: _sevaKey),
    const LiveDarshanScreen(),
    EventsScreen(key: _eventsKey),
    const MoreScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      _sevaKey.currentState?.refresh();
    } else if (index == 3) {
      _eventsKey.currentState?.refresh();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocaleScope.of(context).strings;
    return Scaffold(
      body: VrindavanBackground(
        showTopDecor: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.krishnaBlue.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: s.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.self_improvement_outlined),
              activeIcon: const Icon(Icons.self_improvement),
              label: s.navSeva,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.live_tv_outlined),
              activeIcon: const Icon(Icons.live_tv),
              label: s.navLive,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.event_outlined),
              activeIcon: const Icon(Icons.event),
              label: s.navEvents,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz_outlined),
              activeIcon: const Icon(Icons.more_horiz),
              label: s.navMore,
            ),
          ],
        ),
      ),
    );
  }
}
