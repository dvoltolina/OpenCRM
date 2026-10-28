import 'package:flutter/material.dart';
import '../../../../core/config/communication_config.dart';

/// Dialog for editing message templates.
/// Modern design with rounded corners and sophisticated blue styling.
class TemplateEditorDialog extends StatefulWidget {
  const TemplateEditorDialog({
    super.key,
    required this.template,
    required this.onSave,
  });

  final MessageTemplate template;
  final Future<void> Function(MessageTemplate) onSave;

  @override
  State<TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<TemplateEditorDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.template.subject);
    _bodyController = TextEditingController(text: widget.template.body);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmail = widget.template.channel == MessageChannel.email;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
          minHeight: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isEmail ? Icons.email_outlined : Icons.sms_outlined,
                    size: 28,
                    color: const Color(0xFF1A365D),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit ${isEmail ? 'Email' : 'SMS'} Template',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF1A365D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getTemplateTypeName(widget.template.type),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Variables help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Variables',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.template.variables
                          .map(
                            (v) => Chip(
                              label: Text(
                                '{{$v}}',
                                style: theme.textTheme.labelSmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subject field (email only)
              if (isEmail) ...[
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject Line',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Enter email subject...',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Body field
              Flexible(
                child: TextField(
                  controller: _bodyController,
                  minLines: isEmail ? 8 : 4,
                  maxLines: isEmail ? 15 : 6,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: isEmail ? 'Email Body' : 'SMS Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: isEmail
                        ? 'Enter email body...\n\nUse {{variables}} for dynamic content.'
                        : 'Enter SMS message (160 chars recommended)...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Character count for SMS
              if (!isEmail)
                Text(
                  '${_bodyController.text.length} characters '
                  '(~${(_bodyController.text.length / 160).ceil()} segment${_bodyController.text.length > 160 ? 's' : ''})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _bodyController.text.length > 160
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.end,
                ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Template'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final updatedTemplate = widget.template.copyWith(
      subject: _subjectController.text,
      body: _bodyController.text,
    );

    try {
      await widget.onSave(updatedTemplate);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save template: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getTemplateTypeName(MessageType type) {
    switch (type) {
      case MessageType.bookingConfirmation:
        return 'Booking Confirmation';
      case MessageType.reminder24h:
        return '24-Hour Reminder';
      case MessageType.reminder1h:
        return '1-Hour Reminder';
      case MessageType.cancellationNotice:
        return 'Cancellation Notice';
      case MessageType.followUp:
        return 'Follow-up';
      case MessageType.waitlistNotification:
        return 'Waitlist Notification';
      case MessageType.rescheduleNotice:
        return 'Reschedule Notice';
      case MessageType.paymentReminder:
        return 'Payment Reminder';
    }
  }
}
