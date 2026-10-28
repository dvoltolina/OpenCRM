import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity.
///
/// Provides:
/// - Current connectivity status
/// - Stream of connectivity changes
/// - Simple online/offline boolean
///
/// Usage:
/// ```dart
/// final connectivityService = ConnectivityService();
/// final isOnline = await connectivityService.isOnline;
/// connectivityService.connectivityStream.listen((isOnline) {
///   // Handle connectivity changes
/// });
/// ```
class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Current online status.
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes (true = online, false = offline).
  Stream<bool> get connectivityStream => _statusController.stream;

  void _init() {
    // Check initial connectivity
    _checkConnectivity();

    // Monitor changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectivity(results);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      _updateConnectivity([ConnectivityResult.none]);
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint('ConnectivityService: Status changed - online: $_isOnline');
      _statusController.add(_isOnline);
    }
  }

  /// Manually checks connectivity (useful for pull-to-refresh).
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
