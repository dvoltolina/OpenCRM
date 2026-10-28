// Battery-Aware Sync for Staff App
//
// Monitors battery level and adjusts sync behavior to preserve
// battery life. Reduces sync frequency on low battery.

import 'dart:async';

import 'package:battery_plus/battery_plus.dart' as battery_plus;
import 'package:flutter/foundation.dart';

/// Battery level thresholds.
enum BatteryLevel {
  /// Battery is critically low (< 10%).
  critical,

  /// Battery is low (10-20%).
  low,

  /// Battery is normal (20-50%).
  normal,

  /// Battery is good (> 50%).
  good,
}

/// Battery state for sync decisions.
class BatteryState {
  const BatteryState({
    required this.level,
    required this.percentage,
    required this.isCharging,
    required this.timestamp,
  });

  /// Categorized battery level.
  final BatteryLevel level;

  /// Exact battery percentage (0-100).
  final int percentage;

  /// Whether device is currently charging.
  final bool isCharging;

  /// When this state was captured.
  final DateTime timestamp;

  /// Whether sync should be aggressive.
  bool get allowAggressiveSync => isCharging || level == BatteryLevel.good;

  /// Whether sync should be minimal.
  bool get shouldMinimizeSync => !isCharging && level == BatteryLevel.critical;

  /// Whether background sync is allowed.
  bool get allowBackgroundSync =>
      isCharging || level.index >= BatteryLevel.low.index;

  @override
  String toString() =>
      'BatteryState($percentage%, charging: $isCharging, level: $level)';
}

/// Configuration for battery-aware sync.
class BatteryAwareSyncConfig {
  const BatteryAwareSyncConfig({
    this.criticalThreshold = 10,
    this.lowThreshold = 20,
    this.normalThreshold = 50,
    this.criticalSyncInterval = const Duration(minutes: 30),
    this.lowSyncInterval = const Duration(minutes: 15),
    this.normalSyncInterval = const Duration(minutes: 5),
    this.goodSyncInterval = const Duration(minutes: 2),
    this.chargingSyncInterval = const Duration(minutes: 1),
    this.disableSyncOnCritical = false,
  });

  /// Battery percentage considered critical.
  final int criticalThreshold;

  /// Battery percentage considered low.
  final int lowThreshold;

  /// Battery percentage considered normal.
  final int normalThreshold;

  /// Sync interval when battery is critical.
  final Duration criticalSyncInterval;

  /// Sync interval when battery is low.
  final Duration lowSyncInterval;

  /// Sync interval when battery is normal.
  final Duration normalSyncInterval;

  /// Sync interval when battery is good.
  final Duration goodSyncInterval;

  /// Sync interval when charging.
  final Duration chargingSyncInterval;

  /// Whether to completely disable sync on critical battery.
  final bool disableSyncOnCritical;

  /// Default configuration.
  static const defaultConfig = BatteryAwareSyncConfig();
}

/// Service for battery-aware sync management.
class BatteryAwareSyncService {
  BatteryAwareSyncService._();
  static final BatteryAwareSyncService instance = BatteryAwareSyncService._();

  final battery_plus.Battery _battery = battery_plus.Battery();
  final _stateController = StreamController<BatteryState>.broadcast();

  BatteryState _currentState = BatteryState(
    level: BatteryLevel.good,
    percentage: 100,
    isCharging: false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  BatteryAwareSyncConfig _config = BatteryAwareSyncConfig.defaultConfig;

  StreamSubscription<battery_plus.BatteryState>? _batterySubscription;
  Timer? _checkTimer;

  /// Current battery state.
  BatteryState get currentState => _currentState;

  /// Stream of battery state changes.
  Stream<BatteryState> get stateStream => _stateController.stream;

  /// Current configuration.
  BatteryAwareSyncConfig get config => _config;

  /// Update configuration.
  void configure(BatteryAwareSyncConfig config) {
    _config = config;
  }

  /// Initialize the service.
  Future<void> initialize() async {
    await _updateBatteryState();

    // Listen for battery state changes
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      _updateBatteryState();
    });

