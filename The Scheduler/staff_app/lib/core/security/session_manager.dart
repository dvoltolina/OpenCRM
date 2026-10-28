import 'dart:async';
import 'package:flutter/widgets.dart';

import 'secure_storage_service.dart';

/// Callback type for session events.
typedef SessionCallback = void Function();

/// Session states.
enum SessionState {
  /// Session is active and valid.
  active,

  /// Session is about to expire (warning shown).
  expiring,

  /// Session has expired, user needs to re-authenticate.
  expired,

  /// Session is locked (requires biometric/PIN unlock).
  locked,
}

/// Manages user session with inactivity timeout for HIPAA compliance.
///
/// Tracks user activity and automatically expires the session after
/// a configurable period of inactivity (default 15 minutes per HIPAA).
/// Provides warning before expiration and supports lock mode for quick unlock.
class SessionManager with WidgetsBindingObserver {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  final _secureStorage = SecureStorageService.instance;

  // Default timeouts (HIPAA recommends 15 minutes max)
  static const _defaultInactivityTimeout = Duration(minutes: 15);
  static const _warningBeforeTimeout = Duration(minutes: 1);

  Timer? _inactivityTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  Duration _inactivityTimeout = _defaultInactivityTimeout;

  SessionState _state = SessionState.expired;
  SessionState get state => _state;

  // Callbacks
  SessionCallback? onSessionExpired;
  SessionCallback? onSessionWarning;
  SessionCallback? onSessionLocked;
  VoidCallback? onSessionRestored;

  /// Initializes the session manager and starts observing app lifecycle.
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);

    // Load timeout setting from secure storage
    final timeoutMinutes = await _secureStorage.getSessionTimeout();
    _inactivityTimeout = Duration(minutes: timeoutMinutes);

    // Check if there's a valid previous session
    final lastActivity = await _secureStorage.getLastActivity();
    if (lastActivity != null) {
      final elapsed = DateTime.now().difference(lastActivity);
      if (elapsed < _inactivityTimeout) {
        // Session is still valid
        _lastActivity = lastActivity;
        _state = SessionState.active;
        _startInactivityTimer();
      } else {
        // Session has expired
        _state = SessionState.expired;
      }
    }
  }

  /// Cleans up resources when the session manager is no longer needed.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
  }

  /// Records user activity and resets the inactivity timer.
  ///
  /// Call this on user interactions (taps, scrolls, navigation).
  void recordActivity() {
    if (_state == SessionState.expired || _state == SessionState.locked) {
      return;
    }

    _lastActivity = DateTime.now();
    _secureStorage.setLastActivity(_lastActivity!);

    // Reset to active if we were in warning state
    if (_state == SessionState.expiring) {
      _state = SessionState.active;
    }

    _startInactivityTimer();
  }

  /// Starts a new session after successful authentication.
  void startSession() {
    _lastActivity = DateTime.now();
    _state = SessionState.active;
    _secureStorage.setLastActivity(_lastActivity!);
    _startInactivityTimer();
    onSessionRestored?.call();
  }

  /// Ends the current session (explicit logout).
  void endSession() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _state = SessionState.expired;
    _lastActivity = null;
  }

  /// Locks the session (requires re-authentication to unlock).
  void lockSession() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _state = SessionState.locked;
    onSessionLocked?.call();
  }

  /// Unlocks a locked session (after biometric/PIN verification).
  void unlockSession() {
    _state = SessionState.active;
    _lastActivity = DateTime.now();
    _secureStorage.setLastActivity(_lastActivity!);
    _startInactivityTimer();
    onSessionRestored?.call();
  }

  /// Checks if the current session is valid.
  bool isSessionValid() {
    if (_state == SessionState.expired || _state == SessionState.locked) {
      return false;
    }

    if (_lastActivity == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(_lastActivity!);
    return elapsed < _inactivityTimeout;
  }

  /// Updates the inactivity timeout duration.
  Future<void> setInactivityTimeout(Duration timeout) async {
    _inactivityTimeout = timeout;
    await _secureStorage.setSessionTimeout(timeout.inMinutes);

    // Restart timer if session is active
    if (_state == SessionState.active) {
      _startInactivityTimer();
    }
  }

  /// Gets the remaining time before session expires.
  Duration get remainingTime {
    if (_lastActivity == null) {
      return Duration.zero;
    }

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _inactivityTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Gets the configured inactivity timeout.
  Duration get inactivityTimeout => _inactivityTimeout;

  // Private Methods

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    // Set warning timer
    final warningTime = _inactivityTimeout - _warningBeforeTimeout;
    if (warningTime.isNegative == false) {
      _warningTimer = Timer(warningTime, _onWarning);
    }

    // Set expiration timer
    _inactivityTimer = Timer(_inactivityTimeout, _onInactivityTimeout);
  }

  void _onWarning() {
    if (_state == SessionState.active) {
      _state = SessionState.expiring;
      onSessionWarning?.call();
    }
  }

  void _onInactivityTimeout() {
    _state = SessionState.expired;
    onSessionExpired?.call();
  }

  // App Lifecycle Handling

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - save activity state
        if (_lastActivity != null) {
          _secureStorage.setLastActivity(_lastActivity!);
        }
        break;

      case AppLifecycleState.resumed:
        // App returning to foreground - check session validity
        _checkSessionOnResume();
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App being destroyed - clean up
        _inactivityTimer?.cancel();
        _warningTimer?.cancel();
        break;
    }
  }

  Future<void> _checkSessionOnResume() async {
    final lastActivity = await _secureStorage.getLastActivity();
    if (lastActivity == null) {
      _state = SessionState.expired;
      onSessionExpired?.call();
      return;
    }

    final elapsed = DateTime.now().difference(lastActivity);
    if (elapsed >= _inactivityTimeout) {
      // Session expired while app was in background
      _state = SessionState.expired;
      onSessionExpired?.call();
    } else {
      // Session still valid - restore and restart timer
      _lastActivity = lastActivity;
      _state = SessionState.active;
      _startInactivityTimer();
    }
  }
}

/// Mixin for widgets that should track user activity.
///
/// Add this mixin to StatefulWidget states that handle user input.
/// Call `recordActivity()` on user interactions.
mixin SessionActivityTracker<T extends StatefulWidget> on State<T> {
  void recordActivity() {
    SessionManager.instance.recordActivity();
  }

  /// Wraps a callback to record activity when invoked.
  VoidCallback? trackActivity(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      recordActivity();
      callback();
    };
  }
}
