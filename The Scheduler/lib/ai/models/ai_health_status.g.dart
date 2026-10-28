// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_health_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceHealthDetail _$ServiceHealthDetailFromJson(Map<String, dynamic> json) =>
    _ServiceHealthDetail(
      serviceName: json['serviceName'] as String,
      status: $enumDecode(_$AIServiceHealthEnumMap, json['status']),
      responseTimeMs: (json['responseTimeMs'] as num?)?.toInt(),
      lastSuccessAt: json['lastSuccessAt'] == null
          ? null
          : DateTime.parse(json['lastSuccessAt'] as String),
      lastErrorAt: json['lastErrorAt'] == null
          ? null
          : DateTime.parse(json['lastErrorAt'] as String),
      lastErrorMessage: json['lastErrorMessage'] as String?,
      consecutiveFailures: (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
      circuitBreakerOpen: json['circuitBreakerOpen'] as bool? ?? false,
      requestsLastMinute: (json['requestsLastMinute'] as num?)?.toInt() ?? 0,
      errorsLastMinute: (json['errorsLastMinute'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ServiceHealthDetailToJson(
  _ServiceHealthDetail instance,
) => <String, dynamic>{
  'serviceName': instance.serviceName,
  'status': _$AIServiceHealthEnumMap[instance.status]!,
  'responseTimeMs': instance.responseTimeMs,
  'lastSuccessAt': instance.lastSuccessAt?.toIso8601String(),
  'lastErrorAt': instance.lastErrorAt?.toIso8601String(),
  'lastErrorMessage': instance.lastErrorMessage,
  'consecutiveFailures': instance.consecutiveFailures,
  'circuitBreakerOpen': instance.circuitBreakerOpen,
  'requestsLastMinute': instance.requestsLastMinute,
  'errorsLastMinute': instance.errorsLastMinute,
};

const _$AIServiceHealthEnumMap = {
  AIServiceHealth.healthy: 'healthy',
  AIServiceHealth.degraded: 'degraded',
  AIServiceHealth.unhealthy: 'unhealthy',
  AIServiceHealth.unavailable: 'unavailable',
};

_AIHealthStatus _$AIHealthStatusFromJson(
  Map<String, dynamic> json,
) => _AIHealthStatus(
  overallStatus: $enumDecode(_$AIServiceHealthEnumMap, json['overallStatus']),
  predictionService: ServiceHealthDetail.fromJson(
    json['predictionService'] as Map<String, dynamic>,
  ),
  sentimentService: ServiceHealthDetail.fromJson(
    json['sentimentService'] as Map<String, dynamic>,
  ),
  routingService: ServiceHealthDetail.fromJson(
    json['routingService'] as Map<String, dynamic>,
  ),
  lastHealthCheck: json['lastHealthCheck'] == null
      ? null
      : DateTime.parse(json['lastHealthCheck'] as String),
  lastSuccessfulPrediction: json['lastSuccessfulPrediction'] == null
      ? null
      : DateTime.parse(json['lastSuccessfulPrediction'] as String),
  errorMessage: json['errorMessage'] as String?,
  loadedModels: LoadedModels.fromJson(
    json['loadedModels'] as Map<String, dynamic>,
  ),
  serverVersion: json['serverVersion'] as String?,
  serverUptimeSeconds: (json['serverUptimeSeconds'] as num?)?.toInt(),
  gpuAvailable: json['gpuAvailable'] as bool? ?? false,
  gpuMemoryUsagePercent: (json['gpuMemoryUsagePercent'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AIHealthStatusToJson(_AIHealthStatus instance) =>
    <String, dynamic>{
      'overallStatus': _$AIServiceHealthEnumMap[instance.overallStatus]!,
      'predictionService': instance.predictionService.toJson(),
      'sentimentService': instance.sentimentService.toJson(),
      'routingService': instance.routingService.toJson(),
      'lastHealthCheck': instance.lastHealthCheck?.toIso8601String(),
      'lastSuccessfulPrediction': instance.lastSuccessfulPrediction
          ?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'loadedModels': instance.loadedModels.toJson(),
      'serverVersion': instance.serverVersion,
      'serverUptimeSeconds': instance.serverUptimeSeconds,
      'gpuAvailable': instance.gpuAvailable,
      'gpuMemoryUsagePercent': instance.gpuMemoryUsagePercent,
    };
