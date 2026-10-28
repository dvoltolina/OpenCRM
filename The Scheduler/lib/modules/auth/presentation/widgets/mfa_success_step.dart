import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

/// Success step shown after MFA enrollment is complete.
/// HIPAA Compliance: No PHI in logs or error messages.
class MfaSuccessStep extends StatelessWidget {
  const MfaSuccessStep({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        VSpace.lg,
        Text(
          'Two-Factor Authentication Enabled!',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.md,
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    HSpace.sm,
                    Expanded(
                      child: Text(
                        'Your account is now secured',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                VSpace.sm,
                Text(
                  'You\'ll need to enter a verification code when signing in.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        VSpace.xl,
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue to Dashboard'),
        ),
      ],
    );
  }
}
