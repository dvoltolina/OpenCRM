import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/utils/safe_error_handler.dart';

// TODO(RW2): Uncomment when repository is available
// import '../../../../data/repositories/staff_onboarding_repository.dart';
// import '../../../../core/providers/repository_providers.dart';

/// Dialog for creating a new join code.
/// Modern design with rounded corners and sophisticated blue styling.
///
/// Collects configuration:
/// - Role (staff or admin)
/// - Expiration (1, 7, 30 days, or custom)
/// - Max uses (1-50)
/// - Optional notes
///
/// Calls repository method when implemented:
/// - createJoinCode(context, role, expiresAt, maxUses, notes)
/// - Returns plaintext code (shown only once)
class CreateJoinCodeDialog extends ConsumerStatefulWidget {
  const CreateJoinCodeDialog({super.key});

  @override
  ConsumerState<CreateJoinCodeDialog> createState() =>
      _CreateJoinCodeDialogState();
}

class _CreateJoinCodeDialogState extends ConsumerState<CreateJoinCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'staff';
  int _expiryDays = 7;
  int _maxUses = 5;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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
          Icon(Icons.qr_code_2, color: branding.primaryColor),
          const SizedBox(width: 12),
          const Text('Create Join Code'),
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
                  'Create a shareable join code for staff to join your business.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                VSpace.lg,
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
                VSpace.lg,
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
                    DropdownMenuItem(
                      value: 7,
                      child: Text('7 days (recommended)'),
                    ),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _expiryDays = value;
                      });
                    }
                  },
                ),
                VSpace.lg,
                // Max uses
                Text(
                  'Maximum Uses',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _maxUses.toString(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.people, color: branding.accentColor),
                    helperText: 'How many people can use this code?',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 1 || num > 50) {
                      return 'Enter a number between 1 and 50';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null) {
                      setState(() {
                        _maxUses = num;
                      });
                    }
                  },
                ),
                VSpace.lg,
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
                    hintText: 'e.g., For new front desk staff',
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
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _createJoinCode,
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
                      : const Icon(Icons.add),
                  label: const Text('Create Code'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createJoinCode() async {
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

      final joinCode = await repo.createJoinCode(
        context: securityContext,
        role: _role,
        expiresAt: expiresAt,
        maxUses: _maxUses,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        // Close this dialog
        Navigator.of(context).pop(true);

        // Show the generated code (only time it's visible in plaintext)
        await _showCodeSuccessDialog(joinCode.code);
      }
      */

      // Placeholder for now
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Join code creation requires models and repository implementation',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Creating join code',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
