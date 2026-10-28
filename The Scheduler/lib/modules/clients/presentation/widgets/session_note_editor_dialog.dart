import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/encryption_service.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/models/session_note.dart';
import '../../../../data/repositories/session_notes_repository.dart';
import 'session_note_templates.dart';

enum SessionNoteEditorStatus { saved, deleted }

class SessionNoteEditorResult {
  const SessionNoteEditorResult({required this.status, this.note});

  final SessionNoteEditorStatus status;
  final SessionNote? note;
}

/// Dialog used for both creating and editing provider-only session notes.
class SessionNoteEditorDialog extends StatefulWidget {
  const SessionNoteEditorDialog({
    super.key,
    required this.securityContext,
    required this.repository,
    required this.encryptionService,
    required this.client,
    required this.appointments,
    this.initialAppointmentId,
    this.initialNote,
  });

  final SecurityContext securityContext;
  final SessionNotesRepository repository;
  final EncryptionService encryptionService;
  final Client client;
  final List<Appointment> appointments;
  final String? initialAppointmentId;
  final SessionNote? initialNote;

  @override
  State<SessionNoteEditorDialog> createState() =>
      _SessionNoteEditorDialogState();
}

class _SessionNoteEditorDialogState extends State<SessionNoteEditorDialog> {
  late SessionNoteType _selectedType;
  late SessionNoteVisibility _visibility;
  late TextEditingController _contentController;
  late String? _selectedAppointmentId;
  String? _selectedTemplateId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialNote?.type ?? SessionNoteType.soap;
    _visibility =
        widget.initialNote?.visibility ?? SessionNoteVisibility.providerOnly;
    _contentController = TextEditingController(
      text: widget.initialNote?.decryptedContent ?? '',
    );
    _selectedAppointmentId =
        widget.initialNote?.appointmentId ??
        widget.initialAppointmentId ??
        (widget.appointments.isNotEmpty ? widget.appointments.first.id : null);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialNote != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Session Note' : 'New Session Note'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppointmentDropdown(),
              const SizedBox(height: 16),
              _buildTypeDropdown(),
              const SizedBox(height: 12),
              _buildTemplateChips(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                minLines: 8,
                maxLines: 16,
                decoration: InputDecoration(
                  labelText: 'Session note',
                  alignLabelWithHint: true,
                  helperText:
                      'Detailed, provider-only notes are encrypted before syncing.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Provider-only visibility'),
                subtitle: const Text('Clients never see encrypted notes'),
                value: _visibility == SessionNoteVisibility.providerOnly,
                onChanged: (value) {
                  setState(() {
                    _visibility = value
                        ? SessionNoteVisibility.providerOnly
                        : SessionNoteVisibility.businessOnly;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isEditing)
          TextButton(
            onPressed: _isSaving ? null : _handleDelete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        FilledButton(
          onPressed: _canSave ? _handleSave : null,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  bool get _canSave {
    return !_isSaving &&
        _selectedAppointmentId != null &&
        _contentController.text.trim().isNotEmpty;
  }

  Widget _buildAppointmentDropdown() {
    if (widget.appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No appointments found for this client. Add an appointment first.',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedAppointmentId,
      decoration: const InputDecoration(
        labelText: 'Linked appointment',
        border: OutlineInputBorder(),
      ),
      items: widget.appointments
          .map(
            (appointment) => DropdownMenuItem(
              value: appointment.id,
              child: Text(_formatAppointmentLabel(appointment)),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() {
        _selectedAppointmentId = value;
      }),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<SessionNoteType>(
      initialValue: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Note type',
        border: OutlineInputBorder(),
      ),
      items: SessionNoteType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedType = value;
          _selectedTemplateId = null;
        });
      },
    );
  }

  Widget _buildTemplateChips() {
    final templatesForType = defaultSessionNoteTemplates
        .where((template) => template.type == _selectedType)
        .toList();

    if (templatesForType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Templates', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templatesForType.map((template) {
            final selected = _selectedTemplateId == template.id;
            return ChoiceChip(
              label: Text(template.title),
              selected: selected,
              onSelected: (_) => _applyTemplate(template),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyTemplate(SessionNoteTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      if (_contentController.text.trim().isEmpty) {
        _contentController.text = template.body;
      } else {
        _contentController.text =
            '${_contentController.text.trim()}\n\n${template.body}';
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    final appointment = _findAppointment(_selectedAppointmentId);
    if (appointment == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an appointment.')),
        );
      }
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final content = _contentController.text.trim();
      SessionNote note;
      if (widget.initialNote == null) {
        note = await widget.repository.createNote(
          context: widget.securityContext,
          encryptionService: widget.encryptionService,
          clientId: widget.client.id,
          appointmentId: appointment.id,
          providerId: appointment.providerId,
          type: _selectedType,
          content: content,
          templateId: _selectedTemplateId,
          visibility: _visibility,
        );
      } else {
        note = await widget.repository.updateNote(
          context: widget.securityContext,
          encryptionService: widget.encryptionService,
          noteId: widget.initialNote!.id,
          content: content,
          type: _selectedType,
          visibility: _visibility,
          templateId: _selectedTemplateId,
          appointmentId: appointment.id,
          providerId: appointment.providerId,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(
          SessionNoteEditorResult(
            status: SessionNoteEditorStatus.saved,
            note: note,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(SecureErrorHandler.saveFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session note?'),
        content: const Text(
          'This note will be permanently removed. The deletion action is logged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.initialNote == null) return;

    setState(() {
      _isSaving = true;
    });
    try {
      await widget.repository.deleteNote(
        context: widget.securityContext,
        noteId: widget.initialNote!.id,
      );
      if (mounted) {
        Navigator.of(context).pop(
          const SessionNoteEditorResult(
            status: SessionNoteEditorStatus.deleted,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(SecureErrorHandler.deleteFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatAppointmentLabel(Appointment appointment) {
    final formatter = DateFormat('MMM d, y – h:mm a');
    final date = formatter.format(appointment.startTime);
    return '${appointment.serviceId} • $date';
  }

  Appointment? _findAppointment(String? id) {
    if (id == null) return null;
    for (final appointment in widget.appointments) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }
}
