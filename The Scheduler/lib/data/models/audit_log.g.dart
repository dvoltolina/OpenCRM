// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLogEntry _$AuditLogEntryFromJson(Map<String, dynamic> json) =>
    _AuditLogEntry(
      id: json['id'] as String?,
      businessId: json['businessId'] as String,
      userId: json['userId'] as String,
      actionType: $enumDecode(_$AuditActionTypeEnumMap, json['actionType']),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      timestamp: const NullableTimestampConverter().fromJson(json['timestamp']),
      ipAddress: json['ipAddress'] as String?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      correlationId: json['correlationId'] as String?,
      metadata:
          json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$AuditLogEntryToJson(
  _AuditLogEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'userId': instance.userId,
  'actionType': _$AuditActionTypeEnumMap[instance.actionType]!,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'timestamp': const NullableTimestampConverter().toJson(instance.timestamp),
  'ipAddress': instance.ipAddress,
  'deviceInfo': instance.deviceInfo,
  'correlationId': instance.correlationId,
  'metadata': instance.metadata,
};

const _$AuditActionTypeEnumMap = {
  AuditActionType.loginSuccess: 'loginSuccess',
  AuditActionType.loginFailure: 'loginFailure',
  AuditActionType.phiRead: 'phiRead',
  AuditActionType.phiReadList: 'phiReadList',
  AuditActionType.phiWrite: 'phiWrite',
  AuditActionType.dataExport: 'dataExport',
  AuditActionType.securityEvent: 'securityEvent',
};
