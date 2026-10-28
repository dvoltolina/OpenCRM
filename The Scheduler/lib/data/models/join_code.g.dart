// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinCode _$JoinCodeFromJson(Map<String, dynamic> json) => _JoinCode(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  codeHash: json['codeHash'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  expiresAt: const _TimestampConverter().fromJson(json['expiresAt']),
  maxUses: (json['maxUses'] as num).toInt(),
  uses: (json['uses'] as num?)?.toInt() ?? 0,
  role: json['role'] as String,
  status: $enumDecode(_$JoinCodeStatusEnumMap, json['status']),
  lastUsedAt: const _NullableTimestampConverter().fromJson(json['lastUsedAt']),
  lastUsedBy: json['lastUsedBy'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$JoinCodeToJson(_JoinCode instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'codeHash': instance.codeHash,
  'createdBy': instance.createdBy,
  'createdAt': const _TimestampConverter().toJson(instance.createdAt),
  'expiresAt': const _TimestampConverter().toJson(instance.expiresAt),
  'maxUses': instance.maxUses,
  'uses': instance.uses,
  'role': instance.role,
  'status': _$JoinCodeStatusEnumMap[instance.status]!,
  'lastUsedAt': const _NullableTimestampConverter().toJson(instance.lastUsedAt),
  'lastUsedBy': instance.lastUsedBy,
  'notes': instance.notes,
};

const _$JoinCodeStatusEnumMap = {
  JoinCodeStatus.active: 'active',
  JoinCodeStatus.revoked: 'revoked',
  JoinCodeStatus.expired: 'expired',
};
