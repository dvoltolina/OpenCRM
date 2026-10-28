/// Map configuration and constants for route visualization.
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Configuration for map display and behavior.
class MapConfig {
  MapConfig._();

  /// Default center (US center) when no route data
  static const LatLng defaultCenter = LatLng(39.8283, -98.5795);

  /// Default zoom level
  static const double defaultZoom = 12.0;

  /// Min/max zoom constraints
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  /// Zoom level for single stop focus
  static const double stopFocusZoom = 15.0;

  /// Padding for fitting bounds (in pixels)
  static const EdgeInsets boundspadding = EdgeInsets.all(50.0);

  /// OpenStreetMap tile server URL
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Attribution for OpenStreetMap
  static const String osmAttribution =
      '© OpenStreetMap contributors';

  /// Alternative tile servers (for fallback or different styles)
  static const String cartoLightUrl =
      'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
  static const String cartoDarkUrl =
      'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png';
}

/// Colors for map elements.
class MapColors {
  MapColors._();

  /// Route polyline color
  static const Color routeLine = Color(0xFF2563EB);

  /// Route polyline color (completed portion)
  static const Color routeLineCompleted = Color(0xFF16A34A);

  /// Route polyline color (remaining portion)
  static const Color routeLineRemaining = Color(0xFF94A3B8);

  /// Current location marker
  static const Color currentLocation = Color(0xFF2563EB);

  /// Current location pulse
  static const Color currentLocationPulse = Color(0x402563EB);

  /// Stop markers by status
  static const Color stopPending = Color(0xFF94A3B8);
  static const Color stopCurrent = Color(0xFF2563EB);
  static const Color stopCompleted = Color(0xFF16A34A);
  static const Color stopSkipped = Color(0xFFF59E0B);
  static const Color stopNoShow = Color(0xFFDC2626);

  /// Depot marker
  static const Color depot = Color(0xFF6B7280);
}

/// Sizes for map markers.
class MapMarkerSizes {
  MapMarkerSizes._();

  /// Standard stop marker
  static const double stopMarker = 36.0;

  /// Current stop marker (larger for emphasis)
  static const double currentStopMarker = 44.0;

  /// Depot marker
  static const double depotMarker = 32.0;

  /// Current location marker
  static const double currentLocation = 24.0;

  /// Current location pulse radius
  static const double locationPulseRadius = 48.0;
}

/// Polyline styling.
class MapPolylineStyle {
  MapPolylineStyle._();

  /// Route line width
  static const double routeWidth = 4.0;

  /// Route line width (emphasized)
  static const double routeWidthEmphasized = 6.0;

  /// Completed route line width
  static const double completedWidth = 3.0;

  /// Border width for route lines
  static const double borderWidth = 1.0;
}

/// Extension to convert between coordinate types.
extension LatLngExtension on LatLng {
  /// Convert to a simple map for JSON.
  Map<String, double> toMap() => {
        'lat': latitude,
        'lng': longitude,
      };
}

/// Helper to calculate bounds from a list of coordinates.
class MapBoundsHelper {
  /// Calculate LatLngBounds from a list of points.
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

  /// Calculate center point from bounds.
  static LatLng getCenter(LatLng southwest, LatLng northeast) {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }

  /// Calculate appropriate zoom level for bounds.
  static double getZoomForBounds(
    LatLng southwest,
    LatLng northeast, {
    double mapWidth = 400,
    double mapHeight = 400,
  }) {
    const worldSize = 256.0;

    final latDiff = (northeast.latitude - southwest.latitude).abs();
    final lngDiff = (northeast.longitude - southwest.longitude).abs();

    if (latDiff == 0 && lngDiff == 0) return MapConfig.stopFocusZoom;

    // Calculate zoom based on lat/lng span
    final latZoom = _log2(mapHeight * 360 / (latDiff * worldSize));
    final lngZoom = _log2(mapWidth * 360 / (lngDiff * worldSize));

    // Use the smaller zoom (wider view) and clamp
    return (latZoom < lngZoom ? latZoom : lngZoom)
        .clamp(MapConfig.minZoom, MapConfig.maxZoom - 1);
  }

  static double _log2(double x) => x > 0 ? _ln(x) / _ln(2) : 0;

  static double _ln(double x) {
    if (x <= 0) return 0;
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSq = term * term;
    double current = term;
    for (int i = 1; i < 100; i += 2) {
      result += current / i;
      current *= termSq;
    }
    return 2 * result;
  }
}
