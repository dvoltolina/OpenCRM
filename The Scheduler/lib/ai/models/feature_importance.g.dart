// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_importance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeatureImportance _$FeatureImportanceFromJson(Map<String, dynamic> json) =>
    _FeatureImportance(
      featureName: json['featureName'] as String,
      featureDisplayName: json['featureDisplayName'] as String,
      importance: (json['importance'] as num).toDouble(),
      featureValue: (json['featureValue'] as num).toDouble(),
      impact: json['impact'] as String,
      explanation: json['explanation'] as String?,
    );

Map<String, dynamic> _$FeatureImportanceToJson(_FeatureImportance instance) =>
    <String, dynamic>{
      'featureName': instance.featureName,
      'featureDisplayName': instance.featureDisplayName,
      'importance': instance.importance,
      'featureValue': instance.featureValue,
      'impact': instance.impact,
      'explanation': instance.explanation,
    };
