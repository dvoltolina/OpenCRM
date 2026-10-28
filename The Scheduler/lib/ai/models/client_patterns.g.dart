// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_patterns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientPatterns _$ClientPatternsFromJson(
  Map<String, dynamic> json,
) => _ClientPatterns(
  clientId: json['clientId'] as String,
  businessId: json['businessId'] as String,
  dayOfWeekNoshowRates: (json['dayOfWeekNoshowRates'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(int.parse(k), (e as num).toDouble())),
  hourOfDayNoshowRates: (json['hourOfDayNoshowRates'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(int.parse(k), (e as num).toDouble())),
  providerNoshowRates: (json['providerNoshowRates'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(k, (e as num).toDouble())),
  providerCompletedCounts: Map<String, int>.from(
    json['providerCompletedCounts'] as Map,
  ),
  leadTimeNoshowRates: (json['leadTimeNoshowRates'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(k, (e as num).toDouble())),
  totalAppointments: (json['totalAppointments'] as num).toInt(),
  totalNoshows: (json['totalNoshows'] as num).toInt(),
  totalCancellations: (json['totalCancellations'] as num).toInt(),
  overallNoshowRate: (json['overallNoshowRate'] as num).toDouble(),
  preferredDaysOfWeek:
      (json['preferredDaysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  preferredHours:
      (json['preferredHours'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  preferredProviders:
      (json['preferredProviders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  calculatedAt: DateTime.parse(json['calculatedAt'] as String),
  sampleSize: (json['sampleSize'] as num).toInt(),
);

Map<String, dynamic> _$ClientPatternsToJson(_ClientPatterns instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'businessId': instance.businessId,
      'dayOfWeekNoshowRates': instance.dayOfWeekNoshowRates.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'hourOfDayNoshowRates': instance.hourOfDayNoshowRates.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'providerNoshowRates': instance.providerNoshowRates,
      'providerCompletedCounts': instance.providerCompletedCounts,
      'leadTimeNoshowRates': instance.leadTimeNoshowRates,
      'totalAppointments': instance.totalAppointments,
      'totalNoshows': instance.totalNoshows,
      'totalCancellations': instance.totalCancellations,
      'overallNoshowRate': instance.overallNoshowRate,
      'preferredDaysOfWeek': instance.preferredDaysOfWeek,
      'preferredHours': instance.preferredHours,
      'preferredProviders': instance.preferredProviders,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
      'sampleSize': instance.sampleSize,
    };

_DayOfWeekStats _$DayOfWeekStatsFromJson(Map<String, dynamic> json) =>
    _DayOfWeekStats(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      dayName: json['dayName'] as String,
      appointmentCount: (json['appointmentCount'] as num).toInt(),
      noshowCount: (json['noshowCount'] as num).toInt(),
      noshowRate: (json['noshowRate'] as num).toDouble(),
      isPreferred: json['isPreferred'] as bool,
    );

Map<String, dynamic> _$DayOfWeekStatsToJson(_DayOfWeekStats instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'dayName': instance.dayName,
      'appointmentCount': instance.appointmentCount,
      'noshowCount': instance.noshowCount,
      'noshowRate': instance.noshowRate,
      'isPreferred': instance.isPreferred,
    };

_HourOfDayStats _$HourOfDayStatsFromJson(Map<String, dynamic> json) =>
    _HourOfDayStats(
      hour: (json['hour'] as num).toInt(),
      timeLabel: json['timeLabel'] as String,
      appointmentCount: (json['appointmentCount'] as num).toInt(),
      noshowCount: (json['noshowCount'] as num).toInt(),
      noshowRate: (json['noshowRate'] as num).toDouble(),
      isPreferred: json['isPreferred'] as bool,
    );

Map<String, dynamic> _$HourOfDayStatsToJson(_HourOfDayStats instance) =>
    <String, dynamic>{
      'hour': instance.hour,
      'timeLabel': instance.timeLabel,
      'appointmentCount': instance.appointmentCount,
      'noshowCount': instance.noshowCount,
      'noshowRate': instance.noshowRate,
      'isPreferred': instance.isPreferred,
    };

_ProviderClientHistory _$ProviderClientHistoryFromJson(
  Map<String, dynamic> json,
) => _ProviderClientHistory(
  providerId: json['providerId'] as String,
  providerName: json['providerName'] as String,
  completedAppointments: (json['completedAppointments'] as num).toInt(),
  noshowCount: (json['noshowCount'] as num).toInt(),
  cancellationCount: (json['cancellationCount'] as num).toInt(),
  noshowRate: (json['noshowRate'] as num).toDouble(),
  satisfactionScore: (json['satisfactionScore'] as num).toDouble(),
  lastAppointment: json['lastAppointment'] == null
      ? null
      : DateTime.parse(json['lastAppointment'] as String),
);

Map<String, dynamic> _$ProviderClientHistoryToJson(
  _ProviderClientHistory instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'providerName': instance.providerName,
  'completedAppointments': instance.completedAppointments,
  'noshowCount': instance.noshowCount,
  'cancellationCount': instance.cancellationCount,
  'noshowRate': instance.noshowRate,
  'satisfactionScore': instance.satisfactionScore,
  'lastAppointment': instance.lastAppointment?.toIso8601String(),
};
