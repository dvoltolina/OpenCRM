import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/timesheet_service.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/timesheet_summary.dart';

/// Provider for the selected pay period start date.
final selectedPayPeriodStartProvider = StateProvider<DateTime>((ref) {
  final service = ref.watch(timesheetServiceProvider);
  final period = service.getCurrentPayPeriod();
  return period.start;
});

/// Provider for the selected pay period end date.
final selectedPayPeriodEndProvider = Provider<DateTime>((ref) {
  final start = ref.watch(selectedPayPeriodStartProvider);
  final service = ref.watch(timesheetServiceProvider);
  final period = service.getPayPeriodForDate(start);
  return period.end;
});

/// Provider for pay period type selection.
final payPeriodTypeProvider = StateProvider<PayPeriodType>((ref) {
  return PayPeriodType.biweekly;
});

/// Provider for timesheet filter selection.
final timesheetFilterProvider = StateProvider<TimesheetFilter>((ref) {
  return TimesheetFilter.all;
});

/// Provider for search query.
final timesheetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for all staff timesheets in the selected period.
final timesheetSummariesProvider =
    FutureProvider.family<List<TimesheetSummary>, SecurityContext>(
  (ref, context) async {
    final service = ref.watch(timesheetServiceProvider);
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);

    return service.getAllStaffTimesheets(
      context: context,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  },
);

/// Provider for filtered timesheets based on selected filter.
final filteredTimesheetsProvider =
    Provider.family<AsyncValue<List<TimesheetSummary>>, SecurityContext>(
  (ref, context) {
    final timesheetsAsync = ref.watch(timesheetSummariesProvider(context));
    final filter = ref.watch(timesheetFilterProvider);
    final searchQuery = ref.watch(timesheetSearchQueryProvider).toLowerCase();

    return timesheetsAsync.whenData((timesheets) {
      var filtered = timesheets;

      // Apply status filter
      switch (filter) {
        case TimesheetFilter.all:
          break;
        case TimesheetFilter.pending:
          filtered = filtered
              .where((ts) => ts.status == TimesheetStatus.submitted)
              .toList();
        case TimesheetFilter.approved:
          filtered = filtered
              .where((ts) => ts.status == TimesheetStatus.approved)
              .toList();
        case TimesheetFilter.hasOvertime:
          filtered = filtered.where((ts) => ts.hasOvertime).toList();
        case TimesheetFilter.needsAttention:
          filtered =
              filtered.where((ts) => ts.hasRejectedEntries).toList();
      }

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((ts) {
          return ts.staffName.toLowerCase().contains(searchQuery) ||
              (ts.staffEmail?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }

      return filtered;
    });
  },
);

/// Provider for pay period statistics.
final payPeriodStatsProvider =
    FutureProvider.family<PayPeriodStats, SecurityContext>(
  (ref, context) async {
    final service = ref.watch(timesheetServiceProvider);
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);

    return service.getPayPeriodStats(
      context: context,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  },
);

/// Provider for a single staff member's timesheet.
final staffTimesheetProvider = FutureProvider.family<TimesheetSummary,
    ({SecurityContext context, String staffId})>(
  (ref, params) async {
    final service = ref.watch(timesheetServiceProvider);
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);

    return service.getStaffTimesheet(
      context: params.context,
      staffId: params.staffId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  },
);

/// Notifier for navigating pay periods.
class PayPeriodNavigationNotifier extends StateNotifier<DateTime> {
  PayPeriodNavigationNotifier(this._service)
      : super(_service.getCurrentPayPeriod().start);

  final TimesheetService _service;

  void goToPreviousPeriod() {
    final previousPeriod = _service.getPreviousPayPeriod(state);
    state = previousPeriod.start;
  }

  void goToNextPeriod() {
    final period = _service.getPayPeriodForDate(state);
    final nextPeriod = _service.getNextPayPeriod(period.end);
    state = nextPeriod.start;
  }

  void goToCurrentPeriod() {
    final currentPeriod = _service.getCurrentPayPeriod();
    state = currentPeriod.start;
  }

  void goToDate(DateTime date) {
    final period = _service.getPayPeriodForDate(date);
    state = period.start;
  }

  bool get isCurrentPeriod {
    final currentPeriod = _service.getCurrentPayPeriod();
    return state.year == currentPeriod.start.year &&
        state.month == currentPeriod.start.month &&
        state.day == currentPeriod.start.day;
  }
}

/// Provider for pay period navigation.
final payPeriodNavigationProvider =
    StateNotifierProvider<PayPeriodNavigationNotifier, DateTime>((ref) {
  final service = ref.watch(timesheetServiceProvider);
  return PayPeriodNavigationNotifier(service);
});

/// Filter options for timesheets.
enum TimesheetFilter {
  all,
  pending,
  approved,
  hasOvertime,
  needsAttention,
}

/// Extension for filter display names.
extension TimesheetFilterExtension on TimesheetFilter {
  String get displayName {
    switch (this) {
      case TimesheetFilter.all:
        return 'All';
      case TimesheetFilter.pending:
        return 'Pending Approval';
      case TimesheetFilter.approved:
        return 'Approved';
      case TimesheetFilter.hasOvertime:
        return 'Has Overtime';
      case TimesheetFilter.needsAttention:
        return 'Needs Attention';
    }
  }

  String get description {
    switch (this) {
      case TimesheetFilter.all:
        return 'Show all staff timesheets';
      case TimesheetFilter.pending:
        return 'Timesheets awaiting approval';
      case TimesheetFilter.approved:
        return 'Approved timesheets';
      case TimesheetFilter.hasOvertime:
        return 'Timesheets with overtime hours';
      case TimesheetFilter.needsAttention:
        return 'Timesheets with rejected entries';
    }
  }
}
