import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact action buttons (call, text, navigate).
class ClientContactActions extends StatelessWidget {
  const ClientContactActions({
    super.key,
    this.phone,
    this.address,
  });

  final String? phone;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.call),
          tooltip: 'Call',
          color: colorScheme.primary,
          onPressed:
              phone != null && phone!.isNotEmpty ? () => _call(phone!) : null,
        ),
        IconButton(
          icon: const Icon(Icons.sms),
          tooltip: 'Text',
          color: colorScheme.primary,
          onPressed:
              phone != null && phone!.isNotEmpty ? () => _text(phone!) : null,
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: 'Navigate',
          color: colorScheme.primary,
          onPressed: address != null && address!.isNotEmpty
              ? () => _navigate(address!)
              : null,
        ),
      ],
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _text(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    await launchUrl(uri);
  }

  Future<void> _navigate(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
