// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaitlistScore _$WaitlistScoreFromJson(Map<String, dynamic> json) =>
    _WaitlistScore(
      overallScore: (json['overallScore'] as num).toDouble(),
      timeFlexibilityScore: (json['timeFlexibilityScore'] as num).toDouble(),
      proximityScore: (json['proximityScore'] as num).toDouble(),
      confirmRateScore: (json['confirmRateScore'] as num).toDouble(),
      revenueScore: (json['revenueScore'] as num).toDouble(),
      fairnessScore: (json['fairnessScore'] as num).toDouble(),
      factors:
          (json['factors'] as List<dynamic>?)
              ?.map(
                (e) => WaitlistScoreFactor.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WaitlistScoreToJson(_WaitlistScore instance) =>
    <String, dynamic>{
      'overallScore': instance.overallScore,
      'timeFlexibilityScore': instance.timeFlexibilityScore,
      'proximityScore': instance.proximityScore,
      'confirmRateScore': instance.confirmRateScore,
      'revenueScore': instance.revenueScore,
      'fairnessScore': instance.fairnessScore,
      'factors': instance.factors.map((e) => e.toJson()).toList(),
    };

_WaitlistScoreFactor _$WaitlistScoreFactorFromJson(Map<String, dynamic> json) =>
    _WaitlistScoreFactor(
      factorType: $enumDecode(_$WaitlistFactorTypeEnumMap, json['factorType']),
      description: json['description'] as String,
      impact: (json['impact'] as num).toDouble(),
      maxImpact: (json['maxImpact'] as num).toDouble(),
      iconName: json['iconName'] as String? ?? 'info',
    );

Map<String, dynamic> _$WaitlistScoreFactorToJson(
  _WaitlistScoreFactor instance,
) => <String, dynamic>{
  'factorType': _$WaitlistFactorTypeEnumMap[instance.factorType]!,
  'description': instance.description,
  'impact': instance.impact,
  'maxImpact': instance.maxImpact,
  'iconName': instance.iconName,
};

const _$WaitlistFactorTypeEnumMap = {
  WaitlistFactorType.timeFlexibility: 'timeFlexibility',
  WaitlistFactorType.proximity: 'proximity',
  WaitlistFactorType.confirmRate: 'confirmRate',
  WaitlistFactorType.revenue: 'revenue',
  WaitlistFactorType.fairness: 'fairness',
  WaitlistFactorType.serviceMatch: 'serviceMatch',
  WaitlistFactorType.providerPreference: 'providerPreference',
};

_RankedWaitlistEntry _$RankedWaitlistEntryFromJson(Map<String, dynamic> json) =>
    _RankedWaitlistEntry(
      entryId: json['entryId'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      clientPhone: json['clientPhone'] as String?,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      score: WaitlistScore.fromJson(json['score'] as Map<String, dynamic>),
      rank: (json['rank'] as num).toInt(),
      addedAt: DateTime.parse(json['addedAt'] as String),
      preferredTimes:
          (json['preferredTimes'] as List<dynamic>?)
              ?.map((e) => TimeWindow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      historicalConfirmRate: (json['historicalConfirmRate'] as num?)
          ?.toDouble(),
      estimatedRevenue: (json['estimatedRevenue'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      offerSent: json['offerSent'] as bool? ?? false,
      offerSentAt: json['offerSentAt'] == null
          ? null
          : DateTime.parse(json['offerSentAt'] as String),
      offerResponse: json['offerResponse'] as String?,
      matchReasoning: json['matchReasoning'] as String?,
    );

Map<String, dynamic> _$RankedWaitlistEntryToJson(
  _RankedWaitlistEntry instance,
) => <String, dynamic>{
  'entryId': instance.entryId,
  'clientId': instance.clientId,
  'clientName': instance.clientName,
  'clientPhone': instance.clientPhone,
  'serviceId': instance.serviceId,
  'serviceName': instance.serviceName,
  'score': instance.score.toJson(),
  'rank': instance.rank,
  'addedAt': instance.addedAt.toIso8601String(),
  'preferredTimes': instance.preferredTimes.map((e) => e.toJson()).toList(),
  'distanceKm': instance.distanceKm,
  'historicalConfirmRate': instance.historicalConfirmRate,
  'estimatedRevenue': instance.estimatedRevenue,
  'notes': instance.notes,
  'offerSent': instance.offerSent,
  'offerSentAt': instance.offerSentAt?.toIso8601String(),
  'offerResponse': instance.offerResponse,
  'matchReasoning': instance.matchReasoning,
};

_TimeWindow _$TimeWindowFromJson(Map<String, dynamic> json) => _TimeWindow(
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  startHour: (json['startHour'] as num).toInt(),
  endHour: (json['endHour'] as num).toInt(),
);

Map<String, dynamic> _$TimeWindowToJson(_TimeWindow instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'startHour': instance.startHour,
      'endHour': instance.endHour,
    };

_WaitlistMatchResult _$WaitlistMatchResultFromJson(Map<String, dynamic> json) =>
    _WaitlistMatchResult(
      slotId: json['slotId'] as String,
      serviceId: json['serviceId'] as String,
      providerId: json['providerId'] as String,
      slotDateTime: DateTime.parse(json['slotDateTime'] as String),
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => RankedWaitlistEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCandidates:
          (json['topCandidates'] as List<dynamic>?)
              ?.map(
                (e) => RankedWaitlistEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalConsidered: (json['totalConsidered'] as num).toInt(),
      hasStrongMatches: json['hasStrongMatches'] as bool? ?? false,
      noMatchReason: json['noMatchReason'] as String?,
    );

Map<String, dynamic> _$WaitlistMatchResultToJson(
  _WaitlistMatchResult instance,
) => <String, dynamic>{
  'slotId': instance.slotId,
  'serviceId': instance.serviceId,
  'providerId': instance.providerId,
  'slotDateTime': instance.slotDateTime.toIso8601String(),
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
  'topCandidates': instance.topCandidates.map((e) => e.toJson()).toList(),
  'generatedAt': instance.generatedAt.toIso8601String(),
  'totalConsidered': instance.totalConsidered,
  'hasStrongMatches': instance.hasStrongMatches,
  'noMatchReason': instance.noMatchReason,
};

_WaitlistMatchRequest _$WaitlistMatchRequestFromJson(
  Map<String, dynamic> json,
) => _WaitlistMatchRequest(
  slotId: json['slotId'] as String,
  serviceId: json['serviceId'] as String,
  providerId: json['providerId'] as String,
  slotDateTime: DateTime.parse(json['slotDateTime'] as String),
  locationId: json['locationId'] as String?,
  maxCandidates: (json['maxCandidates'] as num?)?.toInt() ?? 10,
  autoOfferCount: (json['autoOfferCount'] as num?)?.toInt() ?? 3,
  minScore: (json['minScore'] as num?)?.toDouble() ?? 30,
);

Map<String, dynamic> _$WaitlistMatchRequestToJson(
  _WaitlistMatchRequest instance,
) => <String, dynamic>{
  'slotId': instance.slotId,
  'serviceId': instance.serviceId,
  'providerId': instance.providerId,
  'slotDateTime': instance.slotDateTime.toIso8601String(),
  'locationId': instance.locationId,
  'maxCandidates': instance.maxCandidates,
  'autoOfferCount': instance.autoOfferCount,
  'minScore': instance.minScore,
};
