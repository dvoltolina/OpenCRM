@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder', () {
    test('decode returns empty list for empty string', () {
      final result = PolylineDecoder.decode('');
      expect(result, isEmpty);
    });

    test('decode correctly decodes Google polyline example', () {
      // Standard Google polyline example
      // Encodes: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

      final result = PolylineDecoder.decode(encoded);

      expect(result, hasLength(3));
      expect(result[0].latitude, closeTo(38.5, 0.0001));
      expect(result[0].longitude, closeTo(-120.2, 0.0001));
      expect(result[1].latitude, closeTo(40.7, 0.0001));
      expect(result[1].longitude, closeTo(-120.95, 0.0001));
      expect(result[2].latitude, closeTo(43.252, 0.0001));
      expect(result[2].longitude, closeTo(-126.453, 0.0001));
    });

    test('decode handles single point', () {
      // Encode a single point: (37.7749, -122.4194)
      const encoded = 'ohreFnlbjV';

      final result = PolylineDecoder.decode(encoded);

      expect(result, hasLength(1));
      expect(result[0].latitude, closeTo(37.7749, 0.0001));
      expect(result[0].longitude, closeTo(-122.4194, 0.0001));
    });

    test('encode returns empty string for empty list', () {
      final result = PolylineDecoder.encode([]);
      expect(result, isEmpty);
    });

    test('encode produces valid output for known points', () {
      final points = [
        const LatLng(38.5, -120.2),
        const LatLng(40.7, -120.95),
        const LatLng(43.252, -126.453),
      ];

      final encoded = PolylineDecoder.encode(points);
      expect(encoded, isNotEmpty);

      // Verify roundtrip
      final decoded = PolylineDecoder.decode(encoded);
      expect(decoded, hasLength(3));
      expect(decoded[0].latitude, closeTo(38.5, 0.0001));
      expect(decoded[2].longitude, closeTo(-126.453, 0.0001));
    });

    test('encode-decode roundtrip preserves coordinates', () {
      final original = [
        const LatLng(37.7749, -122.4194),
        const LatLng(37.7849, -122.4094),
        const LatLng(37.7649, -122.4294),
      ];

      final encoded = PolylineDecoder.encode(original);
      final decoded = PolylineDecoder.decode(encoded);

      expect(decoded, hasLength(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(decoded[i].latitude, closeTo(original[i].latitude, 0.00001));
        expect(decoded[i].longitude, closeTo(original[i].longitude, 0.00001));
      }
    });

    test('encode handles negative coordinates', () {
      final points = [
        const LatLng(-33.8688, 151.2093), // Sydney
        const LatLng(-37.8136, 144.9631), // Melbourne
      ];

      final encoded = PolylineDecoder.encode(points);
      final decoded = PolylineDecoder.decode(encoded);

      expect(decoded[0].latitude, closeTo(-33.8688, 0.0001));
      expect(decoded[0].longitude, closeTo(151.2093, 0.0001));
    });
  });

  group('LatLng', () {
    test('equality works correctly', () {
      const a = LatLng(37.7749, -122.4194);
      const b = LatLng(37.7749, -122.4194);
      const c = LatLng(37.7750, -122.4194);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toJson and fromJson work correctly', () {
      const original = LatLng(37.7749, -122.4194);

      final json = original.toJson();
      final restored = LatLng.fromJson(json);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });

  group('PolylineUtils', () {
    group('calculateDistance', () {
      test('returns 0 for empty list', () {
        final distance = PolylineUtils.calculateDistance([]);
        expect(distance, 0.0);
      });

      test('returns 0 for single point', () {
        final distance = PolylineUtils.calculateDistance([
          const LatLng(37.7749, -122.4194),
        ]);
        expect(distance, 0.0);
      });

      test('calculates correct distance for two points', () {
        // San Francisco to Oakland (approx 13 km)
        final distance = PolylineUtils.calculateDistance([
          const LatLng(37.7749, -122.4194),
          const LatLng(37.8044, -122.2712),
        ]);

        expect(distance, greaterThan(10000));
        expect(distance, lessThan(20000));
      });

      test('calculates correct total distance for multiple points', () {
        // Triangle route
        final points = [
          const LatLng(37.7749, -122.4194),
          const LatLng(37.7849, -122.4094),
          const LatLng(37.7649, -122.4194),
        ];

        final distance = PolylineUtils.calculateDistance(points);

        // Each leg is roughly 1-2 km
        expect(distance, greaterThan(1000));
        expect(distance, lessThan(10000));
      });
    });

    group('simplify', () {
      test('returns same points for 2 or fewer points', () {
        final points = [
          const LatLng(37.7749, -122.4194),
          const LatLng(37.7849, -122.4094),
        ];

        final simplified = PolylineUtils.simplify(points, tolerance: 10);

        expect(simplified, hasLength(2));
      });

      test('simplifies straight line to endpoints', () {
        // Points in a straight line
        final points = [
          const LatLng(37.0, -122.0),
          const LatLng(37.5, -122.0),
          const LatLng(38.0, -122.0),
        ];

        final simplified = PolylineUtils.simplify(points, tolerance: 100);

        // Should reduce to just endpoints
        expect(simplified, hasLength(2));
        expect(simplified.first.latitude, 37.0);
        expect(simplified.last.latitude, 38.0);
      });

      test('preserves significant corners', () {
        // L-shaped path
        final points = [
          const LatLng(37.0, -122.0),
          const LatLng(37.5, -122.0), // Middle point
          const LatLng(37.5, -121.5), // Corner
          const LatLng(37.5, -121.0), // Middle point
          const LatLng(38.0, -121.0),
        ];

        final simplified = PolylineUtils.simplify(points, tolerance: 10);

        // Should preserve the corner
        expect(simplified.length, greaterThanOrEqualTo(3));
      });
    });

    group('getBounds', () {
      test('returns null for empty list', () {
        final bounds = PolylineUtils.getBounds([]);
        expect(bounds, isNull);
      });

      test('returns correct bounds', () {
        final points = [
          const LatLng(37.0, -122.5),
          const LatLng(38.0, -121.5),
          const LatLng(37.5, -122.0),
        ];

        final bounds = PolylineUtils.getBounds(points);

        expect(bounds, isNotNull);
        expect(bounds!.southwest.latitude, 37.0);
        expect(bounds.southwest.longitude, -122.5);
        expect(bounds.northeast.latitude, 38.0);
        expect(bounds.northeast.longitude, -121.5);
      });
    });

    group('getCenter', () {
      test('returns null for empty list', () {
        final center = PolylineUtils.getCenter([]);
        expect(center, isNull);
      });

      test('returns single point for single point list', () {
        final center = PolylineUtils.getCenter([
          const LatLng(37.0, -122.0),
        ]);

        expect(center!.latitude, 37.0);
        expect(center.longitude, -122.0);
      });

      test('returns correct center', () {
        final points = [
          const LatLng(36.0, -123.0),
          const LatLng(38.0, -121.0),
        ];

        final center = PolylineUtils.getCenter(points);

        expect(center!.latitude, closeTo(37.0, 0.0001));
        expect(center.longitude, closeTo(-122.0, 0.0001));
      });
    });

    group('findNearestPoint', () {
      test('returns null for empty polyline', () {
        final result = PolylineUtils.findNearestPoint(
          [],
          const LatLng(37.0, -122.0),
        );
        expect(result, isNull);
      });

      test('returns single point for single point polyline', () {
        final result = PolylineUtils.findNearestPoint(
          [const LatLng(37.0, -122.0)],
          const LatLng(37.5, -122.0),
        );

        expect(result, isNotNull);
        expect(result!.point.latitude, 37.0);
        expect(result.segmentIndex, 0);
      });

      test('finds nearest point on segment', () {
        final polyline = [
          const LatLng(37.0, -122.0),
          const LatLng(38.0, -122.0),
        ];

        final result = PolylineUtils.findNearestPoint(
          polyline,
          const LatLng(37.5, -121.9),
        );

        expect(result, isNotNull);
        expect(result!.point.latitude, closeTo(37.5, 0.1));
        expect(result.segmentIndex, 0);
      });

      test('finds correct segment for multi-segment polyline', () {
        final polyline = [
          const LatLng(37.0, -122.0),
          const LatLng(37.5, -122.0),
          const LatLng(38.0, -122.0),
        ];

        // Point near second segment
        final result = PolylineUtils.findNearestPoint(
          polyline,
          const LatLng(37.8, -121.9),
        );

        expect(result, isNotNull);
        expect(result!.segmentIndex, 1); // Second segment (index 1)
      });
    });

    group('sampleAtIntervals', () {
      test('returns empty for empty input', () {
        final result = PolylineUtils.sampleAtIntervals([], 100);
        expect(result, isEmpty);
      });

      test('returns single point for single point input', () {
        final result = PolylineUtils.sampleAtIntervals(
          [const LatLng(37.0, -122.0)],
          100,
        );
        expect(result, hasLength(1));
      });

      test('includes first and last points', () {
        final points = [
          const LatLng(37.0, -122.0),
          const LatLng(38.0, -122.0),
        ];

        final result = PolylineUtils.sampleAtIntervals(points, 50000);

        expect(result.first.latitude, 37.0);
        expect(result.last.latitude, 38.0);
      });
    });
  });
}
