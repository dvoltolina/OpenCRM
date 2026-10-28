import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/security_context.dart';

/// Image picker widget for product images.
///
/// Supports uploading images to Firebase Storage with progress indicator.
class ProductImagePicker extends StatefulWidget {
  const ProductImagePicker({
    super.key,
    required this.securityContext,
    this.imageUrl,
    required this.onImageChanged,
  });

  final SecurityContext securityContext;
  final String? imageUrl;
  final ValueChanged<String?> onImageChanged;

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  double? _uploadProgress;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read image file')),
          );
        }
        return;
      }

      // Validate file size (max 5MB)
      const maxSize = 5 * 1024 * 1024;
      if (file.size > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image must be smaller than 5MB')),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Upload to Firebase Storage
      final storage = FirebaseStorage.instance;
      final businessId = widget.securityContext.businessId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final path = 'businesses/$businessId/products/$fileName';

      final ref = storage.ref(path);
      final uploadTask = ref.putData(
        file.bytes!,
        SettableMetadata(
          contentType: _getContentType(file.extension),
          customMetadata: {
            'uploadedBy': widget.securityContext.userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      uploadTask.snapshotEvents.listen((event) {
        if (mounted) {
          setState(() {
            _uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
        widget.onImageChanged(downloadUrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Image preview
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: _buildImagePreview(theme),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.upload),
                  label: Text(widget.imageUrl == null ? 'Upload Image' : 'Change Image'),
                ),
                if (widget.imageUrl != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _isUploading ? null : () => widget.onImageChanged(null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    if (_isUploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: _uploadProgress, strokeWidth: 2),
          const SizedBox(height: 8),
          Text(
            _uploadProgress != null ? '${(_uploadProgress! * 100).toInt()}%' : 'Uploading...',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (widget.imageUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 150,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('Failed to load image', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
