import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../providers/time_clock_providers.dart';

/// Widget for clock in/out and break management.
///
/// Displays current status and provides buttons for:
/// - Clock In / Clock Out
/// - Start/End Meal Break
/// - Start/End Rest Break
class TimeClockWidget extends ConsumerStatefulWidget {
  const TimeClockWidget({
    super.key,
    required this.securityContext,
    this.onClockIn,
    this.onClockOut,
    this.compact = false,
  });

  final SecurityContext securityContext;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;
  final bool compact;

  @override
  ConsumerState<TimeClockWidget> createState() => _TimeClockWidgetState();
}

class _TimeClockWidgetState extends ConsumerState<TimeClockWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Load active entry on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(timeClockNotifierProvider.notifier)
          .loadActiveEntry(widget.securityContext);
    });

    // Update elapsed time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timeClockNotifierProvider);
    final activeEntryAsync =
        ref.watch(activeTimeEntryProvider(widget.securityContext));

    // Use stream data if available, otherwise fall back to notifier state
    final activeEntry = activeEntryAsync.valueOrNull ?? state.activeEntry;

    if (widget.compact) {
      return _CompactTimeClock(
        activeEntry: activeEntry,
        isLoading: state.isLoading,
        onClockIn: () => _handleClockIn(context),
        onClockOut: () => _handleClockOut(context),
      );
    }

    return _FullTimeClock(
      activeEntry: activeEntry,
      state: state,
      onClockIn: () => _handleClockIn(context),
      onClockOut: () => _handleClockOut(context),
      onStartMealBreak: () => _handleStartMealBreak(context),
      onStartRestBreak: () => _handleStartRestBreak(context),
      onEndBreak: () => _handleEndBreak(context),
    );
  }

  Future<void> _handleClockIn(BuildContext context) async {
    // TODO: Get GPS location before clocking in
    await ref.read(timeClockNotifierProvider.notifier).clockIn(
          context: widget.securityContext,
        );

    final error = ref.read(timeClockNotifierProvider).error;
    if (error != null && context.mounted) {
      _showError(context, error);
    } else {
      widget.onClockIn?.call();
    }
  }

  Future<void> _handleClockOut(BuildContext context) async {
    // Confirm clock out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clock Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(timeClockNotifierProvider.notifier).clockOut(
          context: widget.securityContext,
        );

    final error = ref.read(timeClockNotifierProvider).error;
    if (error != null && context.mounted) {
      _showError(context, error);
    } else {
      widget.onClockOut?.call();
    }
  }

  Future<void> _handleStartMealBreak(BuildContext context) async {
    await ref
        .read(timeClockNotifierProvider.notifier)
        .startMealBreak(widget.securityContext);

    final error = ref.read(timeClockNotifierProvider).error;
    if (error != null && context.mounted) {
      _showError(context, error);
    }
  }

  Future<void> _handleStartRestBreak(BuildContext context) async {
    await ref
        .read(timeClockNotifierProvider.notifier)
        .startRestBreak(widget.securityContext);

    final error = ref.read(timeClockNotifierProvider).error;
    if (error != null && context.mounted) {
      _showError(context, error);
    }
  }

  Future<void> _handleEndBreak(BuildContext context) async {
    await ref
        .read(timeClockNotifierProvider.notifier)
        .endBreak(widget.securityContext);

    final error = ref.read(timeClockNotifierProvider).error;
    if (error != null && context.mounted) {
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ),
    );
    ref.read(timeClockNotifierProvider.notifier).clearError();
  }
}

/// Full time clock card with all options.
class _FullTimeClock extends StatelessWidget {
  const _FullTimeClock({
    required this.activeEntry,
    required this.state,
    required this.onClockIn,
    required this.onClockOut,
    required this.onStartMealBreak,
    required this.onStartRestBreak,
    required this.onEndBreak,
  });

