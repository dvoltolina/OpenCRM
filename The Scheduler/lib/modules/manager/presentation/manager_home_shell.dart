import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/manager_providers.dart';
import 'manager_approvals_page.dart';
import 'manager_dashboard_page.dart';
import 'manager_settings_page.dart';
import 'manager_team_page.dart';

class ManagerHomeShell extends ConsumerStatefulWidget {
  const ManagerHomeShell({super.key});

  @override
  ConsumerState<ManagerHomeShell> createState() => _ManagerHomeShellState();
}

class _ManagerHomeShellState extends ConsumerState<ManagerHomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingApprovalsCountProvider);
    final pages = const [
      ManagerDashboardPage(),
      ManagerTeamPage(),
      ManagerApprovalsPage(),
      ManagerSettingsPage(),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = pages.length - 1;
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(icon: Icon(Icons.groups), label: 'Team'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.approval),
            ),
            label: 'Approvals',
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
