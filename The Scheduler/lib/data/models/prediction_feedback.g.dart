// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PredictionFeedback _$PredictionFeedbackFromJson(Map<String, dynamic> json) =>
    _PredictionFeedback(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      appointmentId: json['appointmentId'] as String,
      clientId: json['clientId'] as String,
      predictionId: json['predictionId'] as String?,
      userId: json['userId'] as String,
      userRole: $enumDecode(_$FeedbackUserRoleEnumMap, json['userRole']),
      feedbackType: $enumDecode(_$FeedbackTypeEnumMap, json['feedbackType']),
      negativeReason: $enumDecodeNullable(
        _$NegativeFeedbackReasonEnumMap,
        json['negativeReason'],
      ),
      comment: json['comment'] as String?,
      modelVersion: json['modelVersion'] as String,
      predictedProbability: (json['predictedProbability'] as num).toDouble(),
      predictedRiskLevel: json['predictedRiskLevel'] as String,
      submittedAt: const TimestampConverter().fromJson(json['submittedAt']),
      experimentVariantId: json['experimentVariantId'] as String?,
      experimentId: json['experimentId'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      processedForTraining: json['processedForTraining'] as bool? ?? false,
      processedAt: const NullableTimestampConverter().fromJson(
        json['processedAt'],
      ),
    );

Map<String, dynamic> _$PredictionFeedbackToJson(
  _PredictionFeedback instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'appointmentId': instance.appointmentId,
  'clientId': instance.clientId,
  'predictionId': instance.predictionId,
  'userId': instance.userId,
  'userRole': _$FeedbackUserRoleEnumMap[instance.userRole]!,
  'feedbackType': _$FeedbackTypeEnumMap[instance.feedbackType]!,
  'negativeReason': _$NegativeFeedbackReasonEnumMap[instance.negativeReason],
  'comment': instance.comment,
  'modelVersion': instance.modelVersion,
  'predictedProbability': instance.predictedProbability,
  'predictedRiskLevel': instance.predictedRiskLevel,
  'submittedAt': const TimestampConverter().toJson(instance.submittedAt),
  'experimentVariantId': instance.experimentVariantId,
  'experimentId': instance.experimentId,
  'weight': instance.weight,
  'processedForTraining': instance.processedForTraining,
  'processedAt': const NullableTimestampConverter().toJson(
    instance.processedAt,
  ),
};

const _$FeedbackUserRoleEnumMap = {
  FeedbackUserRole.admin: 'admin',
  FeedbackUserRole.manager: 'manager',
  FeedbackUserRole.staff: 'staff',
  FeedbackUserRole.guest: 'guest',
};

const _$FeedbackTypeEnumMap = {
  FeedbackType.positive: 'positive',
  FeedbackType.negative: 'negative',
  FeedbackType.skipped: 'skipped',
};

const _$NegativeFeedbackReasonEnumMap = {
  NegativeFeedbackReason.probabilityTooHigh: 'probability_too_high',
  NegativeFeedbackReason.probabilityTooLow: 'probability_too_low',
  NegativeFeedbackReason.wrongFactors: 'wrong_factors',
  NegativeFeedbackReason.doesntMatchBehavior: 'doesnt_match_behavior',
  NegativeFeedbackReason.inappropriateAction: 'inappropriate_action',
  NegativeFeedbackReason.other: 'other',
};

_FeedbackSummary _$FeedbackSummaryFromJson(Map<String, dynamic> json) =>
    _FeedbackSummary(
      modelVersion: json['modelVersion'] as String,
      periodStart: const TimestampConverter().fromJson(json['periodStart']),
      periodEnd: const TimestampConverter().fromJson(json['periodEnd']),
      totalFeedback: (json['totalFeedback'] as num).toInt(),
      positiveCount: (json['positiveCount'] as num).toInt(),
      negativeCount: (json['negativeCount'] as num).toInt(),
      skippedCount: (json['skippedCount'] as num).toInt(),
      weightedScoreSum: (json['weightedScoreSum'] as num).toDouble(),
      totalWeight: (json['totalWeight'] as num).toDouble(),
      negativeReasonCounts:
          (json['negativeReasonCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      topNegativeReasons:
          (json['topNegativeReasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      businessId: json['businessId'] as String?,
      experimentId: json['experimentId'] as String?,
      variantId: json['variantId'] as String?,
    );

Map<String, dynamic> _$FeedbackSummaryToJson(_FeedbackSummary instance) =>
    <String, dynamic>{
      'modelVersion': instance.modelVersion,
      'periodStart': const TimestampConverter().toJson(instance.periodStart),
      'periodEnd': const TimestampConverter().toJson(instance.periodEnd),
      'totalFeedback': instance.totalFeedback,
      'positiveCount': instance.positiveCount,
      'negativeCount': instance.negativeCount,
      'skippedCount': instance.skippedCount,
      'weightedScoreSum': instance.weightedScoreSum,
      'totalWeight': instance.totalWeight,
      'negativeReasonCounts': instance.negativeReasonCounts,
      'topNegativeReasons': instance.topNegativeReasons,
      'businessId': instance.businessId,
      'experimentId': instance.experimentId,
      'variantId': instance.variantId,
    };
