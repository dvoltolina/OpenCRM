// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinRequest _$JoinRequestFromJson(Map<String, dynamic> json) => _JoinRequest(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  requestorUserId: json['requestorUserId'] as String,
  requestorEmail: json['requestorEmail'] as String,
  requestorDisplayName: json['requestorDisplayName'] as String,
  role: json['role'] as String,
  status: $enumDecode(_$JoinRequestStatusEnumMap, json['status']),
  metadata:
      json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  reviewedAt: const _NullableTimestampConverter().fromJson(json['reviewedAt']),
  reviewedBy: json['reviewedBy'] as String?,
  reviewNotes: json['reviewNotes'] as String?,
);

Map<String, dynamic> _$JoinRequestToJson(
  _JoinRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'requestorUserId': instance.requestorUserId,
  'requestorEmail': instance.requestorEmail,
  'requestorDisplayName': instance.requestorDisplayName,
  'role': instance.role,
  'status': _$JoinRequestStatusEnumMap[instance.status]!,
  'metadata': instance.metadata,
  'createdAt': const _TimestampConverter().toJson(instance.createdAt),
  'reviewedAt': const _NullableTimestampConverter().toJson(instance.reviewedAt),
  'reviewedBy': instance.reviewedBy,
  'reviewNotes': instance.reviewNotes,
};

const _$JoinRequestStatusEnumMap = {
  JoinRequestStatus.pending: 'pending',
  JoinRequestStatus.approved: 'approved',
  JoinRequestStatus.denied: 'denied',
};