    // Periodically check battery level (battery state changes don't include level)
    _checkTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateBatteryState(),
    );

    debugPrint('BatteryAwareSyncService: Initialized - $_currentState');
  }

  /// Dispose resources.
  void dispose() {
    _batterySubscription?.cancel();
    _checkTimer?.cancel();
    _stateController.close();
  }

  /// Force a battery check.
  Future<BatteryState> checkNow() async {
    await _updateBatteryState();
    return _currentState;
  }

  /// Get recommended sync interval based on current battery state.
  Duration getRecommendedSyncInterval() {
    if (_currentState.isCharging) {
      return _config.chargingSyncInterval;
    }

    switch (_currentState.level) {
      case BatteryLevel.critical:
        return _config.criticalSyncInterval;
      case BatteryLevel.low:
        return _config.lowSyncInterval;
      case BatteryLevel.normal:
        return _config.normalSyncInterval;
      case BatteryLevel.good:
        return _config.goodSyncInterval;
    }
  }

  /// Whether sync should proceed now.
  bool shouldSyncNow() {
    if (_currentState.isCharging) {
      return true;
    }

    if (_currentState.level == BatteryLevel.critical &&
        _config.disableSyncOnCritical) {
      debugPrint('BatteryAwareSyncService: Sync disabled due to critical battery');
      return false;
    }

    return true;
  }

  /// Get sync parameters adjusted for battery state.
  SyncParameters getSyncParameters() {
    final isCharging = _currentState.isCharging;
    final level = _currentState.level;

    // Determine batch size based on battery
    int batchSize;
    if (isCharging) {
      batchSize = 100;
    } else {
      switch (level) {
        case BatteryLevel.critical:
          batchSize = 5;
        case BatteryLevel.low:
          batchSize = 10;
        case BatteryLevel.normal:
          batchSize = 25;
        case BatteryLevel.good:
          batchSize = 50;
      }
    }

    // Determine if we should sync all data or just critical
    final syncMode = isCharging || level == BatteryLevel.good
        ? SyncMode.full
        : level == BatteryLevel.critical
            ? SyncMode.criticalOnly
            : SyncMode.incremental;

    return SyncParameters(
      batchSize: batchSize,
      syncMode: syncMode,
      allowLargeTransfers: isCharging || level == BatteryLevel.good,
      useCompression: !isCharging && level.index <= BatteryLevel.normal.index,
    );
  }

  Future<void> _updateBatteryState() async {
    try {
      final percentage = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      final isCharging = batteryState == battery_plus.BatteryState.charging ||
          batteryState == battery_plus.BatteryState.full;

      final level = _categorizeLevel(percentage);

      final newState = BatteryState(
        level: level,
        percentage: percentage,
        isCharging: isCharging,
        timestamp: DateTime.now(),
      );

      if (_currentState.level != newState.level ||
          _currentState.isCharging != newState.isCharging) {
        _currentState = newState;
        _stateController.add(newState);
        debugPrint('BatteryAwareSyncService: State changed to $newState');
      } else {
        _currentState = newState;
      }
    } catch (e) {
      debugPrint('BatteryAwareSyncService: Failed to get battery state: $e');
    }
  }

  BatteryLevel _categorizeLevel(int percentage) {
    if (percentage < _config.criticalThreshold) {
      return BatteryLevel.critical;
    } else if (percentage < _config.lowThreshold) {
      return BatteryLevel.low;
    } else if (percentage < _config.normalThreshold) {
      return BatteryLevel.normal;
    } else {
      return BatteryLevel.good;
    }
  }
}

/// Sync mode based on battery state.
enum SyncMode {
  /// Sync all data.
  full,

  /// Sync incrementally (changed data only).
  incremental,

  /// Sync only critical data.
  criticalOnly,
}

/// Parameters for sync operations based on battery state.
class SyncParameters {
  const SyncParameters({
    required this.batchSize,
    required this.syncMode,
    required this.allowLargeTransfers,
    required this.useCompression,
  });

  /// Maximum batch size for sync operations.
  final int batchSize;

  /// What data to sync.
  final SyncMode syncMode;

  /// Whether to allow large data transfers.
  final bool allowLargeTransfers;

  /// Whether to use compression to reduce data transfer.
  final bool useCompression;

  @override
  String toString() =>
      'SyncParameters(batch: $batchSize, mode: $syncMode, large: $allowLargeTransfers, compress: $useCompression)';
}

/// Extension for easy battery-aware operations.
extension BatteryAwareExtension on Future<void> Function() {
  /// Execute this operation only if battery permits.
  Future<void> ifBatteryPermits({
    BatteryLevel minLevel = BatteryLevel.low,
  }) async {
    final state = BatteryAwareSyncService.instance.currentState;

    if (state.isCharging || state.level.index >= minLevel.index) {
      await this();
    } else {
      debugPrint('Operation skipped due to low battery (${state.percentage}%)');
    }
  }
}
