import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';

/// Allows clients to upload insurance/ID documents from the portal.
/// Saves metadata to Firestore and uploads bytes to Firebase Storage.
class DocumentUploadCard extends ConsumerStatefulWidget {
  const DocumentUploadCard({
    required this.securityContext,
    required this.client,
    super.key,
  });

  final SecurityContext securityContext;
  final Client client;

  @override
  ConsumerState<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends ConsumerState<DocumentUploadCard> {
  late final FileStorageService _storage;
  late final FileAttachmentRepository _attachments;
  FileCategory _category = FileCategory.identification;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(fileStorageServiceProvider);
    _attachments = FileAttachmentRepository();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [branding.primaryColor, branding.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documents',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Insurance, ID & Medical Records',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                      items: const [
                        DropdownMenuItem(
                          value: FileCategory.identification,
                          child: Text('ID'),
                        ),
                        DropdownMenuItem(
                          value: FileCategory.insurance,
                          child: Text('Insurance'),
                        ),
                        DropdownMenuItem(
                          value: FileCategory.medical,
                          child: Text('Medical'),
                        ),
                        DropdownMenuItem(
                          value: FileCategory.general,
                          child: Text('General'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: Icon(
                    _uploading ? Icons.hourglass_top : Icons.upload_file,
                  ),
                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                    size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF and images up to 10MB. Files are encrypted and private.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<FileAttachment>>(
              stream: _attachments.watchClientAttachments(
                context: widget.securityContext,
                clientId: widget.client.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unable to load documents.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  );
                }

                final files = snapshot.data!;
                if (files.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                          size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'No documents uploaded yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: files.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: branding.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(file.category.icon,
                          color: branding.primaryColor),
                      ),
                      title: Text(file.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${file.category.displayName} • ${_formatSize(file.sizeBytes)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Download',
                        icon: const Icon(Icons.download_outlined),
                        onPressed: file.downloadUrl == null
                            ? null
                            : () => _download(file.downloadUrl!),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: FileStorageService.allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }

      final file = result.files.single;
      final isSensitive =
          _category == FileCategory.medical ||
          _category == FileCategory.insurance;

      final attachment = await _storage.uploadClientFile(
        context: widget.securityContext,
        file: file,
        clientId: widget.client.id,
        category: _category,
        accessLevel: FileAccessLevel.clientOnly,
        isSensitive: isSensitive,
        extraMetadata: {'uploadedBy': 'client'},
      );

      await _attachments.saveAttachment(
        context: widget.securityContext,
        attachment: attachment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SecureErrorHandler.uploadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  Future<void> _download(String url) async {
    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SecureErrorHandler.operationFailed)),
        );
      }
    }
  }
}
