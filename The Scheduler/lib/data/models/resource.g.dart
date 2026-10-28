// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Resource _$ResourceFromJson(Map<String, dynamic> json) => _Resource(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ResourceTypeEnumMap, json['type']),
  description: json['description'] as String?,
  locationId: json['locationId'] as String,
  capacity: (json['capacity'] as num?)?.toInt() ?? 1,
  isActive: json['isActive'] as bool? ?? true,
  maintenanceSchedule:
      (json['maintenanceSchedule'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ResourceToJson(_Resource instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'name': instance.name,
  'type': _$ResourceTypeEnumMap[instance.type]!,
  'description': instance.description,
  'locationId': instance.locationId,
  'capacity': instance.capacity,
  'isActive': instance.isActive,
  'maintenanceSchedule': instance.maintenanceSchedule,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$ResourceTypeEnumMap = {
  ResourceType.room: 'room',
  ResourceType.equipment: 'equipment',
  ResourceType.vehicle: 'vehicle',
  ResourceType.other: 'other',
};
