import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/intake_form.dart';
import '../models/intake_form_draft.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing intake form templates and submissions.
/// Enforces multi-tenant isolation and RBAC permissions.
/// PHI read operations are logged via [AuditLogRepository] for HIPAA compliance.
class IntakeFormRepository {
  IntakeFormRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  // ========== Templates ==========

  /// Create or update a form template (admin only)
  Future<void> upsertTemplate({
    required SecurityContext context,
    required IntakeFormTemplate template,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save intake template');
    }
    context.verifyBusinessAccess(template.businessId);
    if (!context.role.canManageBusiness) {
      throw SecurityException(
        'Only admins can create/modify intake form templates',
      );
    }

    await _businessTemplates(
      template.businessId,
    ).doc(template.id).set(template.toJson(), SetOptions(merge: true));
  }

  /// Watch all templates for a business
  Stream<List<IntakeFormTemplate>> watchTemplates(SecurityContext context) {
    return _businessTemplates(context.businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    IntakeFormTemplate.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  /// Get a single template by ID
  Future<IntakeFormTemplate?> getTemplate({
    required SecurityContext context,
    required String templateId,
  }) async {
    final doc = await _businessTemplates(
      context.businessId,
    ).doc(templateId).get();
    if (!doc.exists) return null;

    return IntakeFormTemplate.fromJson({'id': doc.id, ...doc.data()!});
  }

  /// Delete/deactivate a template (admin only)
  Future<void> deactivateTemplate({
    required SecurityContext context,
    required String templateId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('deactivate intake template');
    }
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only admins can deactivate form templates');
    }

    await _businessTemplates(context.businessId).doc(templateId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== Submissions ==========

  /// Submit a completed intake form
  Future<void> submitForm({
    required SecurityContext context,
    required IntakeFormSubmission submission,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('submit intake form');
    }
    context.verifyBusinessAccess(submission.businessId);

    await _businessSubmissions(
      submission.businessId,
    ).doc(submission.id).set(submission.toJson());
  }

  /// Watch all submissions for a specific client
  Stream<List<IntakeFormSubmission>> watchClientSubmissions({
    required SecurityContext context,
    required String clientId,
  }) {
    // Allow staff to view client submissions
    if (!context.role.canManageClients && context.clientId != clientId) {
      throw SecurityException('Insufficient permissions to view client forms');
    }

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'IntakeFormSubmission',
      entityId: clientId,
      metadata: {
        'source': 'watchClientSubmissions',
        'mode': 'stream',
        'filterClientId': clientId,
      },
    ));

    return _businessSubmissions(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IntakeFormSubmission.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Get a specific submission
  Future<IntakeFormSubmission?> getSubmission({
    required SecurityContext context,
    required String submissionId,
  }) async {
    final doc = await _businessSubmissions(
      context.businessId,
    ).doc(submissionId).get();
    if (!doc.exists) return null;

    final submission = IntakeFormSubmission.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });

    // Verify access
    if (!context.role.canManageClients &&
        context.clientId != submission.clientId) {
      throw SecurityException('Cannot access this form submission');
    }

    // HIPAA: Log PHI single-entity read
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'IntakeFormSubmission',
      entityId: submissionId,
      metadata: {
        'source': 'getSubmission',
        'clientId': submission.clientId,
      },
    ));

    return submission;
  }

  /// Initialize default templates for a business based on industry
  Future<void> initializeDefaultTemplates({
    required SecurityContext context,
    required String industry,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('initialize intake templates');
    }
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only admins can initialize templates');
    }

    IntakeFormTemplate? template;

    switch (industry.toLowerCase()) {
      case 'therapist':
      case 'dentist':
      case 'chiropractor':
        template = DefaultIntakeTemplates.medicalIntake(
          businessId: context.businessId,
        );
        break;
      case 'realtor':
        template = DefaultIntakeTemplates.realEstatePreferences(
          businessId: context.businessId,
        );
        break;
    }

    if (template != null) {
      await upsertTemplate(context: context, template: template);
    }
  }

  // ========== Drafts ==========

  Future<IntakeFormDraft> saveDraft({
    required SecurityContext context,
    required IntakeFormDraft draft,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save intake draft');
    }
    context.verifyBusinessAccess(draft.businessId);

    await _businessDrafts(
      draft.businessId,
    ).doc(draft.id).set(draft.toJson(), SetOptions(merge: true));
    return draft;
  }

  Future<IntakeFormDraft?> getDraft({
    required SecurityContext context,
    required String draftId,
  }) async {
    final doc = await _businessDrafts(context.businessId).doc(draftId).get();
    if (!doc.exists) return null;

    final draft = IntakeFormDraft.fromJson({'id': doc.id, ...doc.data()!});

    // HIPAA: Log PHI single-entity read
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'IntakeFormDraft',
      entityId: draftId,
      metadata: {
        'source': 'getDraft',
        'clientId': draft.clientId,
      },
    ));

    return draft;
  }

  Stream<List<IntakeFormDraft>> watchDraftsForClient({
    required SecurityContext context,
    required String clientId,
  }) {
    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'IntakeFormDraft',
      entityId: clientId,
      metadata: {
        'source': 'watchDraftsForClient',
        'mode': 'stream',
        'filterClientId': clientId,
      },
    ));

    return _businessDrafts(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    IntakeFormDraft.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  Future<IntakeFormDraft?> getActiveDraftForClient({
    required SecurityContext context,
    required String clientId,
    required String templateId,
  }) async {
    final query = await _businessDrafts(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .where('templateId', isEqualTo: templateId)
        .where('status', isEqualTo: 'draft')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final draft = IntakeFormDraft.fromJson({
      'id': query.docs.first.id,
      ...query.docs.first.data(),
    });

    if (draft.isExpired) return null;

    // HIPAA: Log PHI single-entity read
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'IntakeFormDraft',
      entityId: draft.id,
      metadata: {
        'source': 'getActiveDraftForClient',
        'clientId': clientId,
        'templateId': templateId,
      },
    ));

    return draft;
  }

  Future<void> deleteDraft({
    required SecurityContext context,
    required String draftId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete intake draft');
    }
    await _businessDrafts(context.businessId).doc(draftId).delete();
  }

  // ========== Helper Methods ==========

  CollectionReference<Map<String, dynamic>> _businessTemplates(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('intakeFormTemplates');
  }

  CollectionReference<Map<String, dynamic>> _businessSubmissions(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('intakeFormSubmissions');
  }

  CollectionReference<Map<String, dynamic>> _businessDrafts(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('intakeFormDrafts');
  }
}
