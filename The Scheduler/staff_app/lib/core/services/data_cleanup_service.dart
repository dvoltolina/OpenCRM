import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/local/staff_database.dart';

/// Default retention period for appointments (30 days).
const _defaultAppointmentRetention = Duration(days: 30);

/// Default retention period for time entries (90 days).
const _defaultTimeEntryRetention = Duration(days: 90);

/// Storage statistics for the local database.
class StorageStats {
  const StorageStats({
    required this.totalSizeBytes,
    required this.appointmentCount,
    required this.clientCount,
    required this.timeEntryCount,
    required this.syncQueueCount,
    required this.pendingSyncCount,
  });

  final int totalSizeBytes;
  final int appointmentCount;
  final int clientCount;
  final int timeEntryCount;
  final int syncQueueCount;
  final int pendingSyncCount;

  /// Total size in human-readable format.
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Total record count.
  int get totalRecords =>
      appointmentCount + clientCount + timeEntryCount + syncQueueCount;
}

/// Result of a cleanup operation.
class CleanupResult {
  const CleanupResult({
    required this.appointmentsDeleted,
    required this.timeEntriesDeleted,
    required this.syncQueueDeleted,
    required this.clientsDeleted,
    required this.bytesFreed,
    required this.duration,
    this.errors = const [],
  });

  final int appointmentsDeleted;
  final int timeEntriesDeleted;
  final int syncQueueDeleted;
  final int clientsDeleted;
  final int bytesFreed;
  final Duration duration;
  final List<String> errors;

  /// Total records deleted.
  int get totalDeleted =>
      appointmentsDeleted +
      timeEntriesDeleted +
      syncQueueDeleted +
      clientsDeleted;

  /// Whether any cleanup occurred.
  bool get hasCleanup => totalDeleted > 0;

  /// Whether any errors occurred.
  bool get hasErrors => errors.isNotEmpty;
}

/// Service for cleaning up old data from the local database.
///
/// Implements data retention policies to:
/// - Keep database size manageable
/// - Remove stale data that's no longer needed
/// - Never delete pending sync items
/// - Preserve data needed for compliance
class DataCleanupService {
  DataCleanupService(this._db);

  final StaffDatabase _db;

  /// Deletes appointments older than the retention period.
  ///
  /// Only deletes appointments that:
  /// - Are older than [retention] period
  /// - Have been synced (not pending sync)
  Future<int> cleanupOldAppointments({
    Duration retention = _defaultAppointmentRetention,
  }) async {
    try {
      return await _db.appointmentsDao.deleteOldAppointments(
        retention.inDays,
      );
    } catch (e) {
      return 0;
    }
  }

  /// Deletes old time entries that have been synced.
  ///
  /// Only deletes entries that:
  /// - Are older than [retention] period
  /// - Have been synced (not pending sync)
  /// - Have clock out time (completed entries only)
  Future<int> cleanupOldTimeEntries({
    Duration retention = _defaultTimeEntryRetention,
  }) async {
    final cutoffDays = retention.inDays;

    try {
      return await _db.timeEntriesDao.deleteOldEntries(cutoffDays);
    } catch (e) {
      return 0;
    }
  }

  /// Deletes failed items from the sync queue.
  ///
  /// Removes items that have exceeded max retries (permanently failed).
  /// Successfully synced items are already removed by the sync engine.
  Future<int> cleanupSyncQueue({
    int maxRetries = 5,
  }) async {
    try {
      return await _db.syncQueueDao.clearOldFailedItems(maxRetries);
    } catch (e) {
      return 0;
    }
  }

  /// Deletes orphaned client records with no associated appointments.
  ///
  /// Only deletes clients that:
  /// - Have no appointments in the database
  /// - Were created more than 7 days ago (grace period)
  Future<int> cleanupOrphanedClients() async {
    try {
      // This would require a custom query - simplified for now
      // In practice, would use a LEFT JOIN to find orphans
      return 0; // Implement when needed
    } catch (e) {
      return 0;
    }
  }

  /// Gets current storage statistics.
  Future<StorageStats> getStorageStats() async {
    final counts = await _db.getRecordCounts();
    final dbSize = await _getDatabaseFileSize();
    final pendingCount = await _getPendingSyncCount();

    return StorageStats(
      totalSizeBytes: dbSize,
      appointmentCount: counts['appointments'] ?? 0,
      clientCount: counts['clients'] ?? 0,
      timeEntryCount: counts['timeEntries'] ?? 0,
      syncQueueCount: counts['syncQueue'] ?? 0,
      pendingSyncCount: pendingCount,
    );
  }

  /// Runs all cleanup tasks and returns combined results.
  Future<CleanupResult> performFullCleanup({
    Duration appointmentRetention = _defaultAppointmentRetention,
    Duration timeEntryRetention = _defaultTimeEntryRetention,
    int syncQueueMaxRetries = 5,
  }) async {
    final stopwatch = Stopwatch()..start();
    final errors = <String>[];

    final sizeBefore = await _getDatabaseFileSize();

    // Run all cleanup tasks
    int appointmentsDeleted = 0;
    int timeEntriesDeleted = 0;
    int syncQueueDeleted = 0;
    int clientsDeleted = 0;

    try {
      appointmentsDeleted = await cleanupOldAppointments(
        retention: appointmentRetention,
      );
    } catch (e) {
      errors.add('Appointment cleanup failed: $e');
    }

    try {
      timeEntriesDeleted = await cleanupOldTimeEntries(
        retention: timeEntryRetention,
      );
    } catch (e) {
      errors.add('Time entry cleanup failed: $e');
    }

    try {
      syncQueueDeleted = await cleanupSyncQueue(
        maxRetries: syncQueueMaxRetries,
      );
    } catch (e) {
      errors.add('Sync queue cleanup failed: $e');
    }

    try {
      clientsDeleted = await cleanupOrphanedClients();
    } catch (e) {
      errors.add('Client cleanup failed: $e');
    }

    // Vacuum database to reclaim space
    try {
      await _vacuumDatabase();
    } catch (e) {
      errors.add('Database vacuum failed: $e');
    }

    final sizeAfter = await _getDatabaseFileSize();
    final bytesFreed = sizeBefore - sizeAfter;

    stopwatch.stop();

    return CleanupResult(
      appointmentsDeleted: appointmentsDeleted,
      timeEntriesDeleted: timeEntriesDeleted,
      syncQueueDeleted: syncQueueDeleted,
      clientsDeleted: clientsDeleted,
      bytesFreed: bytesFreed > 0 ? bytesFreed : 0,
      duration: stopwatch.elapsed,
      errors: errors,
    );
  }

  /// Clears all local data (for logout or wipe).
  Future<void> clearAllData() async {
    await _db.clearAllData();
  }

  // Private helpers

  Future<int> _getDatabaseFileSize() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/staff_app.sqlite');

      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getPendingSyncCount() async {
    try {
      final items = await _db.syncQueueDao.getPendingItems();
      return items.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _vacuumDatabase() async {
    try {
      await _db.customStatement('VACUUM');
    } catch (e) {
      // Vacuum may fail if database is busy - that's OK
    }
  }
}
