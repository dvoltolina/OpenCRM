// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Client _$ClientFromJson(Map<String, dynamic> json) => _Client(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  birthDate: const NullableTimestampConverter().fromJson(json['birthDate']),
  notes: json['notes'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  lifecycle:
      $enumDecodeNullable(_$ClientLifecycleEnumMap, json['lifecycle']) ??
      ClientLifecycle.newClient,
  lastContactDate: const NullableTimestampConverter().fromJson(
    json['lastContactDate'],
  ),
  lastAppointmentDate: const NullableTimestampConverter().fromJson(
    json['lastAppointmentDate'],
  ),
  preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
  customFields: json['customFields'] as Map<String, dynamic>? ?? const {},
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  userId: json['userId'] as String?,
  hasPaymentMethod: json['hasPaymentMethod'] as bool? ?? false,
  stripeCustomerId: json['stripeCustomerId'] as String?,
  serviceLatitude: (json['serviceLatitude'] as num?)?.toDouble(),
  serviceLongitude: (json['serviceLongitude'] as num?)?.toDouble(),
  serviceNotes: json['serviceNotes'] as String?,
);

Map<String, dynamic> _$ClientToJson(_Client instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'birthDate': const NullableTimestampConverter().toJson(instance.birthDate),
  'notes': instance.notes,
  'tags': instance.tags,
  'lifecycle': _$ClientLifecycleEnumMap[instance.lifecycle]!,
  'lastContactDate': const NullableTimestampConverter().toJson(
    instance.lastContactDate,
  ),
  'lastAppointmentDate': const NullableTimestampConverter().toJson(
    instance.lastAppointmentDate,
  ),
  'preferences': instance.preferences,
  'customFields': instance.customFields,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'userId': instance.userId,
  'hasPaymentMethod': instance.hasPaymentMethod,
  'stripeCustomerId': instance.stripeCustomerId,
  'serviceLatitude': instance.serviceLatitude,
  'serviceLongitude': instance.serviceLongitude,
  'serviceNotes': instance.serviceNotes,
};

const _$ClientLifecycleEnumMap = {
  ClientLifecycle.newClient: 'newClient',
  ClientLifecycle.active: 'active',
  ClientLifecycle.inactive: 'inactive',
  ClientLifecycle.churned: 'churned',
};
