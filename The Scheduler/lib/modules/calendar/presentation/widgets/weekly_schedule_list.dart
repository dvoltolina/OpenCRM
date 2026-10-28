import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/core/ui/components/components.dart' hide EmptyStateWidget;
import 'package:the_scheduler/core/ui/ui_exports.dart';
import 'package:the_scheduler/core/utils/secure_error_handler.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/security_context.dart';

class WeeklyScheduleList extends ConsumerWidget {
  const WeeklyScheduleList({
    super.key,
    required this.securityContext,
    required this.providerId,
    required this.locationId,
  });

  final SecurityContext securityContext;
  final String providerId;
  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityRepo = ref.read(availabilityRepositoryProvider);

    return StreamBuilder<List<WeeklySchedule>>(
      stream: availabilityRepo.watchWeeklySchedules(
        securityContext,
        providerId,
        locationId: locationId,
      ),
      builder: (builderContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: ErrorFeedback(message: SecureErrorHandler.loadingFailed),
          );
        }
        final schedules = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: DayOfWeek.values.length + 1,
          itemBuilder: (context, index) {
            if (index == DayOfWeek.values.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showApplyToAllDialog(context, ref, schedules),
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy Schedule to All Days'),
                ),
              );
            }
            final dayOfWeek = DayOfWeek.values[index];
            final schedule = schedules.firstWhere(
              (s) => s.dayOfWeek == dayOfWeek,
              orElse: () => WeeklySchedule(
                id: const Uuid().v4(),
                providerId: providerId,
                locationId: locationId,
                dayOfWeek: dayOfWeek,
                timeBlocks: [],
                createdAt: DateTime.now(),
              ),
            );
            return _DayScheduleCard(
              schedule: schedule,
              onAdd: () => _showAddTimeBlockDialog(context, ref, schedule),
              onEdit: (block) => _showEditTimeBlockDialog(context, ref, schedule, block),
              onDelete: (block) => _deleteTimeBlock(context, ref, schedule, block),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddTimeBlockDialog(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule schedule,
  ) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Add Time Block for ${schedule.dayOfWeek.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(startTime?.format(context) ?? 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null && context.mounted) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(endTime?.format(context) ?? 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (picked != null && context.mounted) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: startTime != null && endTime != null
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed == true && startTime != null && endTime != null && context.mounted) {
      await _addTimeBlock(context, ref, schedule, startTime!, endTime!);
    }
  }

  Future<void> _showEditTimeBlockDialog(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule schedule,
    TimeBlock block,
  ) async {
    TimeOfDay? startTime = TimeOfDay(
      hour: block.startHour,
      minute: block.startMinute,
    );
    TimeOfDay? endTime = TimeOfDay(
      hour: block.endHour,
      minute: block.endMinute,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Time Block'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(startTime!.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime!,
                    );
                    if (picked != null && context.mounted) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(endTime!.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime!,
                    );
                    if (picked != null && context.mounted) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed == true && startTime != null && endTime != null && context.mounted) {
      await _updateTimeBlock(context, ref, schedule, block, startTime!, endTime!);
    }
  }

  Future<void> _addTimeBlock(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule schedule,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final newBlock = TimeBlock(
      startHour: startTime.hour,
      startMinute: startTime.minute,
      endHour: endTime.hour,
      endMinute: endTime.minute,
    );
    final updatedSchedule = schedule.copyWith(
      timeBlocks: [...schedule.timeBlocks, newBlock],
      isActive: true,
    );
    try {
      await ref.read(availabilityRepositoryProvider).upsertWeeklySchedule(
            securityContext,
            updatedSchedule,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time block added successfully')),
      );
    } catch (e) {
      SecureErrorHandler.showError(
        context,
        error: Exception(e.toString()),
        userMessage: SecureErrorHandler.saveFailed,
      );
    }
  }

  Future<void> _updateTimeBlock(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule schedule,
    TimeBlock oldBlock,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final newBlock = TimeBlock(
      startHour: startTime.hour,
      startMinute: startTime.minute,
      endHour: endTime.hour,
      endMinute: endTime.minute,
    );
    final updatedBlocks = schedule.timeBlocks.map((block) {
      return block == oldBlock ? newBlock : block;
    }).toList();
    final updatedSchedule = schedule.copyWith(timeBlocks: updatedBlocks);
    try {
      await ref.read(availabilityRepositoryProvider).upsertWeeklySchedule(
            securityContext,
            updatedSchedule,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time block updated successfully')),
      );
    } catch (e) {
      SecureErrorHandler.showError(
        context,
        error: Exception(e.toString()),
        userMessage: SecureErrorHandler.updateFailed,
      );
    }
  }

  Future<void> _deleteTimeBlock(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule schedule,
    TimeBlock block,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Time Block'),
        content: Text('Remove ${block.displayTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final updatedBlocks = schedule.timeBlocks.where((b) => b != block).toList();
    final updatedSchedule = schedule.copyWith(timeBlocks: updatedBlocks);
    try {
      await ref.read(availabilityRepositoryProvider).upsertWeeklySchedule(
            securityContext,
            updatedSchedule,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time block deleted successfully')),
      );
    } catch (e) {
      SecureErrorHandler.showError(
        context,
        error: Exception(e.toString()),
        userMessage: SecureErrorHandler.deleteFailed,
      );
    }
  }

  Future<void> _showApplyToAllDialog(
    BuildContext context,
    WidgetRef ref,
    List<WeeklySchedule> schedules,
  ) async {
    final nonEmptySchedules =
        schedules.where((s) => s.timeBlocks.isNotEmpty).toList();

    if (nonEmptySchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one day of availability to copy.'),
        ),
      );
      return;
    }

    WeeklySchedule selected = nonEmptySchedules.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Copy to All Days'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a day to copy to every other day. Existing blocks will be replaced.',
                ),
                VSpace.md,
                DropdownButton<WeeklySchedule>(
                  value: selected,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selected = value);
                    }
                  },
                  items: nonEmptySchedules
                      .map(
                        (s) => DropdownMenuItem<WeeklySchedule>(
                          value: s,
                          child: Text(s.dayOfWeek.displayName),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Copy'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      await _applyScheduleToAll(context, ref, selected, schedules);
    }
  }

  Future<void> _applyScheduleToAll(
    BuildContext context,
    WidgetRef ref,
    WeeklySchedule source,
    List<WeeklySchedule> existing,
  ) async {
    final repo = ref.read(availabilityRepositoryProvider);
    final now = DateTime.now();
    try {
      for (final day in DayOfWeek.values) {
        if (day == source.dayOfWeek) continue;

        final target = existing.firstWhere(
          (s) => s.dayOfWeek == day,
          orElse: () => WeeklySchedule(
            id: const Uuid().v4(),
            providerId: providerId,
            locationId: locationId,
            dayOfWeek: day,
            timeBlocks: const [],
            createdAt: now,
          ),
        );

        final updated = target.copyWith(
          timeBlocks: List<TimeBlock>.from(source.timeBlocks),
          updatedAt: now,
        );

        await repo.upsertWeeklySchedule(
          securityContext,
          updated,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule copied to all days')),
      );
    } catch (e) {
      if (!context.mounted) return;
      SecureErrorHandler.showError(
        context,
        error: Exception(e.toString()),
        userMessage: SecureErrorHandler.updateFailed,
      );
    }
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.schedule,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final WeeklySchedule schedule;
  final VoidCallback onAdd;
  final void Function(TimeBlock block) onEdit;
  final void Function(TimeBlock block) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        tilePadding: AppSpacing.cardPadding,
        childrenPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Row(
          children: [
            Text(
              schedule.dayOfWeek.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (schedule.timeBlocks.isEmpty)
              StatusPill.neutral(label: 'Not Set')
            else
              StatusPill.success(
                label: '${schedule.timeBlocks.length} block${schedule.timeBlocks.length != 1 ? 's' : ''}',
              ),
          ],
        ),
        children: [
          if (schedule.timeBlocks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No availability set for ${schedule.dayOfWeek.displayName}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  VSpace.sm,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time Block'),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...schedule.timeBlocks.map((block) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Icon(
                      Icons.access_time,
                      size: AppIconSize.sm,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(block.displayTime),
                    subtitle: Text('${block.durationMinutes} minutes'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(block),
                          tooltip: 'Edit time block',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete(block),
                          tooltip: 'Delete time block',
                        ),
                      ],
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Time Block'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
