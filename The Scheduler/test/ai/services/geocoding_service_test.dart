@Tags(['ai'])
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_scheduler/ai/models/geocode_result.dart';
import 'package:the_scheduler/ai/repositories/geocode_cache_repository.dart';
import 'package:the_scheduler/ai/services/geocoding_service.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([GeocodeCacheRepository, AuditLogRepository])
import 'geocoding_service_test.mocks.dart';

void main() {
  late GeocodingService service;
  late MockGeocodeCacheRepository mockCacheRepository;
  late MockAuditLogRepository mockAuditLogRepository;
  late GeocodingConfig config;

  final testContext = SecurityContext(
    userId: 'user_123',
    businessId: 'business_123',
    role: UserRole.owner,
  );

  setUp(() {
    mockCacheRepository = MockGeocodeCacheRepository();
    mockAuditLogRepository = MockAuditLogRepository();
    config = GeocodingConfig.development();

    when(mockAuditLogRepository.log(
      context: anyNamed('context'),
      action: anyNamed('action'),
      entityType: anyNamed('entityType'),
      entityId: anyNamed('entityId'),
      details: anyNamed('details'),
      source: anyNamed('source'),
    )).thenAnswer((_) async {});

    when(mockCacheRepository.cacheResult(any, any, clientId: anyNamed('clientId')))
        .thenAnswer((_) async {});
  });

  group('GeocodingService - Geocode Address', () {
    test('geocodeAddress returns cached result when available', () async {
      final cachedResult = GeocodeResult(
        id: 'geo_123',
        originalAddress: '123 Main St, San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      when(mockCacheRepository.getCachedResult(testContext, any))
          .thenAnswer((_) async => cachedResult);

      final mockClient = MockClient((request) async {
        fail('Should not call API when cache hit');
        return http.Response('', 500);
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.geocodeAddress(
        testContext,
        '123 Main St, San Francisco, CA',
      );

      expect(result, isNotNull);
      expect(result!.latitude, 37.7749);
      expect(result.longitude, -122.4194);

      verify(mockCacheRepository.getCachedResult(testContext, any)).called(1);
      verifyNever(mockCacheRepository.cacheResult(any, any));
    });

    test('geocodeAddress calls Nominatim when cache miss', () async {
      when(mockCacheRepository.getCachedResult(testContext, any))
          .thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.url.path, '/search');
        expect(request.headers['User-Agent'], contains('TheSchedulerApp'));

        return http.Response(
          jsonEncode([
            {
              'lat': '37.7749',
              'lon': '-122.4194',
              'display_name': '123 Main St, San Francisco, CA 94105, USA',
              'osm_id': 123456,
              'class': 'building',
              'address': {
                'house_number': '123',
                'road': 'Main St',
                'city': 'San Francisco',
                'state': 'California',
                'postcode': '94105',
                'country': 'United States',
              },
            },
          ]),
          200,
        );
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.geocodeAddress(
        testContext,
        '123 Main St, San Francisco, CA',
      );

      expect(result, isNotNull);
      expect(result!.latitude, 37.7749);
      expect(result.longitude, -122.4194);
      expect(result.provider, GeocodeProvider.openStreetMap);
      expect(result.accuracy, GeocodeAccuracy.rooftop);

      verify(mockCacheRepository.cacheResult(
        testContext,
        any,
        clientId: null,
      )).called(1);
    });

    test('geocodeAddress caches result with clientId', () async {
      when(mockCacheRepository.getCachedResult(testContext, any))
          .thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'lat': '37.7749',
              'lon': '-122.4194',
              'display_name': '123 Main St, San Francisco, CA',
              'class': 'building',
            },
          ]),
          200,
        );
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      await service.geocodeAddress(
        testContext,
        '123 Main St, San Francisco, CA',
        clientId: 'client_123',
      );

      verify(mockCacheRepository.cacheResult(
        testContext,
        any,
        clientId: 'client_123',
      )).called(1);

      verify(mockAuditLogRepository.log(
        context: testContext,
        action: 'geocode_client_address',
        entityType: 'geocodeResult',
        entityId: 'client_123',
        details: anyNamed('details'),
        source: 'GeocodingService',
      )).called(1);
    });

    test('geocodeAddress handles empty address', () async {
      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      final result = await service.geocodeAddress(testContext, '');

      expect(result, isNull);
      verifyNever(mockCacheRepository.getCachedResult(any, any));
    });

    test('geocodeAddress handles API error gracefully', () async {
      when(mockCacheRepository.getCachedResult(testContext, any))
          .thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.geocodeAddress(
        testContext,
        '123 Main St, San Francisco, CA',
      );

      expect(result, isNull);
    });

    test('geocodeAddress handles empty API response', () async {
      when(mockCacheRepository.getCachedResult(testContext, any))
          .thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.geocodeAddress(
        testContext,
        'Invalid Address That Does Not Exist',
      );

      expect(result, isNull);
    });
  });

  group('GeocodingService - Reverse Geocode', () {
    test('reverseGeocode returns address for coordinates', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/reverse');
        expect(request.url.queryParameters['lat'], '37.7749');
        expect(request.url.queryParameters['lon'], '-122.4194');

        return http.Response(
          jsonEncode({
            'display_name': '123 Main St, San Francisco, CA 94105, USA',
            'osm_id': 123456,
            'address': {
              'house_number': '123',
              'road': 'Main St',
              'city': 'San Francisco',
              'state': 'California',
              'postcode': '94105',
              'country': 'United States',
            },
          }),
          200,
        );
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.reverseGeocode(
        testContext,
        37.7749,
        -122.4194,
      );

      expect(result, isNotNull);
      expect(result!.formattedAddress, contains('Main St'));
      expect(result.latitude, 37.7749);
      expect(result.longitude, -122.4194);
    });

    test('reverseGeocode handles API error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Unable to geocode'}),
          200,
        );
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final result = await service.reverseGeocode(testContext, 0, 0);

      expect(result, isNull);
    });
  });

  group('GeocodingService - Batch Geocoding', () {
    test('geocodeAddressesBatch returns cached and new results', () async {
      final cachedResult = GeocodeResult(
        id: 'geo_1',
        originalAddress: 'Address 1',
        latitude: 37.7749,
        longitude: -122.4194,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      when(mockCacheRepository.getCachedResultsBatch(testContext, any))
          .thenAnswer((_) async => {'Address 1': cachedResult});

      when(mockCacheRepository.getCachedResult(testContext, 'Address 2'))
          .thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'lat': '37.7850',
              'lon': '-122.4000',
              'display_name': 'Address 2, SF, CA',
              'class': 'building',
            },
          ]),
          200,
        );
      });

      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
        httpClient: mockClient,
      );

      final results = await service.geocodeAddressesBatch(
        testContext,
        ['Address 1', 'Address 2'],
      );

      expect(results, hasLength(2));
      expect(results['Address 1']!.latitude, 37.7749); // From cache
      expect(results['Address 2']!.latitude, 37.7850); // From API
    });
  });

  group('GeocodingService - Distance Calculation', () {
    test('calculateDistance returns correct distance', () async {
      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      // San Francisco to Oakland (approx 13 km)
      final distance = service.calculateDistance(
        37.7749, -122.4194, // San Francisco
        37.8044, -122.2712, // Oakland
      );

      // Should be approximately 13 km (13000 meters)
      expect(distance, greaterThan(10000));
      expect(distance, lessThan(20000));
    });

    test('calculateDistance returns 0 for same point', () async {
      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      final distance = service.calculateDistance(
        37.7749, -122.4194,
        37.7749, -122.4194,
      );

      expect(distance, closeTo(0, 0.1));
    });
  });

  group('GeocodingService - Coordinate Validation', () {
    test('validateCoordinates returns true for valid coordinates', () async {
      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(service.validateCoordinates(37.7749, -122.4194), isTrue);
      expect(service.validateCoordinates(0, 0), isTrue);
      expect(service.validateCoordinates(-90, -180), isTrue);
      expect(service.validateCoordinates(90, 180), isTrue);
    });

    test('validateCoordinates returns false for invalid coordinates', () async {
      service = GeocodingService(
        config: config,
        cacheRepository: mockCacheRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(service.validateCoordinates(91, 0), isFalse);
      expect(service.validateCoordinates(-91, 0), isFalse);
      expect(service.validateCoordinates(0, 181), isFalse);
      expect(service.validateCoordinates(0, -181), isFalse);
    });
  });
}
