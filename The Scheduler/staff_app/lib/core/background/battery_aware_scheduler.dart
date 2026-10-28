import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimum battery level for background sync (15%).
const _minBatteryLevel = 15;

/// Reduced sync battery threshold (30%).
const _reducedSyncBatteryLevel = 30;

/// Key for storing last sync time in preferences.
const _lastScheduledSyncKey = 'last_scheduled_sync';

/// Interval between scheduled syncs when battery is low.
const _reducedSyncInterval = Duration(hours: 1);

/// Result of a sync eligibility check.
enum SyncEligibility {
  /// Sync should proceed normally.
  allowed,

  /// Sync allowed but should be minimal (battery conservation).
  reducedMode,

  /// Sync should be skipped (battery too low).
  batteryTooLow,

  /// Sync skipped due to scheduling (already synced recently).
  recentlySynced,

  /// User forced sync regardless of battery.
  forcedByUser,
}

/// Service that manages sync scheduling based on battery state.
///
/// Implements battery-aware sync policies to preserve device battery
/// while ensuring data is synchronized regularly.
class BatteryAwareScheduler {
  BatteryAwareScheduler();

  final _battery = Battery();
  bool _forceNextSync = false;

  /// Forces the next sync to proceed regardless of battery level.
  void forceNextSync() {
    _forceNextSync = true;
  }

  /// Checks if a sync should proceed based on current battery state.
  Future<SyncEligibility> shouldSync() async {
    // Check if user forced sync
    if (_forceNextSync) {
      _forceNextSync = false;
      return SyncEligibility.forcedByUser;
    }

    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      // Always allow sync if device is charging
      if (batteryState == BatteryState.charging ||
          batteryState == BatteryState.full) {
        return SyncEligibility.allowed;
      }

      // Don't sync if battery is critically low
      if (batteryLevel < _minBatteryLevel) {
        return SyncEligibility.batteryTooLow;
      }

      // Reduce sync frequency when battery is low
      if (batteryLevel < _reducedSyncBatteryLevel) {
        final shouldSyncNow = await _isScheduledSyncTime();
        if (!shouldSyncNow) {
          return SyncEligibility.recentlySynced;
        }
        return SyncEligibility.reducedMode;
      }

      // Battery is good, allow sync
      return SyncEligibility.allowed;
    } catch (e) {
      // If battery check fails, allow sync (fail open)
      return SyncEligibility.allowed;
    }
  }

  /// Gets the current battery level.
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return -1; // Unknown
    }
  }

  /// Gets the current battery state.
  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  /// Checks if enough time has passed since the last scheduled sync.
  Future<bool> _isScheduledSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_lastScheduledSyncKey);

      if (lastSyncMs == null) {
        return true; // Never synced, should sync now
      }

      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      final elapsed = DateTime.now().difference(lastSync);

      return elapsed >= _reducedSyncInterval;
    } catch (e) {
      return true; // Error checking, allow sync
    }
  }

  /// Records that a scheduled sync occurred.
  Future<void> recordScheduledSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastScheduledSyncKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Gets sync recommendations for UI display.
  Future<SyncRecommendation> getSyncRecommendation() async {
    final eligibility = await shouldSync();
    final batteryLevel = await getBatteryLevel();
    final batteryState = await getBatteryState();

    return SyncRecommendation(
      eligibility: eligibility,
      batteryLevel: batteryLevel,
      isCharging: batteryState == BatteryState.charging ||
          batteryState == BatteryState.full,
      message: _getRecommendationMessage(eligibility, batteryLevel),
    );
  }

  String _getRecommendationMessage(SyncEligibility eligibility, int level) {
    switch (eligibility) {
      case SyncEligibility.allowed:
        return 'Sync ready';
      case SyncEligibility.reducedMode:
        return 'Battery at $level% - reduced sync mode';
      case SyncEligibility.batteryTooLow:
        return 'Battery too low ($level%) - sync paused';
      case SyncEligibility.recentlySynced:
        return 'Recently synced - saving battery';
      case SyncEligibility.forcedByUser:
        return 'Manual sync requested';
    }
  }

  /// Listens to battery state changes.
  Stream<BatteryState> get onBatteryStateChanged {
    return _battery.onBatteryStateChanged;
  }
}

/// Sync recommendation for display in UI.
class SyncRecommendation {
  const SyncRecommendation({
    required this.eligibility,
    required this.batteryLevel,
    required this.isCharging,
    required this.message,
  });

  final SyncEligibility eligibility;
  final int batteryLevel;
  final bool isCharging;
  final String message;

  /// Whether sync is currently allowed.
  bool get canSync =>
      eligibility == SyncEligibility.allowed ||
      eligibility == SyncEligibility.reducedMode ||
      eligibility == SyncEligibility.forcedByUser;
}
