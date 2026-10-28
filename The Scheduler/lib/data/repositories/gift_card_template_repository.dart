import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/gift_card_template.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing gift card templates per business.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// Operations are logged via [AuditLogRepository] for compliance.
class GiftCardTemplateRepository {
  GiftCardTemplateRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  CollectionReference<Map<String, dynamic>> _templatesCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('giftCardTemplates');
  }

  /// Create a new gift card template.
  Future<GiftCardTemplate> createTemplate({
    required SecurityContext context,
    required String name,
    required String description,
    required String imageUrl,
    required String backgroundColor,
    required String textColor,
    List<int>? presetAmountsCents,
    int? minAmountCents,
    int? maxAmountCents,
    int? validityDays,
  }) async {
    DemoGuardService.assertReadOnly('create gift card template');
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final docRef = _templatesCollection(context.businessId).doc();

    final template = GiftCardTemplate(
      id: docRef.id,
      businessId: context.businessId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      backgroundColor: backgroundColor,
      textColor: textColor,
      presetAmountsCents: presetAmountsCents,
      minAmountCents: minAmountCents,
      maxAmountCents: maxAmountCents,
      validityDays: validityDays,
      createdAt: DateTime.now(),
    );

    await docRef.set(template.toJson());

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCardTemplate',
        entityId: template.id,
        metadata: {'action': 'create', 'name': name},
      ),
    );

    return template;
  }

  /// Get a template by ID.
  Future<GiftCardTemplate?> getTemplate(
    SecurityContext context,
    String templateId,
  ) async {
    context.verifyBusinessAccess();

    final doc = await _templatesCollection(
      context.businessId,
    ).doc(templateId).get();

    if (!doc.exists) return null;

    return GiftCardTemplate.fromJson(_decodeTemplateDoc(doc));
  }

  /// Get all active templates for a business.
  Future<List<GiftCardTemplate>> getTemplates(
    SecurityContext context, {
    bool activeOnly = true,
  }) async {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _templatesCollection(
      context.businessId,
    ).orderBy('createdAt', descending: true);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => GiftCardTemplate.fromJson(_decodeTemplateDoc(doc)))
        .toList();
  }

  /// Stream templates for a business.
  Stream<List<GiftCardTemplate>> watchTemplates(
    SecurityContext context, {
    bool activeOnly = true,
  }) {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _templatesCollection(
      context.businessId,
    ).orderBy('createdAt', descending: true);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => GiftCardTemplate.fromJson(_decodeTemplateDoc(doc)))
          .toList(),
    );
  }

  /// Update a template.
  Future<void> updateTemplate({
    required SecurityContext context,
    required String templateId,
    required Map<String, dynamic> updates,
  }) async {
    DemoGuardService.assertReadOnly('update gift card template');
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _templatesCollection(
      context.businessId,
    ).doc(templateId).update(updates);

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCardTemplate',
        entityId: templateId,
        metadata: {'action': 'update'},
      ),
    );
  }

  /// Deactivate a template (soft delete).
  Future<void> deactivateTemplate(
    SecurityContext context,
    String templateId,
  ) async {
    DemoGuardService.assertReadOnly('deactivate gift card template');
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    await _templatesCollection(context.businessId).doc(templateId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCardTemplate',
        entityId: templateId,
        metadata: {'action': 'deactivate'},
      ),
    );
  }

  /// Decode a template document, normalizing timestamps.
  Map<String, dynamic> _decodeTemplateDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return {'id': doc.id};

    final normalized = Map<String, dynamic>.from(data);

    void normalizeField(String key) {
      final value = normalized[key];
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        normalized[key] = value.toIso8601String();
      }
    }

    normalizeField('createdAt');
    normalizeField('updatedAt');
    normalizeField('deactivatedAt');

    return {'id': doc.id, ...normalized};
  }
}
