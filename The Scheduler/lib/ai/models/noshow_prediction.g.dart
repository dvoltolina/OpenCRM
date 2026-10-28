// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noshow_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecommendedAction _$RecommendedActionFromJson(Map<String, dynamic> json) =>
    _RecommendedAction(
      actionId: json['actionId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: $enumDecode(_$ActionPriorityEnumMap, json['priority']),
      automatable: json['automatable'] as bool,
      iconName: json['iconName'] as String?,
      estimatedImpact: (json['estimatedImpact'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RecommendedActionToJson(_RecommendedAction instance) =>
    <String, dynamic>{
      'actionId': instance.actionId,
      'title': instance.title,
      'description': instance.description,
      'priority': _$ActionPriorityEnumMap[instance.priority]!,
      'automatable': instance.automatable,
      'iconName': instance.iconName,
      'estimatedImpact': instance.estimatedImpact,
    };

const _$ActionPriorityEnumMap = {
  ActionPriority.critical: 'critical',
  ActionPriority.high: 'high',
  ActionPriority.medium: 'medium',
  ActionPriority.low: 'low',
};

_NoshowPrediction _$NoshowPredictionFromJson(Map<String, dynamic> json) =>
    _NoshowPrediction(
      appointmentId: json['appointmentId'] as String,
      probability: (json['probability'] as num).toDouble(),
      riskLevel: $enumDecode(_$RiskLevelEnumMap, json['riskLevel']),
      confidence: (json['confidence'] as num).toDouble(),
      recommendedActions: (json['recommendedActions'] as List<dynamic>)
          .map((e) => RecommendedAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      topFeatures: (json['topFeatures'] as List<dynamic>)
          .map((e) => FeatureImportance.fromJson(e as Map<String, dynamic>))
          .toList(),
      modelVersion: json['modelVersion'] as String,
      predictedAt: DateTime.parse(json['predictedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      requestId: json['requestId'] as String?,
    );

Map<String, dynamic> _$NoshowPredictionToJson(_NoshowPrediction instance) =>
    <String, dynamic>{
      'appointmentId': instance.appointmentId,
      'probability': instance.probability,
      'riskLevel': _$RiskLevelEnumMap[instance.riskLevel]!,
      'confidence': instance.confidence,
      'recommendedActions': instance.recommendedActions
          .map((e) => e.toJson())
          .toList(),
      'topFeatures': instance.topFeatures.map((e) => e.toJson()).toList(),
      'modelVersion': instance.modelVersion,
      'predictedAt': instance.predictedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'requestId': instance.requestId,
    };

const _$RiskLevelEnumMap = {
  RiskLevel.high: 'high',
  RiskLevel.medium: 'medium',
  RiskLevel.low: 'low',
  RiskLevel.unknown: 'unknown',
};
