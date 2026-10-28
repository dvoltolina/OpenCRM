import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/local/staff_database.dart';

/// Provider for the active time entry (currently clocked in).
///
/// Returns null if not clocked in.
final activeTimeEntryProvider = StreamProvider<TimeEntriesTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;

  if (staffUser == null) {
    return Stream.value(null);
  }

  return db.timeEntriesDao.watchActiveTimeEntry(staffUser.providerId);
});

/// Provider for checking if currently clocked in.
final isClockedInProvider = Provider<bool>((ref) {
  final activeEntry = ref.watch(activeTimeEntryProvider).valueOrNull;
  return activeEntry != null;
});

/// Banner widget shown when staff is not clocked in.
///
/// Displays a warning with a button to navigate to time clock.
class ClockInBanner extends ConsumerStatefulWidget {
  const ClockInBanner({
    super.key,
    this.onClockIn,
  });

  /// Callback when Clock In button is pressed.
  /// If null, the button navigates to the Time Clock tab.
  final VoidCallback? onClockIn;

  @override
  ConsumerState<ClockInBanner> createState() => _ClockInBannerState();
}

class _ClockInBannerState extends ConsumerState<ClockInBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final isClockedIn = ref.watch(isClockedInProvider);

    // Reset dismissed state when clock status changes
    if (isClockedIn && _dismissed) {
      _dismissed = false;
    }

    if (isClockedIn || _dismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 24,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Not clocked in',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Clock in to start tracking your time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: widget.onClockIn,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade900,
              ),
              child: const Text('Clock In'),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: Colors.orange.shade700,
              ),
              onPressed: () => setState(() => _dismissed = true),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact clock status indicator for app bar.
///
/// Shows green icon when clocked in, orange when not.
class ClockStatusIndicator extends ConsumerWidget {
  const ClockStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEntry = ref.watch(activeTimeEntryProvider);

    return activeEntry.when(
      data: (entry) {
        if (entry != null) {
          // Clocked in - show duration
          final duration = DateTime.now().difference(entry.clockInTime);
          return Tooltip(
            message: 'Clocked in ${_formatDuration(duration)}',
            child: const Icon(
              Icons.timer,
              color: Colors.green,
              size: 20,
            ),
          );
        }
        // Not clocked in
        return const Tooltip(
          message: 'Not clocked in',
          child: Icon(
            Icons.timer_off,
            color: Colors.orange,
            size: 20,
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 20,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
