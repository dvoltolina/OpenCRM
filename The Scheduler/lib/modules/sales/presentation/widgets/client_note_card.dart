import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client_note.dart';

class ClientNoteCard extends StatelessWidget {
  const ClientNoteCard({super.key, required this.note});

  final ClientNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('MMM d, yyyy').format(note.createdAt);
    final iconData = _iconForType(note.type);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18, color: theme.colorScheme.primary),
              HSpace.xs,
              Text(
                _labelForType(note.type),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          VSpace.xs,
          Text(
            note.content,
            style: theme.textTheme.bodyMedium,
          ),
          VSpace.xs,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- ${note.createdByName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(NoteType type) {
    switch (type) {
      case NoteType.call:
        return Icons.call_outlined;
      case NoteType.meeting:
        return Icons.event_note_outlined;
      case NoteType.email:
        return Icons.mail_outline;
      case NoteType.followUp:
        return Icons.check_circle_outline;
      case NoteType.other:
        return Icons.note_alt_outlined;
    }
  }

  String _labelForType(NoteType type) {
    switch (type) {
      case NoteType.call:
        return 'Call';
      case NoteType.meeting:
        return 'Meeting';
      case NoteType.email:
        return 'Email';
      case NoteType.followUp:
        return 'Follow-up';
      case NoteType.other:
        return 'Other';
    }
  }
}
