// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_risk_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecommendedClientAction _$RecommendedClientActionFromJson(
  Map<String, dynamic> json,
) => _RecommendedClientAction(
  actionId: json['actionId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  priority: $enumDecode(_$ClientActionPriorityEnumMap, json['priority']),
  reasoning: json['reasoning'] as String,
  automatable: json['automatable'] as bool,
  automationRuleId: json['automationRuleId'] as String?,
);

Map<String, dynamic> _$RecommendedClientActionToJson(
  _RecommendedClientAction instance,
) => <String, dynamic>{
  'actionId': instance.actionId,
  'title': instance.title,
  'description': instance.description,
  'priority': _$ClientActionPriorityEnumMap[instance.priority]!,
  'reasoning': instance.reasoning,
  'automatable': instance.automatable,
  'automationRuleId': instance.automationRuleId,
};

const _$ClientActionPriorityEnumMap = {
  ClientActionPriority.critical: 'critical',
  ClientActionPriority.high: 'high',
  ClientActionPriority.medium: 'medium',
  ClientActionPriority.low: 'low',
};

_ClientRiskScore _$ClientRiskScoreFromJson(Map<String, dynamic> json) =>
    _ClientRiskScore(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      businessId: json['businessId'] as String,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      churnRiskScore: (json['churnRiskScore'] as num).toInt(),
      satisfactionScore: (json['satisfactionScore'] as num).toInt(),
      vipScore: (json['vipScore'] as num).toInt(),
      overallHealthScore: (json['overallHealthScore'] as num).toInt(),
      churnTrend: $enumDecode(_$ScoreTrendEnumMap, json['churnTrend']),
      satisfactionTrend: $enumDecode(
        _$ScoreTrendEnumMap,
        json['satisfactionTrend'],
      ),
      vipTrend: $enumDecode(_$ScoreTrendEnumMap, json['vipTrend']),
      churnScoreChange: (json['churnScoreChange'] as num?)?.toInt() ?? 0,
      satisfactionScoreChange:
          (json['satisfactionScoreChange'] as num?)?.toInt() ?? 0,
      riskIndicators: (json['riskIndicators'] as List<dynamic>)
          .map((e) => RiskIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      vipIndicators: (json['vipIndicators'] as List<dynamic>)
          .map((e) => RiskIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      topRiskFactors:
          (json['topRiskFactors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      topVipFactors:
          (json['topVipFactors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      textsAnalyzed: (json['textsAnalyzed'] as num).toInt(),
      analysisStartDate: DateTime.parse(json['analysisStartDate'] as String),
      analysisEndDate: DateTime.parse(json['analysisEndDate'] as String),
      averageSentiment: (json['averageSentiment'] as num).toDouble(),
      sentimentStdDev: (json['sentimentStdDev'] as num).toDouble(),
      recommendedActions:
          (json['recommendedActions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RecommendedClientAction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      recentNoshowCount: (json['recentNoshowCount'] as num?)?.toInt() ?? 0,
      recentCancellationCount:
          (json['recentCancellationCount'] as num?)?.toInt() ?? 0,
      daysSinceLastVisit: (json['daysSinceLastVisit'] as num?)?.toInt() ?? 0,
      visitFrequencyTrend: $enumDecodeNullable(
        _$ScoreTrendEnumMap,
        json['visitFrequencyTrend'],
      ),
      scoringVersion: json['scoringVersion'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$ClientRiskScoreToJson(_ClientRiskScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'businessId': instance.businessId,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
      'churnRiskScore': instance.churnRiskScore,
      'satisfactionScore': instance.satisfactionScore,
      'vipScore': instance.vipScore,
      'overallHealthScore': instance.overallHealthScore,
      'churnTrend': _$ScoreTrendEnumMap[instance.churnTrend]!,
      'satisfactionTrend': _$ScoreTrendEnumMap[instance.satisfactionTrend]!,
      'vipTrend': _$ScoreTrendEnumMap[instance.vipTrend]!,
      'churnScoreChange': instance.churnScoreChange,
      'satisfactionScoreChange': instance.satisfactionScoreChange,
      'riskIndicators': instance.riskIndicators.map((e) => e.toJson()).toList(),
      'vipIndicators': instance.vipIndicators.map((e) => e.toJson()).toList(),
      'topRiskFactors': instance.topRiskFactors,
      'topVipFactors': instance.topVipFactors,
      'textsAnalyzed': instance.textsAnalyzed,
      'analysisStartDate': instance.analysisStartDate.toIso8601String(),
      'analysisEndDate': instance.analysisEndDate.toIso8601String(),
      'averageSentiment': instance.averageSentiment,
      'sentimentStdDev': instance.sentimentStdDev,
      'recommendedActions': instance.recommendedActions
          .map((e) => e.toJson())
          .toList(),
      'recentNoshowCount': instance.recentNoshowCount,
      'recentCancellationCount': instance.recentCancellationCount,
      'daysSinceLastVisit': instance.daysSinceLastVisit,
      'visitFrequencyTrend': _$ScoreTrendEnumMap[instance.visitFrequencyTrend],
      'scoringVersion': instance.scoringVersion,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

const _$ScoreTrendEnumMap = {
  ScoreTrend.improving: 'improving',
  ScoreTrend.stable: 'stable',
  ScoreTrend.declining: 'declining',
};
