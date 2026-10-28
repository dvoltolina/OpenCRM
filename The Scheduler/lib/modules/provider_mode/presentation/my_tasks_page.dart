import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/offline/offline_banner.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/task.dart';
import '../../../data/models/security_context.dart';
import 'widgets/task_form_dialog.dart';
import 'widgets/task_filter_sheet.dart';

/// My Tasks page for Provider Mode.
///
/// Lightweight task management for providers:
/// - Create/edit/delete tasks
/// - Filter by status, priority, due date
/// - Link tasks to clients/appointments
/// - Mark tasks complete
///
/// RBAC: Staff can only manage their own tasks unless admin.
class MyTasksPage extends ConsumerStatefulWidget {
  const MyTasksPage({super.key});

  @override
  ConsumerState<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends ConsumerState<MyTasksPage> {
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;

  @override
  Widget build(BuildContext context) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const OfflineIndicator(),
          IconButton(
            icon: Badge(
              isLabelVisible: _filterStatus != null || _filterPriority != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _TasksList(
              securityContext: securityContext,
              filterStatus: _filterStatus,
              filterPriority: _filterPriority,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(context, securityContext),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TaskFilterSheet(
        currentStatus: _filterStatus,
        currentPriority: _filterPriority,
        onApply: (status, priority) {
          setState(() {
            _filterStatus = status;
            _filterPriority = priority;
          });
        },
      ),
    );
  }

  void _showTaskForm(BuildContext context, SecurityContext securityContext) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        securityContext: securityContext,
      ),
    );
  }
}

class _TasksList extends ConsumerWidget {
  const _TasksList({
    required this.securityContext,
    this.filterStatus,
    this.filterPriority,
  });

  final SecurityContext securityContext;
  final TaskStatus? filterStatus;
  final TaskPriority? filterPriority;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(taskRepositoryProvider);

    return StreamBuilder<List<Task>>(
      stream: repo.watchTasks(
        context: securityContext,
        assignedToProviderId: securityContext.providerId,
        status: filterStatus,
        priority: filterPriority,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading tasks: ${snapshot.error}'),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _EmptyTasks(
            hasFilters: filterStatus != null || filterPriority != null,
          );
        }

        // Group tasks by status
        final pending = tasks.where((t) => t.status == TaskStatus.pending).toList();
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
        final completed = tasks.where((t) => t.status == TaskStatus.completed).toList();

        return ListView(
          padding: AppSpacing.pagePadding,
          children: [
            if (pending.isNotEmpty) ...[
              _TaskSection(
                title: 'Pending',
                tasks: pending,
                securityContext: securityContext,
              ),
              VSpace.md,
            ],
            if (inProgress.isNotEmpty) ...[
              _TaskSection(
                title: 'In Progress',
                tasks: inProgress,
                securityContext: securityContext,
              ),
              VSpace.md,
            ],
            if (completed.isNotEmpty) ...[
              _TaskSection(
                title: 'Completed',
                tasks: completed,
                securityContext: securityContext,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.checklist_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          VSpace.md,
          Text(
            hasFilters ? 'No tasks match filters' : 'No tasks yet',
            style: theme.textTheme.titleMedium,
          ),
          VSpace.xs,
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'Create a task to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    required this.securityContext,
  });

  final String title;
  final List<Task> tasks;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            HSpace.xs,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        VSpace.xs,
        ...tasks.map((task) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _TaskCard(
              task: task,
              securityContext: securityContext,
            ),
          );
        }),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.task,
    required this.securityContext,
  });

  final Task task;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => _showTaskForm(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              _PriorityChip(priority: task.priority),
            ],
          ),
          if (task.description != null) ...[
            VSpace.xxs,
            Text(
              task.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          VSpace.xs,
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (task.dueDate != null)
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: _formatDueDate(task.dueDate!),
                  color: task.isOverdue
                      ? Colors.red
                      : task.isDueSoon
                          ? Colors.orange
                          : null,
                ),
              if (task.linkedClientName != null)
                _InfoChip(
                  icon: Icons.person_outline,
                  label: task.linkedClientName!,
                ),
              if (task.linkedAppointmentId != null)
                _InfoChip(
                  icon: Icons.event,
                  label: 'Linked to appointment',
                ),
            ],
          ),
          VSpace.xs,
          Row(
            children: [
              if (task.status != TaskStatus.completed)
                TextButton.icon(
                  onPressed: () => _markComplete(context, ref),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Complete'),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteTask(context, ref),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Due today';
    } else if (taskDate == tomorrow) {
      return 'Due tomorrow';
    } else {
      return 'Due ${DateFormat('MMM d').format(dueDate)}';
    }
  }

  void _showTaskForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        securityContext: securityContext,
        task: task,
      ),
    );
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTaskStatus(
        context: securityContext,
        taskId: task.id,
        status: TaskStatus.completed,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked complete')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    }
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(
        context: securityContext,
        taskId: task.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    }
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();

    final theme = Theme.of(context);

    return Chip(
      label: Text(priority.name.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Chip(
      avatar: Icon(icon, size: 14, color: effectiveColor),
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: effectiveColor,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
