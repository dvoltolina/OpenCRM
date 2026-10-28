/// Interactive route map widget using flutter_map.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/optimized_route.dart';
import '../../models/route_stop.dart';
import '../../services/route_tracking_service.dart';
import '../../utils/polyline_decoder.dart' as decoder;
import 'map_config.dart';
import 'map_markers.dart';

/// Interactive map widget for displaying optimized routes.
class RouteMapWidget extends StatefulWidget {
  const RouteMapWidget({
    super.key,
    required this.route,
    this.currentLocation,
    this.onStopTap,
    this.selectedStopId,
    this.showPolylines = true,
    this.showStopMarkers = true,
    this.showCurrentLocation = true,
    this.interactive = true,
    this.height,
  });

  /// The optimized route to display.
  final OptimizedRoute route;

  /// Current location of the provider (for live tracking).
  final CurrentLocation? currentLocation;

  /// Callback when a stop marker is tapped.
  final void Function(RouteStop stop)? onStopTap;

  /// Currently selected stop ID (for highlighting).
  final String? selectedStopId;

  /// Whether to show route polylines.
  final bool showPolylines;

  /// Whether to show stop markers.
  final bool showStopMarkers;

  /// Whether to show current location marker.
  final bool showCurrentLocation;

  /// Whether the map is interactive (pan/zoom).
  final bool interactive;

  /// Fixed height for the map (null = expand to fill).
  final double? height;

  @override
  RouteMapWidgetState createState() => RouteMapWidgetState();
}

class RouteMapWidgetState extends State<RouteMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate initial bounds
    final stopPoints = widget.route.stops
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    final bounds = MapBoundsHelper.getBounds(stopPoints);
    final initialCenter = bounds != null
        ? MapBoundsHelper.getCenter(bounds.southwest, bounds.northeast)
        : MapConfig.defaultCenter;
    final initialZoom = bounds != null
        ? MapBoundsHelper.getZoomForBounds(bounds.southwest, bounds.northeast)
        : MapConfig.defaultZoom;

    Widget mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
        onTap: (_, __) {
          // Deselect when tapping map background
        },
      ),
      children: [
        // Tile layer (map tiles)
        TileLayer(
          urlTemplate: isDark ? MapConfig.cartoDarkUrl : MapConfig.osmTileUrl,
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.scheduler.app',
          maxZoom: MapConfig.maxZoom,
        ),

        // Route polylines
        if (widget.showPolylines) _buildPolylineLayer(),

        // Stop markers
        if (widget.showStopMarkers) _buildMarkerLayer(),

        // Current location
        if (widget.showCurrentLocation && widget.currentLocation != null)
          _buildCurrentLocationLayer(),

        // Attribution
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(MapConfig.osmAttribution),
          ],
        ),
      ],
    );

    // Wrap in sized box if height specified
    if (widget.height != null) {
      mapWidget = SizedBox(
        height: widget.height,
        child: mapWidget,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: mapWidget,
    );
  }

  /// Build polyline layer for route segments.
  Widget _buildPolylineLayer() {
    final polylines = <Polyline>[];
    final currentStop = widget.route.currentStop;

    for (final segment in widget.route.segments) {
      // Decode polyline if available, otherwise use straight line
      List<LatLng> points;
      if (segment.encodedPolyline != null &&
          segment.encodedPolyline!.isNotEmpty) {
        final decoded = decoder.PolylineDecoder.decode(segment.encodedPolyline!);
        points = decoded
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      } else {
        // Fallback to straight line between stops
        points = [
          LatLng(segment.fromLatitude, segment.fromLongitude),
          LatLng(segment.toLatitude, segment.toLongitude),
        ];
      }

      // Determine if this segment is completed
      final toStop = widget.route.stops.firstWhere(
        (s) => s.id == segment.toStopId,
        orElse: () => widget.route.stops.first,
      );
      final isCompleted = toStop.isCompleted;
      final isCurrent = currentStop != null && toStop.id == currentStop.id;

      Color color;
      double width;
      if (isCompleted) {
        color = MapColors.routeLineCompleted;
        width = MapPolylineStyle.completedWidth;
      } else if (isCurrent) {
        color = MapColors.routeLine;
        width = MapPolylineStyle.routeWidthEmphasized;
      } else {
        color = MapColors.routeLineRemaining;
        width = MapPolylineStyle.routeWidth;
      }

      polylines.add(Polyline(
        points: points,
        color: color,
        strokeWidth: width,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ));
    }

    return PolylineLayer(polylines: polylines);
  }

  /// Build marker layer for stops.
  Widget _buildMarkerLayer() {
    final markers = <Marker>[];
    final currentStop = widget.route.currentStop;

    for (final stop in widget.route.stops) {
      final isCurrent = currentStop?.id == stop.id;
      final isSelected = widget.selectedStopId == stop.id;

      markers.add(Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: isCurrent
            ? MapMarkerSizes.currentStopMarker
            : MapMarkerSizes.stopMarker,
        height: isCurrent
            ? MapMarkerSizes.currentStopMarker
            : MapMarkerSizes.stopMarker,
        child: GestureDetector(
          onTap: widget.onStopTap != null ? () => widget.onStopTap!(stop) : null,
          child: StopMarker(
            stop: stop,
            isCurrent: isCurrent,
            isSelected: isSelected,
          ),
        ),
      ));
    }

    return MarkerLayer(markers: markers);
  }

  /// Build current location layer.
  Widget _buildCurrentLocationLayer() {
    final location = widget.currentLocation!;

    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: MapMarkerSizes.locationPulseRadius,
          height: MapMarkerSizes.locationPulseRadius,
          child: CurrentLocationMarker(
            heading: location.headingDegrees,
          ),
        ),
      ],
    );
  }

  /// Animate to a specific stop.
  void focusOnStop(RouteStop stop) {
    _mapController.move(
      LatLng(stop.latitude, stop.longitude),
      MapConfig.stopFocusZoom,
    );
  }

  /// Fit all stops in view.
  void fitAllStops() {
    final stopPoints = widget.route.stops
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    final bounds = MapBoundsHelper.getBounds(stopPoints);
    if (bounds != null) {
      final center = MapBoundsHelper.getCenter(bounds.southwest, bounds.northeast);
      final zoom = MapBoundsHelper.getZoomForBounds(
        bounds.southwest,
        bounds.northeast,
      );
      _mapController.move(center, zoom);
    }
  }

  /// Focus on current location.
  void focusOnCurrentLocation() {
    if (widget.currentLocation != null) {
      _mapController.move(
        LatLng(
          widget.currentLocation!.latitude,
          widget.currentLocation!.longitude,
        ),
        MapConfig.stopFocusZoom,
      );
    }
  }
}

/// Simplified route map for preview (non-interactive).
class RouteMapPreview extends StatelessWidget {
  const RouteMapPreview({
    super.key,
    required this.route,
    this.height = 150,
  });

  final OptimizedRoute route;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RouteMapWidget(
      route: route,
      height: height,
      interactive: false,
      showCurrentLocation: false,
    );
  }
}
