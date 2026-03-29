import 'package:flutter/material.dart';

import 'l10n/locale_scope.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_darshan_screen.dart';
import 'screens/more_screen.dart';
import 'screens/seva_screen.dart';
import 'widgets/vrindavan_background.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.self_improvement_outlined),
            selectedIcon: const Icon(Icons.self_improvement),
            label: s.navSeva,
          ),
          NavigationDestination(
            icon: const Icon(Icons.live_tv_outlined),
            selectedIcon: const Icon(Icons.live_tv),
            label: s.navLive,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: s.navEvents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: const Icon(Icons.more_horiz),
            label: s.navMore,
          ),
        ],
      ),
    );
  }
}
