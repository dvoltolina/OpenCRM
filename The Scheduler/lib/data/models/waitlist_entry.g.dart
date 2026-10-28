// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaitlistEntry _$WaitlistEntryFromJson(Map<String, dynamic> json) =>
    _WaitlistEntry(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String,
      clientEmail: json['clientEmail'] as String?,
      clientPhone: json['clientPhone'] as String?,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String?,
      providerId: json['providerId'] as String?,
      providerName: json['providerName'] as String?,
      locationId: json['locationId'] as String?,
      preferredDaysOfWeek:
          (json['preferredDaysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      timeOfDayPreferences:
          (json['timeOfDayPreferences'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$TimeOfDayPreferenceEnumMap, e))
              .toList() ??
          const <TimeOfDayPreference>[TimeOfDayPreference.anytime],
      earliestDate: const TimestampConverter().fromJson(json['earliestDate']),
      latestDate: const TimestampConverter().fromJson(json['latestDate']),
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
      notificationPreference:
          $enumDecodeNullable(
            _$NotificationPreferenceEnumMap,
            json['notificationPreference'],
          ) ??
          NotificationPreference.email,
      status:
          $enumDecodeNullable(_$WaitlistStatusEnumMap, json['status']) ??
          WaitlistStatus.active,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      lastNotifiedAt: const NullableTimestampConverter().fromJson(
        json['lastNotifiedAt'],
      ),
      responseExpiresAt: const NullableTimestampConverter().fromJson(
        json['responseExpiresAt'],
      ),
      expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WaitlistEntryToJson(
  _WaitlistEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'clientId': instance.clientId,
  'clientName': instance.clientName,
  'clientEmail': instance.clientEmail,
  'clientPhone': instance.clientPhone,
  'serviceId': instance.serviceId,
  'serviceName': instance.serviceName,
  'providerId': instance.providerId,
  'providerName': instance.providerName,
  'locationId': instance.locationId,
  'preferredDaysOfWeek': instance.preferredDaysOfWeek,
  'timeOfDayPreferences': instance.timeOfDayPreferences
      .map((e) => _$TimeOfDayPreferenceEnumMap[e]!)
      .toList(),
  'earliestDate': const TimestampConverter().toJson(instance.earliestDate),
  'latestDate': const TimestampConverter().toJson(instance.latestDate),
  'priorityScore': instance.priorityScore,
  'notificationPreference':
      _$NotificationPreferenceEnumMap[instance.notificationPreference]!,
  'status': _$WaitlistStatusEnumMap[instance.status]!,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
  'lastNotifiedAt': const NullableTimestampConverter().toJson(
    instance.lastNotifiedAt,
  ),
  'responseExpiresAt': const NullableTimestampConverter().toJson(
    instance.responseExpiresAt,
  ),
  'expiresAt': const NullableTimestampConverter().toJson(instance.expiresAt),
  'notes': instance.notes,
};

const _$TimeOfDayPreferenceEnumMap = {
  TimeOfDayPreference.morning: 'morning',
  TimeOfDayPreference.afternoon: 'afternoon',
  TimeOfDayPreference.evening: 'evening',
  TimeOfDayPreference.anytime: 'anytime',
};

const _$NotificationPreferenceEnumMap = {
  NotificationPreference.email: 'email',
  NotificationPreference.sms: 'sms',
  NotificationPreference.both: 'both',
};

const _$WaitlistStatusEnumMap = {
  WaitlistStatus.active: 'active',
  WaitlistStatus.notified: 'notified',
  WaitlistStatus.expired: 'expired',
  WaitlistStatus.converted: 'converted',
};
