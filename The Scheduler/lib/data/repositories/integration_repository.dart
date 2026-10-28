import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/integration_models.dart';
import '../models/security_context.dart';

/// Repository responsible for persisting integration accounts, tokens, and sync logs.
class IntegrationRepository {
  IntegrationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Watch all integration accounts for the current business.
  Stream<List<IntegrationAccount>> watchIntegrations(
    SecurityContext context,
  ) {
    _ensureAdmin(context);
    return _integrationsCollection(context.businessId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => IntegrationAccount.fromJson({
              'id': doc.id,
              ...doc.data(),
              'businessId': context.businessId,
            }),
          )
          .toList();
    });
  }

  /// Fetch a single integration by provider.
  Future<IntegrationAccount?> getIntegration({
    required SecurityContext context,
    required IntegrationProvider provider,
  }) async {
    _ensureAdmin(context);
    final query = await _integrationsCollection(context.businessId)
        .where('provider', isEqualTo: provider.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return IntegrationAccount.fromJson({
      'id': doc.id,
      ...doc.data(),
      'businessId': context.businessId,
    });
  }

  /// Create or update an integration account.
  Future<String> upsertIntegration({
    required SecurityContext context,
    required IntegrationAccount account,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save integration');
    }
    _ensureAdmin(context);
    context.verifyBusinessAccess(account.businessId);

    final docRef = _integrationsCollection(context.businessId).doc(account.id);
    await docRef.set(account.toJson(), SetOptions(merge: true));
    return docRef.id;
  }

  /// Remove an integration account (used when disconnecting).
  Future<void> deleteIntegration({
    required SecurityContext context,
    required String integrationId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete integration');
    }
    _ensureAdmin(context);
    await _integrationsCollection(context.businessId).doc(integrationId).delete();
  }

  /// Persist encrypted OAuth tokens for a given integration.
  Future<void> saveEncryptedToken({
    required SecurityContext context,
    required EncryptedOAuthToken token,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save integration token', showMessage: false);
    }
    _ensureAdmin(context);

    final doc = _tokenCollection(context.businessId, token.integrationId).doc('oauth');
    await doc.set(token.toJson(), SetOptions(merge: true));
  }

  /// Load encrypted tokens so services can decrypt them locally.
  Future<EncryptedOAuthToken?> getEncryptedToken({
    required SecurityContext context,
    required String integrationId,
  }) async {
    _ensureAdmin(context);

    final doc = await _tokenCollection(context.businessId, integrationId)
        .doc('oauth')
        .get();

    if (!doc.exists) return null;
    return EncryptedOAuthToken.fromJson({
      ...doc.data()!,
      'integrationId': integrationId,
    });
  }

  /// Log sync metadata for troubleshooting.
  Future<void> logSyncEvent({
    required SecurityContext context,
    required String integrationId,
    required CalendarSyncResult result,
  }) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    _ensureAdmin(context);

    final logEntry = {
      'timestamp': FieldValue.serverTimestamp(),
      'success': result.success,
      'syncedAppointments': result.syncedAppointments,
      'conflictCount': result.conflicts.length,
      if (result.errorMessage != null) 'error': result.errorMessage,
    };

    await _tokenCollection(context.businessId, integrationId)
        .doc('last_sync')
        .set(logEntry, SetOptions(merge: true));
  }

  void _ensureAdmin(SecurityContext context) {
    if (!context.isAdmin && !context.isOwner) {
      throw SecurityException(
        'Integration operations require admin or owner permissions.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _integrationsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('integrations');
  }

  CollectionReference<Map<String, dynamic>> _tokenCollection(
    String businessId,
    String integrationId,
  ) {
    return _integrationsCollection(businessId)
        .doc(integrationId)
        .collection('tokens');
  }
}
