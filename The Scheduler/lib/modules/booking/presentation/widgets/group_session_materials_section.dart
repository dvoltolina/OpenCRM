import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

/// Shared section for uploading/downloading group session materials with premium styling.
class GroupSessionMaterialsSection extends ConsumerStatefulWidget {
  const GroupSessionMaterialsSection({
    super.key,
    required this.securityContext,
    required this.session,
    required this.repository,
    this.storageService,
    this.canUpload = false,
    this.canDelete = false,
    this.title = 'Session materials',
    this.emptyMessage = 'No materials have been added yet.',
    this.wrapInCard = true,
  });

  final SecurityContext securityContext;
  final Appointment session;
  final FileAttachmentRepository repository;
  final FileStorageService? storageService;
  final bool canUpload;
  final bool canDelete;
  final String title;
  final String emptyMessage;
  final bool wrapInCard;

  @override
  ConsumerState<GroupSessionMaterialsSection> createState() =>
      _GroupSessionMaterialsSectionState();
}

class _GroupSessionMaterialsSectionState
    extends ConsumerState<GroupSessionMaterialsSection> {
  late final FileStorageService _storage;
  final _dateFormat = DateFormat.yMMMd().add_jm();

  bool _uploading = false;
  double? _progress;
  String? _error;
  FileCategory _category = FileCategory.general;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? FileStorageService();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.canUpload)
                GradientButton(
                  onPressed: _uploading ? null : _pickAndUpload,
                  isLoading: _uploading,
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_uploading) const Icon(Icons.upload_file, size: 18),
                      if (!_uploading) const SizedBox(width: 6),
                      Text(_uploading ? 'Uploading...' : 'Upload'),
                    ],
                  ),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_uploading && _progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(branding.accentColor),
                  minHeight: 8,
                ),
              ),
            ),
          if (widget.canUpload)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<FileCategory>(
                  value: _category,
                  isExpanded: true,
                  underline: const SizedBox(),
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
              ),
            ),
          const SizedBox(height: 8),
          StreamBuilder<List<FileAttachment>>(
            stream: widget.repository.watchAppointmentAttachments(
              context: widget.securityContext,
              appointmentId: widget.session.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error loading materials: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                );
              }
              final files = snapshot.data!;
              if (files.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(widget.emptyMessage),
                );
              }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: files.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      file.isImage ? Icons.image : Icons.insert_drive_file,
                    ),
                    title: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_dateFormat.format(file.uploadedAt)} • ${_formatSize(file.sizeBytes)}',
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
                        if (widget.canDelete)
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
        ],
      ),
    );

    if (!widget.wrapInCard) {
      return content;
    }

    return content;
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
      final uploaded = await _storage.uploadAppointmentMaterial(
        context: widget.securityContext,
        file: file,
        appointmentId: widget.session.id,
        category: _category,
        accessLevel: FileAccessLevel.shared,
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
      final safeMessage = SafeErrorHandler.handle(e, context: 'uploading file');
      setState(() {
        _error = safeMessage;
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
        setState(() => _error = 'Unable to preview PDF');
        return;
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
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
      if (!mounted) return;
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch file');
      }
    } catch (e) {
      if (!mounted) return;
      final safeMessage = SafeErrorHandler.handle(e, context: 'opening file');
      setState(() => _error = safeMessage);
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
      final safeMessage = SafeErrorHandler.handle(e, context: 'deleting file');
      setState(() => _error = safeMessage);
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
