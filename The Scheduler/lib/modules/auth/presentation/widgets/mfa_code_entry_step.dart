import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';
import 'mfa_phone_entry_step.dart';

/// Verification code entry step for MFA enrollment.
/// HIPAA Compliance: No PHI in logs or error messages.
class MfaCodeEntryStep extends StatelessWidget {
  const MfaCodeEntryStep({
    super.key,
    required this.formKey,
    required this.codeController,
    required this.phoneNumber,
    required this.isLoading,
    required this.errorMessage,
    required this.onVerifyCode,
    required this.onResendCode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onVerifyCode;
  final VoidCallback onResendCode;

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
            title: 'Step 2: Enter Verification Code',
            subtitle: 'Enter the 6-digit code sent to $phoneNumber',
          ),
          TextFormField(
            controller: codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(),
              helperText: '6-digit code from SMS',
            ),
            maxLength: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the verification code';
              }
              if (value.trim().length != 6) {
                return 'Code must be 6 digits';
              }
              return null;
            },
            enabled: !isLoading,
            onFieldSubmitted: (_) => onVerifyCode(),
          ),
          VSpace.md,

          if (errorMessage != null)
            MfaErrorBanner(theme: theme, errorMessage: errorMessage!),

          // Verify button
          FilledButton(
            onPressed: isLoading ? null : onVerifyCode,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify and Complete Setup'),
          ),
          VSpace.md,

          // Resend code button
          TextButton.icon(
            onPressed: isLoading ? null : onResendCode,
            icon: const Icon(Icons.refresh),
            label: const Text('Resend Code'),
          ),
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
