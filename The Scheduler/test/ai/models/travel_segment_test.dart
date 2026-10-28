@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/travel_segment.dart';

void main() {
  group('TravelSegment', () {
    late TravelSegment segment;

    setUp(() {
      segment = TravelSegment(
        id: 'seg_1',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 5000,
        estimatedDurationSeconds: 600,
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7589,
        toLongitude: -73.9851,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
    });

    test('calculates distance in km correctly', () {
      expect(segment.distanceKm, 5.0);
    });

    test('calculates distance in miles correctly', () {
      expect(segment.distanceMiles, closeTo(3.11, 0.01));
    });

    test('calculates duration in minutes correctly', () {
      expect(segment.estimatedDurationMinutes, 10.0);
    });

    test('formats distance correctly', () {
      expect(segment.formattedDistance, '5.0km');
    });

    test('formats short distance in meters', () {
      final shortSegment = TravelSegment(
        id: 'seg_short',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 500,
        estimatedDurationSeconds: 60,
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7150,
        toLongitude: -74.0050,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(shortSegment.formattedDistance, '500m');
    });

    test('formats duration correctly', () {
      expect(segment.formattedDuration, '10min');
    });

    test('formats long duration with hours', () {
      final longSegment = TravelSegment(
        id: 'seg_long',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 100000,
        estimatedDurationSeconds: 5400, // 90 minutes
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 41.0000,
        toLongitude: -74.5000,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(longSegment.formattedDuration, '1h 30min');
    });

    test('identifies significant delay', () {
      final delayedSegment = TravelSegment(
        id: 'seg_delayed',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 5000,
        estimatedDurationSeconds: 600,
        actualDurationSeconds: 800, // 33% longer
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7589,
        toLongitude: -73.9851,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(delayedSegment.hadSignificantDelay, true);
    });

    test('identifies no delay when within threshold', () {
      final onTimeSegment = TravelSegment(
        id: 'seg_ontime',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 5000,
        estimatedDurationSeconds: 600,
        actualDurationSeconds: 650, // 8% longer - within 20%
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7589,
        toLongitude: -73.9851,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(onTimeSegment.hadSignificantDelay, false);
    });

    test('returns false for delay when no actual duration', () {
      expect(segment.hadSignificantDelay, false);
    });

    test('returns actual or estimated minutes', () {
      expect(segment.actualOrEstimatedMinutes, 10.0);

      final withActual = TravelSegment(
        id: 'seg_actual',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 5000,
        estimatedDurationSeconds: 600,
        actualDurationSeconds: 720,
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7589,
        toLongitude: -73.9851,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(withActual.actualOrEstimatedMinutes, 12.0);
    });

    test('handles traffic conditions', () {
      final heavyTraffic = TravelSegment(
        id: 'seg_traffic',
        routeId: 'route_1',
        fromStopId: 'stop_1',
        toStopId: 'stop_2',
        sequenceOrder: 1,
        distanceMeters: 5000,
        estimatedDurationSeconds: 600,
        trafficCondition: TrafficCondition.heavy,
        fromLatitude: 40.7128,
        fromLongitude: -74.0060,
        toLatitude: 40.7589,
        toLongitude: -73.9851,
        calculatedAt: DateTime.now(),
        routingSource: 'osrm',
      );
      expect(heavyTraffic.trafficCondition, TrafficCondition.heavy);
    });

    test('default traffic condition is unknown', () {
      expect(segment.trafficCondition, TrafficCondition.unknown);
    });
  });
}
