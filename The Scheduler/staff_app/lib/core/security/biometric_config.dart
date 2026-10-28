// Configurable Biometric Authentication Settings
//
// Provides configurable timeout and security settings for
// biometric authentication in the staff app.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Timeout presets for biometric re-authentication.
enum BiometricTimeoutPreset {
  /// Require auth immediately when app returns to foreground.
  immediate(Duration.zero, 'Immediately'),

  /// Require auth after 1 minute in background.
  oneMinute(Duration(minutes: 1), '1 minute'),

  /// Require auth after 5 minutes in background.
  fiveMinutes(Duration(minutes: 5), '5 minutes'),

  /// Require auth after 15 minutes in background.
  fifteenMinutes(Duration(minutes: 15), '15 minutes'),

  /// Require auth after 30 minutes in background.
  thirtyMinutes(Duration(minutes: 30), '30 minutes'),

  /// Require auth after 1 hour in background.
  oneHour(Duration(hours: 1), '1 hour'),

  /// Never require re-auth (session only).
  sessionOnly(Duration(days: 365), 'Session only');

  const BiometricTimeoutPreset(this.duration, this.displayName);

  final Duration duration;
  final String displayName;

  /// Get preset from duration.
  static BiometricTimeoutPreset fromDuration(Duration duration) {
    for (final preset in values) {
      if (preset.duration == duration) {
        return preset;
      }
    }
    // Return closest match
    return values.reduce((a, b) =>
        (a.duration - duration).abs() < (b.duration - duration).abs() ? a : b);
  }
}

/// Security level for biometric authentication.
enum BiometricSecurityLevel {
  /// Standard security - use any available biometric.
  standard,

  /// High security - prefer strong biometrics (face ID, fingerprint).
  high,

  /// Maximum security - require biometrics, no fallback to PIN.
  maximum,
}

/// Configuration for biometric authentication.
class BiometricConfig {
  const BiometricConfig({
    this.isEnabled = true,
    this.timeout = const Duration(minutes: 5),
    this.securityLevel = BiometricSecurityLevel.standard,
    this.requireOnAppStart = true,
    this.requireOnSensitiveActions = true,
    this.allowFallbackToPin = true,
    this.maxFailedAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 5),
  });

  /// Whether biometric auth is enabled.
  final bool isEnabled;

  /// How long before requiring re-authentication.
  final Duration timeout;

  /// Security level for biometric auth.
  final BiometricSecurityLevel securityLevel;

  /// Whether to require auth on app start.
  final bool requireOnAppStart;

  /// Whether to require auth for sensitive actions.
  final bool requireOnSensitiveActions;

  /// Whether to allow PIN fallback.
  final bool allowFallbackToPin;

  /// Max failed attempts before lockout.
  final int maxFailedAttempts;

  /// How long to lock out after max failed attempts.
  final Duration lockoutDuration;

  /// Timeout preset.
  BiometricTimeoutPreset get timeoutPreset =>
      BiometricTimeoutPreset.fromDuration(timeout);

  /// Copy with modifications.
  BiometricConfig copyWith({
    bool? isEnabled,
    Duration? timeout,
    BiometricSecurityLevel? securityLevel,
    bool? requireOnAppStart,
    bool? requireOnSensitiveActions,
    bool? allowFallbackToPin,
    int? maxFailedAttempts,
    Duration? lockoutDuration,
  }) {
    return BiometricConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      timeout: timeout ?? this.timeout,
      securityLevel: securityLevel ?? this.securityLevel,
      requireOnAppStart: requireOnAppStart ?? this.requireOnAppStart,
      requireOnSensitiveActions:
          requireOnSensitiveActions ?? this.requireOnSensitiveActions,
      allowFallbackToPin: allowFallbackToPin ?? this.allowFallbackToPin,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
    );
  }

  /// Default configuration.
  static const defaultConfig = BiometricConfig();

  /// High security configuration.
  static const highSecurityConfig = BiometricConfig(
    timeout: Duration(minutes: 1),
    securityLevel: BiometricSecurityLevel.high,
    requireOnAppStart: true,
    requireOnSensitiveActions: true,
    allowFallbackToPin: false,
    maxFailedAttempts: 3,
    lockoutDuration: Duration(minutes: 15),
  );
}

/// Service for managing biometric configuration.
class BiometricConfigService {
  BiometricConfigService._();
  static final BiometricConfigService instance = BiometricConfigService._();

  static const _keyEnabled = 'biometric_enabled';
  static const _keyTimeout = 'biometric_timeout_minutes';
  static const _keySecurityLevel = 'biometric_security_level';
  static const _keyRequireOnStart = 'biometric_require_on_start';
  static const _keyRequireOnSensitive = 'biometric_require_on_sensitive';
  static const _keyAllowPinFallback = 'biometric_allow_pin_fallback';
  static const _keyMaxAttempts = 'biometric_max_attempts';
  static const _keyLockoutMinutes = 'biometric_lockout_minutes';

