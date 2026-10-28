import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/security_context.dart';

/// Access scope for a stored file.
enum FileAccessLevel { clientOnly, staffOnly, adminOnly, shared }

/// File category for organization
enum FileCategory {
  intake, // Intake form documents
  insurance, // Insurance cards, policy documents
  identification, // ID cards, driver's license
  medical, // Medical records, prescriptions
  property, // Property photos, documents (real estate)
  general, // General documents
}

extension FileCategoryExtension on FileCategory {
  String get displayName {
    switch (this) {
      case FileCategory.intake:
        return 'Intake Form';
      case FileCategory.insurance:
        return 'Insurance';
      case FileCategory.identification:
        return 'ID';
      case FileCategory.medical:
        return 'Medical';
      case FileCategory.property:
        return 'Property';
      case FileCategory.general:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case FileCategory.intake:
        return Icons.assignment;
      case FileCategory.insurance:
        return Icons.card_membership;
      case FileCategory.identification:
        return Icons.badge;
      case FileCategory.medical:
        return Icons.medical_services;
      case FileCategory.property:
        return Icons.home;
      case FileCategory.general:
        return Icons.insert_drive_file;
    }
  }
}

/// Metadata describing a stored attachment in Firebase Storage.
class FileAttachment {
  FileAttachment({
    required this.id,
    required this.businessId,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.storagePath,
    required this.uploadedAt,
    required this.uploaderId,
    this.uploaderName,
    this.downloadUrl,
    this.clientId,
    this.appointmentId,
    this.intakeFormId,
    this.intakeSubmissionId,
    this.accessLevel = FileAccessLevel.clientOnly,
    this.isSensitive = false,
    this.metadata = const {},
    this.category = FileCategory.general,
    this.providerNotes,
  });

  final String id;
  final String businessId;
  final String name;
  final String contentType;
  final int sizeBytes;
  final String storagePath;
  final DateTime uploadedAt;
  final String uploaderId;
  final String? uploaderName;
  final String? downloadUrl;
  final String? clientId;
  final String? appointmentId;
  final String? intakeFormId;
  final String? intakeSubmissionId;
  final FileAccessLevel accessLevel;
  final bool isSensitive;
  final Map<String, dynamic> metadata;
  final FileCategory category;
  final String? providerNotes;

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';

  FileAttachment copyWith({
    String? id,
    String? businessId,
    String? name,
    String? contentType,
    int? sizeBytes,
    String? storagePath,
    DateTime? uploadedAt,
    String? uploaderId,
    String? uploaderName,
    String? downloadUrl,
    String? clientId,
    String? appointmentId,
    String? intakeFormId,
    String? intakeSubmissionId,
    FileAccessLevel? accessLevel,
    bool? isSensitive,
    Map<String, dynamic>? metadata,
    FileCategory? category,
    String? providerNotes,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      storagePath: storagePath ?? this.storagePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      clientId: clientId ?? this.clientId,
      appointmentId: appointmentId ?? this.appointmentId,
      intakeFormId: intakeFormId ?? this.intakeFormId,
      intakeSubmissionId: intakeSubmissionId ?? this.intakeSubmissionId,
      accessLevel: accessLevel ?? this.accessLevel,
      isSensitive: isSensitive ?? this.isSensitive,
      metadata: metadata ?? this.metadata,
      category: category ?? this.category,
      providerNotes: providerNotes ?? this.providerNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'storagePath': storagePath,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'downloadUrl': downloadUrl,
      'clientId': clientId,
      'appointmentId': appointmentId,
      'intakeFormId': intakeFormId,
      'intakeSubmissionId': intakeSubmissionId,
      'accessLevel': accessLevel.name,
      'isSensitive': isSensitive,
      'metadata': metadata,
      'category': category.name,
      'providerNotes': providerNotes,
    };
  }

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    final fallbackId =
        json['id'] as String? ?? json['name'] as String? ?? 'legacy_file';
    final uploadedAtRaw = json['uploadedAt'];
    final uploadedAt = uploadedAtRaw is String
        ? DateTime.tryParse(uploadedAtRaw) ?? DateTime.now()
        : uploadedAtRaw is Timestamp
            ? uploadedAtRaw.toDate()
            : uploadedAtRaw is DateTime
                ? uploadedAtRaw
                : DateTime.now();
    return FileAttachment(
      id: fallbackId,
      businessId: json['businessId'] as String? ?? '',
      name: json['name'] as String,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      storagePath:
          json['storagePath'] as String? ?? 'legacy/$fallbackId',
      uploadedAt: uploadedAt,
      uploaderId: json['uploaderId'] as String? ?? '',
      uploaderName: json['uploaderName'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      clientId: json['clientId'] as String?,
      appointmentId: json['appointmentId'] as String?,
      intakeFormId: json['intakeFormId'] as String?,
      intakeSubmissionId: json['intakeSubmissionId'] as String?,
      accessLevel: _accessFromJson(json['accessLevel'] as String?),
      isSensitive: json['isSensitive'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      category: _categoryFromJson(json['category'] as String?),
      providerNotes: json['providerNotes'] as String?,
    );
  }

  static FileAccessLevel _accessFromJson(String? raw) {
    switch (raw) {
      case 'staffOnly':
        return FileAccessLevel.staffOnly;
      case 'adminOnly':
        return FileAccessLevel.adminOnly;
      case 'shared':
        return FileAccessLevel.shared;
      default:
        return FileAccessLevel.clientOnly;
    }
  }

  static FileCategory _categoryFromJson(String? raw) {
    switch (raw) {
      case 'intake':
        return FileCategory.intake;
      case 'insurance':
        return FileCategory.insurance;
      case 'identification':
        return FileCategory.identification;
      case 'medical':
        return FileCategory.medical;
      case 'property':
        return FileCategory.property;
      default:
        return FileCategory.general;
    }
  }
}

/// Helper to ensure upload scopes align with the user's security context.
void verifyFileAccess(SecurityContext context, String businessId) {
  context.verifyBusinessAccess(businessId);
}
