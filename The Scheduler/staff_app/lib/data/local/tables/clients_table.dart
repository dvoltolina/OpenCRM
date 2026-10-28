import 'package:drift/drift.dart';

/// Drift table for storing client information locally.
///
/// Contains client details needed for offline display on appointments.
/// Only clients with appointments for this staff member are cached.
class ClientsTable extends Table {
  // Primary key
  TextColumn get id => text()();

  // Business association
  TextColumn get businessId => text()();

  // Required fields
  TextColumn get name => text()();

  // Contact information
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();

  // Additional info
  TextColumn get notes => text().nullable()();

  // Sync metadata
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
