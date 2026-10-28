import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

/// Pre/post visit file phase for appointment attachments.
enum AppointmentFilePhase { preVisit, postVisit }

extension AppointmentFilePhaseExt on AppointmentFilePhase {
  String get label {
    switch (this) {
      case AppointmentFilePhase.preVisit:
        return 'Pre-visit';
      case AppointmentFilePhase.postVisit:
        return 'Post-visit';
    }
  }

  String get metadataValue {
    switch (this) {
      case AppointmentFilePhase.preVisit:
        return 'preVisit';
      case AppointmentFilePhase.postVisit:
        return 'postVisit';
    }
  }
}

/// Files section for appointment detail sheet with upload and file management.
class AppointmentDetailFilesSection extends StatefulWidget {
  const AppointmentDetailFilesSection({
    super.key,
    required this.appointment,
    required this.securityContext,
    required this.fileAttachmentRepository,
    required this.fileStorageService,
    this.client,
  });

  final Appointment appointment;
  final SecurityContext securityContext;
  final FileAttachmentRepository fileAttachmentRepository;
  final FileStorageService fileStorageService;
  final Client? client;

  @override
  State<AppointmentDetailFilesSection> createState() =>
      _AppointmentDetailFilesSectionState();
}

class _AppointmentDetailFilesSectionState
    extends State<AppointmentDetailFilesSection> {
  final _dateFormat = DateFormat.yMMMd().add_jm();

  bool _uploading = false;
  double? _progress;
  String? _error;
  FileCategory _uploadCategory = FileCategory.general;
  AppointmentFilePhase _uploadPhase = AppointmentFilePhase.preVisit;
  bool _staffOnly = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointment Files',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: Icon(_uploading ? Icons.hourglass_top : Icons.upload_file),
                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildUploadControls(theme),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_uploading && _progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: _progress),
              ),
            const SizedBox(height: 12),
            _buildFilesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadControls(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<FileCategory>(
          value: _uploadCategory,
          onChanged: _uploading
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _uploadCategory = value);
                },
          items: FileCategory.values
              .map(
                (category) => DropdownMenuItem<FileCategory>(
                  value: category,
                  child: Text(category.displayName),
                ),
              )
              .toList(),
        ),
        DropdownButton<AppointmentFilePhase>(
          value: _uploadPhase,
          onChanged: _uploading
              ? null
              : (phase) {
                  if (phase == null) return;
                  setState(() => _uploadPhase = phase);
                },
          items: AppointmentFilePhase.values
              .map(
                (phase) => DropdownMenuItem<AppointmentFilePhase>(
                  value: phase,
                  child: Text(phase.label),
                ),
              )
              .toList(),
        ),
        FilterChip(
          label: const Text('Staff only'),
          selected: _staffOnly,
          onSelected: (value) => setState(() => _staffOnly = value),
        ),
      ],
    );
  }

  Widget _buildFilesList() {
    if (widget.client == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Loading client files...'),
      );
    }

    return StreamBuilder<List<FileAttachment>>(
      stream: widget.fileAttachmentRepository.watchAppointmentAttachments(
        context: widget.securityContext,
        appointmentId: widget.appointment.id,
        clientId: widget.client!.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final files = snapshot.data!;
        if (files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  const Text('No files attached yet'),
                  const SizedBox(height: 4),
                  Text(
                    'Upload pre-visit or post-visit documents',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: files.map((file) => _buildFileItem(file)).toList(),
        );
      },
    );
  }

  Widget _buildFileItem(FileAttachment file) {
    final theme = Theme.of(context);
    final visitPhase = file.metadata['visitPhase'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          file.isImage ? Icons.image : Icons.insert_drive_file,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          file.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatSize(file.sizeBytes)} • ${_dateFormat.format(file.uploadedAt)}',
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(file.category.displayName),
                  visualDensity: VisualDensity.compact,
                ),
                if (visitPhase.isNotEmpty)
                  Chip(
                    label: Text(_phaseLabel(visitPhase)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isImage || file.isPdf)
              IconButton(
                tooltip: 'Preview',
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () => _previewFile(file),
              ),
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _downloadFile(file),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFile(file),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    if (widget.client == null) {
      setState(() => _error = 'Client not loaded');
      return;
    }

    setState(() {
      _error = null;
      _uploading = true;
      _progress = 0;
    });

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: FileStorageService.allowedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      setState(() {
        _uploading = false;
        _progress = null;
      });
      return;
    }

    try {
      final file = result.files.first;
      final uploaded = await widget.fileStorageService.uploadClientFile(
        context: widget.securityContext,
        file: file,
        clientId: widget.client!.id,
        appointmentId: widget.appointment.id,
        category: _uploadCategory,
        accessLevel:
            _staffOnly ? FileAccessLevel.staffOnly : FileAccessLevel.shared,
        extraMetadata: {'visitPhase': _uploadPhase.metadataValue},
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );
      await widget.fileAttachmentRepository.saveAttachment(
        context: widget.securityContext,
        attachment: uploaded,
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _progress = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed: $e';
        _uploading = false;
        _progress = null;
      });
    }
  }

  Future<void> _previewFile(FileAttachment attachment) async {
    final url = await widget.fileStorageService.getDownloadUrl(attachment);
    if (!mounted) return;

    if (attachment.isImage) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      );
      return;
    }

    if (attachment.isPdf) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() => _error = 'Unable to preview PDF');
        return;
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 420,
            height: 520,
            child: PdfPreview(
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              pdfFileName: attachment.name,
              build: (format) async => response.bodyBytes,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _downloadFile(FileAttachment attachment) async {
    try {
      final url = await widget.fileStorageService.getDownloadUrl(attachment);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch file');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to open file: $e');
    }
  }

  Future<void> _deleteFile(FileAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This will permanently delete "${attachment.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.fileAttachmentRepository.deleteAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );
      await widget.fileStorageService.deleteAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Delete failed: $e');
    }
  }

  String _phaseLabel(String? raw) {
    switch (raw) {
      case 'preVisit':
        return 'Pre-visit';
      case 'postVisit':
        return 'Post-visit';
      case null:
      case '':
        return 'General';
      default:
        return raw;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
