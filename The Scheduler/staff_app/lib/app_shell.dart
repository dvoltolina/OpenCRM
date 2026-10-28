import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/sync_providers.dart';
import 'modules/schedule/presentation/today_schedule_page.dart';
import 'modules/schedule/presentation/week_schedule_page.dart';
import 'modules/time_clock/presentation/time_clock_page.dart';
import 'modules/time_clock/providers/time_clock_providers.dart';
import 'modules/settings/presentation/settings_page.dart';

/// Main app shell with bottom navigation.
///
/// Provides navigation between the main sections of the staff app:
/// - Today: Today's schedule view
/// - Week: Weekly schedule view
/// - Time Clock: Clock in/out functionality
/// - Settings: App settings and profile
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  // Cache pages to preserve state when switching tabs
  final List<Widget> _pages = const [
    TodaySchedulePage(),
    WeekSchedulePage(),
    TimeClockPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final clockStateAsync = ref.watch(clockStateProvider);

    // Determine if we should show badges
    final hasPendingSync = syncState.hasPendingSync;
    final isNotClockedIn = clockStateAsync.when(
      data: (state) => !state.isClockedIn,
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: isNotClockedIn,
              smallSize: 8,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.access_time_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: isNotClockedIn,
              smallSize: 8,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.access_time_filled),
            ),
            label: 'Time Clock',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasPendingSync,
              label: Text(
                '${syncState.pendingCount}',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.settings_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasPendingSync,
              label: Text(
                '${syncState.pendingCount}',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.settings),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
