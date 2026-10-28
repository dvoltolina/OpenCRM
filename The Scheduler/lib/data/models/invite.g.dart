// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invite _$InviteFromJson(Map<String, dynamic> json) => _Invite(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  tokenHash: json['tokenHash'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  expiresAt: const _TimestampConverter().fromJson(json['expiresAt']),
  status: $enumDecode(_$InviteStatusEnumMap, json['status']),
  acceptedAt: const _NullableTimestampConverter().fromJson(json['acceptedAt']),
  acceptedBy: json['acceptedBy'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$InviteToJson(_Invite instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'email': instance.email,
  'role': instance.role,
  'tokenHash': instance.tokenHash,
  'createdBy': instance.createdBy,
  'createdAt': const _TimestampConverter().toJson(instance.createdAt),
  'expiresAt': const _TimestampConverter().toJson(instance.expiresAt),
  'status': _$InviteStatusEnumMap[instance.status]!,
  'acceptedAt': const _NullableTimestampConverter().toJson(instance.acceptedAt),
  'acceptedBy': instance.acceptedBy,
  'notes': instance.notes,
};

const _$InviteStatusEnumMap = {
  InviteStatus.pending: 'pending',
  InviteStatus.accepted: 'accepted',
  InviteStatus.revoked: 'revoked',
  InviteStatus.expired: 'expired',
};
