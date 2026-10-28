import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

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

/// Bottom sheet that surfaces appointment-level attachments.
class AppointmentFilesSheet extends StatefulWidget {
  const AppointmentFilesSheet({
    super.key,
    required this.securityContext,
    required this.appointment,
    required this.client,
    required this.repository,
    this.storageService,
  });

  final SecurityContext securityContext;
  final Appointment appointment;
  final Client client;
  final FileAttachmentRepository repository;
  final FileStorageService? storageService;

  @override
  State<AppointmentFilesSheet> createState() => _AppointmentFilesSheetState();
}

class _AppointmentFilesSheetState extends State<AppointmentFilesSheet> {
  late final FileStorageService _storage;
  final _dateFormat = DateFormat.yMMMd().add_jm();

  bool _uploading = false;
  double? _progress;
  String? _error;
  FileCategory _category = FileCategory.general;
  AppointmentFilePhase _phase = AppointmentFilePhase.preVisit;
  bool _staffOnly = true;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? FileStorageService();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildUploadControls(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_uploading && _progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<FileAttachment>>(
                stream: widget.repository.watchAppointmentAttachments(
                  context: widget.securityContext,
                  appointmentId: widget.appointment.id,
                  clientId: widget.client.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(SecureErrorHandler.loadingFailed),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final files = snapshot.data!;
                  if (files.isEmpty) {
                    return Center(
                      child: Text(
                        'No files attached to this appointment yet.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, unused) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return ListTile(
                        leading: Icon(
                          file.isImage ? Icons.image : Icons.insert_drive_file,
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
                                Chip(
                                  label: Text(_phaseLabel(
                                    file.metadata['visitPhase'] as String?,
                                  )),
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Files for ${widget.appointment.serviceType ?? 'Appointment'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_dateFormat.format(widget.appointment.startTime)} • ${widget.client.fullName}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildUploadControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<FileCategory>(
          value: _category,
          onChanged: _uploading
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _category = value);
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
          value: _phase,
          onChanged: _uploading
              ? null
              : (phase) {
                  if (phase == null) return;
                  setState(() => _phase = phase);
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
        FilledButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: Icon(_uploading ? Icons.hourglass_top : Icons.upload_file),
          label: Text(_uploading ? 'Uploading...' : 'Upload file'),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
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
      final uploaded = await _storage.uploadClientFile(
        context: widget.securityContext,
        file: file,
        clientId: widget.client.id,
        appointmentId: widget.appointment.id,
        category: _category,
        accessLevel:
            _staffOnly ? FileAccessLevel.staffOnly : FileAccessLevel.shared,
        extraMetadata: {'visitPhase': _phase.metadataValue},
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );
      await widget.repository.saveAttachment(
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
        _error = SecureErrorHandler.uploadFailed;
        _uploading = false;
        _progress = null;
      });
    }
  }

  Future<void> _previewFile(FileAttachment attachment) async {
    final url = await _storage.getDownloadUrl(attachment);
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
        setState(() {
          _error = 'Unable to preview PDF';
        });
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
      final url = await _storage.getDownloadUrl(attachment);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch file');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to open file. Please try again.';
      });
    }
  }

  Future<void> _deleteFile(FileAttachment attachment) async {
    try {
      await widget.repository.deleteAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );
      await _storage.deleteAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SecureErrorHandler.deleteFailed;
      });
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
