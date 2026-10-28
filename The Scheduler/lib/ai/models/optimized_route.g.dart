// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'optimized_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OptimizedRoute _$OptimizedRouteFromJson(Map<String, dynamic> json) =>
    _OptimizedRoute(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      routeDate: DateTime.parse(json['routeDate'] as String),
      status:
          $enumDecodeNullable(_$RouteStatusEnumMap, json['status']) ??
          RouteStatus.planned,
      stops: (json['stops'] as List<dynamic>)
          .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      segments: (json['segments'] as List<dynamic>)
          .map((e) => TravelSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      expectedEndTime: DateTime.parse(json['expectedEndTime'] as String),
      actualEndTime: json['actualEndTime'] == null
          ? null
          : DateTime.parse(json['actualEndTime'] as String),
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toInt(),
      totalTravelTimeSeconds: (json['totalTravelTimeSeconds'] as num).toInt(),
      totalServiceTimeSeconds: (json['totalServiceTimeSeconds'] as num).toInt(),
      originalDistanceMeters: (json['originalDistanceMeters'] as num?)?.toInt(),
      originalTravelTimeSeconds: (json['originalTravelTimeSeconds'] as num?)
          ?.toInt(),
      distanceSavedMeters: (json['distanceSavedMeters'] as num?)?.toInt(),
      timeSavedSeconds: (json['timeSavedSeconds'] as num?)?.toInt(),
      optimizationImprovementPercent:
          (json['optimizationImprovementPercent'] as num?)?.toDouble(),
      objective: $enumDecodeNullable(
        _$OptimizationObjectiveEnumMap,
        json['objective'],
      ),
      optimizerVersion: json['optimizerVersion'] as String,
      optimizedAt: DateTime.parse(json['optimizedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$OptimizedRouteToJson(_OptimizedRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'providerId': instance.providerId,
      'providerName': instance.providerName,
      'routeDate': instance.routeDate.toIso8601String(),
      'status': _$RouteStatusEnumMap[instance.status]!,
      'stops': instance.stops.map((e) => e.toJson()).toList(),
      'segments': instance.segments.map((e) => e.toJson()).toList(),
      'startTime': instance.startTime.toIso8601String(),
      'expectedEndTime': instance.expectedEndTime.toIso8601String(),
      'actualEndTime': instance.actualEndTime?.toIso8601String(),
      'totalDistanceMeters': instance.totalDistanceMeters,
      'totalTravelTimeSeconds': instance.totalTravelTimeSeconds,
      'totalServiceTimeSeconds': instance.totalServiceTimeSeconds,
      'originalDistanceMeters': instance.originalDistanceMeters,
      'originalTravelTimeSeconds': instance.originalTravelTimeSeconds,
      'distanceSavedMeters': instance.distanceSavedMeters,
      'timeSavedSeconds': instance.timeSavedSeconds,
      'optimizationImprovementPercent': instance.optimizationImprovementPercent,
      'objective': _$OptimizationObjectiveEnumMap[instance.objective],
      'optimizerVersion': instance.optimizerVersion,
      'optimizedAt': instance.optimizedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notes': instance.notes,
    };

const _$RouteStatusEnumMap = {
  RouteStatus.planned: 'planned',
  RouteStatus.inProgress: 'inProgress',
  RouteStatus.completed: 'completed',
  RouteStatus.cancelled: 'cancelled',
  RouteStatus.needsReoptimization: 'needsReoptimization',
};

const _$OptimizationObjectiveEnumMap = {
  OptimizationObjective.minimizeTime: 'minimizeTime',
  OptimizationObjective.minimizeDistance: 'minimizeDistance',
  OptimizationObjective.balanced: 'balanced',
  OptimizationObjective.minimizeLatestArrival: 'minimizeLatestArrival',
};
