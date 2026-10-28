import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Callback type for connectivity state changes.
typedef ConnectivityCallback = void Function(bool isOnline);

/// Monitors network connectivity and provides state updates.
///
/// The monitor tracks WiFi, cellular, and other connectivity types
/// and emits updates when connectivity changes. It can trigger
/// sync operations when coming back online.
///
/// ## Usage
/// ```dart
/// final monitor = ConnectivityMonitor();
/// await monitor.initialize();
///
/// monitor.onConnectivityChanged = (isOnline) {
///   if (isOnline) {
///     // Trigger sync
///   }
/// };
///
/// // Check current state
/// if (await monitor.isOnline()) {
///   // Perform network operation
/// }
/// ```
class ConnectivityMonitor {
  ConnectivityMonitor({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _lastKnownState = true;
  bool _isInitialized = false;

  /// Callback invoked when connectivity state changes.
  ConnectivityCallback? onConnectivityChanged;

  /// The last known connectivity state.
  bool get lastKnownState => _lastKnownState;

  /// Whether the monitor has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the connectivity monitor.
  ///
  /// Checks initial connectivity state and starts listening for changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get initial state
    _lastKnownState = await isOnline();
    debugPrint('ConnectivityMonitor: Initial state - online: $_lastKnownState');

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_handleChange);

    _isInitialized = true;
    debugPrint('ConnectivityMonitor: Initialized');
  }

  /// Checks if the device is currently online.
  ///
  /// Returns true if WiFi, mobile, or ethernet connectivity is available.
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  /// Streams connectivity state changes.
  ///
  /// Emits true when online, false when offline.
  Stream<bool> watchConnectivity() {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  /// Returns a stream that emits only on transitions.
  ///
  /// Unlike [watchConnectivity], this only emits when the state
  /// actually changes (online -> offline or offline -> online).
  Stream<bool> watchConnectivityTransitions() async* {
    bool? previousState;

    await for (final result in _connectivity.onConnectivityChanged) {
      final isConnected = _isConnected(result);
      if (previousState != isConnected) {
        previousState = isConnected;
        yield isConnected;
      }
    }
  }

  /// Handles connectivity result changes.
  void _handleChange(ConnectivityResult result) {
    final isConnected = _isConnected(result);

    if (isConnected != _lastKnownState) {
      debugPrint(
          'ConnectivityMonitor: State changed - online: $isConnected');
      _lastKnownState = isConnected;
      onConnectivityChanged?.call(isConnected);
    }
  }

  /// Determines if the connectivity result indicates a connection.
  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Disposes of the connectivity monitor.
  void dispose() {
    debugPrint('ConnectivityMonitor: Disposing');
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }
}

/// Types of network connectivity.
enum NetworkType {
  /// No network connection
  none,

  /// WiFi connection
  wifi,

  /// Mobile data connection
  mobile,

  /// Ethernet connection (desktop/TV)
  ethernet,

  /// Bluetooth connection
  bluetooth,

  /// VPN connection
  vpn,

  /// Other connection type
  other,
}

/// Extension to convert ConnectivityResult to NetworkType.
extension ConnectivityResultExtension on ConnectivityResult {
  /// Converts to a more descriptive NetworkType.
  NetworkType toNetworkType() {
    switch (this) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.bluetooth:
        return NetworkType.bluetooth;
      case ConnectivityResult.vpn:
        return NetworkType.vpn;
      case ConnectivityResult.none:
        return NetworkType.none;
      case ConnectivityResult.other:
        return NetworkType.other;
    }
  }
}
