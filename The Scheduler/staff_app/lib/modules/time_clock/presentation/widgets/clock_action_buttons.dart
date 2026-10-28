import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/clock_state.dart';
import '../../providers/time_clock_providers.dart';
import 'clock_out_dialog.dart';

/// Action buttons for clock in/out and break management.
///
/// Renders appropriate buttons based on current clock state:
/// - Not clocked in: "Clock In" button
/// - Clocked in, not on break: "Meal Break", "Rest Break", "Clock Out" buttons
/// - On break: "End Break" button
class ClockActionButtons extends ConsumerWidget {
  const ClockActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockState = ref.watch(clockStateProvider);
    final actionState = ref.watch(timeClockActionsProvider);

    return clockState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(context, error.toString()),
      data: (state) => _buildButtons(context, ref, state, actionState),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading clock state',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    ClockState state,
    TimeClockActionState actionState,
  ) {
    if (!state.isClockedIn) {
      return _ClockInButton(isLoading: actionState.isLoading);
    }

    if (state.isOnBreak) {
      return _EndBreakButton(
        isLoading: actionState.isLoading,
        breakType: state.currentBreakType,
      );
    }

    return _ClockedInButtons(
      isLoading: actionState.isLoading,
      clockInTime: state.clockInTime!,
      totalBreakMinutes: state.totalBreakMinutes,
    );
  }
}

class _ClockInButton extends ConsumerWidget {
  const _ClockInButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: isLoading
              ? null
              : () => ref.read(timeClockActionsProvider.notifier).clockIn(),
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.login, size: 28),
          label: Text(
            isLoading ? 'Clocking In...' : 'Clock In',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EndBreakButton extends ConsumerWidget {
  const _EndBreakButton({
    required this.isLoading,
    this.breakType,
  });

  final bool isLoading;
  final String? breakType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final breakLabel = breakType == 'meal' ? 'Meal Break' : 'Rest Break';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Break type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  breakType == 'meal' ? Icons.restaurant : Icons.coffee,
                  size: 18,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'On $breakLabel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // End break button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(timeClockActionsProvider.notifier).endBreak(),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
              ),
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onTertiary,
                      ),
                    )
                  : const Icon(Icons.stop_circle_outlined),
              label: Text(isLoading ? 'Ending Break...' : 'End Break'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockedInButtons extends ConsumerWidget {
  const _ClockedInButtons({
    required this.isLoading,
    required this.clockInTime,
    required this.totalBreakMinutes,
  });

  final bool isLoading;
  final DateTime clockInTime;
  final int totalBreakMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Break buttons row
          Row(
            children: [
              Expanded(
                child: _BreakButton(
                  label: 'Meal Break',
                  icon: Icons.restaurant,
                  type: BreakType.meal,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BreakButton(
                  label: 'Rest Break',
                  icon: Icons.coffee,
                  type: BreakType.rest,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clock out button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: isLoading ? null : () => _showClockOutDialog(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onError,
                      ),
                    )
                  : Icon(Icons.logout, color: theme.colorScheme.onError),
              label: Text(
                isLoading ? 'Clocking Out...' : 'Clock Out',
                style: TextStyle(color: theme.colorScheme.onError),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClockOutDialog(BuildContext context, WidgetRef ref) async {
    final notes = await ClockOutDialog.show(
      context,
      clockInTime: clockInTime,
      totalBreakMinutes: totalBreakMinutes,
    );

    // If user confirmed (notes is not null)
    if (notes != null && context.mounted) {
      await ref.read(timeClockActionsProvider.notifier).clockOut(
            notes: notes.isEmpty ? null : notes,
          );
    }
  }
}

class _BreakButton extends ConsumerWidget {
  const _BreakButton({
    required this.label,
    required this.icon,
    required this.type,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final BreakType type;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () => ref.read(timeClockActionsProvider.notifier).startBreak(type),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

/// Shows feedback snackbar for clock action results.
///
/// Call this in the widget that uses ClockActionButtons
/// to display success/error messages.
void showClockActionFeedback(BuildContext context, TimeClockActionState state) {
  if (state.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.errorMessage!),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else if (state.hasSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.successMessage!),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
