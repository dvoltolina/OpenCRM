import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/sync_providers.dart';
import '../providers/schedule_providers.dart';
import 'widgets/appointment_card.dart';
import 'widgets/clock_in_banner.dart';
import 'widgets/status_widgets.dart';
import '../../appointment/presentation/appointment_detail_page.dart';
import 'week_schedule_page.dart';
import '../../time_clock/presentation/time_clock_page.dart';
import '../../settings/presentation/settings_page.dart';

/// Main page showing today's schedule for staff.
///
/// Features:
/// - Current date display
/// - Sync status indicator
/// - Offline mode banner
/// - Clock-in reminder banner
/// - Chronological appointment list
/// - Pull-to-refresh
/// - Empty state
class TodaySchedulePage extends ConsumerStatefulWidget {
  const TodaySchedulePage({super.key});

  @override
  ConsumerState<TodaySchedulePage> createState() => _TodaySchedulePageState();
}

class _TodaySchedulePageState extends ConsumerState<TodaySchedulePage> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline banner (shows only when offline)
          const OfflineBanner(),
          // Sync error banner (shows only when sync error)
          const SyncErrorBanner(),
          // Main content
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Time Clock',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedNavIndex) {
      case 0:
        return const _TodayView();
      case 1:
        return const WeekSchedulePage();
      case 2:
        return const TimeClockPage();
      case 3:
        return const SettingsPage();
      default:
        return const _TodayView();
    }
  }
}

/// The actual Today view content.
class _TodayView extends ConsumerWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today'),
            Text(
              _formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: const [
          // Clock status indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ClockStatusIndicator(),
          ),
          // Sync status with tap to sync
          TappableSyncIndicator(),
        ],
      ),
      body: Column(
        children: [
          // Clock-in banner (shows only when not clocked in)
          ClockInBanner(
            onClockIn: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimeClockPage()),
              );
            },
          ),
          // Appointments list
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return _EmptyState();
                }
                return _AppointmentsList(appointments: appointments);
              },
              loading: () => const _LoadingState(),
              error: (error, stack) => _ErrorState(error: error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

/// List of appointment cards with pull-to-refresh.
class _AppointmentsList extends ConsumerWidget {
  const _AppointmentsList({required this.appointments});

  final List<dynamic> appointments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        final forceSync = ref.read(forceSyncProvider);
        await forceSync();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary header
          SliverToBoxAdapter(
            child: _ScheduleSummary(appointmentCount: appointments.length),
          ),
          // Appointment list
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCard(
                    appointment: appointment,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailPage(
                              appointmentId: appointment.id),
                        ),
                      );
                    },
                  );
                },
                childCount: appointments.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary header showing appointment count and stats.
class _ScheduleSummary extends ConsumerWidget {
  const _ScheduleSummary({required this.appointmentCount});

  final int appointmentCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completed = ref.watch(completedAppointmentsTodayProvider);
    final current = ref.watch(currentAppointmentProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Appointment count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$appointmentCount',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  appointmentCount == 1 ? 'Appointment' : 'Appointments',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Completed count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$completed',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Completed',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remaining count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${appointmentCount - completed}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        current != null ? Colors.orange : colorScheme.primary,
                  ),
                ),
                Text(
                  'Remaining',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no appointments for today.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No appointments today',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free day! Check the week view for upcoming appointments.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state while fetching appointments.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading appointments...'),
        ],
      ),
    );
  }
}

/// Error state when appointments fail to load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load appointments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
