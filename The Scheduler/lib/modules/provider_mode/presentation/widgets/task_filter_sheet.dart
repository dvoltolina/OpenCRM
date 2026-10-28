import 'package:flutter/material.dart';

import '../../../../data/models/task.dart';

/// Bottom sheet for filtering tasks by status and priority.
class TaskFilterSheet extends StatefulWidget {
  const TaskFilterSheet({
    super.key,
    required this.currentStatus,
    required this.currentPriority,
    required this.onApply,
  });

  final TaskStatus? currentStatus;
  final TaskPriority? currentPriority;
  final void Function(TaskStatus?, TaskPriority?) onApply;

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskStatus? _selectedStatus;
  late TaskPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedPriority = widget.currentPriority;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter Tasks',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedPriority = null;
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedStatus == null,
                onSelected: (selected) {
                  setState(() => _selectedStatus = null);
                },
              ),
              ...TaskStatus.values.map((status) {
                return FilterChip(
                  label: Text(_getStatusLabel(status)),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? status : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Priority',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedPriority == null,
                onSelected: (selected) {
                  setState(() => _selectedPriority = null);
                },
              ),
              ...TaskPriority.values.map((priority) {
                return FilterChip(
                  label: Text(_getPriorityLabel(priority)),
                  selected: _selectedPriority == priority,
                  onSelected: (selected) {
                    setState(() =>
                        _selectedPriority = selected ? priority : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_selectedStatus, _selectedPriority);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getStatusLabel(TaskStatus status) {
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

  String _getPriorityLabel(TaskPriority priority) {
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
}
