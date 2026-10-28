import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/safe_error_handler.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

/// Customer-facing attachment picker that uploads directly to Firebase Storage.
class IntakeAttachmentPicker extends StatefulWidget {
  const IntakeAttachmentPicker({
    super.key,
    required this.securityContext,
    required this.clientId,
    required this.templateId,
    required this.attachments,
    required this.onChanged,
    this.appointmentId,
    this.storageService,
    this.attachmentRepository,
    this.enabled = true,
    this.label = 'Attachments (optional)',
    this.allowMultiple = true,
    this.allowedExtensions,
    this.extraMetadata,
    this.maxFiles,
  });

  final SecurityContext securityContext;
  final String clientId;
  final String templateId;
  final String? appointmentId;
  final List<FileAttachment> attachments;
  final ValueChanged<List<FileAttachment>> onChanged;
  final FileStorageService? storageService;
  final FileAttachmentRepository? attachmentRepository;
  final bool enabled;
  final String label;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final Map<String, String>? extraMetadata;
  final int? maxFiles;

  @override
  State<IntakeAttachmentPicker> createState() => _IntakeAttachmentPickerState();
}

class _IntakeAttachmentPickerState extends State<IntakeAttachmentPicker> {
  late FileStorageService _storage;
  FileAttachmentRepository? _repository;
  late List<FileAttachment> _attachments;
  double? _uploadProgress;
  String? _error;
  String? _busyAttachmentId;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? FileStorageService();
    _repository = widget.attachmentRepository;
    _attachments = List<FileAttachment>.from(widget.attachments);
  }

  @override
  void didUpdateWidget(covariant IntakeAttachmentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachments != widget.attachments) {
      _attachments = List<FileAttachment>.from(widget.attachments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_uploading && _uploadProgress != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(value: _uploadProgress),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final attachment in _attachments)
              InputChip(
                avatar: const Icon(Icons.attachment),
                label: Text(
                  '${attachment.name} • ${_formatSize(attachment.sizeBytes)}',
                  overflow: TextOverflow.ellipsis,
                ),
                deleteIcon: const Icon(Icons.close),
                onDeleted: widget.enabled && _busyAttachmentId == null
                    ? () => _removeAttachment(attachment)
                    : null,
              ),
            ActionChip(
              avatar: const Icon(Icons.upload_file),
              label: Text(
                _canAddMore
                    ? (widget.enabled ? 'Add document' : 'Attachments locked')
                    : 'Limit reached',
              ),
              onPressed: widget.enabled && !_uploading && _canAddMore
                  ? _addAttachment
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _buildHelperText(),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  bool get _canAddMore {
    if (!widget.allowMultiple && _attachments.isNotEmpty) {
      return false;
    }
    if (widget.maxFiles != null && _attachments.length >= widget.maxFiles!) {
      return false;
    }
    return true;
  }

  Future<void> _addAttachment() async {
    setState(() {
      _error = null;
    });

    if (!_canAddMore) {
      setState(() {
        _error = widget.maxFiles != null
            ? 'Maximum ${widget.maxFiles} file(s) allowed.'
            : 'Only one file allowed for this question.';
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions:
          widget.allowedExtensions ?? FileStorageService.allowedExtensions,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final uploaded = await _storage.uploadIntakeAttachment(
        context: widget.securityContext,
        file: file,
        clientId: widget.clientId,
        intakeFormId: widget.templateId,
        appointmentId: widget.appointmentId,
        extraMetadata: widget.extraMetadata,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );
      if (_repository != null) {
        await _repository!.saveAttachment(
          context: widget.securityContext,
          attachment: uploaded,
        );
      }
      if (!mounted) return;
      final updated = List<FileAttachment>.from(_attachments)..add(uploaded);
      setState(() {
        _attachments = updated;
        _uploadProgress = null;
        _uploading = false;
      });
      widget.onChanged(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SafeErrorHandler.handle(e);
        _uploadProgress = null;
        _uploading = false;
      });
    }
  }

  Future<void> _removeAttachment(FileAttachment attachment) async {
    setState(() {
      _error = null;
      _busyAttachmentId = attachment.id;
    });
    try {
      await _storage.deleteAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );
      if (_repository != null) {
        await _repository!.deleteAttachment(
          context: widget.securityContext,
          attachment: attachment,
        );
      }
      if (!mounted) return;
      final updated =
          _attachments.where((item) => item.id != attachment.id).toList();
      setState(() {
        _attachments = updated;
        _busyAttachmentId = null;
      });
      widget.onChanged(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SafeErrorHandler.handle(e);
        _busyAttachmentId = null;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _buildHelperText() {
    final extensions =
        (widget.allowedExtensions ?? FileStorageService.allowedExtensions)
            .map((e) => e.toUpperCase())
            .join(', ');
    final buffer = StringBuffer('Allowed: $extensions • Max 10MB per file');
    if (widget.maxFiles != null) {
      buffer.write(' • Max ${widget.maxFiles} file(s)');
    } else if (!widget.allowMultiple) {
      buffer.write(' • Single file only');
    }
    return buffer.toString();
  }
}
