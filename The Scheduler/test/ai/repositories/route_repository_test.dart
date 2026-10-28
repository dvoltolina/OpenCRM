@Tags(['ai'])
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/extensions/client_routing_extension.dart';
import 'package:the_scheduler/ai/extensions/location_routing_extension.dart';
import 'package:the_scheduler/ai/models/optimized_route.dart';
import 'package:the_scheduler/ai/models/route_stop.dart';
import 'package:the_scheduler/ai/repositories/route_repository.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late RouteRepository repository;
  late AuditLogRepository auditLogRepository;
  late SecurityContext context;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    auditLogRepository = AuditLogRepository(firestore: fakeFirestore);
    repository = RouteRepository(
      firestore: fakeFirestore,
      auditLogRepository: auditLogRepository,
    );
    context = const SecurityContext(
      businessId: 'test_business',
      userId: 'test_user',
      role: UserRole.owner,
    );
  });

  group('RouteRepository', () {
    group('Route Operations', () {
      test('saves and retrieves route', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_1',
          businessId: 'test_business',
          providerId: 'provider_1',
          providerName: 'Dr. Test',
          routeDate: now,
          stops: [],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        await repository.saveRoute(context, route);
        final retrieved = await repository.getRoute(context, 'route_1');

        expect(retrieved, isNotNull);
        expect(retrieved!.providerId, 'provider_1');
        expect(retrieved.totalDistanceMeters, 10000);
      });

      test('returns null for non-existent route', () async {
        final retrieved = await repository.getRoute(context, 'nonexistent');
        expect(retrieved, isNull);
      });

      test('deletes route', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_delete',
          businessId: 'test_business',
          providerId: 'provider_1',
          providerName: 'Dr. Test',
          routeDate: now,
          stops: [],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        await repository.saveRoute(context, route);
        await repository.deleteRoute(context, 'route_delete');
        final retrieved = await repository.getRoute(context, 'route_delete');

        expect(retrieved, isNull);
      });

      test('updates route status', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_status',
          businessId: 'test_business',
          providerId: 'provider_1',
          providerName: 'Dr. Test',
          routeDate: now,
          status: RouteStatus.planned,
          stops: [],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        await repository.saveRoute(context, route);
        await repository.updateRouteStatus(
            context, 'route_status', RouteStatus.inProgress);

        final retrieved = await repository.getRoute(context, 'route_status');
        expect(retrieved!.status, RouteStatus.inProgress);
      });

      test('updates stop status', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_stop_update',
          businessId: 'test_business',
          providerId: 'provider_1',
          providerName: 'Dr. Test',
          routeDate: now,
          stops: [
            RouteStop(
              id: 'stop_1',
              sequenceOrder: 0,
              stopType: RouteStopType.appointment,
              status: RouteStopStatus.pending,
              name: 'Client A',
              address: '123 Main St',
              latitude: 40.0,
              longitude: -74.0,
              windowStart: now,
              windowEnd: now.add(const Duration(hours: 1)),
              scheduledArrival: now,
              serviceDurationMinutes: 30,
              updatedAt: now,
            ),
          ],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        await repository.saveRoute(context, route);
        await repository.updateStopStatus(
          context,
          'route_stop_update',
          'stop_1',
          RouteStopStatus.arrived,
          actualArrival: now,
        );

        final retrieved =
            await repository.getRoute(context, 'route_stop_update');
        expect(retrieved!.stops.first.status, RouteStopStatus.arrived);
        expect(retrieved.stops.first.actualArrival, isNotNull);
      });
    });

    group('Location Routing Data', () {
      test('saves and retrieves location routing data', () async {
        final data = LocationRoutingData(
          latitude: 40.7128,
          longitude: -74.0060,
          placeId: 'ChIJOwg_06VPwokRYv534QaPC8g',
          isMobileServiceBase: true,
          defaultTravelBufferMinutes: 15,
          timezone: 'America/New_York',
        );

        await repository.saveLocationRoutingData(context, 'location_1', data);
        final retrieved =
            await repository.getLocationRoutingData(context, 'location_1');

        expect(retrieved, isNotNull);
        expect(retrieved!.latitude, 40.7128);
        expect(retrieved.longitude, -74.0060);
        expect(retrieved.isMobileServiceBase, true);
      });

      test('returns null for non-existent location routing data', () async {
        final retrieved =
            await repository.getLocationRoutingData(context, 'nonexistent');
        expect(retrieved, isNull);
      });

      test('retrieves batch location routing data', () async {
        final data1 = LocationRoutingData(latitude: 40.0, longitude: -74.0);
        final data2 = LocationRoutingData(latitude: 41.0, longitude: -75.0);

        await repository.saveLocationRoutingData(context, 'loc_1', data1);
        await repository.saveLocationRoutingData(context, 'loc_2', data2);

        final results = await repository.getLocationRoutingDataBatch(
          context,
          ['loc_1', 'loc_2', 'loc_nonexistent'],
        );

        expect(results.length, 2);
        expect(results.containsKey('loc_1'), true);
        expect(results.containsKey('loc_2'), true);
        expect(results.containsKey('loc_nonexistent'), false);
      });
    });

    group('Client Routing Data', () {
      test('saves and retrieves client routing data', () async {
        final data = ClientRoutingData(
          requiresMobileService: true,
          serviceAddress: '123 Test St',
          serviceCity: 'Test City',
          serviceState: 'TS',
          serviceZipCode: '12345',
          serviceLatitude: 40.7128,
          serviceLongitude: -74.0060,
          arrivalNotes: 'Gate code: 1234',
        );

        await repository.saveClientRoutingData(context, 'client_1', data);
        final retrieved =
            await repository.getClientRoutingData(context, 'client_1');

        expect(retrieved, isNotNull);
        expect(retrieved!.serviceAddress, '123 Test St');
        expect(retrieved.hasServiceCoordinates, true);
        expect(retrieved.requiresMobileService, true);
      });

      test('returns null for non-existent client routing data', () async {
        final retrieved =
            await repository.getClientRoutingData(context, 'nonexistent');
        expect(retrieved, isNull);
      });

      test('retrieves batch client routing data', () async {
        final data1 = ClientRoutingData(
          requiresMobileService: true,
          serviceLatitude: 40.0,
          serviceLongitude: -74.0,
        );
        final data2 = ClientRoutingData(
          requiresMobileService: false,
          serviceLatitude: 41.0,
          serviceLongitude: -75.0,
        );

        await repository.saveClientRoutingData(context, 'client_1', data1);
        await repository.saveClientRoutingData(context, 'client_2', data2);

        final results = await repository.getClientRoutingDataBatch(
          context,
          ['client_1', 'client_2', 'client_nonexistent'],
        );

        expect(results.length, 2);
        expect(results.containsKey('client_1'), true);
        expect(results.containsKey('client_2'), true);
      });
    });

    group('HIPAA Audit Logging', () {
      test('logs route optimization on save', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_audit',
          businessId: 'test_business',
          providerId: 'provider_1',
          providerName: 'Dr. Audit Test',
          routeDate: now,
          stops: [],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        await repository.saveRoute(context, route);

        // Check that audit log was created
        final auditLogs = await fakeFirestore
            .collection('businesses')
            .doc('test_business')
            .collection('audit_logs')
            .get();

        expect(auditLogs.docs.isNotEmpty, true);

        final logData = auditLogs.docs.first.data();
        expect(logData['entityType'], 'optimizedRoute');
        expect(logData['entityId'], 'route_audit');
        expect(logData['userId'], 'test_user');
      });
    });

    group('Multi-tenant Isolation', () {
      test('cannot access routes from different business', () async {
        final now = DateTime.now();
        final route = OptimizedRoute(
          id: 'route_tenant',
          businessId: 'business_a',
          providerId: 'provider_1',
          providerName: 'Dr. A',
          routeDate: now,
          stops: [],
          segments: [],
          startTime: now,
          expectedEndTime: now.add(const Duration(hours: 8)),
          totalDistanceMeters: 10000,
          totalTravelTimeSeconds: 1200,
          totalServiceTimeSeconds: 3600,
          optimizerVersion: '1.0.0',
          optimizedAt: now,
          updatedAt: now,
        );

        // Save with business_a context
        final contextA = const SecurityContext(
          businessId: 'business_a',
          userId: 'user_a',
          role: UserRole.owner,
        );
        await RouteRepository(
          firestore: fakeFirestore,
          auditLogRepository: auditLogRepository,
        ).saveRoute(contextA, route);

        // Try to retrieve with business_b context
        final contextB = const SecurityContext(
          businessId: 'business_b',
          userId: 'user_b',
          role: UserRole.owner,
        );
        final retrieved = await RouteRepository(
          firestore: fakeFirestore,
          auditLogRepository: auditLogRepository,
        ).getRoute(contextB, 'route_tenant');

        // Should not find the route (different business)
        expect(retrieved, isNull);
      });
    });
  });
}
