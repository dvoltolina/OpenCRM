import 'package:flutter/material.dart';

import '../../../../data/models/client.dart';

/// Client information card for appointment detail sheet.
class AppointmentDetailClientCard extends StatelessWidget {
  const AppointmentDetailClientCard({
    super.key,
    required this.client,
    required this.isLoading,
    this.error,
  });

  final Client? client;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Text(error!, style: TextStyle(color: theme.colorScheme.error))
                : client != null
                    ? _buildClientInfo(theme, client!)
                    : const Text('Client not found'),
      ),
    );
  }

  Widget _buildClientInfo(ThemeData theme, Client client) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(client.lifecycleColorValue).withValues(alpha: 0.2),
          child: Text(
            client.initials,
            style: TextStyle(
              color: Color(client.lifecycleColorValue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (client.email != null && client.email!.isNotEmpty)
                Text(
                  client.email!,
                  style: theme.textTheme.bodySmall,
                ),
              if (client.phone != null && client.phone!.isNotEmpty)
                Text(
                  client.phone!,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(client.lifecycleColorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            client.lifecycleDisplay,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Color(client.lifecycleColorValue),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
