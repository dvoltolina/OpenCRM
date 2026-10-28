// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demand_forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DemandForecast _$DemandForecastFromJson(Map<String, dynamic> json) =>
    _DemandForecast(
      date: DateTime.parse(json['date'] as String),
      predictedCount: (json['predictedCount'] as num).toDouble(),
      lowerBound: (json['lowerBound'] as num).toDouble(),
      upperBound: (json['upperBound'] as num).toDouble(),
      demandLevel: $enumDecode(_$DemandLevelEnumMap, json['demandLevel']),
      confidence: (json['confidence'] as num).toDouble(),
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      isHoliday: json['isHoliday'] as bool? ?? false,
      holidayName: json['holidayName'] as String?,
      yearOverYearChange: (json['yearOverYearChange'] as num?)?.toDouble(),
      weekOverWeekChange: (json['weekOverWeekChange'] as num?)?.toDouble(),
      serviceBreakdown:
          (json['serviceBreakdown'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      hourlyBreakdown:
          (json['hourlyBreakdown'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
    );

Map<String, dynamic> _$DemandForecastToJson(_DemandForecast instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'predictedCount': instance.predictedCount,
      'lowerBound': instance.lowerBound,
      'upperBound': instance.upperBound,
      'demandLevel': _$DemandLevelEnumMap[instance.demandLevel]!,
      'confidence': instance.confidence,
      'dayOfWeek': instance.dayOfWeek,
      'isHoliday': instance.isHoliday,
      'holidayName': instance.holidayName,
      'yearOverYearChange': instance.yearOverYearChange,
      'weekOverWeekChange': instance.weekOverWeekChange,
      'serviceBreakdown': instance.serviceBreakdown,
      'hourlyBreakdown': instance.hourlyBreakdown,
    };

const _$DemandLevelEnumMap = {
  DemandLevel.veryLow: 'veryLow',
  DemandLevel.low: 'low',
  DemandLevel.normal: 'normal',
  DemandLevel.high: 'high',
  DemandLevel.veryHigh: 'veryHigh',
};

_StaffingRecommendation _$StaffingRecommendationFromJson(
  Map<String, dynamic> json,
) => _StaffingRecommendation(
  date: DateTime.parse(json['date'] as String),
  forecast: DemandForecast.fromJson(json['forecast'] as Map<String, dynamic>),
  currentCapacity: (json['currentCapacity'] as num).toInt(),
  recommendedCapacity: (json['recommendedCapacity'] as num).toInt(),
  action: $enumDecode(_$StaffingActionEnumMap, json['action']),
  urgency: (json['urgency'] as num).toInt(),
  reasoning: json['reasoning'] as String,
  suggestions:
      (json['suggestions'] as List<dynamic>?)
          ?.map((e) => StaffingSuggestion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  revenueImpact: (json['revenueImpact'] as num?)?.toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$StaffingRecommendationToJson(
  _StaffingRecommendation instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'forecast': instance.forecast.toJson(),
  'currentCapacity': instance.currentCapacity,
  'recommendedCapacity': instance.recommendedCapacity,
  'action': _$StaffingActionEnumMap[instance.action]!,
  'urgency': instance.urgency,
  'reasoning': instance.reasoning,
  'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
  'revenueImpact': instance.revenueImpact,
  'confidence': instance.confidence,
};

const _$StaffingActionEnumMap = {
  StaffingAction.addStaff: 'addStaff',
  StaffingAction.runPromotion: 'runPromotion',
  StaffingAction.optimal: 'optimal',
  StaffingAction.reduceStaff: 'reduceStaff',
  StaffingAction.reduceHours: 'reduceHours',
};

_StaffingSuggestion _$StaffingSuggestionFromJson(Map<String, dynamic> json) =>
    _StaffingSuggestion(
      type: json['type'] as String,
      description: json['description'] as String,
      priority: (json['priority'] as num).toInt(),
      impact: json['impact'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );

Map<String, dynamic> _$StaffingSuggestionToJson(_StaffingSuggestion instance) =>
    <String, dynamic>{
      'type': instance.type,
      'description': instance.description,
      'priority': instance.priority,
      'impact': instance.impact,
      'actionUrl': instance.actionUrl,
    };

_DemandForecastResult _$DemandForecastResultFromJson(
  Map<String, dynamic> json,
) => _DemandForecastResult(
  businessId: json['businessId'] as String,
  locationId: json['locationId'] as String?,
  serviceId: json['serviceId'] as String?,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  forecasts: (json['forecasts'] as List<dynamic>)
      .map((e) => DemandForecast.fromJson(e as Map<String, dynamic>))
      .toList(),
  staffingRecommendations:
      (json['staffingRecommendations'] as List<dynamic>?)
          ?.map(
            (e) => StaffingRecommendation.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  modelVersion: json['modelVersion'] as String?,
  averageDemand: (json['averageDemand'] as num).toDouble(),
  peakDay: json['peakDay'] == null
      ? null
      : DemandForecast.fromJson(json['peakDay'] as Map<String, dynamic>),
  valleyDay: json['valleyDay'] == null
      ? null
      : DemandForecast.fromJson(json['valleyDay'] as Map<String, dynamic>),
  highDemandDays:
      (json['highDemandDays'] as List<dynamic>?)
          ?.map((e) => DemandForecast.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  urgentDays:
      (json['urgentDays'] as List<dynamic>?)
          ?.map(
            (e) => StaffingRecommendation.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$DemandForecastResultToJson(
  _DemandForecastResult instance,
) => <String, dynamic>{
  'businessId': instance.businessId,
  'locationId': instance.locationId,
  'serviceId': instance.serviceId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'forecasts': instance.forecasts.map((e) => e.toJson()).toList(),
  'staffingRecommendations': instance.staffingRecommendations
      .map((e) => e.toJson())
      .toList(),
  'generatedAt': instance.generatedAt.toIso8601String(),
  'modelVersion': instance.modelVersion,
  'averageDemand': instance.averageDemand,
  'peakDay': instance.peakDay?.toJson(),
  'valleyDay': instance.valleyDay?.toJson(),
  'highDemandDays': instance.highDemandDays.map((e) => e.toJson()).toList(),
  'urgentDays': instance.urgentDays.map((e) => e.toJson()).toList(),
};

_DemandForecastRequest _$DemandForecastRequestFromJson(
  Map<String, dynamic> json,
) => _DemandForecastRequest(
  businessId: json['businessId'] as String,
  locationId: json['locationId'] as String?,
  serviceId: json['serviceId'] as String?,
  startDate: DateTime.parse(json['startDate'] as String),
  forecastDays: (json['forecastDays'] as num?)?.toInt() ?? 30,
  includeStaffing: json['includeStaffing'] as bool? ?? true,
  currentCapacity: (json['currentCapacity'] as num?)?.toInt(),
  includeHourly: json['includeHourly'] as bool? ?? false,
  includeServiceBreakdown: json['includeServiceBreakdown'] as bool? ?? false,
);

Map<String, dynamic> _$DemandForecastRequestToJson(
  _DemandForecastRequest instance,
) => <String, dynamic>{
  'businessId': instance.businessId,
  'locationId': instance.locationId,
  'serviceId': instance.serviceId,
  'startDate': instance.startDate.toIso8601String(),
  'forecastDays': instance.forecastDays,
  'includeStaffing': instance.includeStaffing,
  'currentCapacity': instance.currentCapacity,
  'includeHourly': instance.includeHourly,
  'includeServiceBreakdown': instance.includeServiceBreakdown,
};
