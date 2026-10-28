// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessId: json['businessId'] as String?,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      priority:
          $enumDecodeNullable(
            _$NotificationPriorityEnumMap,
            json['priority'],
          ) ??
          NotificationPriority.normal,
      isRead: json['isRead'] as bool? ?? false,
      readAt: const NullableTimestampConverter().fromJson(json['readAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      targetType: json['targetType'] as String?,
      targetId: json['targetId'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
    );

Map<String, dynamic> _$AppNotificationToJson(
  _AppNotification instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'businessId': instance.businessId,
  'type': _$NotificationTypeEnumMap[instance.type]!,
  'title': instance.title,
  'body': instance.body,
  'priority': _$NotificationPriorityEnumMap[instance.priority]!,
  'isRead': instance.isRead,
  'readAt': const NullableTimestampConverter().toJson(instance.readAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'data': instance.data,
  'expiresAt': const NullableTimestampConverter().toJson(instance.expiresAt),
};

const _$NotificationTypeEnumMap = {
  NotificationType.appointmentReminder: 'appointmentReminder',
  NotificationType.appointmentConfirmed: 'appointmentConfirmed',
  NotificationType.appointmentCancelled: 'appointmentCancelled',
  NotificationType.appointmentRescheduled: 'appointmentRescheduled',
  NotificationType.waitlistAvailable: 'waitlistAvailable',
  NotificationType.newMessage: 'newMessage',
  NotificationType.paymentReceived: 'paymentReceived',
  NotificationType.paymentFailed: 'paymentFailed',
  NotificationType.intakeFormRequired: 'intakeFormRequired',
  NotificationType.general: 'general',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};
