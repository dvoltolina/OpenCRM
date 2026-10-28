// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_optimization_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteWaypoint _$RouteWaypointFromJson(Map<String, dynamic> json) =>
    _RouteWaypoint(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      windowStart: DateTime.parse(json['windowStart'] as String),
      windowEnd: DateTime.parse(json['windowEnd'] as String),
      serviceDurationMinutes: (json['serviceDurationMinutes'] as num).toInt(),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      isRequired: json['isRequired'] as bool? ?? true,
      clientId: json['clientId'] as String?,
      appointmentId: json['appointmentId'] as String?,
    );

Map<String, dynamic> _$RouteWaypointToJson(_RouteWaypoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'windowStart': instance.windowStart.toIso8601String(),
      'windowEnd': instance.windowEnd.toIso8601String(),
      'serviceDurationMinutes': instance.serviceDurationMinutes,
      'priority': instance.priority,
      'isRequired': instance.isRequired,
      'clientId': instance.clientId,
      'appointmentId': instance.appointmentId,
    };

_RouteOptimizationRequest _$RouteOptimizationRequestFromJson(
  Map<String, dynamic> json,
) => _RouteOptimizationRequest(
  businessId: json['businessId'] as String,
  providerId: json['providerId'] as String,
  routeDate: DateTime.parse(json['routeDate'] as String),
  depotLatitude: (json['depotLatitude'] as num).toDouble(),
  depotLongitude: (json['depotLongitude'] as num).toDouble(),
  depotAddress: json['depotAddress'] as String,
  returnToDepot: json['returnToDepot'] as bool? ?? true,
  endLatitude: (json['endLatitude'] as num?)?.toDouble(),
  endLongitude: (json['endLongitude'] as num?)?.toDouble(),
  endAddress: json['endAddress'] as String?,
  waypoints: (json['waypoints'] as List<dynamic>)
      .map((e) => RouteWaypoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  earliestDeparture: DateTime.parse(json['earliestDeparture'] as String),
  latestReturn: DateTime.parse(json['latestReturn'] as String),
  maxDrivingMinutes: (json['maxDrivingMinutes'] as num?)?.toInt(),
  objective:
      $enumDecodeNullable(_$OptimizationObjectiveEnumMap, json['objective']) ??
      OptimizationObjective.minimizeTime,
  includeBreaks: json['includeBreaks'] as bool? ?? false,
  breakDurationMinutes: (json['breakDurationMinutes'] as num?)?.toInt() ?? 30,
  breakWindowStart: json['breakWindowStart'] == null
      ? null
      : DateTime.parse(json['breakWindowStart'] as String),
  breakWindowEnd: json['breakWindowEnd'] == null
      ? null
      : DateTime.parse(json['breakWindowEnd'] as String),
  averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toInt() ?? 40,
  bufferBetweenStopsMinutes:
      (json['bufferBetweenStopsMinutes'] as num?)?.toInt() ?? 5,
);

Map<String, dynamic> _$RouteOptimizationRequestToJson(
  _RouteOptimizationRequest instance,
) => <String, dynamic>{
  'businessId': instance.businessId,
  'providerId': instance.providerId,
  'routeDate': instance.routeDate.toIso8601String(),
  'depotLatitude': instance.depotLatitude,
  'depotLongitude': instance.depotLongitude,
  'depotAddress': instance.depotAddress,
  'returnToDepot': instance.returnToDepot,
  'endLatitude': instance.endLatitude,
  'endLongitude': instance.endLongitude,
  'endAddress': instance.endAddress,
  'waypoints': instance.waypoints.map((e) => e.toJson()).toList(),
  'earliestDeparture': instance.earliestDeparture.toIso8601String(),
  'latestReturn': instance.latestReturn.toIso8601String(),
  'maxDrivingMinutes': instance.maxDrivingMinutes,
  'objective': _$OptimizationObjectiveEnumMap[instance.objective]!,
  'includeBreaks': instance.includeBreaks,
  'breakDurationMinutes': instance.breakDurationMinutes,
  'breakWindowStart': instance.breakWindowStart?.toIso8601String(),
  'breakWindowEnd': instance.breakWindowEnd?.toIso8601String(),
  'averageSpeedKmh': instance.averageSpeedKmh,
  'bufferBetweenStopsMinutes': instance.bufferBetweenStopsMinutes,
};

const _$OptimizationObjectiveEnumMap = {
  OptimizationObjective.minimizeTime: 'minimizeTime',
  OptimizationObjective.minimizeDistance: 'minimizeDistance',
  OptimizationObjective.balanced: 'balanced',
  OptimizationObjective.minimizeLatestArrival: 'minimizeLatestArrival',
};
