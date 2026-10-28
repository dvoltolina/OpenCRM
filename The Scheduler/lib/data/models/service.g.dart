// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Service _$ServiceFromJson(Map<String, dynamic> json) => _Service(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  name: json['name'] as String,
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String?,
  category: json['category'] as String?,
  providerIds:
      (json['providerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiredResources:
      (json['requiredResources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  intakeFormTemplateId: json['intakeFormTemplateId'] as String?,
  bufferMinutes: (json['bufferMinutes'] as num?)?.toInt(),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ServiceToJson(_Service instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'name': instance.name,
  'durationMinutes': instance.durationMinutes,
  'price': instance.price,
  'description': instance.description,
  'category': instance.category,
  'providerIds': instance.providerIds,
  'requiredResources': instance.requiredResources,
  'intakeFormTemplateId': instance.intakeFormTemplateId,
  'bufferMinutes': instance.bufferMinutes,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
