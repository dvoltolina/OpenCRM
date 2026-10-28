import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/timesheet_providers.dart';

/// Widget for navigating between pay periods.
///
/// Shows previous/next arrows with current period date range,
/// and a "Today" button to jump to the current period.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);
    final navigation = ref.watch(payPeriodNavigationProvider.notifier);
    final isCurrentPeriod = navigation.isCurrentPeriod;

    final dateFormat = DateFormat.MMMd();
    final periodLabel = '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous period button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              tooltip: 'Previous period',
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(payPeriodNavigationProvider.notifier).goToPreviousPeriod();
                ref.read(selectedPayPeriodStartProvider.notifier).state =
                    ref.read(payPeriodNavigationProvider);
              },
            ),
          ),

          // Period label
          Flexible(
            child: InkWell(
              onTap: () => _showPeriodPicker(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      periodLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCurrentPeriod)
                      Text(
                        'Tap to select',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Next period button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: 'Next period',
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(payPeriodNavigationProvider.notifier).goToNextPeriod();
                ref.read(selectedPayPeriodStartProvider.notifier).state =
                    ref.read(payPeriodNavigationProvider);
              },
            ),
          ),

          // Today button (only show if not on current period)
          if (!isCurrentPeriod) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: 32,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: theme.textTheme.bodySmall,
                ),
                onPressed: () {
                  ref.read(payPeriodNavigationProvider.notifier).goToCurrentPeriod();
                  ref.read(selectedPayPeriodStartProvider.notifier).state =
                      ref.read(payPeriodNavigationProvider);
                },
                child: const Text('Today'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPeriodPicker(BuildContext context, WidgetRef ref) async {
    final currentStart = ref.read(selectedPayPeriodStartProvider);

    final selected = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a date in the period',
    );

    if (selected != null) {
      ref.read(payPeriodNavigationProvider.notifier).goToDate(selected);
      ref.read(selectedPayPeriodStartProvider.notifier).state =
          ref.read(payPeriodNavigationProvider);
    }
  }
}

/// Compact version of period selector for app bars.
class CompactPeriodSelector extends ConsumerWidget {
  const CompactPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);

    final dateFormat = DateFormat.MMMd();
    final periodLabel = '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous',
          onPressed: () {
            ref.read(payPeriodNavigationProvider.notifier).goToPreviousPeriod();
            ref.read(selectedPayPeriodStartProvider.notifier).state =
                ref.read(payPeriodNavigationProvider);
          },
        ),
        Text(
          periodLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next',
          onPressed: () {
            ref.read(payPeriodNavigationProvider.notifier).goToNextPeriod();
            ref.read(selectedPayPeriodStartProvider.notifier).state =
                ref.read(payPeriodNavigationProvider);
          },
        ),
      ],
    );
  }
}
