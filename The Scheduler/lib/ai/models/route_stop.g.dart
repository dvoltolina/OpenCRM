// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteStop _$RouteStopFromJson(Map<String, dynamic> json) => _RouteStop(
  id: json['id'] as String,
  sequenceOrder: (json['sequenceOrder'] as num).toInt(),
  stopType: $enumDecode(_$RouteStopTypeEnumMap, json['stopType']),
  status:
      $enumDecodeNullable(_$RouteStopStatusEnumMap, json['status']) ??
      RouteStopStatus.pending,
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  arrivalNotes: json['arrivalNotes'] as String?,
  windowStart: DateTime.parse(json['windowStart'] as String),
  windowEnd: DateTime.parse(json['windowEnd'] as String),
  scheduledArrival: DateTime.parse(json['scheduledArrival'] as String),
  actualArrival: json['actualArrival'] == null
      ? null
      : DateTime.parse(json['actualArrival'] as String),
  serviceDurationMinutes: (json['serviceDurationMinutes'] as num).toInt(),
  bufferMinutes: (json['bufferMinutes'] as num?)?.toInt() ?? 0,
  actualDeparture: json['actualDeparture'] == null
      ? null
      : DateTime.parse(json['actualDeparture'] as String),
  appointmentId: json['appointmentId'] as String?,
  clientId: json['clientId'] as String?,
  serviceId: json['serviceId'] as String?,
  serviceName: json['serviceName'] as String?,
  travelToNextMinutes: (json['travelToNextMinutes'] as num?)?.toInt(),
  distanceToNextMeters: (json['distanceToNextMeters'] as num?)?.toInt(),
  providerNotes: json['providerNotes'] as String?,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RouteStopToJson(_RouteStop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sequenceOrder': instance.sequenceOrder,
      'stopType': _$RouteStopTypeEnumMap[instance.stopType]!,
      'status': _$RouteStopStatusEnumMap[instance.status]!,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'arrivalNotes': instance.arrivalNotes,
      'windowStart': instance.windowStart.toIso8601String(),
      'windowEnd': instance.windowEnd.toIso8601String(),
      'scheduledArrival': instance.scheduledArrival.toIso8601String(),
      'actualArrival': instance.actualArrival?.toIso8601String(),
      'serviceDurationMinutes': instance.serviceDurationMinutes,
      'bufferMinutes': instance.bufferMinutes,
      'actualDeparture': instance.actualDeparture?.toIso8601String(),
      'appointmentId': instance.appointmentId,
      'clientId': instance.clientId,
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName,
      'travelToNextMinutes': instance.travelToNextMinutes,
      'distanceToNextMeters': instance.distanceToNextMeters,
      'providerNotes': instance.providerNotes,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$RouteStopTypeEnumMap = {
  RouteStopType.depot: 'depot',
  RouteStopType.appointment: 'appointment',
  RouteStopType.breakStop: 'breakStop',
  RouteStopType.endDepot: 'endDepot',
};

const _$RouteStopStatusEnumMap = {
  RouteStopStatus.pending: 'pending',
  RouteStopStatus.enRoute: 'enRoute',
  RouteStopStatus.arrived: 'arrived',
  RouteStopStatus.inProgress: 'inProgress',
  RouteStopStatus.completed: 'completed',
  RouteStopStatus.skipped: 'skipped',
  RouteStopStatus.clientNoShow: 'clientNoShow',
};
