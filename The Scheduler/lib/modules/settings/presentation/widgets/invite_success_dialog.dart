import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteSuccessDialog extends StatelessWidget {
  const InviteSuccessDialog({
    super.key,
    required this.code,
    required this.link,
    required this.roleLabel,
    required this.expiresAt,
    required this.remainingUses,
  });

  final String code;
  final String link;
  final String roleLabel;
  final DateTime expiresAt;
  final int remainingUses;

  @override
  Widget build(BuildContext context) {
    final expiresText = expiresAt.toLocal().toIso8601String().split('T').first;

    return AlertDialog(
      title: const Text('Invite Created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share this code with your new team member:'),
          const SizedBox(height: 8),
          _copyRow(
            context,
            label: code,
            onCopy: () => Clipboard.setData(ClipboardData(text: code)),
          ),
          const SizedBox(height: 12),
          const Text('Or share this link:'),
          const SizedBox(height: 8),
          _copyRow(
            context,
            label: link,
            onCopy: () => Clipboard.setData(ClipboardData(text: link)),
          ),
          const SizedBox(height: 12),
          Text('Role: $roleLabel'),
          Text('Expires: $expiresText'),
          Text('Uses remaining: $remainingUses'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _launch('mailto:?subject=Team%20Invite&body=$link'),
          child: const Text('Share via Email'),
        ),
        TextButton(
          onPressed: () => _launch('sms:?body=$link'),
          child: const Text('Share via SMS'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _copyRow(
    BuildContext context, {
    required String label,
    required VoidCallback onCopy,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
