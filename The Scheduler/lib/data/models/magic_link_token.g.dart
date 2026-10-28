// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_link_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MagicLinkToken _$MagicLinkTokenFromJson(Map<String, dynamic> json) =>
    _MagicLinkToken(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      appointmentId: json['appointmentId'] as String,
      clientId: json['clientId'] as String,
      clientEmail: json['clientEmail'] as String,
      token: json['token'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      expiresAt: const TimestampConverter().fromJson(json['expiresAt']),
      hasBeenUsed: json['hasBeenUsed'] as bool? ?? false,
      lastAccessedAt: const NullableTimestampConverter().fromJson(
        json['lastAccessedAt'],
      ),
      accessCount: (json['accessCount'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(_$MagicLinkTokenStatusEnumMap, json['status']) ??
          MagicLinkTokenStatus.active,
    );

Map<String, dynamic> _$MagicLinkTokenToJson(_MagicLinkToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'appointmentId': instance.appointmentId,
      'clientId': instance.clientId,
      'clientEmail': instance.clientEmail,
      'token': instance.token,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'expiresAt': const TimestampConverter().toJson(instance.expiresAt),
      'hasBeenUsed': instance.hasBeenUsed,
      'lastAccessedAt': const NullableTimestampConverter().toJson(
        instance.lastAccessedAt,
      ),
      'accessCount': instance.accessCount,
      'status': _$MagicLinkTokenStatusEnumMap[instance.status]!,
    };

const _$MagicLinkTokenStatusEnumMap = {
  MagicLinkTokenStatus.active: 'active',
  MagicLinkTokenStatus.revoked: 'revoked',
  MagicLinkTokenStatus.expired: 'expired',
};
