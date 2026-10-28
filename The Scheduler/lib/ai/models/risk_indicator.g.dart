// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_indicator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RiskIndicator _$RiskIndicatorFromJson(Map<String, dynamic> json) =>
    _RiskIndicator(
      id: json['id'] as String,
      type: $enumDecode(_$IndicatorTypeEnumMap, json['type']),
      severity: $enumDecode(_$IndicatorSeverityEnumMap, json['severity']),
      category: json['category'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: $enumDecode(_$SentimentSourceEnumMap, json['source']),
      sourceDocumentId: json['sourceDocumentId'] as String?,
      triggerText: json['triggerText'] as String?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      suggestedAction: json['suggestedAction'] as String?,
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
    );

Map<String, dynamic> _$RiskIndicatorToJson(_RiskIndicator instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$IndicatorTypeEnumMap[instance.type]!,
      'severity': _$IndicatorSeverityEnumMap[instance.severity]!,
      'category': instance.category,
      'description': instance.description,
      'confidence': instance.confidence,
      'source': _$SentimentSourceEnumMap[instance.source]!,
      'sourceDocumentId': instance.sourceDocumentId,
      'triggerText': instance.triggerText,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'suggestedAction': instance.suggestedAction,
      'acknowledged': instance.acknowledged,
      'acknowledgedBy': instance.acknowledgedBy,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
    };

const _$IndicatorTypeEnumMap = {
  IndicatorType.negative: 'negative',
  IndicatorType.positive: 'positive',
  IndicatorType.risk: 'risk',
  IndicatorType.vip: 'vip',
  IndicatorType.neutral: 'neutral',
};

const _$IndicatorSeverityEnumMap = {
  IndicatorSeverity.critical: 'critical',
  IndicatorSeverity.high: 'high',
  IndicatorSeverity.medium: 'medium',
  IndicatorSeverity.low: 'low',
};

const _$SentimentSourceEnumMap = {
  SentimentSource.smsReply: 'smsReply',
  SentimentSource.emailReply: 'emailReply',
  SentimentSource.intakeFormText: 'intakeFormText',
  SentimentSource.sessionNote: 'sessionNote',
  SentimentSource.cancellationReason: 'cancellationReason',
  SentimentSource.rescheduleReason: 'rescheduleReason',
  SentimentSource.feedbackText: 'feedbackText',
  SentimentSource.staffNote: 'staffNote',
};
