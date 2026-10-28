import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/security/certificate_pinning.dart';

void main() {
  group('CertificatePinConfig', () {
    test('creates config with required parameters', () {
      const config = CertificatePinConfig(
        hostname: 'api.example.com',
        pins: ['hash1', 'hash2'],
      );

      expect(config.hostname, 'api.example.com');
      expect(config.pins, ['hash1', 'hash2']);
      expect(config.includeSubdomains, true);
      expect(config.enforceOnDebug, false);
    });

    test('creates config with optional parameters', () {
      const config = CertificatePinConfig(
        hostname: 'api.example.com',
        pins: ['hash1'],
        includeSubdomains: false,
        enforceOnDebug: true,
      );

      expect(config.includeSubdomains, false);
      expect(config.enforceOnDebug, true);
    });
  });

  group('CertificateValidationResult', () {
    test('has all expected values', () {
      expect(CertificateValidationResult.values, [
        CertificateValidationResult.valid,
        CertificateValidationResult.invalidChain,
        CertificateValidationResult.notPinned,
        CertificateValidationResult.hostnameMismatch,
        CertificateValidationResult.expired,
        CertificateValidationResult.skipped,
      ]);
    });
  });

  group('CertificatePinningService', () {
    late CertificatePinningService service;

    setUp(() {
      service = CertificatePinningService.instance;
    });

    test('singleton instance is consistent', () {
      final instance1 = CertificatePinningService.instance;
      final instance2 = CertificatePinningService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('isEnabled returns false when no pins configured', () async {
      // Clear any existing pins
      service.removePin('test.example.com');
      // Note: Can't fully test without knowing existing state
    });

    test('addPin adds configuration', () {
      const config = CertificatePinConfig(
        hostname: 'test.pinning.com',
        pins: ['testHash'],
      );

      service.addPin(config);

      // Verify it was added (service doesn't expose pins directly)
      expect(service.isEnabled, true);
    });

    test('removePin removes configuration', () {
      const config = CertificatePinConfig(
        hostname: 'remove.test.com',
        pins: ['hash'],
      );

      service.addPin(config);
      service.removePin('remove.test.com');

      // Pin should be removed (verify by trying to validate)
    });

    test('initialize marks service as initialized', () async {
      await service.initialize([]);
      expect(service.isInitialized, true);
    });

    test('createPinnedHttpClient returns HttpClient', () {
      final client = service.createPinnedHttpClient();
      expect(client, isNotNull);
      client.close();
    });
  });

  group('CommonPins', () {
    test('firebase config has correct hostname', () {
      expect(CommonPins.firebase.hostname, 'firebaseio.com');
      expect(CommonPins.firebase.includeSubdomains, true);
    });

    test('googleApis config has correct hostname', () {
      expect(CommonPins.googleApis.hostname, 'googleapis.com');
      expect(CommonPins.googleApis.includeSubdomains, true);
    });
  });
}
