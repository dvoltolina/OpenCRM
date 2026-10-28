import 'package:drift/drift.dart';

/// Drift table for storing appointments locally.
///
/// Includes all fields from LocalAppointment model plus sync metadata.
/// Optimized for offline storage with denormalized client/service info.
class AppointmentsTable extends Table {
  // Primary key
  TextColumn get id => text()();

  // Required identifiers
  TextColumn get businessId => text()();
  TextColumn get staffId => text().withDefault(const Constant(''))();
  TextColumn get clientId => text()();
  TextColumn get serviceId => text()();
  TextColumn get locationId => text()();

  // Denormalized client info (for offline display)
  TextColumn get clientName => text().nullable()();
  TextColumn get clientPhone => text().nullable()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get clientAddress => text().nullable()();

  // Denormalized service/location info (for offline display)
  TextColumn get serviceName => text().nullable()();
  TextColumn get locationName => text().nullable()();
  IntColumn get serviceDurationMinutes => integer().nullable()();

  // Time fields
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  // Appointment status
  TextColumn get status => text()();

  // Notes
  TextColumn get notes => text().nullable()();
  TextColumn get staffNotes => text().nullable()();

  // Payment info
  BoolColumn get requiresPayment => boolean().withDefault(const Constant(false))();
  TextColumn get paymentStatus => text().nullable()();

  // Offline sync fields
  DateTimeColumn get localUpdatedAt => dateTime().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  TextColumn get syncAction => text().nullable()();

  // Check-in tracking
  DateTimeColumn get checkedInAt => dateTime().nullable()();
  TextColumn get checkedInByStaffId => text().nullable()();

  // Completion tracking
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completedByStaffId => text().nullable()();

  // Last synced from server
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // Index defined in database schema - drift generates this automatically
  // from @TableIndex annotation or database-level configuration
}
