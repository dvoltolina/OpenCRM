import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../config/demo_config.dart';
import '../../data/models/file_attachment.dart';
import '../../data/models/security_context.dart';
import 'demo_guard_service.dart';

/// Handles uploads to Firebase Storage with multi-tenant isolation and
/// basic validation (size/type/quota).
typedef UploadBytesHandler = Future<String> Function(
  String path,
  Uint8List bytes,
  SettableMetadata metadata,
  void Function(double progress)? onProgress,
);

class FileStorageService {
  FileStorageService({
    FirebaseStorage? storage,
    UploadBytesHandler? uploadHandler,
  })  : _storageOverride = storage,
        _uploadBytesOverride = uploadHandler;

  static const _uuid = Uuid();
  static const _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB per file
  static const allowedExtensions = [
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'heic'
  ];

  final FirebaseStorage? _storageOverride;
  final UploadBytesHandler? _uploadBytesOverride;

  /// Lazily access Firebase Storage - avoids initialization in test mode
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  /// Upload an intake attachment for a client (backward compatible helper).
  Future<FileAttachment> uploadIntakeAttachment({
    required SecurityContext context,
    required PlatformFile file,
    required String clientId,
    String? intakeFormId,
    String? intakeSubmissionId,
    String? appointmentId,
    bool isSensitive = false,
    Map<String, String>? extraMetadata,
    void Function(double progress)? onProgress,
  }) {
    return uploadClientFile(
      context: context,
      file: file,
      clientId: clientId,
      appointmentId: appointmentId,
      category: FileCategory.intake,
      accessLevel: FileAccessLevel.clientOnly,
      isSensitive: isSensitive,
      extraMetadata: {
        if (intakeFormId != null) 'intakeFormId': intakeFormId,
        if (intakeSubmissionId != null)
          'intakeSubmissionId': intakeSubmissionId,
        ...?extraMetadata,
      },
      onProgress: onProgress,
    );
  }

  /// Upload a general client file (used by staff uploads & appointment files).
  Future<FileAttachment> uploadClientFile({
    required SecurityContext context,
    required PlatformFile file,
    required String clientId,
    String? appointmentId,
    FileCategory category = FileCategory.general,
    FileAccessLevel accessLevel = FileAccessLevel.staffOnly,
    bool isSensitive = false,
    Map<String, String>? extraMetadata,
    void Function(double progress)? onProgress,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('upload file');
    }
    verifyFileAccess(context, context.businessId);
    _validateFile(file);

    final bytes = await _loadBytes(file);
    final attachmentId = _uuid.v4();
    final path =
        'businesses/${context.businessId}/clients/$clientId/files/$attachmentId-${file.name}';

    final metadata = _buildMetadata(
      context: context,
      contentType: _guessContentType(file),
      clientId: clientId,
      appointmentId: appointmentId,
      accessLevel: accessLevel,
      isSensitive: isSensitive,
      category: category,
      extraMetadata: extraMetadata,
    );

    final downloadUrl = await _uploadBytes(
      path: path,
      bytes: bytes,
      metadata: metadata,
      onProgress: onProgress,
    );

    return FileAttachment(
      id: attachmentId,
      businessId: context.businessId,
      name: file.name,
      contentType: metadata.contentType ?? 'application/octet-stream',
      sizeBytes: bytes.lengthInBytes,
      storagePath: path,
      uploadedAt: DateTime.now(),
      uploaderId: context.userId,
      uploaderName: context.userFullName,
      downloadUrl: downloadUrl,
      clientId: clientId,
      appointmentId: appointmentId,
      accessLevel: accessLevel,
      isSensitive: isSensitive,
      metadata: {
        ...?extraMetadata,
      },
      category: category,
    );
  }

  /// Upload shared session materials or appointment-level files (no client).
  Future<FileAttachment> uploadAppointmentMaterial({
    required SecurityContext context,
    required PlatformFile file,
    required String appointmentId,
    FileCategory category = FileCategory.general,
    FileAccessLevel accessLevel = FileAccessLevel.shared,
    bool isSensitive = false,
    Map<String, String>? extraMetadata,
    void Function(double progress)? onProgress,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('upload appointment material');
    }
    verifyFileAccess(context, context.businessId);
    _validateFile(file);

    final bytes = await _loadBytes(file);
    final attachmentId = _uuid.v4();
    final path =
        'businesses/${context.businessId}/appointments/$appointmentId/materials/$attachmentId-${file.name}';

    final metadata = _buildMetadata(
      context: context,
      contentType: _guessContentType(file),
      appointmentId: appointmentId,
      accessLevel: accessLevel,
      isSensitive: isSensitive,
      category: category,
      extraMetadata: extraMetadata,
    );

    final downloadUrl = await _uploadBytes(
      path: path,
      bytes: bytes,
      metadata: metadata,
      onProgress: onProgress,
    );

    return FileAttachment(
      id: attachmentId,
      businessId: context.businessId,
      name: file.name,
      contentType: metadata.contentType ?? 'application/octet-stream',
      sizeBytes: bytes.lengthInBytes,
      storagePath: path,
      uploadedAt: DateTime.now(),
      uploaderId: context.userId,
      uploaderName: context.userFullName,
      downloadUrl: downloadUrl,
      appointmentId: appointmentId,
      accessLevel: accessLevel,
      isSensitive: isSensitive,
      metadata: {
        ...?extraMetadata,
      },
      category: category,
    );
  }

  /// Delete a stored attachment.
  Future<void> deleteAttachment({
    required SecurityContext context,
    required FileAttachment attachment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete file attachment');
    }
    verifyFileAccess(context, attachment.businessId);
    await _storage.ref().child(attachment.storagePath).delete();
  }

  Future<String> _uploadBytes({
    required String path,
    required Uint8List bytes,
    required SettableMetadata metadata,
    void Function(double progress)? onProgress,
  }) async {
    if (_uploadBytesOverride != null) {
      return _uploadBytesOverride(path, bytes, metadata, onProgress);
    }
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(bytes, metadata);
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes == 0 ? 1 : event.totalBytes;
        onProgress(event.bytesTransferred / total);
      });
    }

    await uploadTask;
    return ref.getDownloadURL();
  }

  SettableMetadata _buildMetadata({
    required SecurityContext context,
    required String contentType,
    String? clientId,
    String? appointmentId,
    required FileAccessLevel accessLevel,
    required bool isSensitive,
    required FileCategory category,
    Map<String, String>? extraMetadata,
  }) {
    final metadata = <String, String>{
      'businessId': context.businessId,
      if (clientId != null) 'clientId': clientId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'uploadedBy': context.userId,
      'uploaderName': context.userFullName ?? '',
      'accessLevel': accessLevel.name,
      'isSensitive': isSensitive.toString(),
      'category': category.name,
      ...?extraMetadata,
    };

    return SettableMetadata(
      contentType: contentType,
      customMetadata: metadata,
    );
  }

  /// Generate a new download URL (Firebase Storage tokens are time-limited).
  Future<String> getDownloadUrl(FileAttachment attachment) {
    return _storage.ref().child(attachment.storagePath).getDownloadURL();
  }

  void _validateFile(PlatformFile file) {
    if (file.size > _maxFileSizeBytes) {
      throw Exception('File too large. Maximum is 10MB per attachment.');
    }
    final ext = (file.extension ?? '').toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
        'Unsupported file type. Allowed: ${allowedExtensions.join(', ')}',
      );
    }
  }

  String _guessContentType(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Uint8List> _loadBytes(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null) return bytes;
    throw Exception('File bytes missing. Enable withData=true when picking.');
  }
}
