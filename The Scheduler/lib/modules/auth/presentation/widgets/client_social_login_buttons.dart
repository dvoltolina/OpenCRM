import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

enum ClientSocialProvider { google, apple }

class ClientSocialLoginButtons extends StatelessWidget {
  const ClientSocialLoginButtons({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final ValueChanged<ClientSocialProvider> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Or continue with',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.sm,
        FilledButton.icon(
          onPressed:
              isLoading ? null : () => onTap(ClientSocialProvider.google),
          icon: const Icon(Icons.login),
          label: const Text('Continue with Google'),
        ),
        VSpace.sm,
        FilledButton.icon(
          onPressed: isLoading ? null : () => onTap(ClientSocialProvider.apple),
          icon: const Icon(Icons.apple),
          label: const Text('Continue with Apple'),
        ),
        if (isLoading) ...[
          VSpace.sm,
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
