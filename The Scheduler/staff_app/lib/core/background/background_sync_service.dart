import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import 'battery_aware_scheduler.dart';
import '../services/data_cleanup_service.dart';

/// Background task identifiers.
const _periodicSyncTaskName = 'staffAppPeriodicSync';
const _immediateTaskName = 'staffAppImmediateSync';
const _cleanupTaskName = 'staffAppCleanup';

/// Background sync configuration.
class BackgroundSyncConfig {
  const BackgroundSyncConfig({
    this.syncInterval = const Duration(minutes: 15),
    this.cleanupInterval = const Duration(hours: 24),
    this.requiresNetwork = true,
    this.requiresBatteryNotLow = true,
    this.requiresCharging = false,
  });

  /// How often to run background sync.
  final Duration syncInterval;

  /// How often to run cleanup tasks.
  final Duration cleanupInterval;

  /// Whether network connectivity is required.
  final bool requiresNetwork;

  /// Whether battery must be above low threshold.
  final bool requiresBatteryNotLow;

  /// Whether device must be charging (more aggressive for periodic).
  final bool requiresCharging;

  /// Default config for normal usage.
  static const standard = BackgroundSyncConfig();

  /// Config for aggressive sync (when user prefers fresh data).
  static const aggressive = BackgroundSyncConfig(
    requiresBatteryNotLow: false,
  );

  /// Config for battery-saver mode.
  static const batterySaver = BackgroundSyncConfig(
    syncInterval: Duration(hours: 1),
    requiresCharging: true,
  );
}

/// Status of the background sync service.
enum BackgroundSyncStatus {
  /// Service not initialized.
  uninitialized,

  /// Service initialized and running.
  running,

  /// Service paused (user preference or system).
  paused,

  /// Service stopped.
  stopped,

  /// Error occurred during initialization.
  error,
}

/// Result of a background sync operation.
class BackgroundSyncResult {
  const BackgroundSyncResult({
    required this.success,
    required this.itemsSynced,
    required this.itemsFailed,
    required this.duration,
    this.error,
    this.cleanupResult,
  });

  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final Duration duration;
  final String? error;
  final CleanupResult? cleanupResult;

  /// Creates a success result.
  factory BackgroundSyncResult.success({
    required int itemsSynced,
    required Duration duration,
    CleanupResult? cleanupResult,
  }) {
    return BackgroundSyncResult(
      success: true,
      itemsSynced: itemsSynced,
      itemsFailed: 0,
      duration: duration,
      cleanupResult: cleanupResult,
    );
  }

  /// Creates a failure result.
  factory BackgroundSyncResult.failure({
    required String error,
    int itemsSynced = 0,
    int itemsFailed = 0,
    required Duration duration,
  }) {
    return BackgroundSyncResult(
      success: false,
      itemsSynced: itemsSynced,
      itemsFailed: itemsFailed,
      duration: duration,
      error: error,
    );
  }
}

/// Platform-agnostic background sync service.
///
/// Handles scheduling and executing background sync tasks on both
/// Android (WorkManager) and iOS (BGTaskScheduler via WorkManager plugin).
class BackgroundSyncService {
  BackgroundSyncService._();
  static final BackgroundSyncService instance = BackgroundSyncService._();

  BackgroundSyncStatus _status = BackgroundSyncStatus.uninitialized;
  BackgroundSyncStatus get status => _status;

  final _batteryScheduler = BatteryAwareScheduler();
  BackgroundSyncConfig _config = BackgroundSyncConfig.standard;

  /// Callback for sync progress updates.
  void Function(String message)? onProgress;

  /// Callback when sync completes.
  void Function(BackgroundSyncResult result)? onComplete;

