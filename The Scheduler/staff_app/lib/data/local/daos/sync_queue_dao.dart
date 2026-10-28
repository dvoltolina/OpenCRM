import 'package:drift/drift.dart';

import '../staff_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// Data Access Object for sync queue table operations.
///
/// Manages the queue of pending changes to be synced to Firestore
/// when the device comes online.
@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<StaffDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Gets all pending sync items ordered by creation time.
  ///
  /// Oldest items are processed first (FIFO).
  Future<List<SyncQueueTableData>> getPendingItems() {
    return (select(syncQueueTable)
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Gets pending items with retry count less than max retries.
  ///
  /// Items that have failed too many times are excluded.
  Future<List<SyncQueueTableData>> getPendingItemsWithRetryLimit(
      int maxRetries) {
    return (select(syncQueueTable)
          ..where((q) => q.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Adds a new item to the sync queue.
  Future<int> addToQueue(SyncQueueTableCompanion item) {
    return into(syncQueueTable).insert(item);
  }

  /// Removes an item from the sync queue by ID.
  ///
  /// Called after successful sync.
  Future<void> removeFromQueue(int id) {
    return (delete(syncQueueTable)..where((q) => q.id.equals(id))).go();
  }

  /// Increments retry count and records error message.
  ///
  /// Called when sync fails for an item.
  Future<void> incrementRetryCount(int id, String error) {
    return customUpdate(
      'UPDATE sync_queue_table '
      'SET retry_count = retry_count + 1, '
      'last_error = ?, '
      'last_attempt_at = ? '
      'WHERE id = ?',
      variables: [
        Variable.withString(error),
        Variable.withDateTime(DateTime.now()),
        Variable.withInt(id),
      ],
      updates: {syncQueueTable},
    );
  }

  /// Gets the total count of items in the queue.
  Future<int> getQueueCount() async {
    final result = await (selectOnly(syncQueueTable)..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();
    return result ?? 0;
  }

  /// Gets count of items for a specific entity type.
  Future<int> getQueueCountByType(String entityType) async {
    final result = await (selectOnly(syncQueueTable)
          ..addColumns([countAll()])
          ..where(syncQueueTable.entityType.equals(entityType)))
        .map((row) => row.read(countAll()))
        .getSingle();
    return result ?? 0;
  }

  /// Clears items that have exceeded max retries.
  ///
  /// These items have failed too many times and are considered
  /// permanently failed. They should be logged/reported.
  Future<int> clearOldFailedItems(int maxRetries) {
    return (delete(syncQueueTable)
          ..where((q) => q.retryCount.isBiggerOrEqualValue(maxRetries)))
        .go();
  }

  /// Gets items that have exceeded max retries for logging/reporting.
  Future<List<SyncQueueTableData>> getFailedItems(int maxRetries) {
    return (select(syncQueueTable)
          ..where((q) => q.retryCount.isBiggerOrEqualValue(maxRetries)))
        .get();
  }

  /// Clears all items in the queue.
  ///
  /// Used for logout/clear data.
  Future<int> clearAll() {
    return delete(syncQueueTable).go();
  }

  /// Checks if there are any pending items for an entity.
  Future<bool> hasPendingSync(String entityType, String entityId) async {
    final result = await (select(syncQueueTable)
          ..where((q) => q.entityType.equals(entityType))
          ..where((q) => q.entityId.equals(entityId))
          ..limit(1))
        .getSingleOrNull();
    return result != null;
  }

  /// Removes all pending items for a specific entity.
  ///
  /// Useful when an entity is deleted locally.
  Future<int> removeAllForEntity(String entityType, String entityId) {
    return (delete(syncQueueTable)
          ..where((q) => q.entityType.equals(entityType))
          ..where((q) => q.entityId.equals(entityId)))
        .go();
  }

  /// Gets the most recent item for an entity (to avoid duplicate queuing).
  Future<SyncQueueTableData?> getLatestForEntity(
      String entityType, String entityId) {
    return (select(syncQueueTable)
          ..where((q) => q.entityType.equals(entityType))
          ..where((q) => q.entityId.equals(entityId))
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Updates the action for an existing queue item.
  ///
  /// Used when a newer action supersedes an older one.
  Future<void> updateAction(int id, String action, String payload) {
    return (update(syncQueueTable)..where((q) => q.id.equals(id))).write(
      SyncQueueTableCompanion(
        action: Value(action),
        payload: Value(payload),
      ),
    );
  }
}
