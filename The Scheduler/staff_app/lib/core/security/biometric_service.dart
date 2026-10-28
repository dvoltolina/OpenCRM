import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'secure_storage_service.dart';

/// Result of a biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// Authentication failed (wrong fingerprint, face, etc.).
  failed,

  /// User cancelled the authentication dialog.
  cancelled,

  /// Biometric authentication is not available on this device.
  notAvailable,

  /// Biometric authentication is not enrolled/configured.
  notEnrolled,

  /// Device is locked out due to too many failed attempts.
  lockedOut,

  /// Permanent lockout - device passcode required.
  permanentlyLockedOut,

  /// An error occurred during authentication.
  error,
}

/// Service for biometric authentication (fingerprint, face).
///
/// Uses platform-native biometric APIs for secure, convenient
/// authentication. Supports fallback to device passcode.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _localAuth = LocalAuthentication();
  final _secureStorage = SecureStorageService.instance;

  // Cache availability check results
  bool? _isAvailable;
  List<BiometricType>? _availableBiometrics;

  /// Checks if biometric authentication is available on this device.
  Future<bool> isBiometricAvailable() async {
    if (_isAvailable != null) return _isAvailable!;

    try {
      // Check if device supports biometrics
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      _isAvailable = canCheck || isSupported;
      return _isAvailable!;
    } on PlatformException {
      _isAvailable = false;
      return false;
    }
  }

  /// Gets the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (_availableBiometrics != null) return _availableBiometrics!;

    try {
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      return _availableBiometrics!;
    } on PlatformException {
      _availableBiometrics = [];
      return [];
    }
  }

  /// Gets a human-readable description of available biometrics.
  Future<String> getBiometricDescription() async {
    final types = await getAvailableBiometrics();

    if (types.isEmpty) return 'Not available';

    final descriptions = <String>[];
    for (final type in types) {
      switch (type) {
        case BiometricType.face:
          descriptions.add('Face ID');
          break;
        case BiometricType.fingerprint:
          descriptions.add('Fingerprint');
          break;
        case BiometricType.iris:
          descriptions.add('Iris');
          break;
        case BiometricType.strong:
          descriptions.add('Biometric');
          break;
        case BiometricType.weak:
          descriptions.add('Biometric');
          break;
      }
    }

    return descriptions.toSet().join(', ');
  }

  /// Authenticates the user using biometrics.
  ///
  /// [reason] is displayed to the user explaining why authentication is needed.
  /// [useErrorDialogs] shows system error dialogs (recommended true).
  /// [stickyAuth] keeps auth active during app lifecycle changes.
  /// [biometricOnly] disables fallback to device passcode.
  Future<BiometricResult> authenticate({
    String reason = 'Verify your identity to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult.notAvailable;
      }

      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return BiometricResult.notEnrolled;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Authenticates for a sensitive action (like viewing PHI or clocking out).
  Future<BiometricResult> authenticateForSensitiveAction(String action) async {
    return authenticate(
      reason: 'Verify your identity to $action',
      biometricOnly: false, // Allow device passcode fallback
    );
  }

  /// Authenticates for quick unlock after session timeout.
  Future<BiometricResult> authenticateForUnlock() async {
    return authenticate(
      reason: 'Unlock Staff App',
      biometricOnly: false,
    );
  }

  /// Cancels any ongoing biometric authentication.
  Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  // User Preferences

  /// Checks if the user has enabled biometric authentication.
  Future<bool> isEnabled() async {
    return _secureStorage.isBiometricEnabled();
  }

  /// Enables or disables biometric authentication.
  ///
  /// When enabling, verifies biometrics work first.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      // Verify biometrics work before enabling
      final result = await authenticate(
        reason: 'Verify to enable biometric login',
      );

      if (result != BiometricResult.success) {
        return false;
      }
    }

    await _secureStorage.setBiometricEnabled(enabled);
    return true;
  }

  // Private Methods

  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricResult.notAvailable;
      case 'NotEnrolled':
        return BiometricResult.notEnrolled;
      case 'LockedOut':
        return BiometricResult.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricResult.permanentlyLockedOut;
      case 'OtherOperatingSystem':
      case 'PasscodeNotSet':
        return BiometricResult.notAvailable;
      default:
        return BiometricResult.error;
    }
  }

  /// Clears cached availability data (call after device settings change).
  void clearCache() {
    _isAvailable = null;
    _availableBiometrics = null;
  }
}
