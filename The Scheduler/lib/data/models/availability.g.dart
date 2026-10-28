// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimeBlock _$TimeBlockFromJson(Map<String, dynamic> json) => _TimeBlock(
  startHour: (json['startHour'] as num).toInt(),
  startMinute: (json['startMinute'] as num).toInt(),
  endHour: (json['endHour'] as num).toInt(),
  endMinute: (json['endMinute'] as num).toInt(),
);

Map<String, dynamic> _$TimeBlockToJson(_TimeBlock instance) =>
    <String, dynamic>{
      'startHour': instance.startHour,
      'startMinute': instance.startMinute,
      'endHour': instance.endHour,
      'endMinute': instance.endMinute,
    };

_WeeklySchedule _$WeeklyScheduleFromJson(Map<String, dynamic> json) =>
    _WeeklySchedule(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      locationId: json['locationId'] as String,
      dayOfWeek: $enumDecode(_$DayOfWeekEnumMap, json['dayOfWeek']),
      timeBlocks: (json['timeBlocks'] as List<dynamic>)
          .map((e) => TimeBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$WeeklyScheduleToJson(
  _WeeklySchedule instance,
) => <String, dynamic>{
  'id': instance.id,
  'providerId': instance.providerId,
  'locationId': instance.locationId,
  'dayOfWeek': _$DayOfWeekEnumMap[instance.dayOfWeek]!,
  'timeBlocks': instance.timeBlocks.map((e) => e.toJson()).toList(),
  'isActive': instance.isActive,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$DayOfWeekEnumMap = {
  DayOfWeek.monday: 'monday',
  DayOfWeek.tuesday: 'tuesday',
  DayOfWeek.wednesday: 'wednesday',
  DayOfWeek.thursday: 'thursday',
  DayOfWeek.friday: 'friday',
  DayOfWeek.saturday: 'saturday',
  DayOfWeek.sunday: 'sunday',
};

_Availability _$AvailabilityFromJson(Map<String, dynamic> json) =>
    _Availability(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      locationId: json['locationId'] as String,
      startTime: const TimestampConverter().fromJson(json['startTime']),
      endTime: const TimestampConverter().fromJson(json['endTime']),
      type: $enumDecode(_$AvailabilityTypeEnumMap, json['type']),
      reason: json['reason'] as String?,
      isRecurring: json['isRecurring'] as bool?,
      specificDate: const NullableTimestampConverter().fromJson(
        json['specificDate'],
      ),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$AvailabilityToJson(
  _Availability instance,
) => <String, dynamic>{
  'id': instance.id,
  'providerId': instance.providerId,
  'locationId': instance.locationId,
  'startTime': const TimestampConverter().toJson(instance.startTime),
  'endTime': const TimestampConverter().toJson(instance.endTime),
  'type': _$AvailabilityTypeEnumMap[instance.type]!,
  'reason': instance.reason,
  'isRecurring': instance.isRecurring,
  'specificDate': const NullableTimestampConverter().toJson(
    instance.specificDate,
  ),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$AvailabilityTypeEnumMap = {
  AvailabilityType.available: 'available',
  AvailabilityType.blocked: 'blocked',
  AvailabilityType.override: 'override',
};
