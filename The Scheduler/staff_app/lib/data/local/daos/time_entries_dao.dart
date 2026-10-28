import 'package:drift/drift.dart';

import '../staff_database.dart';
import '../tables/time_entries_table.dart';

part 'time_entries_dao.g.dart';

/// Data Access Object for time entries table operations.
///
/// Provides methods for clock in/out, break management, and querying
/// time entry records in the local SQLite database.
@DriftAccessor(tables: [TimeEntriesTable])
class TimeEntriesDao extends DatabaseAccessor<StaffDatabase>
    with _$TimeEntriesDaoMixin {
  TimeEntriesDao(super.db);

  /// Gets the currently active time entry (clocked in, not clocked out).
  ///
  /// Returns null if no active entry exists.
  Future<TimeEntriesTableData?> getActiveTimeEntry(String staffId) {
    return (select(timeEntriesTable)
          ..where((t) => t.staffId.equals(staffId))
          ..where((t) => t.status.equals('active'))
          ..where((t) => t.clockOutTime.isNull()))
        .getSingleOrNull();
  }

  /// Watches the active time entry for real-time UI updates.
  Stream<TimeEntriesTableData?> watchActiveTimeEntry(String staffId) {
    return (select(timeEntriesTable)
          ..where((t) => t.staffId.equals(staffId))
          ..where((t) => t.status.equals('active'))
          ..where((t) => t.clockOutTime.isNull()))
        .watchSingleOrNull();
  }

  /// Gets today's time entries for a staff member.
  Future<List<TimeEntriesTableData>> getTodayEntries(String staffId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(timeEntriesTable)
          ..where((t) => t.staffId.equals(staffId))
          ..where((t) => t.clockInTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.clockInTime.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.clockInTime)]))
        .get();
  }

  /// Watches today's time entries for real-time UI updates.
  Stream<List<TimeEntriesTableData>> watchTodayEntries(String staffId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(timeEntriesTable)
          ..where((t) => t.staffId.equals(staffId))
          ..where((t) => t.clockInTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.clockInTime.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.clockInTime)]))
        .watch();
  }

  /// Gets time entries within a date range.
  Future<List<TimeEntriesTableData>> getEntriesInRange(
    String staffId,
    DateTime start,
    DateTime end,
  ) {
    return (select(timeEntriesTable)
          ..where((t) => t.staffId.equals(staffId))
          ..where((t) => t.clockInTime.isBiggerOrEqualValue(start))
          ..where((t) => t.clockInTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.clockInTime)]))
        .get();
  }

  /// Gets a single time entry by ID.
  Future<TimeEntriesTableData?> getTimeEntryById(String id) {
    return (select(timeEntriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new time entry.
  Future<void> insertTimeEntry(TimeEntriesTableCompanion entry) {
    return into(timeEntriesTable).insert(entry);
  }

  /// Updates an existing time entry.
  Future<void> updateTimeEntry(
    String id,
    TimeEntriesTableCompanion entry,
  ) {
    return (update(timeEntriesTable)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  /// Inserts or updates a time entry.
  Future<void> upsertTimeEntry(TimeEntriesTableCompanion entry) {
    return into(timeEntriesTable).insertOnConflictUpdate(entry);
  }

  /// Marks a time entry as pending sync.
  Future<void> markPendingSync(String id, {String? action}) {
    return (update(timeEntriesTable)..where((t) => t.id.equals(id))).write(
      TimeEntriesTableCompanion(
        pendingSync: const Value(true),
        syncAction: Value(action),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Gets all time entries pending sync.
  Future<List<TimeEntriesTableData>> getPendingSyncEntries() {
    return (select(timeEntriesTable)
          ..where((t) => t.pendingSync.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
  }

  /// Watches count of entries pending sync for UI indicator.
  Stream<int> watchPendingSyncCount() {
    final query = select(timeEntriesTable)
      ..where((t) => t.pendingSync.equals(true));
    return query.watch().map((entries) => entries.length);
  }

  /// Clears pending sync status for a time entry.
  Future<void> clearPendingSync(String id) {
    return (update(timeEntriesTable)..where((t) => t.id.equals(id))).write(
      TimeEntriesTableCompanion(
        pendingSync: const Value(false),
        syncAction: const Value(null),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates the breaks JSON for a time entry.
  Future<void> updateBreaks(String id, String breaksJson) {
    return (update(timeEntriesTable)..where((t) => t.id.equals(id))).write(
      TimeEntriesTableCompanion(
        breaksJson: Value(breaksJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Records clock out for a time entry.
  Future<void> clockOut(
    String id, {
    required DateTime clockOutTime,
    double? latitude,
    double? longitude,
    String? address,
    String? locationId,
    bool outsideGeofence = false,
    int? totalMinutes,
    int? breakMinutes,
    int? workedMinutes,
    String? notes,
  }) {
    return (update(timeEntriesTable)..where((t) => t.id.equals(id))).write(
      TimeEntriesTableCompanion(
        clockOutTime: Value(clockOutTime),
        clockOutLatitude: Value(latitude),
        clockOutLongitude: Value(longitude),
        clockOutAddress: Value(address),
        clockOutLocationId: Value(locationId),
        clockOutOutsideGeofence: Value(outsideGeofence),
        totalMinutes: Value(totalMinutes),
        breakMinutes: Value(breakMinutes),
        workedMinutes: Value(workedMinutes),
        staffNotes: Value(notes),
        status: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Gets entries pending approval for a business.
  Future<List<TimeEntriesTableData>> getEntriesPendingApproval(
      String businessId) {
    return (select(timeEntriesTable)
          ..where((t) => t.businessId.equals(businessId))
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.clockInTime)]))
        .get();
  }

  /// Deletes time entries older than retention period.
  ///
  /// Only deletes entries that are not pending sync.
  Future<int> deleteOldEntries(int retentionDays) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return (delete(timeEntriesTable)
          ..where((t) => t.clockInTime.isSmallerThanValue(cutoff))
          ..where((t) => t.pendingSync.equals(false)))
        .go();
  }
}
