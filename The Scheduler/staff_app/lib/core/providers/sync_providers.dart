import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/sync_engine.dart';
import '../offline/connectivity_monitor.dart';
import 'database_provider.dart';
import 'auth_providers.dart';

/// Enum representing the current sync status.
enum SyncStatus {
  /// No sync in progress, everything up to date
  idle,

  /// Currently syncing data
  syncing,

  /// Sync encountered an error
  error,

  /// Device is offline
  offline,
}

/// Provider for connectivity state stream.
///
/// Emits true when online, false when offline.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result != ConnectivityResult.none;
  });
});

/// Provider for checking if currently online.
///
/// Convenience provider that returns a simple bool.
/// Defaults to true to avoid blocking UI on first load.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.valueOrNull ?? true;
});

/// Provider for the connectivity monitor instance.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor();

  // Auto-initialize when first accessed
  monitor.initialize();

  ref.onDispose(() => monitor.dispose());

  return monitor;
});

/// Provider for the sync engine instance.
///
/// Requires authenticated staff user to be available.
/// Returns null if user is not authenticated.
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final db = ref.watch(databaseProvider);
  final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;

  if (staffUser == null) {
    return null;
  }

  final engine = SyncEngine(
    db: db,
    firestore: FirebaseFirestore.instance,
    staffId: staffUser.providerId,
    businessId: staffUser.businessId,
  );

  ref.onDispose(() => engine.dispose());

  return engine;
});

/// Provider for sync engine initialization.
///
/// Returns a future that completes when sync engine is initialized.
/// Returns false if user is not authenticated.
final syncEngineInitializedProvider = FutureProvider<bool>((ref) async {
  final engine = ref.watch(syncEngineProvider);

  if (engine == null) {
    return false;
  }

  if (!engine.isInitialized) {
    await engine.initialize();
  }

  return engine.isInitialized;
});

/// State notifier for sync status management.
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.idle);

  /// Updates the sync status.
  void setStatus(SyncStatus status) {
    state = status;
  }

  /// Sets status to syncing.
  void startSync() {
    state = SyncStatus.syncing;
  }

  /// Sets status to idle.
  void completeSync() {
    state = SyncStatus.idle;
  }

  /// Sets status to error.
  void setError() {
    state = SyncStatus.error;
  }

  /// Sets status to offline.
  void setOffline() {
    state = SyncStatus.offline;
  }
}

/// Provider for sync status state.
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  final notifier = SyncStatusNotifier();
  final engine = ref.watch(syncEngineProvider);

  if (engine != null) {
    // Listen to engine status changes
    engine.onStatusChange = (engineStatus) {
      switch (engineStatus) {
        case SyncEngineStatus.idle:
          notifier.completeSync();
          break;
        case SyncEngineStatus.syncing:
          notifier.startSync();
          break;
        case SyncEngineStatus.error:
          notifier.setError();
          break;
        case SyncEngineStatus.offline:
          notifier.setOffline();
          break;
        case SyncEngineStatus.uninitialized:
          // Keep current state
          break;
      }
    };
  }

  // Also watch connectivity and update status accordingly
  final isOnline = ref.watch(isOnlineProvider);
  if (!isOnline) {
    // Use a microtask to avoid setting state during provider initialization
    Future.microtask(() => notifier.setOffline());
  }

  return notifier;
});

/// Provider for count of pending sync items.
///
/// Watches the sync queue count and updates reactively.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.syncQueueDao.getQueueCount();
});

/// Provider for streaming pending sync count.
///
/// Updates more frequently when queue changes.
final pendingSyncCountStreamProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);

  // Poll every 5 seconds for simplicity
  // In production, could use database triggers
  return Stream.periodic(
    const Duration(seconds: 5),
    (_) => db.syncQueueDao.getQueueCount(),
  ).asyncMap((future) => future);
});

