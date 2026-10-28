import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/timesheet_providers.dart';

/// Filter bar for filtering timesheets by status.
class TimesheetsFilterBar extends ConsumerWidget {
  const TimesheetsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFilter = ref.watch(timesheetFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in TimesheetFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.displayName),
                  selected: selectedFilter == filter,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(timesheetFilterProvider.notifier).state = filter;
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
