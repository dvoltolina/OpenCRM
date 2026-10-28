import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_log.dart';
import '../models/provider.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';
import 'business_collection_repository.dart';

/// Repository for managing service providers with multi-tenant isolation.
/// Only admins can manage providers.
///
/// Security events (provider creation, deletion) are audit-logged
/// for HIPAA compliance.
class ProvidersRepository extends BusinessCollectionRepository<Provider> {
  ProvidersRepository({
    super.firestore,
    AuditLogRepository? auditLogRepository,
  }) : _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final AuditLogRepository _auditLogRepository;

  @override
  String get collectionName => 'providers';

  @override
  String get defaultOrderBy => 'lastName';

  @override
  Provider fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing provider data for ${doc.id}');
    }
    return Provider.fromJson({'id': doc.id, ...data});
  }

  @override
  Map<String, dynamic> toMap(Provider model) => model.toJson();

  @override
  String getId(Provider model) => model.id;

  @override
  void authorizeWrite(SecurityContext context, Provider model) {
    context.verifyBusinessAccess(model.businessId);
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to modify providers');
    }
  }

  @override
  void authorizeDelete(SecurityContext context) {
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to delete providers');
    }
    super.authorizeDelete(context);
  }

  @override
  Future<void> upsert({
    required SecurityContext context,
    required Provider model,
  }) async {
    // Check if this is a new provider or an update
    final existing = await getById(context: context, id: model.id);
    final isNew = existing == null;

    await super.upsert(context: context, model: model);

    // Audit log provider creation or update (non-blocking)
    await _logSecurityEvent(
      context: context,
      providerId: model.id,
      event: isNew ? 'providerCreated' : 'providerUpdated',
    );
  }

  @override
  Future<void> delete({
    required SecurityContext context,
    required String id,
  }) async {
    await super.delete(context: context, id: id);

    // Audit log provider deletion (non-blocking)
    await _logSecurityEvent(
      context: context,
      providerId: id,
      event: 'providerDeleted',
    );
  }

  /// Backwards-compatible API
  Future<void> upsertProvider({
    required SecurityContext context,
    required Provider provider,
  }) =>
      upsert(context: context, model: provider);

  Stream<List<Provider>> watchProviders(SecurityContext context) =>
      watchAll(context);

  Future<List<Provider>> getProviders({
    required SecurityContext context,
  }) =>
      getAll(context: context);

  Future<Provider?> getProvider({
    required SecurityContext context,
    required String providerId,
  }) =>
      getById(context: context, id: providerId);

  Future<void> deleteProvider({
    required SecurityContext context,
    required String providerId,
  }) =>
      delete(context: context, id: providerId);

  /// Logs a security event for HIPAA audit trail.
  ///
  /// Errors are swallowed to ensure provider operations are non-blocking.
  Future<void> _logSecurityEvent({
    required SecurityContext context,
    required String providerId,
    required String event,
  }) async {
    try {
      await _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.securityEvent,
          entityType: 'Provider',
          entityId: providerId,
          metadata: {
            'event': event,
          },
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to log security event (non-blocking)',
        name: 'ProvidersRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
