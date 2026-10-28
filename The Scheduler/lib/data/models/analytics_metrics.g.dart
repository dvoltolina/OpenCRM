// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyticsMetrics _$AnalyticsMetricsFromJson(
  Map<String, dynamic> json,
) => _AnalyticsMetrics(
  businessId: json['businessId'] as String,
  startDate: const TimestampConverter().fromJson(json['startDate']),
  endDate: const TimestampConverter().fromJson(json['endDate']),
  totalAppointments: (json['totalAppointments'] as num).toInt(),
  confirmedAppointments: (json['confirmedAppointments'] as num).toInt(),
  canceledAppointments: (json['canceledAppointments'] as num).toInt(),
  completedAppointments: (json['completedAppointments'] as num).toInt(),
  pendingAppointments: (json['pendingAppointments'] as num).toInt(),
  noShowAppointments: (json['noShowAppointments'] as num).toInt(),
  totalRevenueCents: (json['totalRevenueCents'] as num).toInt(),
  paidRevenueCents: (json['paidRevenueCents'] as num).toInt(),
  pendingRevenueCents: (json['pendingRevenueCents'] as num).toInt(),
  refundedRevenueCents: (json['refundedRevenueCents'] as num).toInt(),
  totalClients: (json['totalClients'] as num).toInt(),
  newClients: (json['newClients'] as num).toInt(),
  returningClients: (json['returningClients'] as num).toInt(),
  activeClients: (json['activeClients'] as num).toInt(),
  inactiveClients: (json['inactiveClients'] as num).toInt(),
  appointmentsByProvider: Map<String, int>.from(
    json['appointmentsByProvider'] as Map,
  ),
  revenueByProvider: Map<String, int>.from(json['revenueByProvider'] as Map),
  appointmentsByService: Map<String, int>.from(
    json['appointmentsByService'] as Map,
  ),
  revenueByService: Map<String, int>.from(json['revenueByService'] as Map),
  appointmentsByDayOfWeek: Map<String, int>.from(
    json['appointmentsByDayOfWeek'] as Map,
  ),
  appointmentsByHourOfDay:
      (json['appointmentsByHourOfDay'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
  appointmentsByDate: Map<String, int>.from(json['appointmentsByDate'] as Map),
  averageBookingLeadDays: (json['averageBookingLeadDays'] as num).toDouble(),
  cancellationRate: (json['cancellationRate'] as num).toDouble(),
  noShowRate: (json['noShowRate'] as num).toDouble(),
  utilizationRate: (json['utilizationRate'] as num).toDouble(),
  totalGroupSessions: (json['totalGroupSessions'] as num?)?.toInt() ?? 0,
  totalGroupSessionAttendees:
      (json['totalGroupSessionAttendees'] as num?)?.toInt() ?? 0,
  totalGroupSessionCapacity:
      (json['totalGroupSessionCapacity'] as num?)?.toInt() ?? 0,
  groupSessionUtilizationRate:
      (json['groupSessionUtilizationRate'] as num?)?.toDouble() ?? 0.0,
  groupSessionsByService:
      (json['groupSessionsByService'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  attendeesByGroupSession:
      (json['attendeesByGroupSession'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
);

Map<String, dynamic> _$AnalyticsMetricsToJson(_AnalyticsMetrics instance) =>
    <String, dynamic>{
      'businessId': instance.businessId,
      'startDate': const TimestampConverter().toJson(instance.startDate),
      'endDate': const TimestampConverter().toJson(instance.endDate),
      'totalAppointments': instance.totalAppointments,
      'confirmedAppointments': instance.confirmedAppointments,
      'canceledAppointments': instance.canceledAppointments,
      'completedAppointments': instance.completedAppointments,
      'pendingAppointments': instance.pendingAppointments,
      'noShowAppointments': instance.noShowAppointments,
      'totalRevenueCents': instance.totalRevenueCents,
      'paidRevenueCents': instance.paidRevenueCents,
      'pendingRevenueCents': instance.pendingRevenueCents,
      'refundedRevenueCents': instance.refundedRevenueCents,
      'totalClients': instance.totalClients,
      'newClients': instance.newClients,
      'returningClients': instance.returningClients,
      'activeClients': instance.activeClients,
      'inactiveClients': instance.inactiveClients,
      'appointmentsByProvider': instance.appointmentsByProvider,
      'revenueByProvider': instance.revenueByProvider,
      'appointmentsByService': instance.appointmentsByService,
      'revenueByService': instance.revenueByService,
      'appointmentsByDayOfWeek': instance.appointmentsByDayOfWeek,
      'appointmentsByHourOfDay': instance.appointmentsByHourOfDay.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'appointmentsByDate': instance.appointmentsByDate,
      'averageBookingLeadDays': instance.averageBookingLeadDays,
      'cancellationRate': instance.cancellationRate,
      'noShowRate': instance.noShowRate,
      'utilizationRate': instance.utilizationRate,
      'totalGroupSessions': instance.totalGroupSessions,
      'totalGroupSessionAttendees': instance.totalGroupSessionAttendees,
      'totalGroupSessionCapacity': instance.totalGroupSessionCapacity,
      'groupSessionUtilizationRate': instance.groupSessionUtilizationRate,
      'groupSessionsByService': instance.groupSessionsByService,
      'attendeesByGroupSession': instance.attendeesByGroupSession,
    };

_DateRangeFilter _$DateRangeFilterFromJson(Map<String, dynamic> json) =>
    _DateRangeFilter(
      startDate: const TimestampConverter().fromJson(json['startDate']),
      endDate: const TimestampConverter().fromJson(json['endDate']),
      period: $enumDecode(_$DateRangePeriodEnumMap, json['period']),
    );

Map<String, dynamic> _$DateRangeFilterToJson(_DateRangeFilter instance) =>
    <String, dynamic>{
      'startDate': const TimestampConverter().toJson(instance.startDate),
      'endDate': const TimestampConverter().toJson(instance.endDate),
      'period': _$DateRangePeriodEnumMap[instance.period]!,
    };

const _$DateRangePeriodEnumMap = {
  DateRangePeriod.today: 'today',
  DateRangePeriod.yesterday: 'yesterday',
  DateRangePeriod.last7Days: 'last7Days',
  DateRangePeriod.last30Days: 'last30Days',
  DateRangePeriod.thisMonth: 'thisMonth',
  DateRangePeriod.lastMonth: 'lastMonth',
  DateRangePeriod.thisQuarter: 'thisQuarter',
  DateRangePeriod.lastQuarter: 'lastQuarter',
  DateRangePeriod.thisYear: 'thisYear',
  DateRangePeriod.lastYear: 'lastYear',
  DateRangePeriod.custom: 'custom',
};
