// Certificate Pinning for Staff App
//
// Implements SSL/TLS certificate pinning to prevent man-in-the-middle
// attacks. Essential for healthcare apps handling sensitive data.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Configuration for certificate pinning.
///
/// Uses SHA-256 hashes of the certificate's DER-encoded data for pinning.
/// Generate pins using: openssl x509 -in cert.pem -outform DER | openssl dgst -sha256 -binary | base64
class CertificatePinConfig {
  const CertificatePinConfig({
    required this.hostname,
    required this.pins,
    this.includeSubdomains = true,
    this.enforceOnDebug = false,
  });

  /// Hostname to pin (e.g., 'api.example.com').
  final String hostname;

  /// SHA-256 hashes of trusted certificates (base64-encoded).
  /// Generate using: openssl x509 -in cert.pem -outform DER | openssl dgst -sha256 -binary | base64
  final List<String> pins;

  /// Whether to include subdomains.
  final bool includeSubdomains;

  /// Whether to enforce pinning in debug mode.
  final bool enforceOnDebug;
}

/// Result of certificate validation.
enum CertificateValidationResult {
  /// Certificate is valid and pinned.
  valid,

  /// Certificate chain is invalid.
  invalidChain,

  /// Certificate is not pinned (unknown).
  notPinned,

  /// Hostname mismatch.
  hostnameMismatch,

  /// Certificate has expired.
  expired,

  /// Validation skipped (debug mode).
  skipped,
}

/// Service for certificate pinning.
class CertificatePinningService {
  CertificatePinningService._();
  static final CertificatePinningService instance = CertificatePinningService._();

  final Map<String, CertificatePinConfig> _pins = {};
  bool _initialized = false;

  /// Whether pinning is enabled.
  bool get isEnabled => _pins.isNotEmpty;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize with pin configurations.
  Future<void> initialize(List<CertificatePinConfig> configs) async {
    for (final config in configs) {
      _pins[config.hostname.toLowerCase()] = config;
    }
    _initialized = true;
    debugPrint('CertificatePinningService: Initialized with ${_pins.length} pins');
  }

  /// Add a pin configuration.
  void addPin(CertificatePinConfig config) {
    _pins[config.hostname.toLowerCase()] = config;
  }

  /// Remove a pin configuration.
  void removePin(String hostname) {
    _pins.remove(hostname.toLowerCase());
  }

  /// Create an HttpClient with certificate pinning.
  HttpClient createPinnedHttpClient() {
    final client = HttpClient();

    client.badCertificateCallback = (cert, host, port) {
      final result = validateCertificate(cert, host);
      if (result != CertificateValidationResult.valid &&
          result != CertificateValidationResult.skipped) {
        debugPrint('CertificatePinningService: Rejected connection to $host: $result');
        return false;
      }
      return true;
    };

    return client;
  }

  /// Validate a certificate against pins.
  CertificateValidationResult validateCertificate(
    X509Certificate certificate,
    String hostname,
  ) {
    // Skip validation in debug mode unless enforced
    if (kDebugMode) {
      final config = _getConfigForHost(hostname);
      if (config == null || !config.enforceOnDebug) {
        return CertificateValidationResult.skipped;
      }
    }

    // Get config for this hostname
    final config = _getConfigForHost(hostname);
    if (config == null) {
      // No pin configured, allow by default (or reject if strict mode)
      debugPrint('CertificatePinningService: No pin for $hostname');
      return CertificateValidationResult.valid;
    }

    // Check certificate validity period
    final now = DateTime.now();
    if (certificate.endValidity.isBefore(now)) {
      return CertificateValidationResult.expired;
    }
    if (certificate.startValidity.isAfter(now)) {
      return CertificateValidationResult.invalidChain;
    }

    // Extract and hash the public key
    final publicKeyHash = _hashPublicKey(certificate);

    // Check if the hash matches any of our pins
    if (config.pins.contains(publicKeyHash)) {
      return CertificateValidationResult.valid;
    }

    debugPrint('CertificatePinningService: Certificate not pinned for $hostname');
    debugPrint('CertificatePinningService: Got hash: $publicKeyHash');
    debugPrint('CertificatePinningService: Expected: ${config.pins}');

    return CertificateValidationResult.notPinned;
  }

  CertificatePinConfig? _getConfigForHost(String hostname) {
    hostname = hostname.toLowerCase();

    // Direct match
    if (_pins.containsKey(hostname)) {
      return _pins[hostname];
    }

    // Check subdomain matches
    for (final entry in _pins.entries) {
      if (entry.value.includeSubdomains) {
        if (hostname.endsWith('.${entry.key}')) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Hash the certificate's DER-encoded data using SHA-256.
  ///
  /// Returns a base64-encoded SHA-256 hash of the certificate's DER data.
  /// This can be compared against pins generated with:
  /// `openssl x509 -in cert.pem -outform DER | openssl dgst -sha256 -binary | base64`
  String _hashPublicKey(X509Certificate certificate) {
    final der = certificate.der;
    final hash = sha256.convert(der);
    return base64.encode(hash.bytes);
  }

  /// Load pins from bundled asset file.
  Future<void> loadPinsFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final pins = jsonData['pins'] as List<dynamic>;

      for (final pinData in pins) {
        final pin = pinData as Map<String, dynamic>;
        addPin(CertificatePinConfig(
          hostname: pin['hostname'] as String,
          pins: (pin['pins'] as List<dynamic>).cast<String>(),
          includeSubdomains: pin['includeSubdomains'] as bool? ?? true,
          enforceOnDebug: pin['enforceOnDebug'] as bool? ?? false,
        ));
      }

      debugPrint('CertificatePinningService: Loaded ${pins.length} pins from asset');
    } catch (e) {
      debugPrint('CertificatePinningService: Failed to load pins from asset: $e');
    }
  }

  /// Get the SHA-256 hash of a certificate for pinning setup.
  ///
  /// Use this method to get the hash of your server's certificate
  /// during development for adding to your pin configuration.
  static String getCertificateHash(X509Certificate certificate) {
    final der = certificate.der;
    final hash = sha256.convert(der);
    return base64.encode(hash.bytes);
  }
}

/// Extension to add pinning to HttpClientRequest.
extension PinnedHttpClient on HttpClient {
  /// Create a request with certificate pinning validation.
  Future<HttpClientRequest> openUrlPinned(
    String method,
    Uri url, {
    required CertificatePinningService pinningService,
  }) async {
    badCertificateCallback = (cert, host, port) {
      final result = pinningService.validateCertificate(cert, host);
      return result == CertificateValidationResult.valid ||
          result == CertificateValidationResult.skipped;
    };

    return openUrl(method, url);
  }
}

/// Common pins for Firebase services (example).
///
/// NOTE: These are placeholder values. In production, you would
/// get the actual certificate hashes from your servers.
class CommonPins {
  CommonPins._();

  /// Firebase pins (placeholder).
  static const firebase = CertificatePinConfig(
    hostname: 'firebaseio.com',
    pins: [
      // Add actual Firebase certificate hashes here
      'PLACEHOLDER_HASH_1',
      'PLACEHOLDER_HASH_2',
    ],
    includeSubdomains: true,
  );

  /// Google APIs pins (placeholder).
  static const googleApis = CertificatePinConfig(
    hostname: 'googleapis.com',
    pins: [
      // Add actual Google APIs certificate hashes here
      'PLACEHOLDER_HASH_1',
      'PLACEHOLDER_HASH_2',
    ],
    includeSubdomains: true,
  );
}
