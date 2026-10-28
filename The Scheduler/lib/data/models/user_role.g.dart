// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  providerId: json['providerId'] as String?,
  clientId: json['clientId'] as String?,
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  lastLoginAt: const _NullableTimestampConverter().fromJson(
    json['lastLoginAt'],
  ),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'role': _$UserRoleEnumMap[instance.role]!,
      'providerId': instance.providerId,
      'clientId': instance.clientId,
      'email': instance.email,
      'displayName': instance.displayName,
      'createdAt': const _TimestampConverter().toJson(instance.createdAt),
      'lastLoginAt': const _NullableTimestampConverter().toJson(
        instance.lastLoginAt,
      ),
    };

const _$UserRoleEnumMap = {
  UserRole.owner: 'owner',
  UserRole.admin: 'admin',
  UserRole.staff: 'staff',
  UserRole.client: 'client',
  UserRole.manager: 'manager',
  UserRole.sales: 'sales',
  UserRole.provider: 'provider',
  UserRole.frontDesk: 'frontDesk',
};
