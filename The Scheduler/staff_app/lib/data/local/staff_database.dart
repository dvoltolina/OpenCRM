import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/appointments_table.dart';
import 'tables/clients_table.dart';
import 'tables/time_entries_table.dart';
import 'tables/sync_queue_table.dart';
import 'daos/appointments_dao.dart';
import 'daos/time_entries_dao.dart';
import 'daos/sync_queue_dao.dart';
import '../../core/security/secure_storage_service.dart';

part 'staff_database.g.dart';

/// Staff App local SQLite database using Drift.
///
/// Provides offline storage for appointments, clients, time entries,
/// and a sync queue for pending changes.
@DriftDatabase(
  tables: [
    AppointmentsTable,
    ClientsTable,
    TimeEntriesTable,
    SyncQueueTable,
  ],
  daos: [
    AppointmentsDao,
    TimeEntriesDao,
    SyncQueueDao,
  ],
)
class StaffDatabase extends _$StaffDatabase {
  /// Creates a new database instance.
  ///
  /// Uses [_openConnection] to create a lazy database connection
  /// that initializes the SQLite file in the app documents directory.
  StaffDatabase() : super(_openConnection());

  /// Creates a database instance with a custom query executor.
  ///
  /// Useful for testing with in-memory databases.
  StaffDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  /// Opens an encrypted connection to the SQLite database file.
  ///
  /// The database file is stored in the app's documents directory
  /// as 'staff_app.sqlite'. Uses SQLCipher for 256-bit AES encryption
  /// with a key stored in secure platform storage.
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'staff_app.sqlite'));

      // Get or generate encryption key from secure storage
      final key = await SecureStorageService.instance.getOrCreateDatabaseKey();

      return NativeDatabase.createInBackground(
        file,
        setup: (db) {
          // Enable SQLCipher encryption with the secure key
          // Using PRAGMA key with hex encoding for safety
          db.execute("PRAGMA key = '$key'");
          // Use SQLCipher 4 defaults for strong encryption
          db.execute('PRAGMA cipher_page_size = 4096');
          db.execute('PRAGMA kdf_iter = 256000');
          db.execute('PRAGMA cipher_memory_security = ON');
        },
      );
    });
  }

  /// Opens an unencrypted database for testing/migration.
  // ignore: unused_element
  static LazyDatabase _openUnencryptedConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'staff_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(appointmentsTable, appointmentsTable.staffId);
          }
          if (from < 3) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_appointments_business_staff_start '
              'ON appointments_table (business_id, staff_id, start_time)',
            );
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Deletes all data from all tables.
  ///
  /// Used for logout/clear data functionality.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(syncQueueTable).go();
      await delete(timeEntriesTable).go();
      await delete(appointmentsTable).go();
      await delete(clientsTable).go();
    });
  }

  /// Gets the count of all records across tables.
  ///
  /// Useful for debugging and storage stats.
  Future<Map<String, int>> getRecordCounts() async {
    final appointments =
        await (selectOnly(appointmentsTable)..addColumns([countAll()]))
            .map((row) => row.read(countAll()))
            .getSingle();
    final clients = await (selectOnly(clientsTable)..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();
    final timeEntries =
        await (selectOnly(timeEntriesTable)..addColumns([countAll()]))
            .map((row) => row.read(countAll()))
            .getSingle();
    final syncQueue =
        await (selectOnly(syncQueueTable)..addColumns([countAll()]))
            .map((row) => row.read(countAll()))
            .getSingle();

    return {
      'appointments': appointments ?? 0,
      'clients': clients ?? 0,
      'timeEntries': timeEntries ?? 0,
      'syncQueue': syncQueue ?? 0,
    };
  }
}
