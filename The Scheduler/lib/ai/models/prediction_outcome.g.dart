// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PredictionOutcome _$PredictionOutcomeFromJson(Map<String, dynamic> json) =>
    _PredictionOutcome(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      appointmentId: json['appointmentId'] as String,
      clientId: json['clientId'] as String,
      predictedProbability: (json['predictedProbability'] as num).toDouble(),
      predictedRiskLevel: json['predictedRiskLevel'] as String,
      modelVersion: json['modelVersion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      predictedAt: DateTime.parse(json['predictedAt'] as String),
      appointmentTime: DateTime.parse(json['appointmentTime'] as String),
      outcome:
          $enumDecodeNullable(_$AppointmentOutcomeEnumMap, json['outcome']) ??
          AppointmentOutcome.pending,
      outcomeRecordedAt: json['outcomeRecordedAt'] == null
          ? null
          : DateTime.parse(json['outcomeRecordedAt'] as String),
      predictionCorrect: json['predictionCorrect'] as bool?,
      predictionError: (json['predictionError'] as num?)?.toDouble(),
      topFeatures:
          (json['topFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      providerId: json['providerId'] as String?,
      serviceId: json['serviceId'] as String?,
    );

Map<String, dynamic> _$PredictionOutcomeToJson(_PredictionOutcome instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'appointmentId': instance.appointmentId,
      'clientId': instance.clientId,
      'predictedProbability': instance.predictedProbability,
      'predictedRiskLevel': instance.predictedRiskLevel,
      'modelVersion': instance.modelVersion,
      'confidence': instance.confidence,
      'predictedAt': instance.predictedAt.toIso8601String(),
      'appointmentTime': instance.appointmentTime.toIso8601String(),
      'outcome': _$AppointmentOutcomeEnumMap[instance.outcome]!,
      'outcomeRecordedAt': instance.outcomeRecordedAt?.toIso8601String(),
      'predictionCorrect': instance.predictionCorrect,
      'predictionError': instance.predictionError,
      'topFeatures': instance.topFeatures,
      'providerId': instance.providerId,
      'serviceId': instance.serviceId,
    };

const _$AppointmentOutcomeEnumMap = {
  AppointmentOutcome.attended: 'attended',
  AppointmentOutcome.noshow: 'noshow',
  AppointmentOutcome.cancelled: 'cancelled',
  AppointmentOutcome.rescheduled: 'rescheduled',
  AppointmentOutcome.pending: 'pending',
};

_PredictionOutcomeSummary _$PredictionOutcomeSummaryFromJson(
  Map<String, dynamic> json,
) => _PredictionOutcomeSummary(
  periodStart: DateTime.parse(json['periodStart'] as String),
  periodEnd: DateTime.parse(json['periodEnd'] as String),
  totalPredictions: (json['totalPredictions'] as num).toInt(),
  evaluatedPredictions: (json['evaluatedPredictions'] as num).toInt(),
  correctPredictions: (json['correctPredictions'] as num).toInt(),
  actualNoShows: (json['actualNoShows'] as num).toInt(),
  truePositives: (json['truePositives'] as num).toInt(),
  trueNegatives: (json['trueNegatives'] as num).toInt(),
  falsePositives: (json['falsePositives'] as num).toInt(),
  falseNegatives: (json['falseNegatives'] as num).toInt(),
  modelVersions: (json['modelVersions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PredictionOutcomeSummaryToJson(
  _PredictionOutcomeSummary instance,
) => <String, dynamic>{
  'periodStart': instance.periodStart.toIso8601String(),
  'periodEnd': instance.periodEnd.toIso8601String(),
  'totalPredictions': instance.totalPredictions,
  'evaluatedPredictions': instance.evaluatedPredictions,
  'correctPredictions': instance.correctPredictions,
  'actualNoShows': instance.actualNoShows,
  'truePositives': instance.truePositives,
  'trueNegatives': instance.trueNegatives,
  'falsePositives': instance.falsePositives,
  'falseNegatives': instance.falseNegatives,
  'modelVersions': instance.modelVersions,
};
