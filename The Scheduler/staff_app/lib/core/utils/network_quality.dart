// Network Quality Detection
//
// Monitors network connection quality and adjusts app behavior
// accordingly (e.g., sync frequency, data fetching strategy).

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Quality level of the network connection.
enum NetworkQuality {
  /// No network connection.
  offline,

  /// Very poor connection (high latency, packet loss).
  poor,

  /// Moderate connection (usable but slow).
  moderate,

  /// Good connection (responsive).
  good,

  /// Excellent connection (fast, low latency).
  excellent,
}

/// Type of network connection.
enum NetworkType {
  none,
  wifi,
  cellular,
  ethernet,
  vpn,
  other,
}

/// Current network status.
class NetworkStatus {
  const NetworkStatus({
    required this.type,
    required this.quality,
    required this.isConnected,
    this.latencyMs,
    this.downloadSpeedMbps,
  });

  /// Type of connection.
  final NetworkType type;

  /// Quality assessment.
  final NetworkQuality quality;

  /// Whether we have any connection.
  final bool isConnected;

  /// Measured latency in milliseconds.
  final int? latencyMs;

  /// Estimated download speed in Mbps.
  final double? downloadSpeedMbps;

  /// Whether connection is good enough for background sync.
  bool get canBackgroundSync =>
      isConnected && quality.index >= NetworkQuality.moderate.index;

  /// Whether connection is good enough for large data transfers.
  bool get canLargeTransfer =>
      isConnected && quality.index >= NetworkQuality.good.index;

  /// Whether we should prefer cached data.
  bool get preferCache =>
      !isConnected || quality.index <= NetworkQuality.poor.index;

  /// Human-readable description.
  String get description {
    if (!isConnected) return 'Offline';
    final typeStr = type.name.toUpperCase();
    final qualityStr = quality.name;
    final latencyStr = latencyMs != null ? ' (${latencyMs}ms)' : '';
    return '$typeStr - $qualityStr$latencyStr';
  }

  @override
  String toString() => 'NetworkStatus($description)';
}

/// Service for monitoring network quality.
class NetworkQualityService {
  NetworkQualityService._();
  static final NetworkQualityService instance = NetworkQualityService._();

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = const NetworkStatus(
    type: NetworkType.none,
    quality: NetworkQuality.offline,
    isConnected: false,
  );

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _qualityCheckTimer;

  /// Current network status.
  NetworkStatus get currentStatus => _currentStatus;

  /// Stream of network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Whether currently connected.
  bool get isConnected => _currentStatus.isConnected;

  /// Initialize the service.
  Future<void> initialize() async {
    // Get initial status
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (_) => _checkConnectivity(),
    );

    // Periodically check quality
    _qualityCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkQuality(),
    );

    debugPrint('NetworkQualityService: Initialized - $_currentStatus');
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _qualityCheckTimer?.cancel();
    _statusController.close();
  }

  /// Force a quality check.
  Future<NetworkStatus> checkNow() async {
    await _checkConnectivity();
    await _checkQuality();
    return _currentStatus;
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final type = _mapConnectivityResult(result);

    if (type == NetworkType.none) {
      _updateStatus(const NetworkStatus(
        type: NetworkType.none,
        quality: NetworkQuality.offline,
        isConnected: false,
      ));
    } else {
      // We have some connection, check quality
      await _checkQuality(type: type);
    }
  }

  Future<void> _checkQuality({NetworkType? type}) async {
    final connectionType = type ?? _currentStatus.type;

    if (connectionType == NetworkType.none) {
      return;
    }

    try {
      // Measure latency by pinging a reliable server
      final latency = await _measureLatency();
      final quality = _assessQuality(latency, connectionType);

      _updateStatus(NetworkStatus(
        type: connectionType,
        quality: quality,
        isConnected: true,
        latencyMs: latency,
      ));
    } catch (e) {
      debugPrint('NetworkQualityService: Quality check failed: $e');

      // Assume moderate quality if we can't measure
      _updateStatus(NetworkStatus(
        type: connectionType,
        quality: NetworkQuality.moderate,
        isConnected: true,
      ));
    }
  }

  Future<int> _measureLatency() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Try to resolve a well-known hostname
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (result.isNotEmpty) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      stopwatch.stop();
    }

    // If lookup failed, try socket connection
    try {
      final socket = await Socket.connect(
        'google.com',
        443,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      throw Exception('Unable to measure latency');
    }
  }

  NetworkQuality _assessQuality(int latencyMs, NetworkType type) {
    // Adjust thresholds based on connection type
    final multiplier = type == NetworkType.cellular ? 1.5 : 1.0;

    if (latencyMs < 50 * multiplier) {
      return NetworkQuality.excellent;
    } else if (latencyMs < 150 * multiplier) {
      return NetworkQuality.good;
    } else if (latencyMs < 500 * multiplier) {
      return NetworkQuality.moderate;
    } else {
      return NetworkQuality.poor;
    }
  }

  NetworkType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.none:
        return NetworkType.none;
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.cellular;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.vpn:
        return NetworkType.vpn;
      default:
        return NetworkType.other;
    }
  }

  void _updateStatus(NetworkStatus status) {
    if (_currentStatus.type != status.type ||
        _currentStatus.quality != status.quality ||
        _currentStatus.isConnected != status.isConnected) {
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('NetworkQualityService: Status changed to $status');
    }
  }
}

/// Extension for sync decisions based on network quality.
extension NetworkQualitySync on NetworkQuality {
  /// Recommended sync interval for this quality level.
  Duration get recommendedSyncInterval {
    switch (this) {
      case NetworkQuality.offline:
        return Duration.zero; // Don't sync
      case NetworkQuality.poor:
        return const Duration(minutes: 15);
      case NetworkQuality.moderate:
        return const Duration(minutes: 5);
      case NetworkQuality.good:
        return const Duration(minutes: 2);
      case NetworkQuality.excellent:
        return const Duration(minutes: 1);
    }
  }

  /// Maximum batch size for sync operations.
  int get maxSyncBatchSize {
    switch (this) {
      case NetworkQuality.offline:
        return 0;
      case NetworkQuality.poor:
        return 5;
      case NetworkQuality.moderate:
        return 20;
      case NetworkQuality.good:
        return 50;
      case NetworkQuality.excellent:
        return 100;
    }
  }
}
