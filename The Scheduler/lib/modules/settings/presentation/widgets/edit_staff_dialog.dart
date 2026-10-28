import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/staff_member.dart';
import '../../../../data/models/user_role.dart';

class EditStaffDialog extends ConsumerStatefulWidget {
  const EditStaffDialog({
    super.key,
    required this.member,
  });

  final StaffMember member;

  @override
  ConsumerState<EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends ConsumerState<EditStaffDialog> {
  late UserRole _role;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _role = widget.member.role;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelf =
        ref.watch(securityContextProvider).valueOrNull?.userId == widget.member.id;

    return AlertDialog(
      title: const Text('Edit Team Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.member.displayName, style: theme.textTheme.titleMedium),
          Text(widget.member.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: _roleOptions
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(_roleLabel(role)),
                  ),
                )
                .toList(),
            onChanged: isSelf
                ? null
                : (role) {
                    if (role != null) {
                      setState(() => _role = role);
                    }
                  },
          ),
          const SizedBox(height: 12),
          Text(
            _roleDescription(_role),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.member.isDeactivated)
          TextButton(
            onPressed: _submitting ? null : _reactivate,
            child: const Text('Reactivate'),
          )
        else
          TextButton(
            onPressed: _submitting ? null : _deactivate,
            child: const Text('Deactivate'),
          ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final contextValue = ref.read(securityContextProvider).valueOrNull;
    if (contextValue == null) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.updateStaffRole(contextValue, widget.member.id, _role);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update role')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deactivate() async {
    final contextValue = ref.read(securityContextProvider).valueOrNull;
    if (contextValue == null) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.deactivateStaff(contextValue, widget.member.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deactivate')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reactivate() async {
    final contextValue = ref.read(securityContextProvider).valueOrNull;
    if (contextValue == null) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.reactivateStaff(contextValue, widget.member.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reactivate')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static const _roleOptions = [
    UserRole.provider,
    UserRole.sales,
    UserRole.manager,
    UserRole.frontDesk,
    UserRole.admin,
    UserRole.owner,
  ];

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.provider:
      case UserRole.staff:
        return 'Provider';
      case UserRole.sales:
        return 'Sales';
      case UserRole.manager:
        return 'Manager';
      case UserRole.frontDesk:
        return 'Front Desk';
      case UserRole.admin:
        return 'Admin';
      case UserRole.owner:
        return 'Owner';
      case UserRole.client:
        return 'Client';
    }
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.provider:
      case UserRole.staff:
        return 'Access to own schedule, booking, time clock, and assigned clients.';
      case UserRole.sales:
        return 'CRM access (leads, deals) and own schedule.';
      case UserRole.manager:
        return 'Team oversight, approvals, schedules, and reports.';
      case UserRole.frontDesk:
        return 'Check-in and booking for front desk operations.';
      case UserRole.admin:
        return 'Full admin access. Owner approval recommended.';
      case UserRole.owner:
        return 'Business owner. Highest access.';
      case UserRole.client:
        return 'Client role (not for staff).';
    }
  }
}
