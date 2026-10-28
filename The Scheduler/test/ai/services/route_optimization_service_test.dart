@Tags(['ai'])
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_scheduler/ai/models/ai_exceptions.dart';
import 'package:the_scheduler/ai/models/optimized_route.dart';
import 'package:the_scheduler/ai/models/route_optimization_request.dart';
import 'package:the_scheduler/ai/repositories/route_repository.dart';
import 'package:the_scheduler/ai/services/ai_client.dart';
import 'package:the_scheduler/ai/services/route_optimization_service.dart';
import 'package:the_scheduler/core/config/ai_config.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([RouteRepository, AuditLogRepository])
import 'route_optimization_service_test.mocks.dart';

void main() {
  late RouteOptimizationService service;
  late MockRouteRepository mockRouteRepository;
  late MockAuditLogRepository mockAuditLogRepository;
  late AIConfig config;

  final testContext = SecurityContext(
    userId: 'user_123',
    businessId: 'business_123',
    role: UserRole.owner,
  );

  final testRequest = RouteOptimizationRequest(
    businessId: 'business_123',
    providerId: 'provider_123',
    routeDate: DateTime(2024, 1, 15),
    depotLatitude: 37.7749,
    depotLongitude: -122.4194,
    depotAddress: '123 Main St, San Francisco, CA',
    waypoints: [
      RouteWaypoint(
        id: 'waypoint_1',
        name: 'Client A',
        latitude: 37.7849,
        longitude: -122.4094,
        windowStart: DateTime(2024, 1, 15, 9, 0),
        windowEnd: DateTime(2024, 1, 15, 10, 0),
        serviceDurationMinutes: 60,
      ),
      RouteWaypoint(
        id: 'waypoint_2',
        name: 'Client B',
        latitude: 37.7649,
        longitude: -122.4294,
        windowStart: DateTime(2024, 1, 15, 10, 30),
        windowEnd: DateTime(2024, 1, 15, 11, 30),
        serviceDurationMinutes: 45,
      ),
    ],
    earliestDeparture: DateTime(2024, 1, 15, 8, 0),
    latestReturn: DateTime(2024, 1, 15, 18, 0),
  );

  setUp(() {
    mockRouteRepository = MockRouteRepository();
    mockAuditLogRepository = MockAuditLogRepository();
    config = AIConfig.test();

    when(mockAuditLogRepository.log(
      context: anyNamed('context'),
      action: anyNamed('action'),
      entityType: anyNamed('entityType'),
      entityId: anyNamed('entityId'),
      details: anyNamed('details'),
      source: anyNamed('source'),
    )).thenAnswer((_) async {});

    when(mockRouteRepository.saveRoute(any, any)).thenAnswer((_) async {});
  });

  group('RouteOptimizationService', () {
    test('optimizeRoute returns optimized route on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/v1/routes/optimize'));
        expect(request.headers['X-Business-ID'], 'business_123');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['business_id'], 'business_123');
        expect(body['provider_id'], 'provider_123');
        expect(body['waypoints'], hasLength(2));

        return http.Response(
          jsonEncode({
            'id': 'route_123',
            'business_id': 'business_123',
            'provider_id': 'provider_123',
            'provider_name': 'Test Provider',
            'status': 'planned',
            'stops': [
              {
                'id': 'stop_depot',
                'sequence_order': -1,
                'stop_type': 'depot',
                'name': 'Depot',
                'address': '123 Main St',
                'latitude': 37.7749,
                'longitude': -122.4194,
                'window_start': '2024-01-15T08:00:00.000Z',
                'window_end': '2024-01-15T09:00:00.000Z',
                'scheduled_arrival': '2024-01-15T08:00:00.000Z',
                'service_duration_minutes': 0,
              },
              {
                'id': 'stop_1',
                'sequence_order': 0,
                'stop_type': 'appointment',
                'name': 'Client A',
                'address': '456 Oak Ave',
                'latitude': 37.7849,
                'longitude': -122.4094,
                'window_start': '2024-01-15T09:00:00.000Z',
                'window_end': '2024-01-15T10:00:00.000Z',
                'scheduled_arrival': '2024-01-15T09:15:00.000Z',
                'service_duration_minutes': 60,
                'appointment_id': 'appt_1',
                'client_id': 'client_1',
              },
            ],
            'segments': [],
            'start_time': '2024-01-15T08:00:00.000Z',
            'expected_end_time': '2024-01-15T17:00:00.000Z',
            'total_distance_meters': 15000,
            'total_travel_time_seconds': 1800,
            'total_service_time_seconds': 6300,
            'time_saved_seconds': 600,
            'optimization_improvement_percent': 15.5,
            'optimizer_version': '1.0.0',
          }),
          200,
        );
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      final result = await service.optimizeRoute(testContext, testRequest);

      expect(result.id, 'route_123');
      expect(result.businessId, 'business_123');
      expect(result.providerId, 'provider_123');
      expect(result.status, RouteStatus.planned);
      expect(result.stops, isNotEmpty);
      expect(result.totalDistanceMeters, 15000);
      expect(result.timeSavedSeconds, 600);

      verify(mockRouteRepository.saveRoute(testContext, any)).called(1);
      verify(mockAuditLogRepository.log(
        context: testContext,
        action: 'ai_route_optimization_success',
        entityType: 'optimizedRoute',
        entityId: 'route_123',
        details: anyNamed('details'),
        source: 'RouteOptimizationService',
      )).called(1);
    });

    test('optimizeRoute throws validation error for invalid request', () async {
      final invalidRequest = RouteOptimizationRequest(
        businessId: 'business_123',
        providerId: 'provider_123',
        routeDate: DateTime(2024, 1, 15),
        depotLatitude: 37.7749,
        depotLongitude: -122.4194,
        depotAddress: '123 Main St',
        waypoints: [], // Empty waypoints - invalid
        earliestDeparture: DateTime(2024, 1, 15, 8, 0),
        latestReturn: DateTime(2024, 1, 15, 18, 0),
      );

      final mockClient = MockClient((request) async {
        return http.Response('', 500);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(
        () => service.optimizeRoute(testContext, invalidRequest),
        throwsA(isA<AIValidationException>()),
      );
    });

    test('optimizeRoute handles HTTP timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 10));
        return http.Response('', 200);
      });

      final shortTimeoutConfig = AIConfig.test().copyWith(readTimeoutMs: 100);
      final aiClient = AIClient(config: shortTimeoutConfig, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: shortTimeoutConfig,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(
        () => service.optimizeRoute(testContext, testRequest),
        throwsA(isA<AITimeoutException>()),
      );
    });

    test('optimizeRoute handles HTTP 400 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Invalid request',
            'code': 'VALIDATION_ERROR',
          }),
          400,
        );
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(
        () => service.optimizeRoute(testContext, testRequest),
        throwsA(isA<AIServerErrorException>()),
      );
    });

    test('optimizeRoute handles HTTP 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      // Use config with no retries for faster test
      final noRetryConfig = config.copyWith(maxRetries: 0);
      final aiClient = AIClient(config: noRetryConfig, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: noRetryConfig,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      expect(
        () => service.optimizeRoute(testContext, testRequest),
        throwsA(isA<AIServerErrorException>()),
      );
    });

    test('API calls include businessId for multi-tenant isolation', () async {
      String? capturedBusinessId;

      final mockClient = MockClient((request) async {
        capturedBusinessId = request.headers['X-Business-ID'];

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['business_id'], 'business_123');

        return http.Response(
          jsonEncode({
            'id': 'route_123',
            'stops': [],
            'segments': [],
            'total_distance_meters': 0,
            'total_travel_time_seconds': 0,
          }),
          200,
        );
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      await service.optimizeRoute(testContext, testRequest);

      expect(capturedBusinessId, 'business_123');
    });

    test('concurrent request handling', () async {
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        await Future.delayed(const Duration(milliseconds: 50));

        return http.Response(
          jsonEncode({
            'id': 'route_$requestCount',
            'stops': [],
            'segments': [],
            'total_distance_meters': 0,
            'total_travel_time_seconds': 0,
          }),
          200,
        );
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      // Send 3 concurrent requests
      final futures = <Future<OptimizedRoute>>[];
      for (int i = 0; i < 3; i++) {
        futures.add(service.optimizeRoute(testContext, testRequest));
      }

      final results = await Future.wait(futures);

      expect(results, hasLength(3));
      expect(requestCount, 3);
    });

    test('model conversion Flutter to JSON to Flutter', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'id': 'route_123',
            'stops': [
              {
                'id': 'stop_1',
                'sequence_order': 0,
                'stop_type': 'appointment',
                'name': 'Client A',
                'address': '456 Oak Ave',
                'latitude': 37.7849,
                'longitude': -122.4094,
                'window_start': '2024-01-15T09:00:00.000Z',
                'window_end': '2024-01-15T10:00:00.000Z',
                'scheduled_arrival': '2024-01-15T09:15:00.000Z',
                'service_duration_minutes': 60,
              },
            ],
            'segments': [],
            'total_distance_meters': 15000,
            'total_travel_time_seconds': 1800,
          }),
          200,
        );
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      final result = await service.optimizeRoute(testContext, testRequest);

      // Verify request body
      expect(capturedBody, isNotNull);
      expect(capturedBody!['business_id'], testRequest.businessId);
      expect(capturedBody!['provider_id'], testRequest.providerId);
      expect(capturedBody!['waypoints'], hasLength(2));
      expect(capturedBody!['waypoints'][0]['id'], 'waypoint_1');
      expect(capturedBody!['waypoints'][0]['latitude'], 37.7849);

      // Verify response parsing
      expect(result.id, 'route_123');
      expect(result.stops, hasLength(1));
      expect(result.stops[0].latitude, 37.7849);
      expect(result.totalDistanceMeters, 15000);
    });
  });

  group('Route Status Updates', () {
    test('startRoute updates status to inProgress', () async {
      when(mockRouteRepository.updateRouteStatus(any, any, any))
          .thenAnswer((_) async {});

      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      await service.startRoute(testContext, 'route_123');

      verify(mockRouteRepository.updateRouteStatus(
        testContext,
        'route_123',
        RouteStatus.inProgress,
      )).called(1);
    });

    test('completeRoute updates status to completed', () async {
      when(mockRouteRepository.updateRouteStatus(any, any, any))
          .thenAnswer((_) async {});

      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      await service.completeRoute(testContext, 'route_123');

      verify(mockRouteRepository.updateRouteStatus(
        testContext,
        'route_123',
        RouteStatus.completed,
      )).called(1);
    });

    test('cancelRoute updates status to cancelled', () async {
      when(mockRouteRepository.updateRouteStatus(any, any, any))
          .thenAnswer((_) async {});

      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      service = RouteOptimizationService(
        aiClient: aiClient,
        config: config,
        routeRepository: mockRouteRepository,
        auditLogRepository: mockAuditLogRepository,
      );

      await service.cancelRoute(testContext, 'route_123', reason: 'Weather');

      verify(mockRouteRepository.updateRouteStatus(
        testContext,
        'route_123',
        RouteStatus.cancelled,
      )).called(1);
    });
  });
}
