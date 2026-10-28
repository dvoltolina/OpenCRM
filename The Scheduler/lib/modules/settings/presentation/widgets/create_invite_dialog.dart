import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/utils/safe_error_handler.dart';

// TODO(RW2): Uncomment when repository is available
// import '../../../../data/repositories/staff_onboarding_repository.dart';
// import '../../../../core/providers/repository_providers.dart';

/// Dialog for creating a new email invite.
/// Modern design with rounded corners and sophisticated blue styling.
///
/// Collects configuration:
/// - Email address
/// - Role (staff or admin)
/// - Expiration (1, 7, 30 days, or custom)
/// - Optional notes
///
/// Calls repository method when implemented:
/// - createInvite(context, email, role, expiresAt, notes)
/// - Sends email automatically
class CreateInviteDialog extends ConsumerStatefulWidget {
  const CreateInviteDialog({super.key});

  @override
  ConsumerState<CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends ConsumerState<CreateInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _role = 'staff';
  int _expiryDays = 7;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(appConfigProvider).branding;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      title: Row(
        children: [
          Icon(Icons.send, color: branding.primaryColor),
          const SizedBox(width: 12),
          const Text('Send Invite'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send a personalized invitation to a specific staff member.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                // Email
                Text(
                  'Email Address',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email, color: branding.accentColor),
                    hintText: 'staff@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Role selection
                Text(
                  'Role',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'staff',
                      label: Text('Staff'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 'admin',
                      label: Text('Admin'),
                      icon: Icon(Icons.admin_panel_settings),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _role = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Expiration
                Text(
                  'Expires In',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _expiryDays,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.schedule, color: branding.accentColor),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 day')),
                    DropdownMenuItem(value: 7, child: Text('7 days (recommended)')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _expiryDays = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Notes
                Text(
                  'Notes (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., Welcome message',
                    prefixIcon: Icon(Icons.note, color: branding.accentColor),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _sendInvite,
                  style: FilledButton.styleFrom(
                    backgroundColor: branding.effectiveCtaColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send Invite'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO(RW2): Uncomment when repository is available
      /*
      final securityContext = ref.read(currentSecurityContextProvider);
      if (securityContext == null) {
        throw Exception('Not authenticated');
      }

      final repo = ref.read(staffOnboardingRepositoryProvider);
      final expiresAt = DateTime.now().add(Duration(days: _expiryDays));
      final email = _emailController.text.trim().toLowerCase();

      await repo.createInvite(
        context: securityContext,
        email: email,
        role: _role,
        expiresAt: expiresAt,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
      */

      // Placeholder for now
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite sending requires models and repository implementation'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Sending invite',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
