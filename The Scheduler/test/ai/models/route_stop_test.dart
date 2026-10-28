@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/route_stop.dart';

void main() {
  group('RouteStop', () {
    test('creates valid appointment stop', () {
      final stop = RouteStop(
        id: 'stop_1',
        sequenceOrder: 0,
        stopType: RouteStopType.appointment,
        name: 'John Doe',
        address: '123 Main St, City, ST 12345',
        latitude: 40.7128,
        longitude: -74.0060,
        windowStart: DateTime(2024, 1, 15, 9, 0),
        windowEnd: DateTime(2024, 1, 15, 10, 0),
        scheduledArrival: DateTime(2024, 1, 15, 9, 15),
        serviceDurationMinutes: 30,
        appointmentId: 'appt_123',
        clientId: 'client_456',
        updatedAt: DateTime.now(),
      );

      expect(stop.isAppointment, true);
      expect(stop.isCompleted, false);
      expect(stop.scheduledDeparture, DateTime(2024, 1, 15, 9, 45));
    });

    test('creates valid depot stop', () {
      final depot = RouteStopExtensions.depot(
        id: 'depot_1',
        name: 'Office',
        address: '456 Business Ave',
        latitude: 40.7589,
        longitude: -73.9851,
        departureTime: DateTime(2024, 1, 15, 8, 0),
      );

      expect(depot.stopType, RouteStopType.depot);
      expect(depot.isAppointment, false);
      expect(depot.serviceDurationMinutes, 0);
    });

    test('creates end depot stop', () {
      final endDepot = RouteStopExtensions.depot(
        id: 'depot_end',
        name: 'Home',
        address: '789 Home St',
        latitude: 40.7000,
        longitude: -74.0000,
        departureTime: DateTime(2024, 1, 15, 17, 0),
        isEndDepot: true,
      );

      expect(endDepot.stopType, RouteStopType.endDepot);
      expect(endDepot.sequenceOrder, 9999);
    });

    test('correctly identifies late stops', () {
      final lateStop = RouteStop(
        id: 'stop_late',
        sequenceOrder: 1,
        stopType: RouteStopType.appointment,
        status: RouteStopStatus.pending,
        name: 'Late Client',
        address: '789 Late St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime.now().subtract(const Duration(hours: 2)),
        windowEnd: DateTime.now().subtract(const Duration(hours: 1)),
        scheduledArrival:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        serviceDurationMinutes: 60,
        updatedAt: DateTime.now(),
      );

      expect(lateStop.isLate, true);
    });

    test('correctly identifies completed stops', () {
      final completedStop = RouteStop(
        id: 'stop_completed',
        sequenceOrder: 1,
        stopType: RouteStopType.appointment,
        status: RouteStopStatus.completed,
        name: 'Done Client',
        address: '123 Done St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime.now(),
        windowEnd: DateTime.now().add(const Duration(hours: 1)),
        scheduledArrival: DateTime.now(),
        serviceDurationMinutes: 30,
        updatedAt: DateTime.now(),
      );

      expect(completedStop.isCompleted, true);
    });

    test('correctly identifies skipped stops as completed', () {
      final skippedStop = RouteStop(
        id: 'stop_skipped',
        sequenceOrder: 1,
        stopType: RouteStopType.appointment,
        status: RouteStopStatus.skipped,
        name: 'Skipped Client',
        address: '123 Skip St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime.now(),
        windowEnd: DateTime.now().add(const Duration(hours: 1)),
        scheduledArrival: DateTime.now(),
        serviceDurationMinutes: 30,
        updatedAt: DateTime.now(),
      );

      expect(skippedStop.isCompleted, true);
    });

    test('correctly identifies no-show stops as completed', () {
      final noShowStop = RouteStop(
        id: 'stop_noshow',
        sequenceOrder: 1,
        stopType: RouteStopType.appointment,
        status: RouteStopStatus.clientNoShow,
        name: 'NoShow Client',
        address: '123 NoShow St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime.now(),
        windowEnd: DateTime.now().add(const Duration(hours: 1)),
        scheduledArrival: DateTime.now(),
        serviceDurationMinutes: 30,
        updatedAt: DateTime.now(),
      );

      expect(noShowStop.isCompleted, true);
    });

    test('calculates scheduled departure with buffer', () {
      final stop = RouteStop(
        id: 'stop_buffer',
        sequenceOrder: 0,
        stopType: RouteStopType.appointment,
        name: 'Client',
        address: '123 Main St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime(2024, 1, 15, 9, 0),
        windowEnd: DateTime(2024, 1, 15, 10, 0),
        scheduledArrival: DateTime(2024, 1, 15, 9, 0),
        serviceDurationMinutes: 30,
        bufferMinutes: 15,
        updatedAt: DateTime.now(),
      );

      // 9:00 + 30 min service + 15 min buffer = 9:45
      expect(stop.scheduledDeparture, DateTime(2024, 1, 15, 9, 45));
    });

    test('returns coordinates as tuple', () {
      final stop = RouteStop(
        id: 'stop_coords',
        sequenceOrder: 0,
        stopType: RouteStopType.appointment,
        name: 'Client',
        address: '123 Main St',
        latitude: 40.7128,
        longitude: -74.0060,
        windowStart: DateTime.now(),
        windowEnd: DateTime.now().add(const Duration(hours: 1)),
        scheduledArrival: DateTime.now(),
        serviceDurationMinutes: 30,
        updatedAt: DateTime.now(),
      );

      final (lat, lng) = stop.coordinates;
      expect(lat, 40.7128);
      expect(lng, -74.0060);
    });

    test('identifies stop within window', () {
      final stop = RouteStop(
        id: 'stop_window',
        sequenceOrder: 0,
        stopType: RouteStopType.appointment,
        name: 'Client',
        address: '123 Main St',
        latitude: 40.0,
        longitude: -74.0,
        windowStart: DateTime.now().subtract(const Duration(minutes: 30)),
        windowEnd: DateTime.now().add(const Duration(minutes: 30)),
        scheduledArrival: DateTime.now(),
        serviceDurationMinutes: 30,
        updatedAt: DateTime.now(),
      );

      expect(stop.isWithinWindow, true);
    });
  });
}
