import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../data/local/staff_database.dart';

/// Provider for today's appointments.
///
/// Watches from local database, filtered by current staff's business.
/// Sorted by start time ascending.
final todayAppointmentsProvider = StreamProvider<List<AppointmentsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;

  if (staffUser == null) {
    return Stream.value([]);
  }

  return db.appointmentsDao.watchTodayAppointments(
    staffUser.businessId,
    staffUser.providerId,
  );
});

/// Provider for the upcoming appointment (next one starting).
///
/// Returns the first appointment that hasn't started yet, or null.
final upcomingAppointmentProvider = Provider<AppointmentsTableData?>((ref) {
  final appointments = ref.watch(todayAppointmentsProvider).valueOrNull ?? [];
  final now = DateTime.now();

  for (final apt in appointments) {
    if (apt.startTime.isAfter(now)) {
      return apt;
    }
  }
  return null;
});

/// Provider for the current appointment (happening now).
///
/// Returns the appointment where now is between start and end time.
final currentAppointmentProvider = Provider<AppointmentsTableData?>((ref) {
  final appointments = ref.watch(todayAppointmentsProvider).valueOrNull ?? [];
  final now = DateTime.now();

  for (final apt in appointments) {
    if (apt.startTime.isBefore(now) && apt.endTime.isAfter(now)) {
      return apt;
    }
  }
  return null;
});

/// Provider for appointment counts grouped by status.
final appointmentCountsByStatusProvider = Provider<Map<String, int>>((ref) {
  final appointments = ref.watch(todayAppointmentsProvider).valueOrNull ?? [];
  final counts = <String, int>{};

  for (final apt in appointments) {
    counts[apt.status] = (counts[apt.status] ?? 0) + 1;
  }

  return counts;
});

/// Provider for total appointments today.
final totalAppointmentsTodayProvider = Provider<int>((ref) {
  return ref.watch(todayAppointmentsProvider).valueOrNull?.length ?? 0;
});

/// Provider for completed appointments today.
final completedAppointmentsTodayProvider = Provider<int>((ref) {
  final counts = ref.watch(appointmentCountsByStatusProvider);
  return counts['completed'] ?? 0;
});

/// Extension to convert AppointmentsTableData to a display-friendly format.
extension AppointmentDisplayExtension on AppointmentsTableData {
  /// Time range formatted as "9:00 AM - 10:00 AM"
  String get timeRange {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  /// Just the start time formatted
  String get startTimeFormatted => _formatTime(startTime);

  /// Just the end time formatted
  String get endTimeFormatted => _formatTime(endTime);

  /// Duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Whether this appointment is in the past
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Whether this appointment is currently happening
  bool get isCurrent {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  /// Whether this appointment is upcoming (in the future)
  bool get isUpcoming => startTime.isAfter(DateTime.now());

  /// Whether this appointment has been checked in
  bool get isCheckedIn => checkedInAt != null;

  /// Whether this appointment is completed
  bool get isCompleted => status == 'completed';

  /// Whether this appointment was a no-show
  bool get isNoShow => status == 'noShow' || status == 'no_show';

  /// Whether this appointment is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Display name (client name or fallback)
  String get displayName => clientName ?? 'Unknown Client';

  /// Display service (service name or fallback)
  String get displayService => serviceName ?? 'Service';

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
