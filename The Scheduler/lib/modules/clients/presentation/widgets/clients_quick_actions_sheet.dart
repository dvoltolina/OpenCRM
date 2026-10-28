import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/communication_config.dart';
import '../../../../core/ui/animations.dart';
import '../../../../data/models/client.dart';
import '../../../../data/repositories/clients_repository.dart';
import '../../../booking/presentation/booking_page.dart';
import 'client_message_composer.dart';

/// Quick actions bottom sheet for client operations
void showClientsQuickActionsSheet({
  required BuildContext context,
  required Client client,
  required ClientsRepository clientsRepository,
  required dynamic authService,
  required WidgetRef ref,
  required VoidCallback onNavigateToDetail,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => ClientsQuickActionsSheet(
      client: client,
      clientsRepository: clientsRepository,
      authService: authService,
      ref: ref,
      onNavigateToDetail: onNavigateToDetail,
    ),
  );
}

class ClientsQuickActionsSheet extends StatelessWidget {
  final Client client;
  final ClientsRepository clientsRepository;
  final dynamic authService;
  final WidgetRef ref;
  final VoidCallback onNavigateToDetail;

  const ClientsQuickActionsSheet({
    super.key,
    required this.client,
    required this.clientsRepository,
    required this.authService,
    required this.ref,
    required this.onNavigateToDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Book Appointment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                SlidePageRoute(
                  page: const BookingPage(),
                  direction: AxisDirection.left,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Send Email'),
            onTap: () {
              Navigator.pop(context);
              showClientMessageComposer(
                context: context,
                client: client,
                channel: MessageChannel.email,
                clientsRepository: clientsRepository,
                authService: authService,
                ref: ref,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Call Client'),
            enabled: client.hasPhone,
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: client.phone ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Details'),
            onTap: () {
              Navigator.pop(context);
              onNavigateToDetail();
            },
          ),
        ],
      ),
    );
  }
}
