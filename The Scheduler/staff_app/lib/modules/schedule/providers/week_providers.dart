import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../data/local/staff_database.dart';

DateTime startOfWeek(DateTime date) {
  final weekday = date.weekday; // Monday = 1
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
}

/// Selected week start (Monday).
final selectedWeekProvider = StateProvider<DateTime>((ref) {
  return startOfWeek(DateTime.now());
});

/// Appointments for the selected week, grouped by day.
final weekAppointmentsProvider =
    StreamProvider<Map<DateTime, List<AppointmentsTableData>>>((ref) {
  final db = ref.watch(databaseProvider);
  final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;
  final weekStart = ref.watch(selectedWeekProvider);

  if (staffUser == null) {
    return Stream.value({});
  }

  return db.appointmentsDao
      .watchWeekAppointments(
          staffUser.businessId, staffUser.providerId, weekStart)
      .map((appointments) {
    final byDay = <DateTime, List<AppointmentsTableData>>{};
    for (final apt in appointments) {
      final dayKey =
          DateTime(apt.startTime.year, apt.startTime.month, apt.startTime.day);
      byDay.putIfAbsent(dayKey, () => []).add(apt);
    }
    return byDay;
  });
});

/// Count of appointments per day.
final appointmentCountByDayProvider = Provider<Map<DateTime, int>>((ref) {
  final grouped = ref.watch(weekAppointmentsProvider).valueOrNull ?? {};
  return {
    for (final entry in grouped.entries) entry.key: entry.value.length,
  };
});
