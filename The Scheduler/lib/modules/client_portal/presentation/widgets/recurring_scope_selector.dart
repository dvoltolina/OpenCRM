// ignore_for_file: deprecated_member_use
// RadioListTile still requires groupValue/onChanged until Flutter provides
// a stable RadioGroup.of pattern. Will update when alternative is available.
import 'package:flutter/material.dart' hide RadioGroup;

import '../../../../core/ui/components/components.dart';
import '../reschedule_appointment_page.dart';
import 'radio_group.dart';

/// Selector for choosing reschedule scope for recurring appointments
class RecurringScopeSelector extends StatelessWidget {
  const RecurringScopeSelector({
    required this.recurringScope,
    required this.onChanged,
    super.key,
  });

  final RecurringRescheduleScope? recurringScope;
  final ValueChanged<RecurringRescheduleScope?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: theme.colorScheme.primary,
                size: AppIconSize.sm,
              ),
              HSpace.xs,
              Text(
                'Recurring Appointment',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          VSpace.sm,
          Text(
            'This appointment is part of a recurring series. What would you like to reschedule?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          VSpace.sm,
          RadioGroup<RecurringRescheduleScope>(
            groupValue: recurringScope ?? RecurringRescheduleScope.thisOnly,
            onChanged: onChanged,
            child: Column(
              children: [
                RadioListTile<RecurringRescheduleScope>(
                  title: const Text('Reschedule just this appointment'),
                  subtitle: const Text('Other appointments in the series stay as scheduled'),
                  value: RecurringRescheduleScope.thisOnly,
                  groupValue: recurringScope ?? RecurringRescheduleScope.thisOnly,
                  onChanged: onChanged,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<RecurringRescheduleScope>(
                  title: const Text('Reschedule all future appointments'),
                  subtitle: const Text('All remaining appointments shift to the new time'),
                  value: RecurringRescheduleScope.allFuture,
                  groupValue: recurringScope ?? RecurringRescheduleScope.thisOnly,
                  onChanged: onChanged,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