  final TimeEntry? activeEntry;
  final TimeClockState state;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onStartMealBreak;
  final VoidCallback onStartRestBreak;
  final VoidCallback onEndBreak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isClockedIn = activeEntry != null;
    final isOnBreak = activeEntry?.isOnBreak ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isClockedIn ? Icons.timer : Icons.timer_off_outlined,
                  color: isClockedIn ? AppColors.success : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Time Clock',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _StatusBadge(
                  isClockedIn: isClockedIn,
                  isOnBreak: isOnBreak,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Time display
            if (isClockedIn) ...[
              _TimeDisplay(entry: activeEntry!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action buttons
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!isClockedIn)
              _ClockInButton(onPressed: onClockIn)
            else if (isOnBreak)
              _EndBreakButton(onPressed: onEndBreak)
            else
              _ClockedInActions(
                onClockOut: onClockOut,
                onStartMealBreak: onStartMealBreak,
                onStartRestBreak: onStartRestBreak,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact time clock for embedding in other screens.
class _CompactTimeClock extends StatelessWidget {
  const _CompactTimeClock({
    required this.activeEntry,
    required this.isLoading,
    required this.onClockIn,
    required this.onClockOut,
  });

  final TimeEntry? activeEntry;
  final bool isLoading;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    final isClockedIn = activeEntry != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isClockedIn
            ? AppColors.success.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isClockedIn ? AppColors.success : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClockedIn ? Icons.timer : Icons.timer_off_outlined,
            size: 18,
            color: isClockedIn ? AppColors.success : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          if (isClockedIn) ...[
            Text(
              _formatElapsed(activeEntry!.clockInTime),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: isClockedIn ? onClockOut : onClockIn,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isClockedIn ? 'Clock Out' : 'Clock In'),
            ),
        ],
      ),
    );
  }

  String _formatElapsed(DateTime clockInTime) {
    final elapsed = DateTime.now().difference(clockInTime);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

/// Status badge showing clocked in/out/break status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isClockedIn,
    required this.isOnBreak,
  });

  final bool isClockedIn;
  final bool isOnBreak;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (!isClockedIn) {
      label = 'Clocked Out';
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (isOnBreak) {
      label = 'On Break';
      color = AppColors.warning;
    } else {
      label = 'Clocked In';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Displays elapsed time and break info.
class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.entry});

  final TimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(entry.clockInTime);
    final breakMinutes = entry.calculatedBreakMinutes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          // Main elapsed time
          Text(
            _formatDuration(elapsed),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Clocked in at ${_formatTime(entry.clockInTime)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),

          // Break info
          if (breakMinutes > 0 || entry.isOnBreak) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: 16,
                  color: entry.isOnBreak ? AppColors.warning : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  entry.isOnBreak
                      ? 'On break (${_formatBreakElapsed(entry.breaks.last.startTime)})'
                      : 'Break time: ${breakMinutes}m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: entry.isOnBreak
                            ? AppColors.warning
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatBreakElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    return '${elapsed.inMinutes}m';
  }
}

/// Clock in button.
class _ClockInButton extends StatelessWidget {
  const _ClockInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.login),
      label: const Text('Clock In'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }
}

/// End break button.
class _EndBreakButton extends StatelessWidget {
  const _EndBreakButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow),
      label: const Text('End Break'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.warning,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }
}

/// Actions when clocked in (not on break).
class _ClockedInActions extends StatelessWidget {
  const _ClockedInActions({
    required this.onClockOut,
    required this.onStartMealBreak,
    required this.onStartRestBreak,
  });

  final VoidCallback onClockOut;
  final VoidCallback onStartMealBreak;
  final VoidCallback onStartRestBreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Break buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartMealBreak,
                icon: const Icon(Icons.restaurant, size: 18),
                label: const Text('Lunch'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartRestBreak,
                icon: const Icon(Icons.coffee, size: 18),
                label: const Text('Break'),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Clock out button
        FilledButton.icon(
          onPressed: onClockOut,
          icon: const Icon(Icons.logout),
          label: const Text('Clock Out'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}
