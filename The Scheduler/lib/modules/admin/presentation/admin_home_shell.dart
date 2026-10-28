import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_providers.dart';
import 'admin_dashboard_page.dart';
import 'admin_schedule_page.dart';
import 'admin_settings_page.dart';
import 'admin_team_page.dart';

/// Admin home shell with bottom navigation.
///
/// Provides mobile-optimized view for Admins/Owners who created their
/// accounts on the web. This is NOT a duplicate of web admin - it's for
/// on-the-go oversight.
///
/// Navigation:
/// - Home: Dashboard with business health and pending actions
/// - Schedule: All providers' appointments with filters
/// - Team: Team status, pending approvals, quick actions
/// - Settings: Account, business settings, emergency actions
///
/// HIPAA: Contains PHI in various tabs - all access is audit logged
/// via repository operations.
class AdminHomeShell extends ConsumerStatefulWidget {
  const AdminHomeShell({super.key});

  @override
  ConsumerState<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends ConsumerState<AdminHomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    AdminDashboardPage(),
    AdminSchedulePage(),
    AdminTeamPage(),
    AdminSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(adminPendingActionsCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.groups),
            ),
            label: 'Team',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
