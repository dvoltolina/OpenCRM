import 'package:drift/drift.dart';

import '../staff_database.dart';
import '../tables/appointments_table.dart';

part 'appointments_dao.g.dart';

/// Data Access Object for appointments table operations.
///
/// Provides methods for querying, inserting, updating, and syncing
/// appointment records in the local SQLite database.
@DriftAccessor(tables: [AppointmentsTable])
class AppointmentsDao extends DatabaseAccessor<StaffDatabase>
    with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);

  /// Watches today's appointments for a specific staff member.
  ///
  /// Returns a stream that updates whenever appointments change.
  /// Filters by businessId and date range (start of day to end of day).
  Stream<List<AppointmentsTableData>> watchTodayAppointments(
    String businessId,
    String staffId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(appointmentsTable)
          ..where((a) => a.businessId.equals(businessId))
          ..where((a) => a.staffId.equals(staffId))
          ..where((a) => a.startTime.isBiggerOrEqualValue(startOfDay))
          ..where((a) => a.startTime.isSmallerThanValue(endOfDay))
          ..orderBy([(a) => OrderingTerm.asc(a.startTime)]))
        .watch();
  }

  /// Watches appointments for a week starting from [weekStart].
  ///
  /// Returns a stream of appointments sorted by start time.
  Stream<List<AppointmentsTableData>> watchWeekAppointments(
    String businessId,
    String staffId,
    DateTime weekStart,
  ) {
    final weekEnd = weekStart.add(const Duration(days: 7));

    return (select(appointmentsTable)
          ..where((a) => a.businessId.equals(businessId))
          ..where((a) => a.staffId.equals(staffId))
          ..where((a) => a.startTime.isBiggerOrEqualValue(weekStart))
          ..where((a) => a.startTime.isSmallerThanValue(weekEnd))
          ..orderBy([(a) => OrderingTerm.asc(a.startTime)]))
        .watch();
  }

  /// Gets a single appointment by ID.
  Future<AppointmentsTableData?> getAppointmentById(String id) {
    return (select(appointmentsTable)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watches a single appointment by ID.
  ///
  /// Returns a stream that updates when the appointment changes.
  Stream<AppointmentsTableData?> watchAppointmentById(String id) {
    return (select(appointmentsTable)..where((a) => a.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Inserts or updates an appointment.
  ///
  /// Uses upsert to handle both new records and updates.
  Future<void> upsertAppointment(AppointmentsTableCompanion appointment) {
    return into(appointmentsTable).insertOnConflictUpdate(appointment);
  }

  /// Batch inserts or updates multiple appointments.
  ///
  /// Runs in a transaction for atomicity.
  Future<void> upsertAppointments(
      List<AppointmentsTableCompanion> appointments) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(appointmentsTable, appointments);
    });
  }

  /// Marks an appointment as pending sync with a specific action.
  ///
  /// Sets pendingSync to true, updates syncAction, and sets localUpdatedAt.
  Future<void> markPendingSync(String id, String action) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        pendingSync: const Value(true),
        syncAction: Value(action),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Gets all appointments that are pending sync.
  Future<List<AppointmentsTableData>> getPendingSyncAppointments() {
    return (select(appointmentsTable)
          ..where((a) => a.pendingSync.equals(true))
          ..orderBy([(a) => OrderingTerm.asc(a.localUpdatedAt)]))
        .get();
  }

  /// Clears pending sync status for an appointment.
  ///
  /// Called after successful sync to Firestore.
  Future<void> clearPendingSync(String id) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        pendingSync: const Value(false),
        syncAction: const Value(null),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates an appointment's status.
  Future<void> updateStatus(String id, String status) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        status: Value(status),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Records check-in for an appointment.
  Future<void> checkIn(String id, String staffId) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        checkedInAt: Value(DateTime.now()),
        checkedInByStaffId: Value(staffId),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Records completion for an appointment.
  Future<void> complete(String id, String staffId) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
        completedByStaffId: Value(staffId),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates staff notes for an appointment.
  Future<void> updateStaffNotes(String id, String notes) {
    return (update(appointmentsTable)..where((a) => a.id.equals(id))).write(
      AppointmentsTableCompanion(
        staffNotes: Value(notes),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes appointments older than [retention] days.
  ///
  /// Used for cleanup to manage storage.
  Future<int> deleteOldAppointments(int retentionDays) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return (delete(appointmentsTable)
          ..where((a) => a.endTime.isSmallerThanValue(cutoff))
          ..where((a) => a.pendingSync.equals(false)))
        .go();
  }
}
