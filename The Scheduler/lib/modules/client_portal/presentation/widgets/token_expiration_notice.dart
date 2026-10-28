import 'package:flutter/material.dart';

import '../../../../data/models/magic_link_token.dart';

/// Notice displaying token expiration information.
class TokenExpirationNotice extends StatelessWidget {
  const TokenExpirationNotice({
    required this.token,
    super.key,
  });

  final MagicLinkToken token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This link ${token.expirationDisplay.toLowerCase()}. '
              'You can request a new link via email if needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
