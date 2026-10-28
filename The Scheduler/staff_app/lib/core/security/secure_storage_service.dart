import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data using platform-native encryption.
///
/// Uses Android EncryptedSharedPreferences and iOS Keychain for secure storage
/// of authentication tokens, database encryption keys, and other sensitive data.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'staff_app_secure_prefs',
      preferencesKeyPrefix: 'staff_app_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'staff_app',
    ),
  );

  // Storage keys
  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyDatabaseKey = 'database_encryption_key';
  static const _keyDeviceId = 'device_id';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keySessionTimeout = 'session_timeout_minutes';
  static const _keyLastActivity = 'last_activity_timestamp';

  // Auth Token Operations

  /// Stores the Firebase auth token securely.
  Future<void> storeAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Retrieves the stored auth token.
  Future<String?> getAuthToken() async {
    return _storage.read(key: _keyAuthToken);
  }

  /// Deletes the stored auth token.
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
  }

  /// Stores the refresh token securely.
  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  // Database Encryption Key Operations

  /// Stores the database encryption key securely.
  Future<void> storeDatabaseKey(String key) async {
    await _storage.write(key: _keyDatabaseKey, value: key);
  }

  /// Retrieves the stored database encryption key.
  Future<String?> getDatabaseKey() async {
    return _storage.read(key: _keyDatabaseKey);
  }

  /// Gets or creates a database encryption key.
  ///
  /// If no key exists, generates a new 256-bit (32 byte) key
  /// and stores it securely.
  Future<String> getOrCreateDatabaseKey() async {
    var key = await getDatabaseKey();
    if (key == null) {
      key = _generateSecureKey(32);
      await storeDatabaseKey(key);
    }
    return key;
  }

  // Device ID Operations

  /// Stores the device ID for remote wipe targeting.
  Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  /// Retrieves the stored device ID.
  Future<String?> getDeviceId() async {
    return _storage.read(key: _keyDeviceId);
  }

  /// Gets or creates a unique device ID.
  Future<String> getOrCreateDeviceId() async {
    var deviceId = await getDeviceId();
    if (deviceId == null) {
      deviceId = _generateSecureKey(16);
      await storeDeviceId(deviceId);
    }
    return deviceId;
  }

  // Biometric Settings

  /// Stores the biometric authentication preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// Retrieves the biometric authentication preference.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // Session Timeout Settings

  /// Stores the session timeout in minutes.
  Future<void> setSessionTimeout(int minutes) async {
    await _storage.write(key: _keySessionTimeout, value: minutes.toString());
  }

  /// Retrieves the session timeout in minutes (default: 15 for HIPAA).
  Future<int> getSessionTimeout() async {
    final value = await _storage.read(key: _keySessionTimeout);
    return int.tryParse(value ?? '') ?? 15;
  }

  // Activity Tracking

  /// Stores the last activity timestamp.
  Future<void> setLastActivity(DateTime timestamp) async {
    await _storage.write(
      key: _keyLastActivity,
      value: timestamp.toIso8601String(),
    );
  }

  /// Retrieves the last activity timestamp.
  Future<DateTime?> getLastActivity() async {
    final value = await _storage.read(key: _keyLastActivity);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  // Clear Operations

  /// Clears all secure data (for logout/wipe).
  Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  /// Clears only authentication data (keeps device ID and preferences).
  Future<void> clearAuthData() async {
    await deleteAuthToken();
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyLastActivity);
  }

  // Utility Methods

  /// Generates a cryptographically secure random key.
  String _generateSecureKey(int bytes) {
    final random = Random.secure();
    final values = List<int>.generate(bytes, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Checks if the secure storage is available.
  Future<bool> isAvailable() async {
    try {
      await _storage.write(key: '_test', value: 'test');
      await _storage.delete(key: '_test');
      return true;
    } catch (e) {
      return false;
    }
  }
}
