// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_performance_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModelPerformanceSnapshot _$ModelPerformanceSnapshotFromJson(
  Map<String, dynamic> json,
) => _ModelPerformanceSnapshot(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  modelVersion: json['modelVersion'] as String,
  periodStart: DateTime.parse(json['periodStart'] as String),
  periodEnd: DateTime.parse(json['periodEnd'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  sampleSize: (json['sampleSize'] as num).toInt(),
  aucRoc: (json['aucRoc'] as num).toDouble(),
  precisionAt50: (json['precisionAt50'] as num).toDouble(),
  recallAt50: (json['recallAt50'] as num).toDouble(),
  f1At50: (json['f1At50'] as num).toDouble(),
  brierScore: (json['brierScore'] as num).toDouble(),
  calibrationError: (json['calibrationError'] as num).toDouble(),
  logLoss: (json['logLoss'] as num?)?.toDouble(),
  status: $enumDecode(_$PerformanceStatusEnumMap, json['status']),
  driftType:
      $enumDecodeNullable(_$DriftTypeEnumMap, json['driftType']) ??
      DriftType.none,
  driftScore: (json['driftScore'] as num?)?.toDouble() ?? 0.0,
  driftedFeatures:
      (json['driftedFeatures'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  baseline: json['baseline'] == null
      ? null
      : ModelBaselineMetrics.fromJson(json['baseline'] as Map<String, dynamic>),
  retrainingTriggered: json['retrainingTriggered'] as bool? ?? false,
  alerts:
      (json['alerts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ModelPerformanceSnapshotToJson(
  _ModelPerformanceSnapshot instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'modelVersion': instance.modelVersion,
  'periodStart': instance.periodStart.toIso8601String(),
  'periodEnd': instance.periodEnd.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'sampleSize': instance.sampleSize,
  'aucRoc': instance.aucRoc,
  'precisionAt50': instance.precisionAt50,
  'recallAt50': instance.recallAt50,
  'f1At50': instance.f1At50,
  'brierScore': instance.brierScore,
  'calibrationError': instance.calibrationError,
  'logLoss': instance.logLoss,
  'status': _$PerformanceStatusEnumMap[instance.status]!,
  'driftType': _$DriftTypeEnumMap[instance.driftType]!,
  'driftScore': instance.driftScore,
  'driftedFeatures': instance.driftedFeatures,
  'baseline': instance.baseline?.toJson(),
  'retrainingTriggered': instance.retrainingTriggered,
  'alerts': instance.alerts,
};

const _$PerformanceStatusEnumMap = {
  PerformanceStatus.healthy: 'healthy',
  PerformanceStatus.degraded: 'degraded',
  PerformanceStatus.critical: 'critical',
  PerformanceStatus.insufficientData: 'insufficient_data',
};

const _$DriftTypeEnumMap = {
  DriftType.none: 'none',
  DriftType.dataDrift: 'data_drift',
  DriftType.conceptDrift: 'concept_drift',
  DriftType.both: 'both',
};

_ModelBaselineMetrics _$ModelBaselineMetricsFromJson(
  Map<String, dynamic> json,
) => _ModelBaselineMetrics(
  modelVersion: json['modelVersion'] as String,
  establishedAt: DateTime.parse(json['establishedAt'] as String),
  aucRoc: (json['aucRoc'] as num).toDouble(),
  precision: (json['precision'] as num).toDouble(),
  recall: (json['recall'] as num).toDouble(),
  f1: (json['f1'] as num).toDouble(),
  brierScore: (json['brierScore'] as num).toDouble(),
  calibrationError: (json['calibrationError'] as num).toDouble(),
  trainingSampleSize: (json['trainingSampleSize'] as num).toInt(),
  featureImportances:
      (json['featureImportances'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  featureStats:
      (json['featureStats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FeatureStats.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$ModelBaselineMetricsToJson(
  _ModelBaselineMetrics instance,
) => <String, dynamic>{
  'modelVersion': instance.modelVersion,
  'establishedAt': instance.establishedAt.toIso8601String(),
  'aucRoc': instance.aucRoc,
  'precision': instance.precision,
  'recall': instance.recall,
  'f1': instance.f1,
  'brierScore': instance.brierScore,
  'calibrationError': instance.calibrationError,
  'trainingSampleSize': instance.trainingSampleSize,
  'featureImportances': instance.featureImportances,
  'featureStats': instance.featureStats.map((k, e) => MapEntry(k, e.toJson())),
};

_FeatureStats _$FeatureStatsFromJson(Map<String, dynamic> json) =>
    _FeatureStats(
      featureName: json['featureName'] as String,
      mean: (json['mean'] as num?)?.toDouble(),
      stdDev: (json['stdDev'] as num?)?.toDouble(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      distribution:
          (json['distribution'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      sampleCount: (json['sampleCount'] as num).toInt(),
    );

Map<String, dynamic> _$FeatureStatsToJson(_FeatureStats instance) =>
    <String, dynamic>{
      'featureName': instance.featureName,
      'mean': instance.mean,
      'stdDev': instance.stdDev,
      'min': instance.min,
      'max': instance.max,
      'distribution': instance.distribution,
      'sampleCount': instance.sampleCount,
    };

_MonitoringThresholds _$MonitoringThresholdsFromJson(
  Map<String, dynamic> json,
) => _MonitoringThresholds(
  minAuc: (json['minAuc'] as num?)?.toDouble() ?? 0.75,
  maxCalibrationError: (json['maxCalibrationError'] as num?)?.toDouble() ?? 0.1,
  aucDropThreshold: (json['aucDropThreshold'] as num?)?.toDouble() ?? 0.05,
  driftThreshold: (json['driftThreshold'] as num?)?.toDouble() ?? 2.0,
  minSampleSize: (json['minSampleSize'] as num?)?.toInt() ?? 50,
  minOutcomesForRetraining:
      (json['minOutcomesForRetraining'] as num?)?.toInt() ?? 1000,
);

Map<String, dynamic> _$MonitoringThresholdsToJson(
  _MonitoringThresholds instance,
) => <String, dynamic>{
  'minAuc': instance.minAuc,
  'maxCalibrationError': instance.maxCalibrationError,
  'aucDropThreshold': instance.aucDropThreshold,
  'driftThreshold': instance.driftThreshold,
  'minSampleSize': instance.minSampleSize,
  'minOutcomesForRetraining': instance.minOutcomesForRetraining,
};
