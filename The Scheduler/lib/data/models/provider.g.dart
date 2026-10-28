// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Provider _$ProviderFromJson(Map<String, dynamic> json) => _Provider(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  stripeAccountId: json['stripeAccountId'] as String?,
  bio: json['bio'] as String?,
  specializations:
      (json['specializations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  serviceIds:
      (json['serviceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  locationIds:
      (json['locationIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  colorHex: json['colorHex'] as String? ?? '4285F4',
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ProviderToJson(_Provider instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phone': instance.phone,
  'stripeAccountId': instance.stripeAccountId,
  'bio': instance.bio,
  'specializations': instance.specializations,
  'serviceIds': instance.serviceIds,
  'locationIds': instance.locationIds,
  'colorHex': instance.colorHex,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
