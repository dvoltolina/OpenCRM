import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';

class SalesClientCard extends StatelessWidget {
  const SalesClientCard({
    super.key,
    required this.client,
    this.onTap,
  });

  final Client client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastContact = client.lastContactDate != null
        ? DateFormat('MMM d').format(client.lastContactDate!)
        : 'No recent activity';
    final company = _companyName(client);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            child: Text(client.initials),
          ),
          HSpace.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (company != null)
                  Text(
                    company,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  'Last contact: $lastContact',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  String? _companyName(Client client) {
    final company = client.preferences['company'] ?? client.customFields['company'];
    if (company is String && company.isNotEmpty) {
      return company;
    }
    return null;
  }
}
