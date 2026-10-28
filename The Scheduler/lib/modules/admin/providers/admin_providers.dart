import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/audit_log.dart';
import '../../../data/models/business_stats.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/staff_member.dart';
import '../../../data/models/timesheet_summary.dart';
import '../../manager/providers/manager_providers.dart';

part 'admin_providers.freezed.dart';

/// Helper to log PHI list access for HIPAA compliance.
/// Throttled server-side to avoid excessive writes.
Future<void> _logPhiListAccess({
  required Ref ref,
  required SecurityContext context,
  required String entityType,
  required int count,
  required String source,
  Map<String, dynamic>? additionalMetadata,
}) async {
  final auditRepo = ref.read(auditLogRepositoryProvider);
  await auditRepo.logEvent(AuditLogEntry(
    businessId: context.businessId,
    userId: context.userId,
    actionType: AuditActionType.phiReadList,
    entityType: entityType,
    entityId: '${source}_list_view',
    metadata: {
      'source': source,
      'count': count,
      ...?additionalMetadata,
    },
  ));
}

/// Date range for querying appointments.
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// Business overview stats for admin dashboard.
///
/// HIPAA: Only aggregated counts/revenue, no PHI.
final businessStatsProvider = FutureProvider<BusinessStats>((ref) async {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || !context.role.canManageBusiness) {
    return const BusinessStats(
      appointmentsToday: 0,
      appointmentsChange: 0,
      revenueTodayCents: 0,
      revenueChangePercent: 0.0,
      staffOnDuty: 0,
      staffTotal: 0,
    );
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final lastWeekToday = today.subtract(const Duration(days: 7));
  final lastWeekTomorrow = lastWeekToday.add(const Duration(days: 1));

  final repo = ref.watch(appointmentsRepositoryProvider);

  // Get today's appointments
  final todayAppts = await repo
      .watchAppointmentsInRange(
        context: context,
        start: today,
        end: tomorrow,
      )
      .first;

  // Get last week's same day for comparison
  final lastWeekAppts = await repo
      .watchAppointmentsInRange(
        context: context,
        start: lastWeekToday,
        end: lastWeekTomorrow,
      )
      .first;

  // Calculate stats
  final appointmentsToday = todayAppts.length;
  final appointmentsChange = appointmentsToday - lastWeekAppts.length;

  // Calculate revenue (sum of paid appointments)
  int revenueTodayCents = 0;
  int lastWeekRevenueCents = 0;
  int completedCount = 0;
  int cancelledCount = 0;
  int noShowCount = 0;

  for (final appt in todayAppts) {
    if (appt.paymentStatus == PaymentStatus.completed && appt.paymentAmountCents != null) {
      revenueTodayCents += appt.paymentAmountCents!;
    }
    if (appt.status == AppointmentStatus.completed) completedCount++;
    if (appt.status == AppointmentStatus.cancelled) cancelledCount++;
    if (appt.status == AppointmentStatus.noShow) noShowCount++;
  }

  for (final appt in lastWeekAppts) {
    if (appt.paymentStatus == PaymentStatus.completed && appt.paymentAmountCents != null) {
      lastWeekRevenueCents += appt.paymentAmountCents!;
    }
  }

  // Calculate revenue change percentage
  double revenueChangePercent = 0.0;
  if (lastWeekRevenueCents > 0) {
    revenueChangePercent = ((revenueTodayCents - lastWeekRevenueCents) / lastWeekRevenueCents) * 100;
  } else if (revenueTodayCents > 0) {
    revenueChangePercent = 100.0;
  }

  // Get staff counts
  final staffMembers = ref.watch(teamMembersProvider).valueOrNull ?? [];
  final clockStatus = ref.watch(teamClockStatusProvider).valueOrNull ?? {};
  final staffOnDuty = clockStatus.values
      .where((s) => s == ClockStatus.clockedIn || s == ClockStatus.onBreak)
      .length;

  return BusinessStats(
    appointmentsToday: appointmentsToday,
    appointmentsChange: appointmentsChange,
    revenueTodayCents: revenueTodayCents,
    revenueChangePercent: revenueChangePercent,
    staffOnDuty: staffOnDuty,
    staffTotal: staffMembers.where((s) => s.isActive).length,
    appointmentsCompleted: completedCount,
    appointmentsCancelled: cancelledCount,
    appointmentsNoShow: noShowCount,
  );
});

