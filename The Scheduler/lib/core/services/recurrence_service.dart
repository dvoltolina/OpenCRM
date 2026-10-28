import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/appointment.dart';
import '../../data/models/recurrence_pattern.dart';

/// Service for managing recurring appointments and their instances.
/// Handles generation, modification, and deletion of recurring appointment series.
class RecurrenceService {
  final FirebaseFirestore _firestore;

  RecurrenceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generates all appointment instances from a recurrence pattern.
  /// Returns a list of appointments to be created (excluding the parent).
  /// Maximum 52 occurrences to prevent abuse.
  List<Appointment> generateRecurringInstances({
    required Appointment parentAppointment,
    required RecurrencePattern pattern,
  }) {
    if (!parentAppointment.isRecurring || pattern.id != parentAppointment.id) {
      throw ArgumentError('Invalid parent appointment or pattern');
    }

    final instances = <Appointment>[];
    DateTime currentDate = parentAppointment.startTime;
    final duration = parentAppointment.endTime.difference(parentAppointment.startTime);
    int occurrenceCount = 0;
    final maxOccurrences = _getMaxOccurrences(pattern);

    // Generate instances up to the limit
    while (occurrenceCount < maxOccurrences) {
      final nextDate = _getNextOccurrence(
        currentDate: currentDate,
        pattern: pattern,
        isFirst: occurrenceCount == 0,
      );

      if (nextDate == null) break;

      // Check end conditions (compare dates only, endDate is inclusive)
      if (pattern.endType == RecurrenceEndType.onDate &&
          pattern.endDate != null) {
        final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
        final endDateOnly = DateTime(
          pattern.endDate!.year,
          pattern.endDate!.month,
          pattern.endDate!.day,
        );
        if (nextDateOnly.isAfter(endDateOnly)) {
          break;
        }
      }

      // Check if date is excluded
      if (!pattern.isDateExcluded(nextDate)) {
        // Skip the first occurrence (that's the parent)
        if (occurrenceCount > 0) {
          instances.add(
            parentAppointment.copyWith(
              id: _generateInstanceId(parentAppointment.id, nextDate),
              startTime: nextDate,
              endTime: nextDate.add(duration),
              date: DateTime(nextDate.year, nextDate.month, nextDate.day),
              recurrencePattern: null, // Only parent has pattern
              isRecurrenceException: false,
              originalStartTime: null,
            ),
          );
        }
      }

      currentDate = nextDate;
      occurrenceCount++;

      // Safety check: never generate more than 52 instances
      if (instances.length >= 52) break;
    }

    return instances;
  }

  /// Gets the next occurrence date based on the recurrence pattern.
  DateTime? _getNextOccurrence({
    required DateTime currentDate,
    required RecurrencePattern pattern,
    required bool isFirst,
  }) {
    switch (pattern.frequency) {
      case RecurrenceFrequency.daily:
        return isFirst ? currentDate : currentDate.add(const Duration(days: 1));

      case RecurrenceFrequency.weekly:
        return _getNextWeeklyOccurrence(currentDate, pattern, isFirst);

      case RecurrenceFrequency.biweekly:
        return _getNextWeeklyOccurrence(currentDate, pattern, isFirst, weeksOffset: 2);

      case RecurrenceFrequency.monthly:
        return _getNextMonthlyOccurrence(currentDate, isFirst);

      case RecurrenceFrequency.custom:
        return _getNextCustomOccurrence(currentDate, pattern, isFirst);
    }
  }

