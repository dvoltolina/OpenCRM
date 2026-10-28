import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/state_widgets.dart';
import '../providers/week_providers.dart';
import 'widgets/day_section.dart';
import 'widgets/week_navigation.dart';

/// Week schedule view showing appointments grouped by day.
class WeekSchedulePage extends ConsumerWidget {
  const WeekSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);
    final grouped = ref.watch(weekAppointmentsProvider);
    final earliest = startOfWeek(DateTime.now());
    final latest = startOfWeek(DateTime.now().add(const Duration(days: 7)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Week'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WeekNavigation(
              weekStart: weekStart,
              canGoPrevious: weekStart.isAfter(earliest),
              canGoNext: weekStart.isBefore(latest),
              onPrevious: () => ref.read(selectedWeekProvider.notifier).state =
                  weekStart.subtract(const Duration(days: 7)),
              onNext: () => ref.read(selectedWeekProvider.notifier).state =
                  weekStart.add(const Duration(days: 7)),
              onToday: () => ref.read(selectedWeekProvider.notifier).state =
                  startOfWeek(DateTime.now()),
            ),
          ),
        ),
      ),
      body: grouped.when(
        data: (byDay) {
          if (byDay.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.calendar_month_outlined,
              title: 'No appointments this week',
              subtitle: 'Your schedule is clear for this week',
            );
          }
          final days = byDay.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final items = byDay[day] ?? [];
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              return DaySection(
                date: day,
                appointments: items,
                isToday: isToday,
              );
            },
          );
        },
        loading: () => const LoadingStateWidget(
          message: 'Loading schedule...',
        ),
        error: (err, _) => ErrorStateWidget(
          error: err,
          message: 'Failed to load week schedule',
          onRetry: () {
            // Force refresh by updating the selected week
            ref.invalidate(weekAppointmentsProvider);
          },
        ),
      ),
    );
  }
}

// Using reusable state widgets instead of custom implementations
