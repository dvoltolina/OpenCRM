// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModelMetadata _$ModelMetadataFromJson(Map<String, dynamic> json) =>
    _ModelMetadata(
      modelId: json['modelId'] as String,
      modelType: $enumDecode(_$AIModelTypeEnumMap, json['modelType']),
      version: json['version'] as String,
      trainedAt: DateTime.parse(json['trainedAt'] as String),
      featureSchemaVersion: (json['featureSchemaVersion'] as num).toInt(),
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      featureNames: (json['featureNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      hyperparameters: json['hyperparameters'] as Map<String, dynamic>?,
      trainingSampleCount: (json['trainingSampleCount'] as num?)?.toInt(),
      trainingDataHash: json['trainingDataHash'] as String?,
      trainedBy: json['trainedBy'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      deployedAt: json['deployedAt'] == null
          ? null
          : DateTime.parse(json['deployedAt'] as String),
    );

Map<String, dynamic> _$ModelMetadataToJson(_ModelMetadata instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'modelType': _$AIModelTypeEnumMap[instance.modelType]!,
      'version': instance.version,
      'trainedAt': instance.trainedAt.toIso8601String(),
      'featureSchemaVersion': instance.featureSchemaVersion,
      'metrics': instance.metrics,
      'featureNames': instance.featureNames,
      'description': instance.description,
      'hyperparameters': instance.hyperparameters,
      'trainingSampleCount': instance.trainingSampleCount,
      'trainingDataHash': instance.trainingDataHash,
      'trainedBy': instance.trainedBy,
      'isActive': instance.isActive,
      'deployedAt': instance.deployedAt?.toIso8601String(),
    };

const _$AIModelTypeEnumMap = {
  AIModelType.lightgbm: 'lightgbm',
  AIModelType.xgboost: 'xgboost',
  AIModelType.llm: 'llm',
  AIModelType.ortools: 'ortools',
  AIModelType.unknown: 'unknown',
};

_LoadedModels _$LoadedModelsFromJson(
  Map<String, dynamic> json,
) => _LoadedModels(
  predictionModel: json['predictionModel'] == null
      ? null
      : ModelMetadata.fromJson(json['predictionModel'] as Map<String, dynamic>),
  sentimentModel: json['sentimentModel'] == null
      ? null
      : ModelMetadata.fromJson(json['sentimentModel'] as Map<String, dynamic>),
  routeModel: json['routeModel'] == null
      ? null
      : ModelMetadata.fromJson(json['routeModel'] as Map<String, dynamic>),
  lastRefreshed: json['lastRefreshed'] == null
      ? null
      : DateTime.parse(json['lastRefreshed'] as String),
);

Map<String, dynamic> _$LoadedModelsToJson(_LoadedModels instance) =>
    <String, dynamic>{
      'predictionModel': instance.predictionModel?.toJson(),
      'sentimentModel': instance.sentimentModel?.toJson(),
      'routeModel': instance.routeModel?.toJson(),
      'lastRefreshed': instance.lastRefreshed?.toIso8601String(),
    };