  /// Initializes the background sync service.
  ///
  /// Must be called during app startup before scheduling tasks.
  Future<void> initialize({
    BackgroundSyncConfig config = BackgroundSyncConfig.standard,
    bool isDebugMode = false,
  }) async {
    _config = config;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: isDebugMode,
      );
      _status = BackgroundSyncStatus.running;
    } catch (e) {
      _status = BackgroundSyncStatus.error;
      rethrow;
    }
  }

  /// Schedules periodic background sync.
  Future<void> schedulePeriodicSync() async {
    if (_status != BackgroundSyncStatus.running) {
      throw StateError('BackgroundSyncService not initialized');
    }

    await Workmanager().registerPeriodicTask(
      _periodicSyncTaskName,
      _periodicSyncTaskName,
      frequency: _config.syncInterval,
      constraints: Constraints(
        networkType:
            _config.requiresNetwork ? NetworkType.connected : NetworkType.not_required,
        requiresBatteryNotLow: _config.requiresBatteryNotLow,
        requiresCharging: _config.requiresCharging,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      initialDelay: const Duration(minutes: 1),
    );
  }

  /// Cancels scheduled periodic sync.
  Future<void> cancelScheduledSync() async {
    await Workmanager().cancelByUniqueName(_periodicSyncTaskName);
  }

  /// Requests an immediate one-time sync.
  Future<void> requestImmediateSync() async {
    if (_status != BackgroundSyncStatus.running) {
      throw StateError('BackgroundSyncService not initialized');
    }

    // Force sync regardless of battery
    _batteryScheduler.forceNextSync();

    await Workmanager().registerOneOffTask(
      '${_immediateTaskName}_${DateTime.now().millisecondsSinceEpoch}',
      _immediateTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Schedules periodic cleanup task.
  Future<void> scheduleCleanup() async {
    if (_status != BackgroundSyncStatus.running) {
      throw StateError('BackgroundSyncService not initialized');
    }

    await Workmanager().registerPeriodicTask(
      _cleanupTaskName,
      _cleanupTaskName,
      frequency: _config.cleanupInterval,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
        requiresCharging: true, // Only cleanup when charging
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// Cancels all scheduled tasks.
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    _status = BackgroundSyncStatus.stopped;
  }

  /// Pauses background sync (keeps registration but won't execute).
  void pause() {
    _status = BackgroundSyncStatus.paused;
  }

  /// Resumes background sync.
  void resume() {
    if (_status == BackgroundSyncStatus.paused) {
      _status = BackgroundSyncStatus.running;
    }
  }

  /// Updates the sync configuration.
  Future<void> updateConfig(BackgroundSyncConfig config) async {
    _config = config;
    // Re-register with new config
    await cancelScheduledSync();
    await schedulePeriodicSync();
  }

  /// Gets the battery-aware scheduler for UI.
  BatteryAwareScheduler get batteryScheduler => _batteryScheduler;

  /// Checks if sync is currently allowed.
  Future<bool> canSyncNow() async {
    // Check service status
    if (_status != BackgroundSyncStatus.running) {
      return false;
    }

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return false;
    }

    // Check battery
    final eligibility = await _batteryScheduler.shouldSync();
    return eligibility == SyncEligibility.allowed ||
        eligibility == SyncEligibility.reducedMode ||
        eligibility == SyncEligibility.forcedByUser;
  }
}

/// Background task callback dispatcher.
///
/// This runs in a separate isolate, so it must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        // No network, skip sync but don't fail (will retry)
        return true;
      }

      // Check battery (unless forced)
      final batteryScheduler = BatteryAwareScheduler();
      final eligibility = await batteryScheduler.shouldSync();

      if (eligibility == SyncEligibility.batteryTooLow) {
        // Battery too low, skip but don't fail
        return true;
      }

      // Execute task based on type
      switch (taskName) {
        case _periodicSyncTaskName:
        case _immediateTaskName:
          return await _performBackgroundSync(
            reducedMode: eligibility == SyncEligibility.reducedMode,
          );

        case _cleanupTaskName:
          return await _performBackgroundCleanup();

        default:
          return true;
      }
    } catch (e) {
      // Return false to indicate failure (WorkManager will retry)
      return false;
    }
  });
}

/// Performs the actual background sync.
///
/// This is called from the background isolate.
Future<bool> _performBackgroundSync({bool reducedMode = false}) async {
  // Note: In a real implementation, this would:
  // 1. Initialize the database
  // 2. Get pending sync items
  // 3. Upload to Firestore
  // 4. Download new data
  // 5. Resolve conflicts
  // 6. Update local database

  // Simplified implementation - actual sync logic would use SyncEngine
  try {
    // Record sync time
    final batteryScheduler = BatteryAwareScheduler();
    await batteryScheduler.recordScheduledSync();

    return true;
  } catch (e) {
    return false;
  }
}

/// Performs background cleanup.
Future<bool> _performBackgroundCleanup() async {
  // Note: In a real implementation, this would initialize
  // the database and run DataCleanupService

  try {
    // Cleanup would run here
    return true;
  } catch (e) {
    return false;
  }
}

/// iOS-specific background configuration.
///
/// Add these to your Info.plist:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///   <string>fetch</string>
///   <string>processing</string>
/// </array>
/// <key>BGTaskSchedulerPermittedIdentifiers</key>
/// <array>
///   <string>com.yourapp.staffAppPeriodicSync</string>
///   <string>com.yourapp.staffAppCleanup</string>
/// </array>
/// ```
class IOSBackgroundConfig {
  /// Identifier prefix for iOS background tasks.
  static const identifierPrefix = 'com.scheduler.staff';

  /// Gets the full task identifier for iOS.
  static String getTaskIdentifier(String taskName) {
    return '$identifierPrefix.$taskName';
  }
}

/// Android-specific background configuration.
///
/// Add to your AndroidManifest.xml inside the `application` block:
/// ```xml
/// <provider
///     android:name="androidx.startup.InitializationProvider"
///     android:authorities="${applicationId}.androidx-startup"
///     tools:node="merge">
///     <meta-data
///         android:name="androidx.work.WorkManagerInitializer"
///         android:value="androidx.startup" />
/// </provider>
/// ```
class AndroidBackgroundConfig {
  /// Whether to use expedited work for urgent syncs (Android 12+).
  static const useExpeditedWork = true;

  /// Backoff policy for failed tasks.
  static const backoffPolicy = BackoffPolicy.exponential;

  /// Initial backoff delay.
  static const initialBackoffDelay = Duration(seconds: 30);
}
