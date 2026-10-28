import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// Service for encrypting and decrypting sensitive data (session notes, medical records)
///
/// Uses AES-256-GCM encryption for HIPAA compliance.
/// Encryption keys are derived from a master key per business.
/// 
/// SECURITY NOTES:
/// - Master keys should be stored in secure key management system (Google Cloud KMS, AWS KMS)
/// - For MVP, keys can be stored in Firestore with restricted access
/// - Production systems should use hardware security modules (HSM)
/// - Keys should be rotated periodically
class EncryptionService {
  EncryptionService({
    required String masterKey,
  }) : _masterKey = masterKey;

  final String _masterKey;
  late encrypt_pkg.Key _key;
  late encrypt_pkg.Encrypter _encrypter;

  /// Initialize encryption service with master key
  void initialize() {
    // Derive 256-bit key from master key using SHA-256
    final keyBytes = sha256.convert(utf8.encode(_masterKey)).bytes;
    _key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    
    // Use AES with GCM mode for authenticated encryption
    _encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(_key, mode: encrypt_pkg.AESMode.gcm),
    );
  }

  /// Encrypt plain text content
  /// Returns base64-encoded encrypted string with IV prepended
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    // Generate random IV for each encryption (security best practice)
    final iv = encrypt_pkg.IV.fromSecureRandom(16);

    // Encrypt the content
    final encrypted = _encrypter.encrypt(plainText, iv: iv);

    // Combine IV and encrypted data (IV:ENCRYPTED)
    final combined = '${iv.base64}:${encrypted.base64}';
    return combined;
  }

  /// Decrypt encrypted content
  /// Expects format: IV:ENCRYPTED (both base64-encoded)
  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      // Split IV and encrypted data
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = encrypt_pkg.IV.fromBase64(parts[0]);
      final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);

      // Decrypt the content
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  /// Encrypt multiple fields in a map
  Map<String, String> encryptFields(Map<String, String> fields) {
    return fields.map((key, value) => MapEntry(key, encrypt(value)));
  }

  /// Decrypt multiple fields in a map
  Map<String, String> decryptFields(Map<String, String> encryptedFields) {
    return encryptedFields.map((key, value) => MapEntry(key, decrypt(value)));
  }

  /// Zeroize key material in memory.
  void dispose() {
    try {
      final zeros = Uint8List(32);
      _key = encrypt_pkg.Key(zeros);
      _encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(_key, mode: encrypt_pkg.AESMode.gcm),
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Validate that encrypted data can be decrypted
  bool validate(String encryptedText) {
    try {
      decrypt(encryptedText);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a secure random master key (for new businesses)
  static String generateMasterKey() {
    final random = encrypt_pkg.IV.fromSecureRandom(32); // 256 bits
    return random.base64;
  }

  /// Hash content for searching (since encrypted content can't be searched)
  /// Returns a consistent hash that can be indexed
  static String hashForSearch(String content) {
    final normalized = content.toLowerCase().trim();
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}

/// Mock encryption service for testing (does NOT actually encrypt)
class MockEncryptionService extends EncryptionService {
  MockEncryptionService() : super(masterKey: 'mock-key-for-testing');

  @override
  void initialize() {
    // No-op for mock
  }

  @override
  String encrypt(String plainText) {
    // Return plain text with marker for testing
    return 'MOCK_ENCRYPTED:$plainText';
  }

  @override
  String decrypt(String encryptedText) {
    // Remove mock marker if present
    if (encryptedText.startsWith('MOCK_ENCRYPTED:')) {
      return encryptedText.substring('MOCK_ENCRYPTED:'.length);
    }
    return encryptedText;
  }

  @override
  bool validate(String encryptedText) => true;
}

/// Service for managing encryption keys per business
///
/// HIPAA Compliance: Uses Google Cloud KMS for secure key management.
/// - Master keys stored in Cloud KMS (never leave Google's infrastructure)
/// - Data Encryption Keys (DEKs) encrypted with envelope encryption
/// - Audit logging for all key operations
/// - Key rotation support
/// - Future hardening: perform encryption server-side so DEKs never leave the
///   trusted boundary (KMS-rooted envelope keys only).
class EncryptionKeyManager {
  // Cache for encryption services (avoids repeated Cloud Function calls)
  static final Map<String, _CachedKey> _keyCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get encryption service for a business
  ///
  /// HIPAA: Fetches DEK from Cloud Functions, which decrypts it using Cloud KMS.
  /// The decrypted key is cached locally for performance.
  static Future<EncryptionService> getForBusiness(String businessId) async {
    // Check cache first
    final cached = _keyCache[businessId];
    if (cached != null) {
      if (!cached.isExpired) {
        return cached.service;
      }
      cached.service.dispose();
      _keyCache.remove(businessId);
    }

    try {
      // Call Cloud Function to get decrypted key
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('getEncryptionKey');

      final result = await callable.call<Map<String, dynamic>>({
        'businessId': businessId,
      });

      final data = result.data;
      final masterKey = data['key'] as String;
      final keyVersion = data['keyVersion'] as int;

      final service = EncryptionService(masterKey: masterKey);
      service.initialize();

      // Cache the service
      _keyCache[businessId] = _CachedKey(
        service: service,
        keyVersion: keyVersion,
        cachedAt: DateTime.now(),
      );

      return service;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        // Key not initialized - initialize it first
        await initializeKeyForBusiness(businessId);
        return getForBusiness(businessId);
      }
      rethrow;
    }
  }

  /// Initialize encryption key for a new business
  ///
  /// HIPAA: Creates a new DEK, encrypts it with Cloud KMS, and stores in Firestore.
  /// Only callable by business admins/owners.
  static Future<void> initializeKeyForBusiness(String businessId) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('initializeEncryptionKey');

    await callable.call<Map<String, dynamic>>({
      'businessId': businessId,
    });

    // Clear cache to ensure fresh key is fetched
    _keyCache.remove(businessId);
  }

  /// Rotate encryption key for a business
  ///
  /// HIPAA: Generates new DEK, archives old version for decrypting legacy data.
  /// Only callable by business owners.
  ///
  /// NOTE: After rotation, existing encrypted data should be re-encrypted
  /// with the new key during a maintenance window.
  static Future<RotationResult> rotateKey(String businessId) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('rotateEncryptionKey');

    final result = await callable.call<Map<String, dynamic>>({
      'businessId': businessId,
    });

    // Clear cache to force fresh key fetch
    _keyCache.remove(businessId);

    return RotationResult(
      previousVersion: result.data['previousVersion'] as int,
      newVersion: result.data['newVersion'] as int,
    );
  }

  /// Get encryption service for a specific key version
  ///
  /// Used for decrypting legacy data during re-encryption migration.
  static Future<EncryptionService> getForBusinessByVersion(
    String businessId,
    int version,
  ) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('getEncryptionKeyByVersion');

    final result = await callable.call<Map<String, dynamic>>({
      'businessId': businessId,
      'version': version,
    });

    final masterKey = result.data['key'] as String;

    final service = EncryptionService(masterKey: masterKey);
    service.initialize();

    return service;
  }

  /// Clear cached keys (e.g., on logout)
  static void clearCache() {
    for (final entry in _keyCache.values) {
      entry.service.dispose();
    }
    _keyCache.clear();
  }

  /// Clear cached key for a specific business
  static void clearCacheForBusiness(String businessId) {
    final cached = _keyCache.remove(businessId);
    cached?.service.dispose();
  }

  // ============================================================
  // Fallback for development/testing without Cloud Functions
  // ============================================================

  /// Get encryption service using mock key (DEVELOPMENT ONLY)
  ///
  /// WARNING: This is NOT secure! Only use for local development/testing.
  static Future<EncryptionService> getForBusinessMock(String businessId) async {
    assert(() {
      // ignore: avoid_print
      print('WARNING: Using mock encryption key (development only)');
      // ignore: avoid_print
      print('WARNING: This is NOT HIPAA compliant - use Cloud KMS in production');
      return true;
    }());

    final hash = sha256.convert(utf8.encode('scheduler-app-$businessId')).bytes;
    final masterKey = base64.encode(hash);

    final service = EncryptionService(masterKey: masterKey);
    service.initialize();
    return service;
  }
}

/// Cached encryption key with expiry
class _CachedKey {
  _CachedKey({
    required this.service,
    required this.keyVersion,
    required this.cachedAt,
  });

  final EncryptionService service;
  final int keyVersion;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > EncryptionKeyManager._cacheExpiry;
}

/// Result of key rotation operation
class RotationResult {
  RotationResult({
    required this.previousVersion,
    required this.newVersion,
  });

  final int previousVersion;
  final int newVersion;
}
