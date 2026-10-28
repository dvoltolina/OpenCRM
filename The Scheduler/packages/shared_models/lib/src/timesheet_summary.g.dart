// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimesheetSummaryImpl _$$TimesheetSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$TimesheetSummaryImpl(
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalWorkedMinutes: (json['totalWorkedMinutes'] as num).toInt(),
      totalBreakMinutes: (json['totalBreakMinutes'] as num).toInt(),
      totalShifts: (json['totalShifts'] as num).toInt(),
      regularMinutes: (json['regularMinutes'] as num).toInt(),
      overtimeMinutes: (json['overtimeMinutes'] as num).toInt(),
      estimatedPayAmount: (json['estimatedPayAmount'] as num).toDouble(),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$TimesheetStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$$TimesheetSummaryImplToJson(
        _$TimesheetSummaryImpl instance) =>
    <String, dynamic>{
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'totalWorkedMinutes': instance.totalWorkedMinutes,
      'totalBreakMinutes': instance.totalBreakMinutes,
      'totalShifts': instance.totalShifts,
      'regularMinutes': instance.regularMinutes,
      'overtimeMinutes': instance.overtimeMinutes,
      'estimatedPayAmount': instance.estimatedPayAmount,
      'entries': instance.entries,
      'status': _$TimesheetStatusEnumMap[instance.status]!,
    };

const _$TimesheetStatusEnumMap = {
  TimesheetStatus.draft: 'draft',
  TimesheetStatus.submitted: 'submitted',
  TimesheetStatus.approved: 'approved',
  TimesheetStatus.processed: 'processed',
};