/// All appointments for admin view across all providers.
///
/// HIPAA: Contains PHI - use only in authenticated context with proper RBAC.
/// Access is audit logged for compliance.
final adminAllAppointmentsProvider = StreamProvider.family<List<Appointment>, DateRange>(
  (ref, range) {
    final context = ref.watch(securityContextProvider).valueOrNull;
    if (context == null || !context.role.canManageAllAppointments) {
      return const Stream<List<Appointment>>.empty();
    }

    final repo = ref.watch(appointmentsRepositoryProvider);
    final stream = repo.watchAppointmentsInRange(
      context: context,
      start: range.start,
      end: range.end,
    );

    // Log PHI list access for HIPAA compliance (non-blocking)
    stream.first.then((appointments) {
      if (appointments.isNotEmpty) {
        _logPhiListAccess(
          ref: ref,
          context: context,
          entityType: 'Appointment',
          count: appointments.length,
          source: 'admin_schedule',
          additionalMetadata: {
            'dateRangeStart': range.start.toIso8601String().split('T')[0],
            'dateRangeEnd': range.end.toIso8601String().split('T')[0],
          },
        );
      }
    }).catchError((_) {
      // Non-blocking - don't fail the provider on audit log errors
    });

    return stream;
  },
);

/// Pending actions count for admin (timesheets + schedule change requests).
///
/// HIPAA: Only counts, no PHI.
final adminPendingActionsCountProvider = Provider<int>((ref) {
  final timesheets = ref.watch(pendingTimesheetsProvider).valueOrNull ?? [];
  // TODO: Add pending schedule change requests when that feature is built
  return timesheets.length;
});

/// Pending timesheets for admin approval.
///
/// HIPAA: Contains staff info - audit access.
final adminPendingTimesheetsProvider = FutureProvider<List<TimesheetSummary>>((ref) async {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || !context.role.canManageUsers) {
    return [];
  }

  return ref.watch(pendingTimesheetsProvider).valueOrNull ?? [];
});

/// Team member status for admin view.
@freezed
abstract class TeamMemberStatus with _$TeamMemberStatus {
  const factory TeamMemberStatus({
    required StaffMember member,
    required ClockStatus clockStatus,
  }) = _TeamMemberStatus;
}

/// Team members with current clock status.
///
/// HIPAA: Contains staff info - audit access logged for compliance.
final adminTeamStatusProvider = StreamProvider<List<TeamMemberStatus>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || !context.role.canManageUsers) {
    return const Stream<List<TeamMemberStatus>>.empty();
  }

  final staff = ref.watch(teamMembersProvider).valueOrNull ?? [];
  final clockStatus = ref.watch(teamClockStatusProvider).valueOrNull ?? {};

  final teamMembers = staff.map((s) {
    return TeamMemberStatus(
      member: s,
      clockStatus: clockStatus[s.id] ?? ClockStatus.off,
    );
  }).toList();

  // Log PHI list access for HIPAA compliance (non-blocking)
  if (teamMembers.isNotEmpty) {
    _logPhiListAccess(
      ref: ref,
      context: context,
      entityType: 'StaffMember',
      count: teamMembers.length,
      source: 'admin_team',
    ).catchError((_) {
      // Non-blocking - don't fail the provider on audit log errors
    });
  }

  return Stream.value(teamMembers);
});

/// Selected date for admin schedule view.
final adminSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// View mode for admin schedule (today or week).
final adminScheduleViewModeProvider = StateProvider<ScheduleViewMode>(
  (ref) => ScheduleViewMode.today,
);

enum ScheduleViewMode { today, week }

/// Selected provider filter for admin schedule (null = all providers).
final adminSelectedProviderIdProvider = StateProvider<String?>((ref) => null);

/// Filtered appointments for admin schedule view.
///
/// HIPAA: Contains PHI - use only in authenticated context with proper RBAC.
final adminFilteredAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final selectedDate = ref.watch(adminSelectedDateProvider);
  final viewMode = ref.watch(adminScheduleViewModeProvider);
  final selectedProviderId = ref.watch(adminSelectedProviderIdProvider);

  DateTime start;
  DateTime end;

  if (viewMode == ScheduleViewMode.today) {
    start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    end = start.add(const Duration(days: 1));
  } else {
    // Week view: Start from Monday of the week
    final weekday = selectedDate.weekday;
    start = selectedDate.subtract(Duration(days: weekday - 1));
    start = DateTime(start.year, start.month, start.day);
    end = start.add(const Duration(days: 7));
  }

  final range = DateRange(start: start, end: end);
  final allAppointments = ref.watch(adminAllAppointmentsProvider(range));

  return allAppointments.when(
    data: (appointments) {
      if (selectedProviderId == null) {
        return Stream.value(appointments);
      }
      return Stream.value(
        appointments.where((a) => a.providerId == selectedProviderId).toList(),
      );
    },
    loading: () => const Stream<List<Appointment>>.empty(),
    error: (error, stackTrace) => const Stream<List<Appointment>>.empty(),
  );
});
