// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentiment_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SentimentResult _$SentimentResultFromJson(Map<String, dynamic> json) =>
    _SentimentResult(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      clientId: json['clientId'] as String,
      source: $enumDecode(_$SentimentSourceEnumMap, json['source']),
      sourceDocumentId: json['sourceDocumentId'] as String?,
      analyzedText: json['analyzedText'] as String,
      sentimentScore: (json['sentimentScore'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      riskIndicators: (json['riskIndicators'] as List<dynamic>)
          .map((e) => RiskIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      vipIndicators: (json['vipIndicators'] as List<dynamic>)
          .map((e) => RiskIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
      recommendedAction: json['recommendedAction'] as String?,
      modelVersion: json['modelVersion'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SentimentResultToJson(_SentimentResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'clientId': instance.clientId,
      'source': _$SentimentSourceEnumMap[instance.source]!,
      'sourceDocumentId': instance.sourceDocumentId,
      'analyzedText': instance.analyzedText,
      'sentimentScore': instance.sentimentScore,
      'confidence': instance.confidence,
      'riskIndicators': instance.riskIndicators.map((e) => e.toJson()).toList(),
      'vipIndicators': instance.vipIndicators.map((e) => e.toJson()).toList(),
      'summary': instance.summary,
      'recommendedAction': instance.recommendedAction,
      'modelVersion': instance.modelVersion,
      'analyzedAt': instance.analyzedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'processingTimeMs': instance.processingTimeMs,
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
