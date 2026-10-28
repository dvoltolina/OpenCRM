// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_pattern.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurrencePattern _$RecurrencePatternFromJson(Map<String, dynamic> json) =>
    _RecurrencePattern(
      id: json['id'] as String,
      frequency: $enumDecode(_$RecurrenceFrequencyEnumMap, json['frequency']),
      daysOfWeek:
          (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$DayOfWeekEnumMap, e))
              .toList() ??
          const [],
      customInterval: (json['customInterval'] as num?)?.toInt(),
      customIntervalUnit: json['customIntervalUnit'] as String?,
      endType: $enumDecode(_$RecurrenceEndTypeEnumMap, json['endType']),
      numberOfOccurrences: (json['numberOfOccurrences'] as num?)?.toInt(),
      endDate: const NullableTimestampConverter().fromJson(json['endDate']),
      exclusionDates: json['exclusionDates'] == null
          ? const []
          : const TimestampListConverter().fromJson(
              json['exclusionDates'] as List,
            ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$RecurrencePatternToJson(
  _RecurrencePattern instance,
) => <String, dynamic>{
  'id': instance.id,
  'frequency': _$RecurrenceFrequencyEnumMap[instance.frequency]!,
  'daysOfWeek': instance.daysOfWeek.map((e) => _$DayOfWeekEnumMap[e]!).toList(),
  'customInterval': instance.customInterval,
  'customIntervalUnit': instance.customIntervalUnit,
  'endType': _$RecurrenceEndTypeEnumMap[instance.endType]!,
  'numberOfOccurrences': instance.numberOfOccurrences,
  'endDate': const NullableTimestampConverter().toJson(instance.endDate),
  'exclusionDates': const TimestampListConverter().toJson(
    instance.exclusionDates,
  ),
  'isActive': instance.isActive,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.daily: 'daily',
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.biweekly: 'biweekly',
  RecurrenceFrequency.monthly: 'monthly',
  RecurrenceFrequency.custom: 'custom',
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

const _$RecurrenceEndTypeEnumMap = {
  RecurrenceEndType.never: 'never',
  RecurrenceEndType.afterOccurrences: 'afterOccurrences',
  RecurrenceEndType.onDate: 'onDate',
};
