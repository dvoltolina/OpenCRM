import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/front_desk_app_bar.dart';
import 'panels/schedule_panel.dart';
import 'panels/arrivals_panel.dart';
import 'panels/waitlist_panel.dart';

/// Front Desk Home Shell - Main view for front desk staff at stationary businesses.
///
/// Features:
/// - Wide layout (tablet): Side-by-side schedule and actions panels
/// - Narrow layout (phone): Tabbed interface (Schedule | Check-In | Waitlist)
/// - Real-time updates for appointments, arrivals, and waitlist
/// - Quick check-in and walk-in booking workflows
///
/// HIPAA Compliance:
/// - All operations use SecurityContext
/// - PHI displayed on screen (consider screen privacy in waiting areas)
/// - Check-ins are audit logged
class FrontDeskHomeShell extends ConsumerStatefulWidget {
  const FrontDeskHomeShell({super.key});

  @override
  ConsumerState<FrontDeskHomeShell> createState() =>
      _FrontDeskHomeShellState();
}

class _FrontDeskHomeShellState extends ConsumerState<FrontDeskHomeShell> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const FrontDeskAppBar(),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  /// Wide layout for tablets/desktops with side-by-side panels.
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left panel: Schedule
        Expanded(
          flex: 3,
          child: Card(
            margin: const EdgeInsets.all(8),
            child: const SchedulePanel(),
          ),
        ),
        // Right panel: Actions (Arrivals + Waitlist)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: const ArrivalsPanel(),
                ),
              ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: const WaitlistPanel(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Narrow layout for phones with tabbed interface.
  Widget _buildNarrowLayout() {
    final tabs = [
      const SchedulePanel(),
      const ArrivalsPanel(),
      const WaitlistPanel(),
    ];

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildTab(0, Icons.calendar_today, 'Schedule'),
              _buildTab(1, Icons.login, 'Check-In'),
              _buildTab(2, Icons.people, 'Waitlist'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: IndexedStack(
            index: _currentTabIndex,
            children: tabs,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