  /// Gets the next weekly occurrence based on days of week.
  DateTime? _getNextWeeklyOccurrence(
    DateTime currentDate,
    RecurrencePattern pattern,
    bool isFirst, {
    int weeksOffset = 1,
  }) {
    if (pattern.daysOfWeek.isEmpty) {
      // No specific days set, use same day of week
      return isFirst ? currentDate : currentDate.add(Duration(days: 7 * weeksOffset));
    }

    // Find next occurrence matching one of the specified days
    DateTime searchDate = isFirst ? currentDate : currentDate.add(const Duration(days: 1));
    int daysSearched = 0;
    final maxDaysToSearch = 7 * weeksOffset * 4; // Search up to 4 cycles

    while (daysSearched < maxDaysToSearch) {
      final dayOfWeek = _getDayOfWeek(searchDate.weekday);
      if (pattern.daysOfWeek.contains(dayOfWeek)) {
        // Check if we're in the correct week cycle
        final weeksDiff = searchDate.difference(currentDate).inDays ~/ 7;
        if (weeksDiff % weeksOffset == 0) {
          return _createDateTime(
            searchDate.year,
            searchDate.month,
            searchDate.day,
            currentDate.hour,
            currentDate.minute,
            isUtc: currentDate.isUtc,
          );
        }
      }
      searchDate = searchDate.add(const Duration(days: 1));
      daysSearched++;
    }

    return null;
  }

  /// Gets the next monthly occurrence (same day of month).
  DateTime? _getNextMonthlyOccurrence(DateTime currentDate, bool isFirst) {
    if (isFirst) return currentDate;

    final nextMonth = _createDateTime(
      currentDate.year,
      currentDate.month + 1,
      1,
      currentDate.hour,
      currentDate.minute,
      isUtc: currentDate.isUtc,
    );

    // Handle day overflow (e.g., Jan 31 -> Feb 28)
    final targetDay = currentDate.day;
    final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final actualDay = targetDay <= daysInNextMonth ? targetDay : daysInNextMonth;

    return _createDateTime(
      nextMonth.year,
      nextMonth.month,
      actualDay,
      currentDate.hour,
      currentDate.minute,
      isUtc: currentDate.isUtc,
    );
  }

  /// Gets the next custom occurrence based on custom interval.
  DateTime? _getNextCustomOccurrence(
    DateTime currentDate,
    RecurrencePattern pattern,
    bool isFirst,
  ) {
    if (isFirst) return currentDate;
    if (pattern.customInterval == null || pattern.customIntervalUnit == null) {
      return null;
    }

    final interval = pattern.customInterval!;
    switch (pattern.customIntervalUnit) {
      case 'days':
        return currentDate.add(Duration(days: interval));
      case 'weeks':
        return currentDate.add(Duration(days: interval * 7));
      case 'months':
        return _createDateTime(
          currentDate.year,
          currentDate.month + interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
          isUtc: currentDate.isUtc,
        );
      default:
        return null;
    }
  }

  /// Creates a DateTime preserving UTC/local status.
  DateTime _createDateTime(
    int year,
    int month,
    int day,
    int hour,
    int minute, {
    required bool isUtc,
  }) {
    return isUtc
        ? DateTime.utc(year, month, day, hour, minute)
        : DateTime(year, month, day, hour, minute);
  }

