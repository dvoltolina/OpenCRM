// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_explanation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExplanationFactor _$ExplanationFactorFromJson(Map<String, dynamic> json) =>
    _ExplanationFactor(
      feature: json['feature'] as String,
      displayName: json['display_name'] as String,
      impact: json['impact'] as String,
      magnitude: (json['magnitude'] as num).toDouble(),
      explanation: json['explanation'] as String,
      featureValue: json['feature_value'],
    );

Map<String, dynamic> _$ExplanationFactorToJson(_ExplanationFactor instance) =>
    <String, dynamic>{
      'feature': instance.feature,
      'display_name': instance.displayName,
      'impact': instance.impact,
      'magnitude': instance.magnitude,
      'explanation': instance.explanation,
      'feature_value': instance.featureValue,
    };

_PredictionExplanation _$PredictionExplanationFromJson(
  Map<String, dynamic> json,
) => _PredictionExplanation(
  appointmentId: json['appointmentId'] as String,
  probability: (json['probability'] as num).toDouble(),
  riskLevel: json['riskLevel'] as String,
  summary: json['summary'] as String,
  topFactors: (json['topFactors'] as List<dynamic>)
      .map((e) => ExplanationFactor.fromJson(e as Map<String, dynamic>))
      .toList(),
  modelVersion: json['modelVersion'] as String,
  explanationVersion: json['explanationVersion'] as String? ?? '1.0.0',
  generatedAt: json['generatedAt'] == null
      ? null
      : DateTime.parse(json['generatedAt'] as String),
);

Map<String, dynamic> _$PredictionExplanationToJson(
  _PredictionExplanation instance,
) => <String, dynamic>{
  'appointmentId': instance.appointmentId,
  'probability': instance.probability,
  'riskLevel': instance.riskLevel,
  'summary': instance.summary,
  'topFactors': instance.topFactors.map((e) => e.toJson()).toList(),
  'modelVersion': instance.modelVersion,
  'explanationVersion': instance.explanationVersion,
  'generatedAt': instance.generatedAt?.toIso8601String(),
};

_ExplanationRequest _$ExplanationRequestFromJson(Map<String, dynamic> json) =>
    _ExplanationRequest(
      appointmentId: json['appointment_id'] as String,
      includeAllFactors: json['include_all_factors'] as bool? ?? false,
      numFactors: (json['num_factors'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$ExplanationRequestToJson(_ExplanationRequest instance) =>
    <String, dynamic>{
      'appointment_id': instance.appointmentId,
      'include_all_factors': instance.includeAllFactors,
      'num_factors': instance.numFactors,
    };

_CachedExplanation _$CachedExplanationFromJson(Map<String, dynamic> json) =>
    _CachedExplanation(
      explanation: PredictionExplanation.fromJson(
        json['explanation'] as Map<String, dynamic>,
      ),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$CachedExplanationToJson(_CachedExplanation instance) =>
    <String, dynamic>{
      'explanation': instance.explanation.toJson(),
      'cachedAt': instance.cachedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
