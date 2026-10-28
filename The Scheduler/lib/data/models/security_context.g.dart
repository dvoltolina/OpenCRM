// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecurityContext _$SecurityContextFromJson(
  Map<String, dynamic> json,
) => _SecurityContext(
  userId: json['userId'] as String,
  businessId: json['businessId'] as String,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.client,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  providerId: json['providerId'] as String?,
  clientId: json['clientId'] as String?,
  userFullName: json['userFullName'] as String?,
  authToken: json['authToken'] as String?,
);

Map<String, dynamic> _$SecurityContextToJson(_SecurityContext instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'businessId': instance.businessId,
      'role': _$UserRoleEnumMap[instance.role]!,
      'roles': instance.roles,
      'providerId': instance.providerId,
      'clientId': instance.clientId,
      'userFullName': instance.userFullName,
      'authToken': instance.authToken,
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
