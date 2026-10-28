// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModificationRequest _$ModificationRequestFromJson(
  Map<String, dynamic> json,
) => _ModificationRequest(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  appointmentId: json['appointmentId'] as String,
  clientId: json['clientId'] as String,
  providerId: json['providerId'] as String,
  type: $enumDecode(_$ModificationRequestTypeEnumMap, json['type']),
  status:
      $enumDecodeNullable(_$ModificationRequestStatusEnumMap, json['status']) ??
      ModificationRequestStatus.pending,
  requestedStartTime: const NullableTimestampConverter().fromJson(
    json['requestedStartTime'],
  ),
  requestedDurationMinutes: (json['requestedDurationMinutes'] as num?)?.toInt(),
  reason: json['reason'] as String?,
  policyWindowBreached: json['policyWindowBreached'] as bool? ?? false,
  feeRequired: json['feeRequired'] as bool? ?? false,
  feeAmount: (json['feeAmount'] as num?)?.toDouble(),
  feeCollected: json['feeCollected'] as bool? ?? false,
  requestedByName: json['requestedByName'] as String?,
  requestedByEmail: json['requestedByEmail'] as String?,
  decisionAt: const NullableTimestampConverter().fromJson(json['decisionAt']),
  decidedBy: json['decidedBy'] as String?,
  decisionNotes: json['decisionNotes'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ModificationRequestToJson(
  _ModificationRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'appointmentId': instance.appointmentId,
  'clientId': instance.clientId,
  'providerId': instance.providerId,
  'type': _$ModificationRequestTypeEnumMap[instance.type]!,
  'status': _$ModificationRequestStatusEnumMap[instance.status]!,
  'requestedStartTime': const NullableTimestampConverter().toJson(
    instance.requestedStartTime,
  ),
  'requestedDurationMinutes': instance.requestedDurationMinutes,
  'reason': instance.reason,
  'policyWindowBreached': instance.policyWindowBreached,
  'feeRequired': instance.feeRequired,
  'feeAmount': instance.feeAmount,
  'feeCollected': instance.feeCollected,
  'requestedByName': instance.requestedByName,
  'requestedByEmail': instance.requestedByEmail,
  'decisionAt': const NullableTimestampConverter().toJson(instance.decisionAt),
  'decidedBy': instance.decidedBy,
  'decisionNotes': instance.decisionNotes,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'metadata': instance.metadata,
};

const _$ModificationRequestTypeEnumMap = {
  ModificationRequestType.reschedule: 'reschedule',
  ModificationRequestType.cancel: 'cancel',
};

const _$ModificationRequestStatusEnumMap = {
  ModificationRequestStatus.pending: 'pending',
  ModificationRequestStatus.approved: 'approved',
  ModificationRequestStatus.rejected: 'rejected',
  ModificationRequestStatus.autoApproved: 'autoApproved',
};
