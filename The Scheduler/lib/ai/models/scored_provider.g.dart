// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scored_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoredProvider _$ScoredProviderFromJson(Map<String, dynamic> json) =>
    _ScoredProvider(
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      matchScore: (json['matchScore'] as num).toDouble(),
      noshowRateWithClient: (json['noshowRateWithClient'] as num).toDouble(),
      completedAppointments: (json['completedAppointments'] as num).toInt(),
      noshowCount: (json['noshowCount'] as num).toInt(),
      cancellationCount: (json['cancellationCount'] as num).toInt(),
      isRecommended: json['isRecommended'] as bool,
      matchQuality: $enumDecode(
        _$ProviderMatchQualityEnumMap,
        json['matchQuality'],
      ),
      matchFactors: (json['matchFactors'] as List<dynamic>)
          .map((e) => ProviderMatchFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendationText: json['recommendationText'] as String?,
      providerOverallNoshowRate: (json['providerOverallNoshowRate'] as num?)
          ?.toDouble(),
      clientVsAveragePercent: (json['clientVsAveragePercent'] as num?)
          ?.toDouble(),
      lastAppointmentDate: json['lastAppointmentDate'] == null
          ? null
          : DateTime.parse(json['lastAppointmentDate'] as String),
      specialties:
          (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isAcceptingAppointments: json['isAcceptingAppointments'] as bool? ?? true,
    );

Map<String, dynamic> _$ScoredProviderToJson(_ScoredProvider instance) =>
    <String, dynamic>{
      'providerId': instance.providerId,
      'providerName': instance.providerName,
      'profileImageUrl': instance.profileImageUrl,
      'matchScore': instance.matchScore,
      'noshowRateWithClient': instance.noshowRateWithClient,
      'completedAppointments': instance.completedAppointments,
      'noshowCount': instance.noshowCount,
      'cancellationCount': instance.cancellationCount,
      'isRecommended': instance.isRecommended,
      'matchQuality': _$ProviderMatchQualityEnumMap[instance.matchQuality]!,
      'matchFactors': instance.matchFactors.map((e) => e.toJson()).toList(),
      'recommendationText': instance.recommendationText,
      'providerOverallNoshowRate': instance.providerOverallNoshowRate,
      'clientVsAveragePercent': instance.clientVsAveragePercent,
      'lastAppointmentDate': instance.lastAppointmentDate?.toIso8601String(),
      'specialties': instance.specialties,
      'isAcceptingAppointments': instance.isAcceptingAppointments,
    };

const _$ProviderMatchQualityEnumMap = {
  ProviderMatchQuality.excellent: 'excellent',
  ProviderMatchQuality.good: 'good',
  ProviderMatchQuality.fair: 'fair',
  ProviderMatchQuality.poor: 'poor',
  ProviderMatchQuality.unknown: 'unknown',
};

_ProviderMatchFactor _$ProviderMatchFactorFromJson(Map<String, dynamic> json) =>
    _ProviderMatchFactor(
      factorType: $enumDecode(_$ProviderFactorTypeEnumMap, json['factorType']),
      description: json['description'] as String,
      impact: (json['impact'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      iconName: json['iconName'] as String?,
    );

Map<String, dynamic> _$ProviderMatchFactorToJson(
  _ProviderMatchFactor instance,
) => <String, dynamic>{
  'factorType': _$ProviderFactorTypeEnumMap[instance.factorType]!,
  'description': instance.description,
  'impact': instance.impact,
  'weight': instance.weight,
  'iconName': instance.iconName,
};

const _$ProviderFactorTypeEnumMap = {
  ProviderFactorType.clientNoshowHistory: 'clientNoshowHistory',
  ProviderFactorType.appointmentHistory: 'appointmentHistory',
  ProviderFactorType.providerOverallRate: 'providerOverallRate',
  ProviderFactorType.recency: 'recency',
  ProviderFactorType.clientPreference: 'clientPreference',
  ProviderFactorType.specialtyMatch: 'specialtyMatch',
  ProviderFactorType.availability: 'availability',
};

_ProviderMatchResult _$ProviderMatchResultFromJson(Map<String, dynamic> json) =>
    _ProviderMatchResult(
      clientId: json['clientId'] as String,
      serviceId: json['serviceId'] as String,
      scoredProviders: (json['scoredProviders'] as List<dynamic>)
          .map((e) => ScoredProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedProviders: (json['recommendedProviders'] as List<dynamic>)
          .map((e) => ScoredProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestMatch: json['bestMatch'] == null
          ? null
          : ScoredProvider.fromJson(json['bestMatch'] as Map<String, dynamic>),
      preferredProvider: json['preferredProvider'] == null
          ? null
          : ScoredProvider.fromJson(
              json['preferredProvider'] as Map<String, dynamic>,
            ),
      hasProviderHistory: json['hasProviderHistory'] as bool,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      noHistoryMessage: json['noHistoryMessage'] as String?,
    );

Map<String, dynamic> _$ProviderMatchResultToJson(
  _ProviderMatchResult instance,
) => <String, dynamic>{
  'clientId': instance.clientId,
  'serviceId': instance.serviceId,
  'scoredProviders': instance.scoredProviders.map((e) => e.toJson()).toList(),
  'recommendedProviders': instance.recommendedProviders
      .map((e) => e.toJson())
      .toList(),
  'bestMatch': instance.bestMatch?.toJson(),
  'preferredProvider': instance.preferredProvider?.toJson(),
  'hasProviderHistory': instance.hasProviderHistory,
  'generatedAt': instance.generatedAt.toIso8601String(),
  'noHistoryMessage': instance.noHistoryMessage,
};

_ProviderMatchRequest _$ProviderMatchRequestFromJson(
  Map<String, dynamic> json,
) => _ProviderMatchRequest(
  clientId: json['clientId'] as String,
  serviceId: json['serviceId'] as String,
  locationId: json['locationId'] as String?,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  maxResults: (json['maxResults'] as num?)?.toInt() ?? 10,
  minAppointmentsForReliability:
      (json['minAppointmentsForReliability'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$ProviderMatchRequestToJson(
  _ProviderMatchRequest instance,
) => <String, dynamic>{
  'clientId': instance.clientId,
  'serviceId': instance.serviceId,
  'locationId': instance.locationId,
  'date': instance.date?.toIso8601String(),
  'maxResults': instance.maxResults,
  'minAppointmentsForReliability': instance.minAppointmentsForReliability,
};
