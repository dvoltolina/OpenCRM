import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

/// Phone number entry step for MFA enrollment.
/// HIPAA Compliance: No PHI in logs or error messages.
class MfaPhoneEntryStep extends StatelessWidget {
  const MfaPhoneEntryStep({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSendCode,
    required this.onSkipForDevelopment,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSendCode;
  final VoidCallback onSkipForDevelopment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(
            theme: theme,
            title: 'Step 1: Enter Your Phone Number',
            subtitle: 'We\'ll send you a verification code via SMS',
          ),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              helperText: 'Include country code (e.g., +1 for US)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
              if (cleaned.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            enabled: !isLoading,
            onFieldSubmitted: (_) => onSendCode(),
          ),
          VSpace.md,
          if (errorMessage != null)
            MfaErrorBanner(theme: theme, errorMessage: errorMessage!),

          // Send code button
          FilledButton(
            onPressed: isLoading ? null : onSendCode,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Send Verification Code'),
          ),

          // Skip button for development only
          if (kDebugMode) ...[
            VSpace.lg,
            const Divider(),
            VSpace.md,
            TextButton(
              onPressed: isLoading ? null : onSkipForDevelopment,
              child: Text(
                'Skip for Development',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header for MFA enrollment steps.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  final ThemeData theme;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.xs,
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        VSpace.lg,
      ],
    );
  }
}

/// Error banner for MFA enrollment.
class MfaErrorBanner extends StatelessWidget {
  const MfaErrorBanner({
    super.key,
    required this.theme,
    required this.errorMessage,
  });

  final ThemeData theme;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            HSpace.sm,
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
