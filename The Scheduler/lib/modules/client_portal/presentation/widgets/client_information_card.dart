import 'package:flutter/material.dart';

import '../../../../data/models/client.dart';
import 'appointment_detail_row.dart';

/// Card displaying client information.
class ClientInformationCard extends StatelessWidget {
  const ClientInformationCard({
    required this.client,
    super.key,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AppointmentDetailRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: client.fullName,
            ),
            if (client.email != null) ...[
              const Divider(height: 24),
              AppointmentDetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: client.email!,
              ),
            ],
            if (client.phone != null) ...[
              const Divider(height: 24),
              AppointmentDetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: client.phone!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
