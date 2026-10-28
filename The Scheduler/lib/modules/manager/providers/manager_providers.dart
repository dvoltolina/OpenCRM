import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/models/timesheet_summary.dart';
import '../../../data/models/staff_member.dart';
import '../../staff/providers/timesheet_providers.dart' as staff_timesheets;

/// Clock status buckets for team overview.
enum ClockStatus { clockedIn, onBreak, pending, off }

/// Team members for manager's business (manager/admin only).
final teamMembersProvider = StreamProvider<List<StaffMember>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return const Stream<List<StaffMember>>.empty();

  // Managers are allowed to view staff via StaffRepository.
  return ref.watch(staffRepositoryProvider).watchStaffMembers(context);
});

/// Clock status per staffId for the current day.
final teamClockStatusProvider = StreamProvider<Map<String, ClockStatus>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return const Stream<Map<String, ClockStatus>>.empty();

  final repo = ref.watch(timeEntryRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));

  return repo
      .watchTimeEntries(
        context: context,
        startDate: start,
        endDate: end,
        statuses: const [TimeEntryStatus.active, TimeEntryStatus.pending],
        limit: 200,
      )
      .map((entries) {
        final statusMap = <String, ClockStatus>{};
        for (final entry in entries) {
          if (entry.isActive) {
            statusMap[entry.staffId] = entry.isOnBreak
                ? ClockStatus.onBreak
                : ClockStatus.clockedIn;
          } else if (entry.isPendingApproval) {
            statusMap[entry.staffId] = ClockStatus.pending;
          }
        }
        return statusMap;
      });
});

/// Aggregated counts for clock statuses.
final clockStatusCountsProvider = Provider<ClockStatusCounts>((ref) {
  final statuses = ref.watch(teamClockStatusProvider).valueOrNull ?? {};
  final members = ref.watch(teamMembersProvider).valueOrNull ?? [];
  final total = members.length;
  final inOrBreak = statuses.values
      .where((s) => s == ClockStatus.clockedIn || s == ClockStatus.onBreak)
      .length;
  final offCount = (total - inOrBreak).clamp(0, total);
  return ClockStatusCounts(
    clockedIn: statuses.values.where((s) => s == ClockStatus.clockedIn).length,
    onBreak: statuses.values.where((s) => s == ClockStatus.onBreak).length,
    off: offCount,
    pending: statuses.values.where((s) => s == ClockStatus.pending).length,
  );
});

/// Pending timesheets (submitted) for approvals.
final pendingTimesheetsProvider = FutureProvider<List<TimesheetSummary>>((
  ref,
) async {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || !context.role.canManageAllAppointments) return [];

  final service = ref.watch(timesheetServiceProvider);
  final period = service.getCurrentPayPeriod();
  final timesheets = await service.getAllStaffTimesheets(
    context: context,
    periodStart: period.start,
    periodEnd: period.end,
  );

  return timesheets
      .where((ts) => ts.status == TimesheetStatus.submitted)
      .toList();
});

/// Count of pending approvals (timesheets only for now).
final pendingApprovalsCountProvider = Provider<int>((ref) {
  final timesheets = ref.watch(pendingTimesheetsProvider).valueOrNull ?? [];
  return timesheets.length;
});

/// Team schedule for a specific date.
final teamScheduleProvider = StreamProvider.family<List<Appointment>, DateTime>(
  (ref, date) {
    final context = ref.watch(securityContextProvider).valueOrNull;
    if (context == null) return const Stream<List<Appointment>>.empty();

    final repo = ref.watch(appointmentsRepositoryProvider);
    final start = DateTime(date.year, date.month, date.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    return repo.watchAppointmentsInRange(
      context: context,
      start: start,
      end: end,
    );
  },
);

/// Selected date for the team view.
final selectedTeamDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Upcoming schedule for a specific staff member on a date.
final staffDailyScheduleProvider =
    StreamProvider.family<List<Appointment>, ({DateTime date, String staffId})>(
      (ref, params) {
        final context = ref.watch(securityContextProvider).valueOrNull;
        if (context == null) return const Stream<List<Appointment>>.empty();

        final repo = ref.watch(appointmentsRepositoryProvider);
        final start = DateTime(
          params.date.year,
          params.date.month,
          params.date.day,
        );
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));

        return repo.watchAppointmentsInRange(
          context: context,
          start: start,
          end: end,
          providerId: params.staffId,
        );
      },
    );

/// Active entry for a staff member.
final staffActiveEntryProvider = FutureProvider.family<TimeEntry?, String>((
  ref,
  staffId,
) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Future.value(null);

  final repo = ref.watch(timeEntryRepositoryProvider);
  return repo.getActiveEntry(context: context, staffId: staffId);
});

/// Staff timesheet for the current period (reuse staff providers).
final managerStaffTimesheetProvider =
    FutureProvider.family<TimesheetSummary, String>((ref, staffId) async {
      final context = ref.watch(securityContextProvider).valueOrNull;
      if (context == null) {
        throw SecurityException('Authentication required');
      }

      final periodStart = ref.watch(
        staff_timesheets.selectedPayPeriodStartProvider,
      );
      final service = ref.watch(timesheetServiceProvider);
      final period = service.getPayPeriodForDate(periodStart);

      return service.getStaffTimesheet(
        context: context,
        staffId: staffId,
        periodStart: period.start,
        periodEnd: period.end,
      );
    });

/// Helper counts container.
class ClockStatusCounts {
  ClockStatusCounts({
    required this.clockedIn,
    required this.onBreak,
    required this.off,
    required this.pending,
  });

  final int clockedIn;
  final int onBreak;
  final int off;
  final int pending;
}
