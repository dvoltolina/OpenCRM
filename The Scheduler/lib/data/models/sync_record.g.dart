// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncRecord _$SyncRecordFromJson(Map<String, dynamic> json) => _SyncRecord(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  connectionId: json['connectionId'] as String,
  localId: json['localId'] as String,
  localType: $enumDecode(_$SyncLocalTypeEnumMap, json['localType']),
  remoteId: json['remoteId'] as String?,
  remoteType: $enumDecode(_$SyncRemoteTypeEnumMap, json['remoteType']),
  syncedAt: const TimestampConverter().fromJson(json['syncedAt']),
  syncDirection: $enumDecode(_$SyncDirectionEnumMap, json['syncDirection']),
  status:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['status']) ??
      SyncStatus.pending,
  errorMessage: json['errorMessage'] as String?,
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SyncRecordToJson(
  _SyncRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'connectionId': instance.connectionId,
  'localId': instance.localId,
  'localType': _$SyncLocalTypeEnumMap[instance.localType]!,
  'remoteId': instance.remoteId,
  'remoteType': _$SyncRemoteTypeEnumMap[instance.remoteType]!,
  'syncedAt': const TimestampConverter().toJson(instance.syncedAt),
  'syncDirection': _$SyncDirectionEnumMap[instance.syncDirection]!,
  'status': _$SyncStatusEnumMap[instance.status]!,
  'errorMessage': instance.errorMessage,
  'retryCount': instance.retryCount,
  'metadata': instance.metadata,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$SyncLocalTypeEnumMap = {
  SyncLocalType.payment: 'payment',
  SyncLocalType.client: 'client',
  SyncLocalType.invoice: 'invoice',
  SyncLocalType.appointment: 'appointment',
  SyncLocalType.product: 'product',
  SyncLocalType.service: 'service',
};

const _$SyncRemoteTypeEnumMap = {
  SyncRemoteType.invoice: 'invoice',
  SyncRemoteType.payment: 'payment',
  SyncRemoteType.customer: 'customer',
  SyncRemoteType.salesReceipt: 'salesReceipt',
  SyncRemoteType.item: 'item',
  SyncRemoteType.contact: 'contact',
};

const _$SyncDirectionEnumMap = {
  SyncDirection.toAccounting: 'toAccounting',
  SyncDirection.fromAccounting: 'fromAccounting',
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.success: 'success',
  SyncStatus.failed: 'failed',
  SyncStatus.skipped: 'skipped',
};
