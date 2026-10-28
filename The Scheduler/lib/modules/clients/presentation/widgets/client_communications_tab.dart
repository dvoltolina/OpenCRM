import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/communication_config.dart';
import '../../../../data/repositories/communication_repository.dart';

class ClientCommunicationsTab extends StatelessWidget {
  const ClientCommunicationsTab({
    super.key,
    required this.communicationRepository,
    required this.clientId,
  });

  final CommunicationRepository communicationRepository;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MessageHistory>>(
      future: communicationRepository.getMessageHistory(clientId: clientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                const Text('No communications yet'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: messages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final message = messages[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    message.channel == MessageChannel.email
                        ? Icons.email
                        : Icons.sms,
                  ),
                ),
                title: Text(
                  message.subject.isNotEmpty
                      ? message.subject
                      : message.messageType.name,
                ),
                subtitle: Text(
                  DateFormat('MMM d, y - h:mm a').format(message.timestamp),
                ),
                trailing: Chip(
                  label: Text(message.status.name),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
