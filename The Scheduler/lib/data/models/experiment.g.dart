// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExperimentVariant _$ExperimentVariantFromJson(Map<String, dynamic> json) =>
    _ExperimentVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trafficPercentage: (json['trafficPercentage'] as num).toInt(),
      isControl: json['isControl'] as bool? ?? false,
      config: json['config'] as Map<String, dynamic>? ?? const {},
      assignmentCount: (json['assignmentCount'] as num?)?.toInt() ?? 0,
      conversionCount: (json['conversionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ExperimentVariantToJson(_ExperimentVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'trafficPercentage': instance.trafficPercentage,
      'isControl': instance.isControl,
      'config': instance.config,
      'assignmentCount': instance.assignmentCount,
      'conversionCount': instance.conversionCount,
    };

_Experiment _$ExperimentFromJson(Map<String, dynamic> json) => _Experiment(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$ExperimentTypeEnumMap, json['type']),
  status:
      $enumDecodeNullable(_$ExperimentStatusEnumMap, json['status']) ??
      ExperimentStatus.draft,
  variants: (json['variants'] as List<dynamic>)
      .map((e) => ExperimentVariant.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  createdBy: json['createdBy'] as String,
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  startedAt: const NullableTimestampConverter().fromJson(json['startedAt']),
  endedAt: const NullableTimestampConverter().fromJson(json['endedAt']),
  targetSampleSize: (json['targetSampleSize'] as num?)?.toInt(),
  minimumRunDays: (json['minimumRunDays'] as num?)?.toInt() ?? 7,
  maximumRunDays: (json['maximumRunDays'] as num?)?.toInt() ?? 30,
  primaryMetric: json['primaryMetric'] as String? ?? 'prediction_accuracy',
  secondaryMetrics:
      (json['secondaryMetrics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  winningVariantId: json['winningVariantId'] as String?,
  requiredConfidence: (json['requiredConfidence'] as num?)?.toDouble() ?? 0.95,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ExperimentToJson(
  _Experiment instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'name': instance.name,
  'description': instance.description,
  'type': _$ExperimentTypeEnumMap[instance.type]!,
  'status': _$ExperimentStatusEnumMap[instance.status]!,
  'variants': instance.variants.map((e) => e.toJson()).toList(),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'createdBy': instance.createdBy,
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'startedAt': const NullableTimestampConverter().toJson(instance.startedAt),
  'endedAt': const NullableTimestampConverter().toJson(instance.endedAt),
  'targetSampleSize': instance.targetSampleSize,
  'minimumRunDays': instance.minimumRunDays,
  'maximumRunDays': instance.maximumRunDays,
  'primaryMetric': instance.primaryMetric,
  'secondaryMetrics': instance.secondaryMetrics,
  'winningVariantId': instance.winningVariantId,
  'requiredConfidence': instance.requiredConfidence,
  'tags': instance.tags,
};

const _$ExperimentTypeEnumMap = {
  ExperimentType.modelComparison: 'model_comparison',
  ExperimentType.thresholdTesting: 'threshold_testing',
  ExperimentType.uiTreatment: 'ui_treatment',
  ExperimentType.featureTesting: 'feature_testing',
};

const _$ExperimentStatusEnumMap = {
  ExperimentStatus.draft: 'draft',
  ExperimentStatus.active: 'active',
  ExperimentStatus.paused: 'paused',
  ExperimentStatus.completed: 'completed',
  ExperimentStatus.cancelled: 'cancelled',
};

_ExperimentAssignment _$ExperimentAssignmentFromJson(
  Map<String, dynamic> json,
) => _ExperimentAssignment(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  experimentId: json['experimentId'] as String,
  variantId: json['variantId'] as String,
  userId: json['userId'] as String,
  assignedAt: const TimestampConverter().fromJson(json['assignedAt']),
  entityId: json['entityId'] as String?,
  entityType: json['entityType'] as String?,
  converted: json['converted'] as bool?,
  convertedAt: const NullableTimestampConverter().fromJson(json['convertedAt']),
  conversionMetadata:
      json['conversionMetadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ExperimentAssignmentToJson(
  _ExperimentAssignment instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'experimentId': instance.experimentId,
  'variantId': instance.variantId,
  'userId': instance.userId,
  'assignedAt': const TimestampConverter().toJson(instance.assignedAt),
  'entityId': instance.entityId,
  'entityType': instance.entityType,
  'converted': instance.converted,
  'convertedAt': const NullableTimestampConverter().toJson(
    instance.convertedAt,
  ),
  'conversionMetadata': instance.conversionMetadata,
};
