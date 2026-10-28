import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

class IntegrationTile extends StatelessWidget {
  const IntegrationTile({
    super.key,
    required this.title,
    required this.description,
    required this.isConnected,
    this.onConnect,
    this.onDisconnect,
  });

  final String title;
  final String description;
  final bool isConnected;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                ),
                VSpace.xxs,
                Text(
                  isConnected ? 'Connected' : 'Not connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isConnected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            FilledButton(
              onPressed: onConnect,
              child: Text(isConnected ? 'Reconnect' : 'Connect'),
            ),
          ],
        ),
        VSpace.xs,
        Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        if (isConnected && onDisconnect != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDisconnect,
              child: const Text('Disconnect'),
            ),
          ),
      ],
    );
  }
}
