import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/file_attachment.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Persists file attachment metadata in Firestore for discoverability and audit.
/// PHI read operations are logged via [AuditLogRepository] for HIPAA compliance.
class FileAttachmentRepository {
  FileAttachmentRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  Future<FileAttachment> saveAttachment({
    required SecurityContext context,
    required FileAttachment attachment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save file attachment');
    }
    final clientId = attachment.clientId;
    final appointmentId = attachment.appointmentId;
    final data = attachment.toJson()
      ..['uploadedAt'] = attachment.uploadedAt;

    if (clientId != null && clientId.isNotEmpty) {
      context.verifyClientAccess(clientId, attachment.businessId);
      await _clientFiles(
        attachment.businessId,
        clientId,
      ).doc(attachment.id).set(data, SetOptions(merge: true));
    } else if (appointmentId != null && appointmentId.isNotEmpty) {
      context.verifyBusinessAccess(attachment.businessId);
      await _appointmentFiles(
        attachment.businessId,
        appointmentId,
      ).doc(attachment.id).set(data, SetOptions(merge: true));
    } else {
      throw SecurityException('Attachment missing clientId or appointmentId');
    }

    return attachment;
  }

  Stream<List<FileAttachment>> watchClientAttachments({
    required SecurityContext context,
    required String clientId,
  }) {
    context.verifyClientAccess(clientId, context.businessId);

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'FileAttachment',
      entityId: clientId,
      metadata: {
        'source': 'watchClientAttachments',
        'mode': 'stream',
        'filterClientId': clientId,
      },
    ));

    return _clientFiles(context.businessId, clientId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FileAttachment.fromJson(
                  {'id': doc.id, ...doc.data()},
                ),
              )
              .toList(),
        );
  }

  Stream<List<FileAttachment>> watchAppointmentAttachments({
    required SecurityContext context,
    required String appointmentId,
    String? clientId,
  }) {
    context.verifyBusinessAccess(context.businessId);

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'FileAttachment',
      entityId: appointmentId,
      metadata: {
        'source': 'watchAppointmentAttachments',
        'mode': 'stream',
        'filterAppointmentId': appointmentId,
        if (clientId != null) 'filterClientId': clientId,
      },
    ));

    final query = clientId != null
        ? _clientFiles(context.businessId, clientId)
            .where('appointmentId', isEqualTo: appointmentId)
        : _appointmentFiles(context.businessId, appointmentId);

    return query
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FileAttachment.fromJson(
                  {'id': doc.id, ...doc.data()},
                ),
              )
              .toList(),
        );
  }

  Future<void> deleteAttachment({
    required SecurityContext context,
    required FileAttachment attachment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete file attachment');
    }
    final clientId = attachment.clientId;
    final appointmentId = attachment.appointmentId;

    if (clientId != null && clientId.isNotEmpty) {
      context.verifyClientAccess(clientId, attachment.businessId);
      await _clientFiles(
        attachment.businessId,
        clientId,
      ).doc(attachment.id).delete();
      return;
    }

    if (appointmentId != null && appointmentId.isNotEmpty) {
      context.verifyBusinessAccess(attachment.businessId);
      await _appointmentFiles(
        attachment.businessId,
        appointmentId,
      ).doc(attachment.id).delete();
      return;
    }

    throw SecurityException('Attachment missing clientId or appointmentId');
  }

  CollectionReference<Map<String, dynamic>> _clientFiles(
    String businessId,
    String clientId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clients')
        .doc(clientId)
        .collection('files');
  }

  CollectionReference<Map<String, dynamic>> _appointmentFiles(
    String businessId,
    String appointmentId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(appointmentId)
        .collection('files');
  }
}
