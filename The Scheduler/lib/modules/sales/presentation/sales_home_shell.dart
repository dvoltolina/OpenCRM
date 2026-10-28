import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../time_clock/widgets/time_clock_widget.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/sales_providers.dart';
import 'sales_clients_page.dart';
import 'sales_settings_page.dart';
import 'sales_today_page.dart';

class SalesHomeShell extends ConsumerStatefulWidget {
  const SalesHomeShell({super.key});

  @override
  ConsumerState<SalesHomeShell> createState() => _SalesHomeShellState();
}

class _SalesHomeShellState extends ConsumerState<SalesHomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final showTimeClock = ref.watch(salesTimeClockEnabledProvider);
    final pages = <Widget>[
      const SalesTodayPage(),
      const SalesClientsPage(),
      if (showTimeClock) const _TimeClockTab(),
      const SalesSettingsPage(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
      const NavigationDestination(icon: Icon(Icons.people), label: 'Clients'),
      if (showTimeClock)
        const NavigationDestination(icon: Icon(Icons.timer), label: 'Clock'),
      const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = pages.length - 1;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations,
      ),
    );
  }
}

class _TimeClockTab extends ConsumerWidget {
  const _TimeClockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in required for time clock')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Time Clock')),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: TimeClockWidget(
          securityContext: securityContext,
        ),
      ),
    );
  }
}
