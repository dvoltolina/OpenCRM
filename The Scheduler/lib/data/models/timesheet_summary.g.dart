// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimesheetSummary _$TimesheetSummaryFromJson(Map<String, dynamic> json) =>
    _TimesheetSummary(
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String,
      staffEmail: json['staffEmail'] as String?,
      staffAvatarUrl: json['staffAvatarUrl'] as String?,
      periodStart: const TimestampConverter().fromJson(json['periodStart']),
      periodEnd: const TimestampConverter().fromJson(json['periodEnd']),
      totalWorkedMinutes: (json['totalWorkedMinutes'] as num).toInt(),
      totalBreakMinutes: (json['totalBreakMinutes'] as num).toInt(),
      totalShifts: (json['totalShifts'] as num).toInt(),
      regularMinutes: (json['regularMinutes'] as num).toInt(),
      overtimeMinutes: (json['overtimeMinutes'] as num).toInt(),
      hourlyRateCents: (json['hourlyRateCents'] as num?)?.toInt(),
      estimatedPayAmount: (json['estimatedPayAmount'] as num).toDouble(),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$TimesheetStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$TimesheetSummaryToJson(_TimesheetSummary instance) =>
    <String, dynamic>{
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'staffEmail': instance.staffEmail,
      'staffAvatarUrl': instance.staffAvatarUrl,
      'periodStart': const TimestampConverter().toJson(instance.periodStart),
      'periodEnd': const TimestampConverter().toJson(instance.periodEnd),
      'totalWorkedMinutes': instance.totalWorkedMinutes,
      'totalBreakMinutes': instance.totalBreakMinutes,
      'totalShifts': instance.totalShifts,
      'regularMinutes': instance.regularMinutes,
      'overtimeMinutes': instance.overtimeMinutes,
      'hourlyRateCents': instance.hourlyRateCents,
      'estimatedPayAmount': instance.estimatedPayAmount,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'status': _$TimesheetStatusEnumMap[instance.status]!,
    };

const _$TimesheetStatusEnumMap = {
  TimesheetStatus.draft: 'draft',
  TimesheetStatus.submitted: 'submitted',
  TimesheetStatus.approved: 'approved',
  TimesheetStatus.processed: 'processed',
};
