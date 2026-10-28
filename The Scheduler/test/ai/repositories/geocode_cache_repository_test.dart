@Tags(['ai'])
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/geocode_result.dart';
import 'package:the_scheduler/ai/repositories/geocode_cache_repository.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GeocodeCacheRepository repository;
  late AuditLogRepository auditLogRepository;
  late SecurityContext context;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    auditLogRepository = AuditLogRepository(firestore: fakeFirestore);
    repository = GeocodeCacheRepository(
      firestore: fakeFirestore,
      auditLogRepository: auditLogRepository,
    );
    context = const SecurityContext(
      businessId: 'test_business',
      userId: 'test_user',
      role: UserRole.owner,
    );
  });

  group('GeocodeCacheRepository', () {
    test('caches and retrieves geocode result', () async {
      final result = GeocodeResult(
        id: 'geo_1',
        originalAddress: '123 Main St, New York, NY 10001',
        formattedAddress: '123 Main Street, New York, NY 10001, USA',
        latitude: 40.7128,
        longitude: -74.0060,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, result);
      final retrieved = await repository.getCachedResult(
        context,
        '123 Main St, New York, NY 10001',
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.latitude, 40.7128);
      expect(retrieved.longitude, -74.0060);
      expect(retrieved.provider, GeocodeProvider.google);
      // Original address should be masked for security
      expect(retrieved.originalAddress, contains('***'));
    });

    test('returns null for non-existent address', () async {
      final retrieved = await repository.getCachedResult(
        context,
        'Unknown Address',
      );
      expect(retrieved, isNull);
    });

    test('returns null and deletes expired entries', () async {
      final expiredResult = GeocodeResult(
        id: 'geo_expired',
        originalAddress: '456 Expired St, Test City, TC 12345',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.openStreetMap,
        accuracy: GeocodeAccuracy.approximate,
        geocodedAt: DateTime.now().subtract(const Duration(days: 100)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      await repository.cacheResult(context, expiredResult);
      final retrieved = await repository.getCachedResult(
        context,
        '456 Expired St, Test City, TC 12345',
      );

      expect(retrieved, isNull);
    });

    test('normalizes addresses for consistent hashing', () async {
      final result = GeocodeResult(
        id: 'geo_norm',
        originalAddress: '789 Test Ave, City, State',
        latitude: 40.5,
        longitude: -74.5,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.geometricCenter,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, result);

      // Should match with different casing and spacing
      final retrieved1 = await repository.getCachedResult(
        context,
        '789 test ave, city, state',
      );
      final retrieved2 = await repository.getCachedResult(
        context,
        '  789  TEST  AVE,  CITY,  STATE  ',
      );

      expect(retrieved1, isNotNull);
      expect(retrieved2, isNotNull);
      expect(retrieved1!.latitude, retrieved2!.latitude);
    });

    test('deletes cached result', () async {
      final result = GeocodeResult(
        id: 'geo_del',
        originalAddress: '999 Delete Me St, City, State',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.manual,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, result);
      await repository.deleteCachedResult(context, '999 Delete Me St, City, State');

      final retrieved = await repository.getCachedResult(
        context,
        '999 Delete Me St, City, State',
      );
      expect(retrieved, isNull);
    });

    test('checks if address is cached', () async {
      final result = GeocodeResult(
        id: 'geo_check',
        originalAddress: '111 Check St, City, State',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, result);

      final isCached = await repository.isCached(context, '111 Check St, City, State');
      final isNotCached = await repository.isCached(context, '222 Not Cached St, City, State');

      expect(isCached, true);
      expect(isNotCached, false);
    });

    test('returns false for expired cached entries in isCached', () async {
      final expiredResult = GeocodeResult(
        id: 'geo_expired_check',
        originalAddress: '333 Expired Check St, City, State',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now().subtract(const Duration(days: 100)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      await repository.cacheResult(context, expiredResult);

      final isCached = await repository.isCached(context, '333 Expired Check St, City, State');
      expect(isCached, false);
    });

    test('caches multiple results in batch', () async {
      final results = [
        GeocodeResult(
          id: 'geo_batch_1',
          originalAddress: 'Batch Address 1, City, State',
          latitude: 40.1,
          longitude: -74.1,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        ),
        GeocodeResult(
          id: 'geo_batch_2',
          originalAddress: 'Batch Address 2, City, State',
          latitude: 40.2,
          longitude: -74.2,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        ),
      ];

      await repository.cacheResultsBatch(context, results);

      final retrieved1 = await repository.getCachedResult(
        context,
        'Batch Address 1, City, State',
      );
      final retrieved2 = await repository.getCachedResult(
        context,
        'Batch Address 2, City, State',
      );

      expect(retrieved1, isNotNull);
      expect(retrieved2, isNotNull);
      expect(retrieved1!.latitude, 40.1);
      expect(retrieved2!.latitude, 40.2);
    });

    test('retrieves multiple cached results in batch', () async {
      final results = [
        GeocodeResult(
          id: 'geo_batch_get_1',
          originalAddress: 'Batch Get 1, City, State',
          latitude: 40.1,
          longitude: -74.1,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        ),
        GeocodeResult(
          id: 'geo_batch_get_2',
          originalAddress: 'Batch Get 2, City, State',
          latitude: 40.2,
          longitude: -74.2,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        ),
      ];

      await repository.cacheResultsBatch(context, results);

      final batchResults = await repository.getCachedResultsBatch(context, [
        'Batch Get 1, City, State',
        'Batch Get 2, City, State',
        'Nonexistent Address, City, State',
      ]);

      expect(batchResults.length, 2);
      expect(batchResults.containsKey('Batch Get 1, City, State'), true);
      expect(batchResults.containsKey('Batch Get 2, City, State'), true);
      expect(batchResults.containsKey('Nonexistent Address, City, State'), false);
    });

    test('handles different geocode providers', () async {
      final googleResult = GeocodeResult(
        id: 'geo_google',
        originalAddress: 'Google Address, City, State',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      final osmResult = GeocodeResult(
        id: 'geo_osm',
        originalAddress: 'OSM Address, City, State',
        latitude: 41.0,
        longitude: -75.0,
        provider: GeocodeProvider.openStreetMap,
        accuracy: GeocodeAccuracy.geometricCenter,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      final manualResult = GeocodeResult(
        id: 'geo_manual',
        originalAddress: 'Manual Address, City, State',
        latitude: 42.0,
        longitude: -76.0,
        provider: GeocodeProvider.manual,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, googleResult);
      await repository.cacheResult(context, osmResult);
      await repository.cacheResult(context, manualResult);

      final retrievedGoogle = await repository.getCachedResult(
        context,
        'Google Address, City, State',
      );
      final retrievedOsm = await repository.getCachedResult(
        context,
        'OSM Address, City, State',
      );
      final retrievedManual = await repository.getCachedResult(
        context,
        'Manual Address, City, State',
      );

      expect(retrievedGoogle!.provider, GeocodeProvider.google);
      expect(retrievedOsm!.provider, GeocodeProvider.openStreetMap);
      expect(retrievedManual!.provider, GeocodeProvider.manual);
    });

    test('handles different accuracy levels', () async {
      final rooftopResult = GeocodeResult(
        id: 'geo_rooftop',
        originalAddress: 'Rooftop Address, City, State',
        latitude: 40.0,
        longitude: -74.0,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      final approximateResult = GeocodeResult(
        id: 'geo_approx',
        originalAddress: 'Approximate Address, City, State',
        latitude: 41.0,
        longitude: -75.0,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.approximate,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      await repository.cacheResult(context, rooftopResult);
      await repository.cacheResult(context, approximateResult);

      final retrievedRooftop = await repository.getCachedResult(
        context,
        'Rooftop Address, City, State',
      );
      final retrievedApprox = await repository.getCachedResult(
        context,
        'Approximate Address, City, State',
      );

      expect(retrievedRooftop!.accuracy, GeocodeAccuracy.rooftop);
      expect(retrievedRooftop.isSufficientForRouting, true);
      expect(retrievedApprox!.accuracy, GeocodeAccuracy.approximate);
      expect(retrievedApprox.isSufficientForRouting, false);
    });

    group('Multi-tenant Isolation', () {
      test('cannot access cache from different business', () async {
        final result = GeocodeResult(
          id: 'geo_tenant',
          originalAddress: '123 Tenant St, City, State',
          latitude: 40.0,
          longitude: -74.0,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        );

        // Cache with business_a
        final contextA = const SecurityContext(
          businessId: 'business_a',
          userId: 'user_a',
          role: UserRole.owner,
        );
        await repository.cacheResult(contextA, result);

        // Try to retrieve with business_b
        final contextB = const SecurityContext(
          businessId: 'business_b',
          userId: 'user_b',
          role: UserRole.owner,
        );
        final retrieved = await repository.getCachedResult(
          contextB,
          '123 Tenant St, City, State',
        );

        // Should not find the result (different business)
        expect(retrieved, isNull);
      });
    });

    group('HIPAA Compliance', () {
      test('masks original address in stored cache', () async {
        final result = GeocodeResult(
          id: 'geo_mask',
          originalAddress: '123 Client Home St, Private City, NY 10001',
          formattedAddress: '123 Client Home Street, Private City, NY 10001, USA',
          latitude: 40.7128,
          longitude: -74.0060,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        );

        await repository.cacheResult(context, result);

        // Verify the stored data is masked
        final retrieved = await repository.getCachedResult(
          context,
          '123 Client Home St, Private City, NY 10001',
        );

        expect(retrieved, isNotNull);
        // Original address should be masked
        expect(retrieved!.originalAddress, contains('***'));
        // Should NOT contain the street address
        expect(retrieved.originalAddress.contains('123 Client Home'), false);
        // Formatted address should be null (not stored)
        expect(retrieved.formattedAddress, isNull);
      });

      test('logs geocode operations in audit log', () async {
        final result = GeocodeResult(
          id: 'geo_audit',
          originalAddress: '456 Audit Test St, City, State',
          latitude: 40.0,
          longitude: -74.0,
          provider: GeocodeProvider.google,
          accuracy: GeocodeAccuracy.rooftop,
          geocodedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        );

        await repository.cacheResult(context, result, clientId: 'client_123');

        // Check that audit log was created
        final auditLogs = await fakeFirestore
            .collection('businesses')
            .doc('test_business')
            .collection('audit_logs')
            .get();

        expect(auditLogs.docs.isNotEmpty, true);

        final logData = auditLogs.docs.first.data();
        expect(logData['entityType'], 'geocodeCache');
        expect(logData['userId'], 'test_user');
      });
    });
  });
}
