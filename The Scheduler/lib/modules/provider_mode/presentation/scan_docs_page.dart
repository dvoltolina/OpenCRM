import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/offline/offline_banner.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/file_attachment.dart';
import '../../../data/models/audit_log.dart';

/// Scan Docs page for providers - upload files to client records.
///
/// HIPAA Compliance:
/// - Files uploaded with FileStorageService (signed URLs, tenant-scoped)
/// - Metadata stored in FileAttachmentRepository with proper access levels
/// - phiWrite audit logged on successful upload
/// - File type and size validation enforced
///
/// Features:
/// - Select files from device (camera, gallery, documents)
/// - Choose target client
/// - Set file category and sensitivity
/// - Progress tracking during upload
/// - Confirmation after upload
///
/// Under 600 lines by keeping UI focused.
class ScanDocsPage extends ConsumerStatefulWidget {
  const ScanDocsPage({super.key});

  @override
  ConsumerState<ScanDocsPage> createState() => _ScanDocsPageState();
}

class _ScanDocsPageState extends ConsumerState<ScanDocsPage> {
  PlatformFile? _selectedFile;
  String? _selectedClientId;
  String? _selectedClientName;
  FileCategory _category = FileCategory.general;
  bool _isSensitive = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContext = ref.watch(currentSecurityContextProvider);

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Docs'),
        actions: const [OfflineIndicator()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _isUploading
                ? _buildUploadingView(theme)
                : _buildFormView(context, theme, securityContext.businessId),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    ThemeData theme,
    String businessId,
  ) {
    final clientsAsync = ref.watch(_clientsListProvider(businessId));

    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  HSpace.sm,
                  Expanded(
                    child: Text(
                      'Upload documents, images, or scans to client records. '
                      'Maximum file size: 10MB. '
                      'Allowed formats: PDF, PNG, JPG, JPEG, WEBP, HEIC.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VSpace.lg,

          // File selection
          Text('Select File', style: theme.textTheme.titleMedium),
          VSpace.sm,
          if (_selectedFile != null)
            _buildFilePreview(theme)
          else
            _buildFileButtons(context, theme),

          VSpace.lg,

          // Client selection
          Text('Client', style: theme.textTheme.titleMedium),
          VSpace.sm,
          clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return const Text('No clients available');
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedClientId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select client',
                ),
                items: clients.map((client) {
                  return DropdownMenuItem(
                    value: client.id,
                    child: Text('${client.firstName} ${client.lastName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                    _selectedClientName = clients
                        .firstWhere((c) => c.id == value)
                        .fullName;
                  });
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Error loading clients'),
          ),

          VSpace.lg,

          // Category selection
          Text('Category', style: theme.textTheme.titleMedium),
          VSpace.sm,
          DropdownButtonFormField<FileCategory>(
            initialValue: _category,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: FileCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(category.icon, size: 20),
                    HSpace.xs,
                    Text(category.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),

          VSpace.lg,

          // Sensitivity toggle
          SwitchListTile(
            title: const Text('Mark as Sensitive'),
            subtitle: const Text('PHI or confidential information'),
            value: _isSensitive,
            onChanged: (value) => setState(() => _isSensitive = value),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 32), // Keep custom value

          // Upload button
          FilledButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload File'),
            onPressed: _canUpload ? () => _handleUpload(context) : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(ThemeData theme) {
    return Card(
      child: ListTile(
        leading: Icon(
          _selectedFile!.extension == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.image,
          size: 40,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          _selectedFile!.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(_formatFileSize(_selectedFile!.size)),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _selectedFile = null),
        ),
      ),
    );
  }

  Widget _buildFileButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
          onPressed: () => _pickFile(FileType.image, context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        VSpace.sm,
        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          onPressed: () => _pickFile(FileType.image, context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        VSpace.sm,
        OutlinedButton.icon(
          icon: const Icon(Icons.insert_drive_file),
          label: const Text('Choose Document (PDF)'),
          onPressed: () => _pickFile(FileType.custom, context, ['pdf']),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          VSpace.lg,
          Text('Uploading...', style: theme.textTheme.titleMedium),
          VSpace.xs,
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VSpace.md,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(value: _uploadProgress),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(
    FileType type,
    BuildContext context, [
    List<String>? extensions,
  ]) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: extensions,
        withData: true, // Load file bytes for upload
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SafeErrorHandler.handle(e))));
      }
    }
  }

  bool get _canUpload =>
      _selectedFile != null && _selectedClientId != null && !_isUploading;

  Future<void> _handleUpload(BuildContext context) async {
    if (!_canUpload) return;

    final securityContext = ref.read(currentSecurityContextProvider);
    if (securityContext == null) return;

    // Check connectivity before uploading
    final connectivityService = ref.read(connectivityServiceProvider);
    final isOnline = await connectivityService.checkConnectivity();

    if (!isOnline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document upload requires internet connection'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageService = ref.read(fileStorageServiceProvider);
      final attachmentRepo = ref.read(fileAttachmentRepositoryProvider);
      final auditLogRepo = ref.read(auditLogRepositoryProvider);

      // Upload file to storage
      final attachment = await storageService.uploadClientFile(
        context: securityContext,
        file: _selectedFile!,
        clientId: _selectedClientId!,
        category: _category,
        accessLevel: FileAccessLevel.staffOnly,
        isSensitive: _isSensitive,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Save metadata to Firestore
      await attachmentRepo.saveAttachment(
        context: securityContext,
        attachment: attachment,
      );

      // Audit log PHI write
      await auditLogRepo.logEvent(
        AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'FileAttachment',
          entityId: attachment.id,
          metadata: {
            'source': 'scanDocs',
            'clientId': _selectedClientId!,
            'category': _category.name,
            'isSensitive': _isSensitive,
          },
        ),
      );

      if (context.mounted) {
        // Show success
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File uploaded successfully to:'),
                VSpace.xs,
                Text(
                  _selectedClientName ?? 'Client',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Reset form
        setState(() {
          _selectedFile = null;
          _selectedClientId = null;
          _selectedClientName = null;
          _category = FileCategory.general;
          _isSensitive = true;
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SafeErrorHandler.handle(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Provider to fetch client list for file upload.
final _clientsListProvider =
    FutureProvider.family<List<_ClientListItem>, String>((
      ref,
      businessId,
    ) async {
      final securityContext = ref.watch(currentSecurityContextProvider);
      if (securityContext == null) return [];

      final clientsRepo = ref.read(clientsRepositoryProvider);
      final clients = await clientsRepo.getClients(securityContext);

      // Convert to simple list items
      return clients
          .map(
            (c) => _ClientListItem(
              id: c.id,
              firstName: c.firstName,
              lastName: c.lastName,
            ),
          )
          .toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
    });

/// Simple client list item for dropdown
class _ClientListItem {
  const _ClientListItem({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';
}