/// State notifier for last sync time.
class LastSyncTimeNotifier extends StateNotifier<DateTime?> {
  LastSyncTimeNotifier() : super(null);

  /// Updates the last sync time.
  void update(DateTime? time) {
    state = time;
  }

  /// Sets to current time.
  void setNow() {
    state = DateTime.now();
  }
}

/// Provider for last successful sync timestamp.
final lastSyncTimeProvider = StateNotifierProvider<LastSyncTimeNotifier, DateTime?>((ref) {
  final notifier = LastSyncTimeNotifier();
  final engine = ref.watch(syncEngineProvider);

  if (engine != null && engine.lastSyncTime != null) {
    notifier.update(engine.lastSyncTime);
  }

  return notifier;
});

/// Provider for manual sync trigger.
///
/// Call this to force an immediate sync.
final forceSyncProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final engine = ref.read(syncEngineProvider);
    if (engine != null) {
      await engine.forceSync();
      ref.read(lastSyncTimeProvider.notifier).setNow();
    }
  };
});

/// Provider for sync error messages.
final syncErrorProvider = StateProvider<String?>((ref) => null);

/// Provider that combines sync state into a single object.
final syncStateProvider = Provider<SyncState>((ref) {
  final status = ref.watch(syncStatusProvider);
  final pendingCount = ref.watch(pendingSyncCountProvider);
  final lastSyncTime = ref.watch(lastSyncTimeProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final error = ref.watch(syncErrorProvider);

  return SyncState(
    status: status,
    pendingCount: pendingCount.valueOrNull ?? 0,
    lastSyncTime: lastSyncTime,
    isOnline: isOnline,
    error: error,
  );
});

/// Immutable state object for sync information.
class SyncState {
  const SyncState({
    required this.status,
    required this.pendingCount,
    this.lastSyncTime,
    required this.isOnline,
    this.error,
  });

  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final bool isOnline;
  final String? error;

  /// Whether there are items waiting to be synced.
  bool get hasPendingSync => pendingCount > 0;

  /// Whether sync is currently in progress.
  bool get isSyncing => status == SyncStatus.syncing;

  /// Whether there was a sync error.
  bool get hasError => status == SyncStatus.error || error != null;

  /// User-friendly status message.
  String get statusMessage {
    if (!isOnline) return 'Offline';
    if (isSyncing) return 'Syncing...';
    if (hasError) return error ?? 'Sync error';
    if (hasPendingSync) return '$pendingCount pending';
    return 'Synced';
  }
}

/// Supported sync interval options.
enum SyncInterval {
  /// Sync every minute (battery intensive)
  everyMinute(Duration(minutes: 1), '1 minute'),

  /// Sync every 5 minutes (default)
  every5Minutes(Duration(minutes: 5), '5 minutes'),

  /// Sync every 15 minutes (battery saver)
  every15Minutes(Duration(minutes: 15), '15 minutes'),

  /// Sync every 30 minutes (minimal)
  every30Minutes(Duration(minutes: 30), '30 minutes'),

  /// Manual sync only
  manual(Duration.zero, 'Manual only');

  const SyncInterval(this.duration, this.displayName);

  final Duration duration;
  final String displayName;
}

/// Provider for sync interval preference.
///
/// Stores the user's preferred sync interval.
/// Defaults to 5 minutes.
final syncIntervalProvider = StateProvider<SyncInterval>((ref) {
  return SyncInterval.every5Minutes;
});

/// Provider to update sync interval.
///
/// Updates the preference. Note: Actual sync engine interval update
/// would require restarting the engine or adding dynamic interval support.
final updateSyncIntervalProvider = Provider<void Function(SyncInterval)>((ref) {
  return (SyncInterval interval) {
    ref.read(syncIntervalProvider.notifier).state = interval;
    // TODO: Implement dynamic interval update in SyncEngine
    // For now, preference is stored but engine uses StaffAppConfig.syncInterval
  };
});
