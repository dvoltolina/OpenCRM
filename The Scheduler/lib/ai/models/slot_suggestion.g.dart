// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoredSlot _$ScoredSlotFromJson(Map<String, dynamic> json) => _ScoredSlot(
  slotId: json['slotId'] as String,
  providerId: json['providerId'] as String,
  providerName: json['providerName'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  predictedNoshowRisk: (json['predictedNoshowRisk'] as num).toDouble(),
  score: (json['score'] as num).toDouble(),
  isRecommended: json['isRecommended'] as bool,
  riskLevel: $enumDecode(_$SlotRiskLevelEnumMap, json['riskLevel']),
  scoreFactors: (json['scoreFactors'] as List<dynamic>)
      .map((e) => SlotScoreFactor.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendationReason: json['recommendationReason'] as String?,
  riskDifferencePercent: (json['riskDifferencePercent'] as num?)?.toDouble(),
  serviceId: json['serviceId'] as String?,
  locationId: json['locationId'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$ScoredSlotToJson(_ScoredSlot instance) =>
    <String, dynamic>{
      'slotId': instance.slotId,
      'providerId': instance.providerId,
      'providerName': instance.providerName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'predictedNoshowRisk': instance.predictedNoshowRisk,
      'score': instance.score,
      'isRecommended': instance.isRecommended,
      'riskLevel': _$SlotRiskLevelEnumMap[instance.riskLevel]!,
      'scoreFactors': instance.scoreFactors.map((e) => e.toJson()).toList(),
      'recommendationReason': instance.recommendationReason,
      'riskDifferencePercent': instance.riskDifferencePercent,
      'serviceId': instance.serviceId,
      'locationId': instance.locationId,
      'isAvailable': instance.isAvailable,
    };

const _$SlotRiskLevelEnumMap = {
  SlotRiskLevel.low: 'low',
  SlotRiskLevel.medium: 'medium',
  SlotRiskLevel.high: 'high',
  SlotRiskLevel.unknown: 'unknown',
};

_SlotScoreFactor _$SlotScoreFactorFromJson(Map<String, dynamic> json) =>
    _SlotScoreFactor(
      factorType: json['factorType'] as String,
      description: json['description'] as String,
      impact: (json['impact'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      iconName: json['iconName'] as String?,
    );

Map<String, dynamic> _$SlotScoreFactorToJson(_SlotScoreFactor instance) =>
    <String, dynamic>{
      'factorType': instance.factorType,
      'description': instance.description,
      'impact': instance.impact,
      'weight': instance.weight,
      'iconName': instance.iconName,
    };

_SlotSuggestion _$SlotSuggestionFromJson(Map<String, dynamic> json) =>
    _SlotSuggestion(
      slot: ScoredSlot.fromJson(json['slot'] as Map<String, dynamic>),
      rank: (json['rank'] as num).toInt(),
      headline: json['headline'] as String,
      reasoning: json['reasoning'] as String,
      comparisonText: json['comparisonText'] as String?,
      alternatives:
          (json['alternatives'] as List<dynamic>?)
              ?.map((e) => ScoredSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$SlotSuggestionToJson(_SlotSuggestion instance) =>
    <String, dynamic>{
      'slot': instance.slot.toJson(),
      'rank': instance.rank,
      'headline': instance.headline,
      'reasoning': instance.reasoning,
      'comparisonText': instance.comparisonText,
      'alternatives': instance.alternatives.map((e) => e.toJson()).toList(),
      'confidence': instance.confidence,
    };

_SlotSuggestionResult _$SlotSuggestionResultFromJson(
  Map<String, dynamic> json,
) => _SlotSuggestionResult(
  clientId: json['clientId'] as String,
  serviceId: json['serviceId'] as String,
  scoredSlots: (json['scoredSlots'] as List<dynamic>)
      .map((e) => ScoredSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  topSuggestions: (json['topSuggestions'] as List<dynamic>)
      .map((e) => SlotSuggestion.fromJson(e as Map<String, dynamic>))
      .toList(),
  slotsToAvoid: (json['slotsToAvoid'] as List<dynamic>)
      .map((e) => ScoredSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  clientBaselineNoshowRate: (json['clientBaselineNoshowRate'] as num)
      .toDouble(),
  averageSlotRisk: (json['averageSlotRisk'] as num).toDouble(),
  bestSlot: json['bestSlot'] == null
      ? null
      : ScoredSlot.fromJson(json['bestSlot'] as Map<String, dynamic>),
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  hasReliableHistory: json['hasReliableHistory'] as bool,
  insufficientHistoryMessage: json['insufficientHistoryMessage'] as String?,
);

Map<String, dynamic> _$SlotSuggestionResultToJson(
  _SlotSuggestionResult instance,
) => <String, dynamic>{
  'clientId': instance.clientId,
  'serviceId': instance.serviceId,
  'scoredSlots': instance.scoredSlots.map((e) => e.toJson()).toList(),
  'topSuggestions': instance.topSuggestions.map((e) => e.toJson()).toList(),
  'slotsToAvoid': instance.slotsToAvoid.map((e) => e.toJson()).toList(),
  'clientBaselineNoshowRate': instance.clientBaselineNoshowRate,
  'averageSlotRisk': instance.averageSlotRisk,
  'bestSlot': instance.bestSlot?.toJson(),
  'generatedAt': instance.generatedAt.toIso8601String(),
  'hasReliableHistory': instance.hasReliableHistory,
  'insufficientHistoryMessage': instance.insufficientHistoryMessage,
};

_SlotSuggestionRequest _$SlotSuggestionRequestFromJson(
  Map<String, dynamic> json,
) => _SlotSuggestionRequest(
  clientId: json['clientId'] as String,
  serviceId: json['serviceId'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  providerId: json['providerId'] as String?,
  locationId: json['locationId'] as String?,
  maxSuggestions: (json['maxSuggestions'] as num?)?.toInt() ?? 10,
  includeHighRisk: json['includeHighRisk'] as bool? ?? true,
);

Map<String, dynamic> _$SlotSuggestionRequestToJson(
  _SlotSuggestionRequest instance,
) => <String, dynamic>{
  'clientId': instance.clientId,
  'serviceId': instance.serviceId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'providerId': instance.providerId,
  'locationId': instance.locationId,
  'maxSuggestions': instance.maxSuggestions,
  'includeHighRisk': instance.includeHighRisk,
};
