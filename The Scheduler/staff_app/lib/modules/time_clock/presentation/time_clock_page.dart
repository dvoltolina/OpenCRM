import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/clock_state.dart';
import '../providers/time_clock_providers.dart';
import 'widgets/clock_action_buttons.dart';
import 'widgets/elapsed_time_counter.dart';
import 'widgets/todays_activity_list.dart';

/// Main time clock page for staff members.
///
/// Provides a complete interface for:
/// - Clocking in/out
/// - Starting/ending breaks (meal and rest)
/// - Viewing today's time entries
/// - Seeing elapsed time in real-time
///
/// All actions are performed offline-first and synced when connectivity is available.
class TimeClockPage extends ConsumerStatefulWidget {
  const TimeClockPage({super.key});

  @override
  ConsumerState<TimeClockPage> createState() => _TimeClockPageState();
}

class _TimeClockPageState extends ConsumerState<TimeClockPage> {
  @override
  void initState() {
    super.initState();
    // Listen for action feedback to show snackbars
    ref.listenManual(
      timeClockActionsProvider,
      (previous, next) {
        if (previous != null) {
          showClockActionFeedback(context, next);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Clock'),
        actions: [
          // Sync status indicator
          _SyncStatusIndicator(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Clock status display
              const _ClockStatusSection(),

              const Divider(),

              // Action buttons
              const ClockActionButtons(),

              const Divider(),

              // Today's activity list
              const TodaysActivityList(),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Invalidate providers to trigger refresh
    ref.invalidate(clockStateProvider);
    ref.invalidate(todaysEntriesProvider);
    // Small delay to show refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Displays the current clock status with elapsed time.
class _ClockStatusSection extends ConsumerWidget {
  const _ClockStatusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockState = ref.watch(clockStateProvider);

    return clockState.when(
      loading: () => const _StatusLoading(),
      error: (error, _) => _StatusError(error: error.toString()),
      data: (state) => _StatusDisplay(state: state),
    );
  }
}

class _StatusLoading extends StatelessWidget {
  const _StatusLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _StatusError extends StatelessWidget {
  const _StatusError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Error',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusDisplay extends StatelessWidget {
  const _StatusDisplay({required this.state});

  final ClockState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: state.isClockedIn
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  state.isOnBreak
                      ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.surface,
                ],
              )
            : null,
      ),
      child: Column(
        children: [
          // Status icon and label
          _StatusIndicator(state: state),
          const SizedBox(height: 16),

          // Elapsed time (if clocked in)
          if (state.isClockedIn && state.clockInTime != null) ...[
            if (state.isOnBreak && state.currentBreakStart != null)
              // Show break timer
              ElapsedTimeCounter(
                since: state.currentBreakStart!,
                onBreak: true,
                prefix: 'Break Time',
              )
            else
              // Show shift timer
              ElapsedTimeCounter(
                since: state.clockInTime!,
                prefix: 'Shift Time',
              ),
          ] else ...[
            // Not clocked in message
            Text(
              'Ready to start your shift?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.state});

  final ClockState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    String label;
    Color color;

    if (!state.isClockedIn) {
      icon = Icons.schedule;
      label = 'Not Clocked In';
      color = theme.colorScheme.outline;
    } else if (state.isOnBreak) {
      icon = state.currentBreakType == 'meal' ? Icons.restaurant : Icons.coffee;
      label = state.currentBreakType == 'meal' ? 'On Meal Break' : 'On Rest Break';
      color = theme.colorScheme.tertiary;
    } else {
      icon = Icons.timer;
      label = 'Clocked In';
      color = theme.colorScheme.primary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (state.isClockedIn && state.totalBreakMinutes > 0)
              Text(
                'Total breaks: ${_formatMinutes(state.totalBreakMinutes)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// Shows sync status in the app bar.
class _SyncStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return pendingSync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) {
          return IconButton(
            icon: const Icon(Icons.cloud_done),
            tooltip: 'All synced',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All time entries are synced'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        }

        return Badge(
          label: Text('$count'),
          child: IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: '$count entries pending sync',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count entries pending sync'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
