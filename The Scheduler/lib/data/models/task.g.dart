// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  dueDate: const NullableTimestampConverter().fromJson(json['dueDate']),
  priority:
      $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
      TaskPriority.medium,
  status:
      $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
      TaskStatus.pending,
  assignedToProviderId: json['assignedToProviderId'] as String?,
  assignedToProviderName: json['assignedToProviderName'] as String?,
  linkedClientId: json['linkedClientId'] as String?,
  linkedClientName: json['linkedClientName'] as String?,
  linkedAppointmentId: json['linkedAppointmentId'] as String?,
  completedAt: const NullableTimestampConverter().fromJson(json['completedAt']),
  createdByUserId: json['createdByUserId'] as String?,
  createdByUserName: json['createdByUserName'] as String?,
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'title': instance.title,
  'description': instance.description,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'dueDate': const NullableTimestampConverter().toJson(instance.dueDate),
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'assignedToProviderId': instance.assignedToProviderId,
  'assignedToProviderName': instance.assignedToProviderName,
  'linkedClientId': instance.linkedClientId,
  'linkedClientName': instance.linkedClientName,
  'linkedAppointmentId': instance.linkedAppointmentId,
  'completedAt': const NullableTimestampConverter().toJson(
    instance.completedAt,
  ),
  'createdByUserId': instance.createdByUserId,
  'createdByUserName': instance.createdByUserName,
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 'low',
  TaskPriority.medium: 'medium',
  TaskPriority.high: 'high',
  TaskPriority.urgent: 'urgent',
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.inProgress: 'inProgress',
  TaskStatus.completed: 'completed',
  TaskStatus.cancelled: 'cancelled',
};