  BiometricConfig _config = BiometricConfig.defaultConfig;
  final _configController = StreamController<BiometricConfig>.broadcast();

  /// Current configuration.
  BiometricConfig get config => _config;

  /// Stream of configuration changes.
  Stream<BiometricConfig> get configStream => _configController.stream;

  /// Load configuration from storage.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _config = BiometricConfig(
        isEnabled: prefs.getBool(_keyEnabled) ?? true,
        timeout: Duration(minutes: prefs.getInt(_keyTimeout) ?? 5),
        securityLevel: BiometricSecurityLevel
            .values[prefs.getInt(_keySecurityLevel) ?? 0],
        requireOnAppStart: prefs.getBool(_keyRequireOnStart) ?? true,
        requireOnSensitiveActions: prefs.getBool(_keyRequireOnSensitive) ?? true,
        allowFallbackToPin: prefs.getBool(_keyAllowPinFallback) ?? true,
        maxFailedAttempts: prefs.getInt(_keyMaxAttempts) ?? 5,
        lockoutDuration:
            Duration(minutes: prefs.getInt(_keyLockoutMinutes) ?? 5),
      );

      debugPrint('BiometricConfigService: Loaded config');
    } catch (e) {
      debugPrint('BiometricConfigService: Failed to load: $e');
    }
  }

  /// Save configuration to storage.
  Future<void> save(BiometricConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setBool(_keyEnabled, config.isEnabled),
        prefs.setInt(_keyTimeout, config.timeout.inMinutes),
        prefs.setInt(_keySecurityLevel, config.securityLevel.index),
        prefs.setBool(_keyRequireOnStart, config.requireOnAppStart),
        prefs.setBool(_keyRequireOnSensitive, config.requireOnSensitiveActions),
        prefs.setBool(_keyAllowPinFallback, config.allowFallbackToPin),
        prefs.setInt(_keyMaxAttempts, config.maxFailedAttempts),
        prefs.setInt(_keyLockoutMinutes, config.lockoutDuration.inMinutes),
      ]);

      _config = config;
      _configController.add(config);

      debugPrint('BiometricConfigService: Saved config');
    } catch (e) {
      debugPrint('BiometricConfigService: Failed to save: $e');
      rethrow;
    }
  }

  /// Update a single setting.
  Future<void> updateSetting<T>({
    bool? isEnabled,
    Duration? timeout,
    BiometricSecurityLevel? securityLevel,
    bool? requireOnAppStart,
    bool? requireOnSensitiveActions,
    bool? allowFallbackToPin,
    int? maxFailedAttempts,
    Duration? lockoutDuration,
  }) async {
    final newConfig = _config.copyWith(
      isEnabled: isEnabled,
      timeout: timeout,
      securityLevel: securityLevel,
      requireOnAppStart: requireOnAppStart,
      requireOnSensitiveActions: requireOnSensitiveActions,
      allowFallbackToPin: allowFallbackToPin,
      maxFailedAttempts: maxFailedAttempts,
      lockoutDuration: lockoutDuration,
    );

    await save(newConfig);
  }

  /// Reset to default configuration.
  Future<void> resetToDefaults() async {
    await save(BiometricConfig.defaultConfig);
  }

  /// Dispose resources.
  void dispose() {
    _configController.close();
  }
}

/// Tracks biometric authentication state.
class BiometricAuthState {
  BiometricAuthState._();
  static final BiometricAuthState instance = BiometricAuthState._();

  DateTime? _lastAuthTime;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  /// When user last successfully authenticated.
  DateTime? get lastAuthTime => _lastAuthTime;

  /// Number of consecutive failed attempts.
  int get failedAttempts => _failedAttempts;

  /// Whether currently locked out.
  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  /// Time remaining in lockout.
  Duration get lockoutRemaining {
    if (_lockoutUntil == null) return Duration.zero;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether authentication is required based on config and last auth time.
  bool requiresAuthentication(BiometricConfig config) {
    if (!config.isEnabled) return false;
    if (_lastAuthTime == null) return true;

    final elapsed = DateTime.now().difference(_lastAuthTime!);
    return elapsed > config.timeout;
  }

  /// Record a successful authentication.
  void recordSuccess() {
    _lastAuthTime = DateTime.now();
    _failedAttempts = 0;
    _lockoutUntil = null;
    debugPrint('BiometricAuthState: Authentication successful');
  }

  /// Record a failed authentication.
  void recordFailure(BiometricConfig config) {
    _failedAttempts++;
    debugPrint('BiometricAuthState: Authentication failed (attempt $_failedAttempts)');

    if (_failedAttempts >= config.maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(config.lockoutDuration);
      debugPrint('BiometricAuthState: Locked out until $_lockoutUntil');
    }
  }

  /// Reset state (e.g., on logout).
  void reset() {
    _lastAuthTime = null;
    _failedAttempts = 0;
    _lockoutUntil = null;
  }
}
