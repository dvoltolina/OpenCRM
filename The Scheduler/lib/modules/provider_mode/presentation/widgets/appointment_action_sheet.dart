import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/security_context.dart';

/// Bottom sheet with quick actions for an appointment.
///
/// Actions include:
/// - Check-in (pending/confirmed -> confirmed)
/// - Complete (confirmed -> completed)
/// - Mark no-show (pending/confirmed -> noShow)
/// - Add staff notes
class AppointmentActionSheet extends ConsumerStatefulWidget {
  const AppointmentActionSheet({
    super.key,
    required this.appointment,
    required this.securityContext,
  });

  final Appointment appointment;
  final SecurityContext securityContext;

  @override
  ConsumerState<AppointmentActionSheet> createState() =>
      _AppointmentActionSheetState();
}

class _AppointmentActionSheetState
    extends ConsumerState<AppointmentActionSheet> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, y • h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(
                      'Appointment Details',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Time',
                      value: dateFormat.format(widget.appointment.startTime),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Client',
                      value: widget.appointment.clientId,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.medical_services_outlined,
                      label: 'Service',
                      value: widget.appointment.serviceType ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: _getStatusDisplay(widget.appointment.status),
                    ),
                    if (widget.appointment.notes != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.note_outlined,
                        label: 'Notes',
                        value: widget.appointment.notes!,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_canCheckIn)
                      _ActionButton(
                        icon: Icons.how_to_reg,
                        label: 'Check In',
                        onTap: _isUpdating ? null : _handleCheckIn,
                      ),
                    if (_canComplete)
                      _ActionButton(
                        icon: Icons.check_circle,
                        label: 'Mark Complete',
                        onTap: _isUpdating ? null : _handleComplete,
                      ),
                    if (_canMarkNoShow)
                      _ActionButton(
                        icon: Icons.event_busy,
                        label: 'Mark No-Show',
                        color: Colors.red,
                        onTap: _isUpdating ? null : _handleNoShow,
                      ),
                    _ActionButton(
                      icon: Icons.edit_note,
                      label: 'Add Staff Notes',
                      onTap: _isUpdating ? null : _handleAddNotes,
                    ),
                    const SizedBox(height: 16),
                    if (_isUpdating)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _canCheckIn =>
      widget.appointment.status == AppointmentStatus.pending ||
      widget.appointment.status == AppointmentStatus.confirmed;

  bool get _canComplete =>
      widget.appointment.status == AppointmentStatus.confirmed;

  bool get _canMarkNoShow =>
      widget.appointment.status == AppointmentStatus.pending ||
      widget.appointment.status == AppointmentStatus.confirmed;

  String _getStatusDisplay(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No-Show';
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final updated = widget.appointment.copyWith(
        status: AppointmentStatus.confirmed,
      );

      await repo.upsertAppointment(
        context: widget.securityContext,
        appointment: updated,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client checked in')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final updated = widget.appointment.copyWith(
        status: AppointmentStatus.completed,
      );

      await repo.upsertAppointment(
        context: widget.securityContext,
        appointment: updated,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleNoShow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark No-Show'),
        content: const Text(
          'Are you sure you want to mark this appointment as a no-show?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark No-Show'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final updated = widget.appointment.copyWith(
        status: AppointmentStatus.noShow,
      );

      await repo.upsertAppointment(
        context: widget.securityContext,
        appointment: updated,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked as no-show')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleAddNotes() async {
    final controller = TextEditingController(text: widget.appointment.notes);

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (notes == null || notes == widget.appointment.notes) return;

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final updated = widget.appointment.copyWith(notes: notes);

      await repo.upsertAppointment(
        context: widget.securityContext,
        appointment: updated,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: effectiveColor),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: effectiveColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
