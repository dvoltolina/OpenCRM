@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/optimized_route.dart';
import 'package:the_scheduler/ai/models/route_stop.dart';
import 'package:the_scheduler/ai/models/travel_segment.dart';

void main() {
  group('OptimizedRoute', () {
    late OptimizedRoute route;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      route = OptimizedRoute(
        id: 'route_1',
        businessId: 'biz_123',
        providerId: 'provider_456',
        providerName: 'Dr. Smith',
        routeDate: now,
        stops: [
          RouteStopExtensions.depot(
            id: 'depot',
            name: 'Office',
            address: '123 Office St',
            latitude: 40.0,
            longitude: -74.0,
            departureTime: now.add(const Duration(hours: 8)),
          ),
          RouteStop(
            id: 'stop_1',
            sequenceOrder: 0,
            stopType: RouteStopType.appointment,
            status: RouteStopStatus.completed,
            name: 'Client A',
            address: '456 Client A St',
            latitude: 40.1,
            longitude: -74.1,
            windowStart: now.add(const Duration(hours: 9)),
            windowEnd: now.add(const Duration(hours: 10)),
            scheduledArrival: now.add(const Duration(hours: 9, minutes: 15)),
            serviceDurationMinutes: 30,
            appointmentId: 'appt_1',
            updatedAt: now,
          ),
          RouteStop(
            id: 'stop_2',
            sequenceOrder: 1,
            stopType: RouteStopType.appointment,
            status: RouteStopStatus.pending,
            name: 'Client B',
            address: '789 Client B St',
            latitude: 40.2,
            longitude: -74.2,
            windowStart: now.add(const Duration(hours: 10)),
            windowEnd: now.add(const Duration(hours: 11)),
            scheduledArrival: now.add(const Duration(hours: 10, minutes: 15)),
            serviceDurationMinutes: 45,
            appointmentId: 'appt_2',
            updatedAt: now,
          ),
        ],
        segments: [],
        startTime: now.add(const Duration(hours: 8)),
        expectedEndTime: now.add(const Duration(hours: 12)),
        totalDistanceMeters: 15000,
        totalTravelTimeSeconds: 1800,
        totalServiceTimeSeconds: 4500,
        originalTravelTimeSeconds: 2400,
        timeSavedSeconds: 600,
        optimizerVersion: '1.0.0',
        optimizedAt: now,
        updatedAt: now,
      );
    });

    test('calculates appointment count correctly', () {
      expect(route.appointmentCount, 2);
    });

    test('calculates completed stops correctly', () {
      expect(route.completedStopsCount, 1);
    });

    test('calculates progress correctly', () {
      expect(route.progressPercent, 0.5);
    });

    test('identifies current stop', () {
      expect(route.currentStop?.id, 'stop_2');
    });

    test('identifies next stop', () {
      // Current stop is stop_2 (index 2), so next would be index 3 which doesn't exist
      expect(route.nextStop, isNull);
    });

    test('calculates savings correctly', () {
      expect(route.timeSavedMinutes, 10.0);
      expect(route.hasSignificantSavings, true);
    });

    test('converts distances correctly', () {
      expect(route.totalDistanceKm, 15.0);
      expect(route.totalDistanceMiles, closeTo(9.32, 0.01));
    });

    test('calculates total travel time in minutes', () {
      expect(route.totalTravelTimeMinutes, 30.0); // 1800 seconds
    });

    test('calculates total service time in minutes', () {
      expect(route.totalServiceTimeMinutes, 75.0); // 4500 seconds
    });

    test('calculates total duration in minutes', () {
      expect(route.totalDurationMinutes, 105.0); // 30 + 75
    });

    test('formats savings string for minutes', () {
      expect(route.formattedSavings, '10 min saved');
    });

    test('formats savings string for hours', () {
      final longSavingsRoute = route.copyWith(timeSavedSeconds: 5400); // 90 min
      expect(longSavingsRoute.formattedSavings, '1h 30min saved');
    });

    test('identifies when route can be reoptimized', () {
      expect(route.canReoptimize, true); // status is planned

      final inProgressRoute = route.copyWith(status: RouteStatus.inProgress);
      expect(inProgressRoute.canReoptimize, false);

      final completedRoute = route.copyWith(status: RouteStatus.completed);
      expect(completedRoute.canReoptimize, false);

      final needsReoptimizationRoute =
          route.copyWith(status: RouteStatus.needsReoptimization);
      expect(needsReoptimizationRoute.canReoptimize, true);
    });

    test('returns appointment stops only', () {
      final appointmentStops = route.appointmentStops;
      expect(appointmentStops.length, 2);
      expect(appointmentStops.every((s) => s.isAppointment), true);
    });

    test('handles empty route', () {
      final emptyRoute = OptimizedRoute(
        id: 'empty_route',
        businessId: 'biz_123',
        providerId: 'provider_456',
        providerName: 'Dr. Smith',
        routeDate: now,
        stops: [],
        segments: [],
        startTime: now,
        expectedEndTime: now.add(const Duration(hours: 8)),
        totalDistanceMeters: 0,
        totalTravelTimeSeconds: 0,
        totalServiceTimeSeconds: 0,
        optimizerVersion: '1.0.0',
        optimizedAt: now,
        updatedAt: now,
      );

      expect(emptyRoute.appointmentCount, 0);
      expect(emptyRoute.progressPercent, 1.0);
      expect(emptyRoute.currentStop, isNull);
      expect(emptyRoute.estimatedCompletion, now.add(const Duration(hours: 8)));
    });

    test('handles route with all completed stops', () {
      final allCompletedRoute = route.copyWith(
        stops: route.stops
            .map((s) => s.isAppointment
                ? s.copyWith(status: RouteStopStatus.completed)
                : s)
            .toList(),
      );

      expect(allCompletedRoute.completedStopsCount, 2);
      expect(allCompletedRoute.progressPercent, 1.0);
      expect(allCompletedRoute.currentStop, isNull);
    });

    test('identifies running late', () {
      // Create a route with a late stop
      final lateRoute = OptimizedRoute(
        id: 'late_route',
        businessId: 'biz_123',
        providerId: 'provider_456',
        providerName: 'Dr. Smith',
        routeDate: now,
        stops: [
          RouteStop(
            id: 'late_stop',
            sequenceOrder: 0,
            stopType: RouteStopType.appointment,
            status: RouteStopStatus.pending,
            name: 'Late Client',
            address: '123 Late St',
            latitude: 40.0,
            longitude: -74.0,
            windowStart: now.subtract(const Duration(hours: 2)),
            windowEnd: now.subtract(const Duration(hours: 1)),
            scheduledArrival: now.subtract(const Duration(hours: 1)),
            serviceDurationMinutes: 30,
            updatedAt: now,
          ),
        ],
        segments: [],
        startTime: now.subtract(const Duration(hours: 3)),
        expectedEndTime: now,
        totalDistanceMeters: 5000,
        totalTravelTimeSeconds: 600,
        totalServiceTimeSeconds: 1800,
        optimizerVersion: '1.0.0',
        optimizedAt: now,
        updatedAt: now,
      );

      expect(lateRoute.isRunningLate, true);
    });

    test('has no significant savings when savings are small', () {
      final smallSavingsRoute = route.copyWith(timeSavedSeconds: 200); // 3.3 min
      expect(smallSavingsRoute.hasSignificantSavings, false);
    });
  });
}
