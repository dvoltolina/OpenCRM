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
import '../../../../core/ui/state_widgets.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

/// Staff-facing panel to manage client file attachments with previews.
class ClientFilesPanel extends ConsumerStatefulWidget {
  const ClientFilesPanel({
    super.key,
    required this.securityContext,
    required this.clientId,
    required this.fileAttachmentRepository,
    this.fileStorageService,
  });

  final SecurityContext securityContext;
  final String clientId;
  final FileAttachmentRepository fileAttachmentRepository;
  final FileStorageService? fileStorageService;

  @override
  ConsumerState<ClientFilesPanel> createState() => _ClientFilesPanelState();
}

class _ClientFilesPanelState extends ConsumerState<ClientFilesPanel> {
  late final FileStorageService _storage;
  final _uploaderNames = <String, String>{};
  final _dateFormat = DateFormat.yMMMd().add_jm();

  bool _uploading = false;
  double? _progress;
  String? _error;
  FileCategory? _filterCategory;
  FileCategory _uploadCategory = FileCategory.general;
  bool _staffOnly = true;

  @override
  void initState() {
    super.initState();
    _storage = widget.fileStorageService ?? FileStorageService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FileAttachment>>(
      stream: widget.fileAttachmentRepository.watchClientAttachments(
        context: widget.securityContext,
        clientId: widget.clientId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget(
            error: snapshot.error!,
            message: 'Unable to load client files',
          );
        }

        if (!snapshot.hasData) {
          return const LoadingStateWidget(
            message: 'Loading client files...',
          );
        }

        final files = snapshot.data!;
        _primeUploaderNames(files);
        final visibleFiles = _filterCategory == null
            ? files
            : files.where((file) => file.category == _filterCategory).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeader(context),
            ),
            _buildCategoryFilters(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (_uploading && _progress != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(value: _progress),
              ),
            if (visibleFiles.isEmpty)
              Expanded(
                child: EmptyStateWidget(
                  icon: Icons.folder_open_outlined,
                  title: _filterCategory == null
                      ? 'No files uploaded yet'
                      : 'No ${_filterCategory!.displayName} files',
                  subtitle: _filterCategory == null
                      ? 'Upload files to share documents, images, and forms with this client'
                      : 'Try selecting a different category or upload a new file',
                  actionLabel: 'Upload File',
                  onAction: _uploading ? null : _pickAndUpload,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleFiles.length,
                  separatorBuilder: (_, unused) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = visibleFiles[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(file.isImage
                            ? Icons.image
                            : Icons.insert_drive_file),
                        title: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _buildMetadataColumn(file),
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
                              onPressed: () => _confirmDelete(file),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Client files',
                style: theme.textTheme.titleMedium,
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
        Wrap(
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
                      child: Text('Upload as ${category.displayName}'),
                    ),
                  )
                  .toList(),
            ),
            FilterChip(
              label: const Text('Staff only'),
              selected: _staffOnly,
              onSelected: (value) {
                setState(() => _staffOnly = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All categories'),
            selected: _filterCategory == null,
            onSelected: (selected) {
              if (selected) {
                setState(() => _filterCategory = null);
              }
            },
          ),
          const SizedBox(width: 8),
          ...FileCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.displayName),
                selected: _filterCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _filterCategory = selected ? category : null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataColumn(FileAttachment file) {
    final theme = Theme.of(context);
    final uploader =
        _uploaderNames[file.uploaderId] ?? file.uploaderName ?? 'Unknown';
    final visitPhase = file.metadata['visitPhase'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_formatSize(file.sizeBytes)} • ${_dateFormat.format(file.uploadedAt)}',
        ),
        Text(
          'Uploaded by $uploader',
          style: theme.textTheme.bodySmall,
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
              label: Text(_accessLabel(file.accessLevel)),
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
        clientId: widget.clientId,
        category: _uploadCategory,
        accessLevel:
            _staffOnly ? FileAccessLevel.staffOnly : FileAccessLevel.shared,
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

  Future<void> _confirmDelete(FileAttachment attachment) async {
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

    setState(() => _error = null);
    try {
      await widget.fileAttachmentRepository.deleteAttachment(
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

  void _primeUploaderNames(List<FileAttachment> files) {
    for (final attachment in files) {
      final uploaderId = attachment.uploaderId;
      if (uploaderId.isEmpty || _uploaderNames.containsKey(uploaderId)) {
        continue;
      }
      unawaited(_loadUploaderName(uploaderId));
    }
  }

  Future<void> _loadUploaderName(String userId) async {
    try {
      final profile = await ref.read(userRepositoryProvider).getUserProfile(userId);
      if (!mounted) return;
      setState(() {
        _uploaderNames[userId] = profile?.displayName ?? 'Unknown';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploaderNames[userId] = 'Unknown';
      });
    }
  }

  String _accessLabel(FileAccessLevel level) {
    switch (level) {
      case FileAccessLevel.clientOnly:
        return 'Shared with client';
      case FileAccessLevel.staffOnly:
        return 'Staff only';
      case FileAccessLevel.adminOnly:
        return 'Admins only';
      case FileAccessLevel.shared:
        return 'All staff';
    }
  }

  String _phaseLabel(String raw) {
    switch (raw) {
      case 'preVisit':
        return 'Pre-visit';
      case 'postVisit':
        return 'Post-visit';
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
