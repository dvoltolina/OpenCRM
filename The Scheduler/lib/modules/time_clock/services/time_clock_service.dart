import 'package:uuid/uuid.dart';

import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/repositories/time_entry_repository.dart';

/// Service for handling time clock operations (clock in/out, breaks).
///
/// Provides a simplified API for UI components to interact with time entries.
class TimeClockService {
  TimeClockService({required TimeEntryRepository timeEntryRepository})
    : _repository = timeEntryRepository;

  final TimeEntryRepository _repository;
  final _uuid = const Uuid();

  /// Get the current active time entry for the user.
  Future<TimeEntry?> getActiveEntry(SecurityContext context) async {
    final staffId = context.providerId;
    if (staffId == null) return null;

    return _repository.getActiveEntry(context: context, staffId: staffId);
  }

  /// Stream of active time entry for the user.
  Stream<TimeEntry?> watchActiveEntry(SecurityContext context) {
    final staffId = context.providerId;
    if (staffId == null) return Stream.value(null);

    return _repository
        .watchTimeEntries(
          context: context,
          staffId: staffId,
          status: TimeEntryStatus.active,
          limit: 1,
        )
        .map((entries) => entries.isEmpty ? null : entries.first);
  }

  /// Clock in the user.
  ///
  /// Creates a new active time entry with the current timestamp.
  /// Optionally captures GPS location.
  Future<TimeEntry> clockIn({
    required SecurityContext context,
    double? latitude,
    double? longitude,
    String? address,
    String? locationId,
    bool outsideGeofence = false,
    String? notes,
    bool enforceGeofence = false,
  }) async {
    final staffId = context.providerId;
    if (staffId == null) {
      throw StateError('User must be a staff member to clock in');
    }

    // Check if already clocked in
    final existing = await getActiveEntry(context);
    if (existing != null) {
      throw StateError('Already clocked in. Please clock out first.');
    }

    if (enforceGeofence && outsideGeofence) {
      throw StateError('Clock in is restricted to business locations.');
    }

    final now = DateTime.now();
    final entry = TimeEntry(
      id: _uuid.v4(),
      businessId: context.businessId,
      staffId: staffId,
      clockInTime: now,
      clockInLatitude: latitude,
      clockInLongitude: longitude,
      clockInAddress: address,
      clockInLocationId: locationId,
      clockInOutsideGeofence: outsideGeofence,
      staffNotes: notes,
      status: TimeEntryStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createTimeEntry(context: context, entry: entry);

    return entry;
  }

  /// Clock out the user.
  ///
  /// Updates the active time entry with clock out time and calculates totals.
  Future<TimeEntry> clockOut({
    required SecurityContext context,
    double? latitude,
    double? longitude,
    String? address,
    String? locationId,
    bool outsideGeofence = false,
    String? notes,
    bool enforceGeofence = false,
  }) async {
    final entry = await getActiveEntry(context);
    if (entry == null) {
      throw StateError('Not clocked in. Please clock in first.');
    }

    // End any active break first
    TimeEntry updatedEntry = entry;
    if (entry.isOnBreak) {
      updatedEntry = await endBreak(context: context);
    }

    final now = DateTime.now();
    final totalMinutes = now.difference(updatedEntry.clockInTime).inMinutes;
    final breakMinutes = updatedEntry.calculatedBreakMinutes;
    final workedMinutes = totalMinutes - breakMinutes;

    if (enforceGeofence && outsideGeofence) {
      throw StateError('Clock out is restricted to business locations.');
    }

    final clockedOut = updatedEntry.copyWith(
      clockOutTime: now,
      clockOutLatitude: latitude,
      clockOutLongitude: longitude,
      clockOutAddress: address,
      clockOutLocationId: locationId,
      clockOutOutsideGeofence: outsideGeofence,
      totalMinutes: totalMinutes,
      breakMinutes: breakMinutes,
      workedMinutes: workedMinutes,
      status: TimeEntryStatus.pending, // Goes to pending for approval
      staffNotes: notes ?? updatedEntry.staffNotes,
      updatedAt: now,
    );

    await _repository.updateTimeEntry(context: context, entry: clockedOut);

    return clockedOut;
  }

  /// Start a break (meal or rest).
  Future<TimeEntry> startBreak({
    required SecurityContext context,
    required BreakType type,
  }) async {
    final entry = await getActiveEntry(context);
    if (entry == null) {
      throw StateError('Not clocked in. Please clock in first.');
    }

    if (entry.isOnBreak) {
      throw StateError('Already on break. Please end current break first.');
    }

    final now = DateTime.now();
    final newBreak = BreakPeriod(startTime: now, type: type);

    final updated = entry.copyWith(
      breaks: [...entry.breaks, newBreak],
      updatedAt: now,
    );

    await _repository.updateTimeEntry(context: context, entry: updated);

    return updated;
  }

  /// End the current break.
  Future<TimeEntry> endBreak({required SecurityContext context}) async {
    final entry = await getActiveEntry(context);
    if (entry == null) {
      throw StateError('Not clocked in.');
    }

    if (!entry.isOnBreak) {
      throw StateError('Not currently on break.');
    }

    final now = DateTime.now();
    final breaks = entry.breaks.toList();
    final lastBreak = breaks.removeLast();
    final endedBreak = BreakPeriod(
      startTime: lastBreak.startTime,
      endTime: now,
      type: lastBreak.type,
    );
    breaks.add(endedBreak);

    final updated = entry.copyWith(breaks: breaks, updatedAt: now);

    await _repository.updateTimeEntry(context: context, entry: updated);

    return updated;
  }

  /// Add a note to the active entry.
  Future<TimeEntry> addNote({
    required SecurityContext context,
    required String note,
  }) async {
    final entry = await getActiveEntry(context);
    if (entry == null) {
      throw StateError('Not clocked in.');
    }

    final now = DateTime.now();
    final updated = entry.copyWith(staffNotes: note, updatedAt: now);

    await _repository.updateTimeEntry(context: context, entry: updated);

    return updated;
  }

  /// Get time entries for the current user within a date range.
  Future<List<TimeEntry>> getMyEntries({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final staffId = context.providerId;
    if (staffId == null) return [];

    return _repository.getEntriesByStaff(
      context: context,
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get entries for the current pay period (assuming bi-weekly, starting Sunday).
  Future<List<TimeEntry>> getCurrentPayPeriodEntries({
    required SecurityContext context,
  }) async {
    final now = DateTime.now();
    // Find the start of the current pay period (most recent Sunday)
    final daysSinceSunday = now.weekday % 7;
    final startDate = DateTime(
      now.year,
      now.month,
      now.day - daysSinceSunday - 7, // Two weeks back
    );
    final endDate = now;

    return getMyEntries(
      context: context,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculate total hours worked for a list of entries.
  double calculateTotalHours(List<TimeEntry> entries) {
    return entries.fold<double>(
      0,
      (total, entry) => total + (entry.workedMinutes ?? 0) / 60.0,
    );
  }
}
