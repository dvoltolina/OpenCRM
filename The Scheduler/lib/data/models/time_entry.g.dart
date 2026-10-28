// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BreakPeriod _$BreakPeriodFromJson(Map<String, dynamic> json) => _BreakPeriod(
  startTime: const _TimestampConverter().fromJson(json['startTime']),
  endTime: const _NullableTimestampConverter().fromJson(json['endTime']),
  type: $enumDecode(_$BreakTypeEnumMap, json['type']),
);

Map<String, dynamic> _$BreakPeriodToJson(_BreakPeriod instance) =>
    <String, dynamic>{
      'startTime': const _TimestampConverter().toJson(instance.startTime),
      'endTime': const _NullableTimestampConverter().toJson(instance.endTime),
      'type': _$BreakTypeEnumMap[instance.type]!,
    };

const _$BreakTypeEnumMap = {BreakType.meal: 'meal', BreakType.rest: 'rest'};

_TimeEntry _$TimeEntryFromJson(Map<String, dynamic> json) => _TimeEntry(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  staffId: json['staffId'] as String,
  clockInTime: const _TimestampConverter().fromJson(json['clockInTime']),
  clockOutTime: const _NullableTimestampConverter().fromJson(
    json['clockOutTime'],
  ),
  clockInLatitude: (json['clockInLatitude'] as num?)?.toDouble(),
  clockInLongitude: (json['clockInLongitude'] as num?)?.toDouble(),
  clockInAddress: json['clockInAddress'] as String?,
  clockOutLatitude: (json['clockOutLatitude'] as num?)?.toDouble(),
  clockOutLongitude: (json['clockOutLongitude'] as num?)?.toDouble(),
  clockOutAddress: json['clockOutAddress'] as String?,
  clockInLocationId: json['clockInLocationId'] as String?,
  clockOutLocationId: json['clockOutLocationId'] as String?,
  clockInOutsideGeofence: json['clockInOutsideGeofence'] as bool? ?? false,
  clockOutOutsideGeofence: json['clockOutOutsideGeofence'] as bool? ?? false,
  breaks:
      (json['breaks'] as List<dynamic>?)
          ?.map((e) => BreakPeriod.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalMinutes: (json['totalMinutes'] as num?)?.toInt(),
  breakMinutes: (json['breakMinutes'] as num?)?.toInt(),
  workedMinutes: (json['workedMinutes'] as num?)?.toInt(),
  status: $enumDecode(_$TimeEntryStatusEnumMap, json['status']),
  approvedByUserId: json['approvedByUserId'] as String?,
  approvedAt: const _NullableTimestampConverter().fromJson(json['approvedAt']),
  rejectionReason: json['rejectionReason'] as String?,
  staffNotes: json['staffNotes'] as String?,
  managerNotes: json['managerNotes'] as String?,
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const _TimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$TimeEntryToJson(
  _TimeEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'staffId': instance.staffId,
  'clockInTime': const _TimestampConverter().toJson(instance.clockInTime),
  'clockOutTime': const _NullableTimestampConverter().toJson(
    instance.clockOutTime,
  ),
  'clockInLatitude': instance.clockInLatitude,
  'clockInLongitude': instance.clockInLongitude,
  'clockInAddress': instance.clockInAddress,
  'clockOutLatitude': instance.clockOutLatitude,
  'clockOutLongitude': instance.clockOutLongitude,
  'clockOutAddress': instance.clockOutAddress,
  'clockInLocationId': instance.clockInLocationId,
  'clockOutLocationId': instance.clockOutLocationId,
  'clockInOutsideGeofence': instance.clockInOutsideGeofence,
  'clockOutOutsideGeofence': instance.clockOutOutsideGeofence,
  'breaks': instance.breaks.map((e) => e.toJson()).toList(),
  'totalMinutes': instance.totalMinutes,
  'breakMinutes': instance.breakMinutes,
  'workedMinutes': instance.workedMinutes,
  'status': _$TimeEntryStatusEnumMap[instance.status]!,
  'approvedByUserId': instance.approvedByUserId,
  'approvedAt': const _NullableTimestampConverter().toJson(instance.approvedAt),
  'rejectionReason': instance.rejectionReason,
  'staffNotes': instance.staffNotes,
  'managerNotes': instance.managerNotes,
  'createdAt': const _TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const _TimestampConverter().toJson(instance.updatedAt),
};

const _$TimeEntryStatusEnumMap = {
  TimeEntryStatus.active: 'active',
  TimeEntryStatus.pending: 'pending',
  TimeEntryStatus.approved: 'approved',
  TimeEntryStatus.rejected: 'rejected',
};
