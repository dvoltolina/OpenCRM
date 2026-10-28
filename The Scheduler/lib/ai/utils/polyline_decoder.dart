/// Utilities for decoding/encoding polylines from routing services.
///
/// Supports both Google Encoded Polyline format and OSRM format.
/// These formats are used to efficiently transmit route geometries.
library polyline_decoder;

/// A coordinate point with latitude and longitude.
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      latitude == other.latitude &&
      longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  /// Convert to map for JSON serialization.
  Map<String, double> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  /// Create from JSON map.
  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
}

/// Decoder for Google Encoded Polyline Algorithm Format.
///
/// Reference: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
///
/// The encoding uses ASCII characters to represent a series of latitude and
/// longitude deltas with variable-length encoding.
class PolylineDecoder {
  /// Decode an encoded polyline string into a list of coordinates.
  ///
  /// Example:
  /// ```dart
  /// final points = PolylineDecoder.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
  /// // Returns list of LatLng points
  /// ```
  static List<LatLng> decode(String encoded, {int precision = 5}) {
    if (encoded.isEmpty) return [];

    final points = <LatLng>[];
    final precisionFactor = _pow10(precision);

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;

      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(
        lat / precisionFactor,
        lng / precisionFactor,
      ));
    }

    return points;
  }

  /// Encode a list of coordinates into a polyline string.
  ///
  /// Example:
  /// ```dart
  /// final encoded = PolylineDecoder.encode([
  ///   LatLng(38.5, -120.2),
  ///   LatLng(40.7, -120.95),
  ///   LatLng(43.252, -126.453),
  /// ]);
  /// ```
  static String encode(List<LatLng> points, {int precision = 5}) {
    if (points.isEmpty) return '';

    final precisionFactor = _pow10(precision);
    final buffer = StringBuffer();

    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final lat = (point.latitude * precisionFactor).round();
      final lng = (point.longitude * precisionFactor).round();

      _encodeValue(lat - prevLat, buffer);
      _encodeValue(lng - prevLng, buffer);

      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    int v = value < 0 ? ~(value << 1) : (value << 1);

    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1F)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static double _pow10(int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}

/// Utilities for polyline manipulation.
class PolylineUtils {
  /// Calculate the total distance of a polyline in meters.
  static double calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _haversineDistance(points[i], points[i + 1]);
    }
    return total;
  }

  /// Calculate distance between two points using Haversine formula.
  /// Returns distance in meters.
  static double _haversineDistance(LatLng p1, LatLng p2) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);

    final lat1 = _toRadians(p1.latitude);
    final lat2 = _toRadians(p2.latitude);

    final a = _sin2(dLat / 2) + _cos(lat1) * _cos(lat2) * _sin2(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Simplify a polyline using the Douglas-Peucker algorithm.
  ///
  /// [tolerance] is the maximum perpendicular distance in meters
  /// from the simplified line to any removed point.
  static List<LatLng> simplify(List<LatLng> points, {double tolerance = 10.0}) {
    if (points.length <= 2) return List.from(points);

    // Find the point with maximum distance from the line
    double maxDistance = 0;
    int maxIndex = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = simplify(points.sublist(0, maxIndex + 1), tolerance: tolerance);
      final right = simplify(points.sublist(maxIndex), tolerance: tolerance);

      // Combine results (avoiding duplicate at junction)
      return [...left.sublist(0, left.length - 1), ...right];
    }

    // All points within tolerance, return just endpoints
    return [first, last];
  }

  /// Calculate perpendicular distance from a point to a line.
  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Convert to meters for calculation
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;

    final lineLengthSq = dx * dx + dy * dy;

    if (lineLengthSq == 0) {
      return _haversineDistance(point, lineStart);
    }

    // Calculate projection
    var t = ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        lineLengthSq;
    t = t.clamp(0.0, 1.0);

    final projection = LatLng(
      lineStart.latitude + t * dy,
      lineStart.longitude + t * dx,
    );

    return _haversineDistance(point, projection);
  }

  /// Get bounds of a polyline.
  static ({LatLng southwest, LatLng northeast})? getBounds(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return (
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Get center point of a polyline.
  static LatLng? getCenter(List<LatLng> points) {
    if (points.isEmpty) return null;

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  /// Find the point on the polyline nearest to the given point.
  static ({LatLng point, int segmentIndex, double distanceMeters})?
      findNearestPoint(List<LatLng> polyline, LatLng point) {
    if (polyline.isEmpty) return null;
    if (polyline.length == 1) {
      return (
        point: polyline[0],
        segmentIndex: 0,
        distanceMeters: _haversineDistance(point, polyline[0]),
      );
    }

    double minDistance = double.infinity;
    LatLng nearestPoint = polyline[0];
    int nearestSegment = 0;

    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];

      final nearest = _nearestPointOnSegment(point, segmentStart, segmentEnd);
      final distance = _haversineDistance(point, nearest);

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = nearest;
        nearestSegment = i;
      }
    }

    return (
      point: nearestPoint,
      segmentIndex: nearestSegment,
      distanceMeters: minDistance,
    );
  }

  /// Find nearest point on a line segment.
  static LatLng _nearestPointOnSegment(LatLng point, LatLng start, LatLng end) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;

    final lineLengthSq = dx * dx + dy * dy;

    if (lineLengthSq == 0) return start;

    var t = ((point.longitude - start.longitude) * dx +
            (point.latitude - start.latitude) * dy) /
        lineLengthSq;
    t = t.clamp(0.0, 1.0);

    return LatLng(
      start.latitude + t * dy,
      start.longitude + t * dx,
    );
  }

  /// Sample points along a polyline at regular intervals.
  ///
  /// [intervalMeters] is the distance between sampled points.
  static List<LatLng> sampleAtIntervals(List<LatLng> points, double intervalMeters) {
    if (points.isEmpty) return [];
    if (points.length == 1) return [points[0]];

    final result = <LatLng>[points[0]];
    double accumulated = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final segmentDistance = _haversineDistance(points[i], points[i + 1]);

      while (accumulated + (intervalMeters - accumulated % intervalMeters) < segmentDistance) {
        final remaining = intervalMeters - accumulated;
        final fraction = remaining / segmentDistance;

        final interpolated = LatLng(
          points[i].latitude + fraction * (points[i + 1].latitude - points[i].latitude),
          points[i].longitude + fraction * (points[i + 1].longitude - points[i].longitude),
        );

        result.add(interpolated);
        accumulated = 0;
      }

      accumulated += segmentDistance;
    }

    // Always include the last point
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result;
  }

  // Math helpers
  static double _toRadians(double degrees) => degrees * 3.141592653589793 / 180.0;
  static double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _sqrt(double x) => x > 0 ? _newtonSqrt(x) : 0;

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  static double _atan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.141592653589793 / 2 - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int i = 1; i < 20; i += 2) {
      result += term / i;
      term *= -x * x;
    }
    return result;
  }

  static double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