  /// Converts Flutter weekday (1=Monday) to DayOfWeek enum.
  DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return DayOfWeek.monday;
      case 2:
        return DayOfWeek.tuesday;
      case 3:
        return DayOfWeek.wednesday;
      case 4:
        return DayOfWeek.thursday;
      case 5:
        return DayOfWeek.friday;
      case 6:
        return DayOfWeek.saturday;
      case 7:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }

  /// Gets maximum occurrences to generate.
  int _getMaxOccurrences(RecurrencePattern pattern) {
    if (pattern.endType == RecurrenceEndType.afterOccurrences &&
        pattern.numberOfOccurrences != null) {
      return pattern.numberOfOccurrences!.clamp(1, 52);
    }
    return 52; // Default maximum
  }

  /// Generates a unique ID for a recurring instance.
  String _generateInstanceId(String parentId, DateTime date) {
    final timestamp = date.millisecondsSinceEpoch;
    return '${parentId}_$timestamp';
  }

  /// Updates a single instance in a recurring series.
  /// This marks the instance as an exception and preserves the original time.
  Future<void> updateRecurringInstance({
    required String businessId,
    required Appointment instance,
    required Appointment updatedInstance,
  }) async {
    if (!instance.isRecurring || instance.recurrenceId == null) {
      throw ArgumentError('Not a recurring appointment instance');
    }

    // Mark as exception and preserve original time
    final modifiedInstance = updatedInstance.copyWith(
      isRecurrenceException: true,
      originalStartTime: instance.startTime,
    );

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(modifiedInstance.id)
        .set(modifiedInstance.toJson());
  }

  /// Deletes a single instance from a recurring series.
  Future<void> deleteRecurringInstance({
    required String businessId,
    required String appointmentId,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(appointmentId)
        .delete();
  }

  /// Deletes entire recurring series including parent and all instances.
  Future<void> deleteRecurringSeries({
    required String businessId,
    required String recurrenceId,
  }) async {
    // Query all appointments in the series
    final querySnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .where('recurrenceId', isEqualTo: recurrenceId)
        .get();

    // Delete in batch
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Also delete parent if it has different ID structure
    final parentRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(recurrenceId);

    batch.delete(parentRef);
    await batch.commit();
  }

  /// Updates the entire recurring series.
  /// This regenerates all future instances with the new pattern.
  Future<void> updateRecurringSeries({
    required String businessId,
    required Appointment parentAppointment,
    required RecurrencePattern newPattern,
  }) async {
    if (!parentAppointment.isRecurrenceParent) {
      throw ArgumentError('Must be the parent appointment');
    }

    // Delete all existing non-exception instances
    await _deleteNonExceptionInstances(businessId, parentAppointment.recurrenceId!);

    // Update parent with new pattern
    final updatedParent = parentAppointment.copyWith(
      recurrencePattern: newPattern,
    );

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(updatedParent.id)
        .set(updatedParent.toJson());

    // Generate new instances
    final newInstances = generateRecurringInstances(
      parentAppointment: updatedParent,
      pattern: newPattern,
    );

    // Create new instances in batch
    final batch = _firestore.batch();
    for (final instance in newInstances) {
      final docRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('appointments')
          .doc(instance.id);
      batch.set(docRef, instance.toJson());
    }
    await batch.commit();
  }

  /// Deletes non-exception instances from a series.
  Future<void> _deleteNonExceptionInstances(
    String businessId,
    String recurrenceId,
  ) async {
    final querySnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .where('recurrenceId', isEqualTo: recurrenceId)
        .where('isRecurrenceException', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      // Don't delete the parent
      if (doc.id != recurrenceId) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  /// Checks for conflicts with a recurring series.
  /// Returns list of conflicting appointments.
  Future<List<Appointment>> checkRecurrenceConflicts({
    required String businessId,
    required String providerId,
    required List<Appointment> proposedInstances,
  }) async {
    final conflicts = <Appointment>[];

    for (final instance in proposedInstances) {
      final querySnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .where('date', isEqualTo: Timestamp.fromDate(instance.date))
          .where('status', whereIn: [
        AppointmentStatus.pending.name,
        AppointmentStatus.confirmed.name,
      ]).get();

      for (final doc in querySnapshot.docs) {
        final existing = Appointment.fromJson({
          'id': doc.id,
          'businessId': businessId,
          ...doc.data(),
        });
        if (_appointmentsOverlap(instance, existing)) {
          conflicts.add(existing);
        }
      }
    }

    return conflicts;
  }

  /// Checks if two appointments overlap in time.
  bool _appointmentsOverlap(Appointment a, Appointment b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  /// Gets all instances in a recurring series.
  Future<List<Appointment>> getRecurringSeries({
    required String businessId,
    required String recurrenceId,
  }) async {
    final querySnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .where('recurrenceId', isEqualTo: recurrenceId)
        .orderBy('startTime')
        .get();

    return querySnapshot.docs
        .map((doc) => Appointment.fromJson({
              'id': doc.id,
              'businessId': businessId,
              ...doc.data(),
            }))
        .toList();
  }

  /// Gets upcoming instances in a series (excludes past appointments).
  Future<List<Appointment>> getUpcomingRecurringSeries({
    required String businessId,
    required String recurrenceId,
  }) async {
    final now = DateTime.now();
    final querySnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .where('recurrenceId', isEqualTo: recurrenceId)
        .where('startTime', isGreaterThanOrEqualTo: now)
        .orderBy('startTime')
        .get();

    return querySnapshot.docs
        .map((doc) => Appointment.fromJson({
              'id': doc.id,
              'businessId': businessId,
              ...doc.data(),
            }))
        .toList();
  }
}
