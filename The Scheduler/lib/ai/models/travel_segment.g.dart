// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TravelSegment _$TravelSegmentFromJson(Map<String, dynamic> json) =>
    _TravelSegment(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      fromStopId: json['fromStopId'] as String,
      toStopId: json['toStopId'] as String,
      sequenceOrder: (json['sequenceOrder'] as num).toInt(),
      distanceMeters: (json['distanceMeters'] as num).toInt(),
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num)
          .toInt(),
      actualDurationSeconds: (json['actualDurationSeconds'] as num?)?.toInt(),
      trafficCondition:
          $enumDecodeNullable(
            _$TrafficConditionEnumMap,
            json['trafficCondition'],
          ) ??
          TrafficCondition.unknown,
      encodedPolyline: json['encodedPolyline'] as String?,
      turnInstructions: (json['turnInstructions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fromLatitude: (json['fromLatitude'] as num).toDouble(),
      fromLongitude: (json['fromLongitude'] as num).toDouble(),
      toLatitude: (json['toLatitude'] as num).toDouble(),
      toLongitude: (json['toLongitude'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      routingSource: json['routingSource'] as String,
    );

Map<String, dynamic> _$TravelSegmentToJson(_TravelSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'routeId': instance.routeId,
      'fromStopId': instance.fromStopId,
      'toStopId': instance.toStopId,
      'sequenceOrder': instance.sequenceOrder,
      'distanceMeters': instance.distanceMeters,
      'estimatedDurationSeconds': instance.estimatedDurationSeconds,
      'actualDurationSeconds': instance.actualDurationSeconds,
      'trafficCondition': _$TrafficConditionEnumMap[instance.trafficCondition]!,
      'encodedPolyline': instance.encodedPolyline,
      'turnInstructions': instance.turnInstructions,
      'fromLatitude': instance.fromLatitude,
      'fromLongitude': instance.fromLongitude,
      'toLatitude': instance.toLatitude,
      'toLongitude': instance.toLongitude,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
      'routingSource': instance.routingSource,
    };

const _$TrafficConditionEnumMap = {
  TrafficCondition.unknown: 'unknown',
  TrafficCondition.light: 'light',
  TrafficCondition.normal: 'normal',
  TrafficCondition.moderate: 'moderate',
  TrafficCondition.heavy: 'heavy',
  TrafficCondition.severe: 'severe',
};
