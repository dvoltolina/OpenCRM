// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountingConnection _$AccountingConnectionFromJson(
  Map<String, dynamic> json,
) => _AccountingConnection(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  provider: $enumDecode(_$AccountingProviderEnumMap, json['provider']),
  providerCompanyId: json['providerCompanyId'] as String,
  providerCompanyName: json['providerCompanyName'] as String?,
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  tokenExpiresAt: const TimestampConverter().fromJson(json['tokenExpiresAt']),
  syncInvoices: json['syncInvoices'] as bool? ?? true,
  syncPayments: json['syncPayments'] as bool? ?? true,
  syncClients: json['syncClients'] as bool? ?? true,
  syncProducts: json['syncProducts'] as bool? ?? false,
  incomeAccountId: json['incomeAccountId'] as String?,
  incomeAccountName: json['incomeAccountName'] as String?,
  depositAccountId: json['depositAccountId'] as String?,
  depositAccountName: json['depositAccountName'] as String?,
  taxCodeId: json['taxCodeId'] as String?,
  taxCodeName: json['taxCodeName'] as String?,
  status:
      $enumDecodeNullable(_$ConnectionStatusEnumMap, json['status']) ??
      ConnectionStatus.active,
  lastSyncAt: const NullableTimestampConverter().fromJson(json['lastSyncAt']),
  lastSyncError: json['lastSyncError'] as String?,
  connectedAt: const TimestampConverter().fromJson(json['connectedAt']),
  connectedByUserId: json['connectedByUserId'] as String?,
  hipaaMode: json['hipaaMode'] as bool? ?? true,
  baaVerified: json['baaVerified'] as bool? ?? false,
  baaVerifiedAt: const NullableTimestampConverter().fromJson(
    json['baaVerifiedAt'],
  ),
  baaVerifiedByUserId: json['baaVerifiedByUserId'] as String?,
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$AccountingConnectionToJson(
  _AccountingConnection instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'provider': _$AccountingProviderEnumMap[instance.provider]!,
  'providerCompanyId': instance.providerCompanyId,
  'providerCompanyName': instance.providerCompanyName,
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'tokenExpiresAt': const TimestampConverter().toJson(instance.tokenExpiresAt),
  'syncInvoices': instance.syncInvoices,
  'syncPayments': instance.syncPayments,
  'syncClients': instance.syncClients,
  'syncProducts': instance.syncProducts,
  'incomeAccountId': instance.incomeAccountId,
  'incomeAccountName': instance.incomeAccountName,
  'depositAccountId': instance.depositAccountId,
  'depositAccountName': instance.depositAccountName,
  'taxCodeId': instance.taxCodeId,
  'taxCodeName': instance.taxCodeName,
  'status': _$ConnectionStatusEnumMap[instance.status]!,
  'lastSyncAt': const NullableTimestampConverter().toJson(instance.lastSyncAt),
  'lastSyncError': instance.lastSyncError,
  'connectedAt': const TimestampConverter().toJson(instance.connectedAt),
  'connectedByUserId': instance.connectedByUserId,
  'hipaaMode': instance.hipaaMode,
  'baaVerified': instance.baaVerified,
  'baaVerifiedAt': const NullableTimestampConverter().toJson(
    instance.baaVerifiedAt,
  ),
  'baaVerifiedByUserId': instance.baaVerifiedByUserId,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$AccountingProviderEnumMap = {
  AccountingProvider.quickbooks: 'quickbooks',
  AccountingProvider.xero: 'xero',
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.active: 'active',
  ConnectionStatus.expired: 'expired',
  ConnectionStatus.error: 'error',
  ConnectionStatus.disconnected: 'disconnected',
};
