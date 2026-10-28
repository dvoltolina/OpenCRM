import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';
import '../models/task.dart';
import 'audit_log_repository.dart';

/// Repository for managing provider tasks with multi-tenant isolation and RBAC.
/// Staff can view/manage tasks assigned to them.
/// Admins can view/manage all tasks in their business.
class TaskRepository {
  TaskRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  CollectionReference<Map<String, dynamic>> _tasks(String businessId) =>
      _firestore.collection('businesses/$businessId/tasks');

  /// Watch tasks filtered by status and assignee
  Stream<List<Task>> watchTasks({
    required SecurityContext context,
    String? assignedToProviderId,
    TaskStatus? status,
    TaskPriority? priority,
    String? linkedClientId,
  }) {
    Query<Map<String, dynamic>> query = _tasks(context.businessId);

    // Filter by assignee (provider ID)
    if (assignedToProviderId != null) {
      query = query.where(
        'assignedToProviderId',
        isEqualTo: assignedToProviderId,
      );
    } else if (context.providerId != null &&
        !context.role.canManageAllAppointments) {
      // Non-admin staff only see their own tasks
      query = query.where(
        'assignedToProviderId',
        isEqualTo: context.providerId,
      );
    }

    // Filter by status
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    // Filter by priority
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority.name);
    }

    // Filter by linked client
    if (linkedClientId != null) {
      query = query.where('linkedClientId', isEqualTo: linkedClientId);
    }

    // Order by due date (soonest first), then created date
    query = query.orderBy('dueDate', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _mapTaskDoc(doc)).toList();
    });
  }

  /// Get a single task by ID
  Future<Task?> getTask({
    required SecurityContext context,
    required String taskId,
  }) async {
    final doc = await _tasks(context.businessId).doc(taskId).get();
    if (!doc.exists) return null;

    final task = _mapTaskDoc(doc);

    // RBAC check: staff can only view their own tasks unless admin
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        task.assignedToProviderId != context.providerId) {
      throw SecurityException('Staff can only view their own tasks');
    }

    // Audit log PHI read
    await _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiRead,
        entityType: 'Task',
        entityId: taskId,
        metadata: {'source': 'getTask'},
      ),
    );

    return task;
  }

  /// Create a new task
  Future<Task> createTask({
    required SecurityContext context,
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? assignedToProviderId,
    String? assignedToProviderName,
    String? linkedClientId,
    String? linkedClientName,
    String? linkedAppointmentId,
  }) async {
    DemoGuardService.assertReadOnly('create task');
    final docRef = _tasks(context.businessId).doc();
    final now = DateTime.now();

    final task = Task(
      id: docRef.id,
      businessId: context.businessId,
      title: title,
      description: description,
      createdAt: now,
      dueDate: dueDate,
      priority: priority,
      status: TaskStatus.pending,
      assignedToProviderId: assignedToProviderId,
      assignedToProviderName: assignedToProviderName,
      linkedClientId: linkedClientId,
      linkedClientName: linkedClientName,
      linkedAppointmentId: linkedAppointmentId,
      createdByUserId: context.userId,
      updatedAt: now,
    );

    await docRef.set(_taskToFirestore(task));

    // Audit log task creation
    await _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'Task',
        entityId: task.id,
        metadata: {
          'source': 'createTask',
          'action': 'create',
          'priority': priority.name,
        },
      ),
    );

    return task;
  }

  /// Update a task
  Future<void> updateTask({
    required SecurityContext context,
    required Task task,
  }) async {
    DemoGuardService.assertReadOnly('update task');
    // RBAC check: staff can only update their own tasks unless admin
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        task.assignedToProviderId != context.providerId) {
      throw SecurityException('Staff can only update their own tasks');
    }

    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    await _tasks(
      context.businessId,
    ).doc(task.id).set(_taskToFirestore(updatedTask), SetOptions(merge: true));

    // Audit log task update
    await _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'Task',
        entityId: task.id,
        metadata: {
          'source': 'updateTask',
          'action': 'update',
          'status': updatedTask.status.name,
        },
      ),
    );
  }

  /// Update task status
  Future<void> updateTaskStatus({
    required SecurityContext context,
    required String taskId,
    required TaskStatus status,
  }) async {
    DemoGuardService.assertReadOnly('update task status');
    final task = await getTask(context: context, taskId: taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    final updatedTask = task.copyWith(
      status: status,
      completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    await updateTask(context: context, task: updatedTask);
  }

  /// Delete a task
  Future<void> deleteTask({
    required SecurityContext context,
    required String taskId,
  }) async {
    DemoGuardService.assertReadOnly('delete task');
    final task = await getTask(context: context, taskId: taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    // RBAC check: staff can only delete their own tasks unless admin
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        task.assignedToProviderId != context.providerId) {
      throw SecurityException('Staff can only delete their own tasks');
    }

    await _tasks(context.businessId).doc(taskId).delete();

    // Audit log task deletion
    await _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'Task',
        entityId: taskId,
        metadata: {'source': 'deleteTask', 'action': 'delete'},
      ),
    );
  }

  /// Map Firestore doc to Task model
  Task _mapTaskDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      id: doc.id,
      businessId: data['businessId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      assignedToProviderId: data['assignedToProviderId'] as String?,
      assignedToProviderName: data['assignedToProviderName'] as String?,
      linkedClientId: data['linkedClientId'] as String?,
      linkedClientName: data['linkedClientName'] as String?,
      linkedAppointmentId: data['linkedAppointmentId'] as String?,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdByUserId: data['createdByUserId'] as String?,
      createdByUserName: data['createdByUserName'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert Task to Firestore data
  Map<String, dynamic> _taskToFirestore(Task task) {
    final data = task.toJson();
    // Convert DateTime to Timestamp
    data['createdAt'] = Timestamp.fromDate(task.createdAt);
    if (task.dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(task.dueDate!);
    }
    if (task.completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(task.completedAt!);
    }
    if (task.updatedAt != null) {
      data['updatedAt'] = Timestamp.fromDate(task.updatedAt!);
    }
    // Convert enums to strings
    data['priority'] = task.priority.name;
    data['status'] = task.status.name;
    return data;
  }
}

class SecurityException implements Exception {
  SecurityException(this.message);
  final String message;

  @override
  String toString() => 'SecurityException: $message';
}
