// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BreakPeriodImpl _$$BreakPeriodImplFromJson(Map<String, dynamic> json) =>
    _$BreakPeriodImpl(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      type: $enumDecode(_$BreakTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$$BreakPeriodImplToJson(_$BreakPeriodImpl instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'type': _$BreakTypeEnumMap[instance.type]!,
    };

const _$BreakTypeEnumMap = {
  BreakType.meal: 'meal',
  BreakType.rest: 'rest',
};

_$TimeEntryImpl _$$TimeEntryImplFromJson(Map<String, dynamic> json) =>
    _$TimeEntryImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      staffId: json['staffId'] as String,
      clockInTime: DateTime.parse(json['clockInTime'] as String),
      clockOutTime: json['clockOutTime'] == null
          ? null
          : DateTime.parse(json['clockOutTime'] as String),
      clockInLatitude: (json['clockInLatitude'] as num?)?.toDouble(),
      clockInLongitude: (json['clockInLongitude'] as num?)?.toDouble(),
      clockInAddress: json['clockInAddress'] as String?,
      clockOutLatitude: (json['clockOutLatitude'] as num?)?.toDouble(),
      clockOutLongitude: (json['clockOutLongitude'] as num?)?.toDouble(),
      clockOutAddress: json['clockOutAddress'] as String?,
      clockInLocationId: json['clockInLocationId'] as String?,
      clockOutLocationId: json['clockOutLocationId'] as String?,
      clockInOutsideGeofence: json['clockInOutsideGeofence'] as bool? ?? false,
      clockOutOutsideGeofence:
          json['clockOutOutsideGeofence'] as bool? ?? false,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((e) => BreakPeriod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalMinutes: (json['totalMinutes'] as num?)?.toInt(),
      breakMinutes: (json['breakMinutes'] as num?)?.toInt(),
      workedMinutes: (json['workedMinutes'] as num?)?.toInt(),
      status: $enumDecode(_$TimeEntryStatusEnumMap, json['status']),
      approvedByUserId: json['approvedByUserId'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      staffNotes: json['staffNotes'] as String?,
      managerNotes: json['managerNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TimeEntryImplToJson(_$TimeEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'staffId': instance.staffId,
      'clockInTime': instance.clockInTime.toIso8601String(),
      'clockOutTime': instance.clockOutTime?.toIso8601String(),
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
      'breaks': instance.breaks,
      'totalMinutes': instance.totalMinutes,
      'breakMinutes': instance.breakMinutes,
      'workedMinutes': instance.workedMinutes,
      'status': _$TimeEntryStatusEnumMap[instance.status]!,
      'approvedByUserId': instance.approvedByUserId,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'rejectionReason': instance.rejectionReason,
      'staffNotes': instance.staffNotes,
      'managerNotes': instance.managerNotes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$TimeEntryStatusEnumMap = {
  TimeEntryStatus.active: 'active',
  TimeEntryStatus.pending: 'pending',
  TimeEntryStatus.approved: 'approved',
  TimeEntryStatus.rejected: 'rejected',
};
