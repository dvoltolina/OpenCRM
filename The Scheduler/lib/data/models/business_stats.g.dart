// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessStats _$BusinessStatsFromJson(
  Map<String, dynamic> json,
) => _BusinessStats(
  appointmentsToday: (json['appointmentsToday'] as num).toInt(),
  appointmentsChange: (json['appointmentsChange'] as num).toInt(),
  revenueTodayCents: (json['revenueTodayCents'] as num).toInt(),
  revenueChangePercent: (json['revenueChangePercent'] as num).toDouble(),
  staffOnDuty: (json['staffOnDuty'] as num).toInt(),
  staffTotal: (json['staffTotal'] as num).toInt(),
  appointmentsCompleted: (json['appointmentsCompleted'] as num?)?.toInt() ?? 0,
  appointmentsCancelled: (json['appointmentsCancelled'] as num?)?.toInt() ?? 0,
  appointmentsNoShow: (json['appointmentsNoShow'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BusinessStatsToJson(_BusinessStats instance) =>
    <String, dynamic>{
      'appointmentsToday': instance.appointmentsToday,
      'appointmentsChange': instance.appointmentsChange,
      'revenueTodayCents': instance.revenueTodayCents,
      'revenueChangePercent': instance.revenueChangePercent,
      'staffOnDuty': instance.staffOnDuty,
      'staffTotal': instance.staffTotal,
      'appointmentsCompleted': instance.appointmentsCompleted,
      'appointmentsCancelled': instance.appointmentsCancelled,
      'appointmentsNoShow': instance.appointmentsNoShow,
    };
