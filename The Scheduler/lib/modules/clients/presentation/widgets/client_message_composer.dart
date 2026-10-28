import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/communication_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/auth_state_service.dart';
import '../../../../data/models/client.dart';
import '../../../../data/repositories/clients_repository.dart';

/// Bottom sheet for quick email/SMS composition that also logs last contact.
Future<void> showClientMessageComposer({
  required BuildContext context,
  required Client client,
  required MessageChannel channel,
  required ClientsRepository clientsRepository,
  required AuthStateService authService,
  required WidgetRef ref,
}) async {
  final messageController = TextEditingController(
    text: 'Hi ${client.firstName},\n\n',
  );
  final appConfig = ref.read(appConfigProvider);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            channel == MessageChannel.email ? 'Send Email' : 'Send SMS',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: messageController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write a quick note to the client',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                final ctx = await authService.getCurrentSecurityContext();
                if (ctx == null) return;

                final updated = client.copyWith(
                  lastContactDate: DateTime.now(),
                  notes: client.notes == null
                      ? messageController.text
                      : '${client.notes}\n---\n${messageController.text}',
                );
                await clientsRepository.upsertClient(
                  context: ctx,
                  client: updated,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${channel == MessageChannel.email ? 'Email' : 'SMS'} logged for ${client.fullName} (${appConfig.branding.productName})',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ),
        ],
      ),
    ),
  );
}
