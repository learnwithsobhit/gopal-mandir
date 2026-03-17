import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/vrindavan_background.dart';
import 'screens/home_screen.dart';
import 'screens/seva_screen.dart';
import 'screens/live_darshan_screen.dart';
import 'screens/events_screen.dart';
import 'screens/more_screen.dart';
import 'l10n/app_language.dart';
import 'l10n/locale_scope.dart';

void main() {
  runApp(const GopalMandirApp());
}

class GopalMandirApp extends StatefulWidget {
  const GopalMandirApp({super.key});

  @override
  State<GopalMandirApp> createState() => _GopalMandirAppState();
}

class _GopalMandirAppState extends State<GopalMandirApp> {
  AppLanguage _language = AppLanguage.hi;

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      language: _language,
      onLanguageChanged: (l) => setState(() => _language = l),
      child: MaterialApp(
        title: 'Shri Gopal Mandir',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShell(),
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

  final List<Widget> _screens = const [
    HomeScreen(),
    SevaScreen(),
    LiveDarshanScreen(),
    EventsScreen(),
    MoreScreen(),
  ];

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
          onTap: (index) => setState(() => _currentIndex = index),
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
