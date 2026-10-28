import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Task status
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Task entity for provider task management.
/// Multi-tenant: each task belongs to exactly one business.
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String businessId,
    required String title,
    String? description,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? dueDate,
    @Default(TaskPriority.medium) TaskPriority priority,
    @Default(TaskStatus.pending) TaskStatus status,
    /// The provider/staff member assigned to this task
    String? assignedToProviderId,
    String? assignedToProviderName,
    /// Optional link to a client
    String? linkedClientId,
    String? linkedClientName,
    /// Optional link to an appointment
    String? linkedAppointmentId,
    /// When task was completed
    @NullableTimestampConverter() DateTime? completedAt,
    /// User who created the task
    String? createdByUserId,
    String? createdByUserName,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  const Task._();

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task is due soon (within 24 hours)
  bool get isDueSoon {
    if (dueDate == null) return false;
    if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    return dueDate!.isBefore(tomorrow) && dueDate!.isAfter(now);
  }

  /// Get priority display name
  String get priorityDisplay {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}
