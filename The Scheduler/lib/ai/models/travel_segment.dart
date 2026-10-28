import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_segment.freezed.dart';
part 'travel_segment.g.dart';

/// Traffic condition for a segment.
enum TrafficCondition {
  /// No data available
  unknown,

  /// Light traffic, faster than normal
  light,

  /// Normal traffic conditions
  normal,

  /// Moderate traffic, slightly slower
  moderate,

  /// Heavy traffic, significantly slower
  heavy,

  /// Severe traffic or road closure
  severe,
}

/// Travel segment between two route stops.
@freezed
abstract class TravelSegment with _$TravelSegment {
  const factory TravelSegment({
    /// Unique identifier
    required String id,

    /// Route this segment belongs to
    required String routeId,

    /// Origin stop ID
    required String fromStopId,

    /// Destination stop ID
    required String toStopId,

    /// Sequence in route (matches destination stop sequence)
    required int sequenceOrder,

    // ============ Distance & Time ============

    /// Distance in meters
    required int distanceMeters,

    /// Estimated duration in seconds (from OSRM)
    required int estimatedDurationSeconds,

    /// Actual duration in seconds (filled after travel)
    int? actualDurationSeconds,

    /// Traffic condition at time of estimation
    @Default(TrafficCondition.unknown) TrafficCondition trafficCondition,

    // ============ Geometry ============

    /// Encoded polyline for map display (Google format)
    String? encodedPolyline,

    /// Turn-by-turn instructions (optional)
    List<String>? turnInstructions,

    // ============ Waypoints ============

    /// Origin coordinates
    required double fromLatitude,
    required double fromLongitude,

    /// Destination coordinates
    required double toLatitude,
    required double toLongitude,

    // ============ Metadata ============

    /// When this segment was calculated
    required DateTime calculatedAt,

    /// Source of routing data (osrm, google, etc.)
    required String routingSource,
  }) = _TravelSegment;

  factory TravelSegment.fromJson(Map<String, dynamic> json) =>
      _$TravelSegmentFromJson(json);
}

/// Extension methods for TravelSegment.
extension TravelSegmentExtensions on TravelSegment {
  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000.0;

  /// Distance in miles
  double get distanceMiles => distanceMeters / 1609.344;

  /// Estimated duration in minutes
  double get estimatedDurationMinutes => estimatedDurationSeconds / 60.0;

  /// Actual duration in minutes (or estimated if not available)
  double get actualOrEstimatedMinutes =>
      (actualDurationSeconds ?? estimatedDurationSeconds) / 60.0;

  /// Whether actual time differed significantly from estimate (>20%)
  bool get hadSignificantDelay {
    if (actualDurationSeconds == null) return false;
    final diff = actualDurationSeconds! - estimatedDurationSeconds;
    return diff > estimatedDurationSeconds * 0.2;
  }

  /// Formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  /// Formatted duration string
  String get formattedDuration {
    final minutes = estimatedDurationMinutes.round();
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }
}
