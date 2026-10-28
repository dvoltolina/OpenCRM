import 'package:drift/drift.dart';

/// Drift table for storing time entries (clock in/out records) locally.
///
/// Includes all fields from TimeEntry model with breaks stored as JSON.
/// Supports offline clock in/out with pending sync.
class TimeEntriesTable extends Table {
  // Primary key
  TextColumn get id => text()();

  // Required identifiers
  TextColumn get businessId => text()();
  TextColumn get staffId => text()();

  // Clock in/out times
  DateTimeColumn get clockInTime => dateTime()();
  DateTimeColumn get clockOutTime => dateTime().nullable()();

  // Clock-in location tracking (GPS)
  RealColumn get clockInLatitude => real().nullable()();
  RealColumn get clockInLongitude => real().nullable()();
  TextColumn get clockInAddress => text().nullable()();

  // Clock-out location tracking (GPS)
  RealColumn get clockOutLatitude => real().nullable()();
  RealColumn get clockOutLongitude => real().nullable()();
  TextColumn get clockOutAddress => text().nullable()();

  // Geo-fence validation
  TextColumn get clockInLocationId => text().nullable()();
  TextColumn get clockOutLocationId => text().nullable()();
  BoolColumn get clockInOutsideGeofence =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get clockOutOutsideGeofence =>
      boolean().withDefault(const Constant(false))();

  // Breaks stored as JSON array
  // Format: [{"startTime": "ISO8601", "endTime": "ISO8601", "type": "meal|rest"}]
  TextColumn get breaksJson => text().withDefault(const Constant('[]'))();

  // Calculated fields (set on clock out)
  IntColumn get totalMinutes => integer().nullable()();
  IntColumn get breakMinutes => integer().nullable()();
  IntColumn get workedMinutes => integer().nullable()();

  // Status & approval
  // Values: 'active', 'pending', 'approved', 'rejected'
  TextColumn get status => text()();
  TextColumn get approvedByUserId => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get rejectionReason => text().nullable()();

  // Notes
  TextColumn get staffNotes => text().nullable()();
  TextColumn get managerNotes => text().nullable()();

  // Audit fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Offline sync fields
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  TextColumn get syncAction => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
