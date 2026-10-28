import 'package:drift/drift.dart';

/// Drift table for managing the offline sync queue.
///
/// Stores pending changes that need to be synced to Firestore when online.
/// Supports retry logic and error tracking.
class SyncQueueTable extends Table {
  // Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  // Entity type: 'appointment', 'time_entry', 'session_note'
  TextColumn get entityType => text()();

  // Entity ID (the ID of the record being synced)
  TextColumn get entityId => text()();

  // Action: 'update', 'create', 'delete', 'check_in', 'complete', 'no_show',
  //         'clock_in', 'clock_out', 'start_break', 'end_break', 'update_notes'
  TextColumn get action => text()();

  // JSON payload with the data to sync
  TextColumn get payload => text()();

  // When this item was added to the queue
  DateTimeColumn get createdAt => dateTime()();

  // Number of failed sync attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // Last error message (if sync failed)
  TextColumn get lastError => text().nullable()();

  // When the last sync attempt was made
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
