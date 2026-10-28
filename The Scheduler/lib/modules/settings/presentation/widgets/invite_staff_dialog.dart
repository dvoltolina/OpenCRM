import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/user_role.dart';
import 'invite_success_dialog.dart';

class InviteStaffDialog extends ConsumerStatefulWidget {
  const InviteStaffDialog({super.key});

  @override
  ConsumerState<InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends ConsumerState<InviteStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _maxUsesController = TextEditingController(text: '1');
  UserRole _role = UserRole.provider;
  int _expiresDays = 7;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite New Team Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'john@example.com',
                  helperText: 'Leave blank for open invite code',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role *'),
                items: _roleOptions
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabel(r)),
                      ),
                    )
                    .toList(),
                onChanged: (role) {
                  if (role != null) {
                    setState(() => _role = role);
                  }
                },
                validator: (value) =>
                    value == null ? 'Role is required' : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _roleDescription(_role),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _expiresDays,
                decoration: const InputDecoration(labelText: 'Expires In'),
                items: const [1, 7, 14, 30]
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text('$d day${d == 1 ? '' : 's'}'),
                      ),
                    )
                    .toList(),
                onChanged: (days) {
                  if (days != null) setState(() => _expiresDays = days);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(labelText: 'Max Uses'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null) return 'Enter a number';
                  if (parsed < 1 || parsed > 100) {
                    return 'Must be between 1 and 100';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Invite'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final contextValue = ref.read(securityContextProvider).valueOrNull;
    if (contextValue == null) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(inviteRepositoryProvider);
      final maxUses = int.parse(_maxUsesController.text);
      final result = await repo.createStaffInvite(
        contextValue,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        role: _role,
        expiresIn: Duration(days: _expiresDays),
        maxUses: maxUses,
      );

      if (mounted) {
        final navigator = Navigator.of(context);
        await showDialog(
          context: context,
          builder: (_) => InviteSuccessDialog(
            code: result.code,
            link: result.link,
            roleLabel: _roleLabel(_role),
            expiresAt: result.expiresAt,
            remainingUses: maxUses,
          ),
        );
        if (mounted) {
          navigator.pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create invite')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  static const List<UserRole> _roleOptions = [
    UserRole.provider,
    UserRole.sales,
    UserRole.manager,
    UserRole.frontDesk,
    UserRole.admin,
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
        return 'Field staff who deliver services. Access to schedule, time clock, and their clients.';
      case UserRole.sales:
        return 'Sales team members with CRM access, leads, and their own schedule.';
      case UserRole.manager:
        return 'Supervisors with team oversight, schedules, and approvals.';
      case UserRole.frontDesk:
        return 'Reception/check-in and booking access for stationary businesses.';
      case UserRole.admin:
        return 'Full administrative access (requires owner approval).';
      case UserRole.owner:
        return 'Business owner (not typically invited).';
      case UserRole.client:
        return 'Client role (not used for staff invites).';
    }
  }
}
