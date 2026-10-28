import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';

/// Repository for centralized audit logging.
///
/// Writes are best-effort: failures are logged and swallowed so primary user
/// flows are never blocked. IP addresses are intentionally stripped on the
/// client; populate them only from server-side writers.
class AuditLogRepository {
  AuditLogRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _allowedActions = <AuditActionType>{
    AuditActionType.loginSuccess,
    AuditActionType.loginFailure,
    AuditActionType.phiRead,
    AuditActionType.phiWrite,
    AuditActionType.dataExport,
    AuditActionType.securityEvent,
  };
  static final Map<String, DateTime> _throttle = {};
  static const Duration _throttleWindow = Duration(minutes: 5);
  static final Map<String, bool> _auditEnabledCache = {};

  Future<bool> _isAuditLoggingEnabled(String businessId) async {
    // Prefer cached decision.
    final cached = _auditEnabledCache[businessId];
    if (cached != null) return cached;

    try {
      final doc = await _firestore.collection('businesses').doc(businessId).get();
      if (!doc.exists) {
        // If we cannot determine the business flags, fail open to avoid losing HIPAA logs.
        _auditEnabledCache[businessId] = true;
        return true;
      }

      final data = doc.data();
      final enabled = (data?['requiresHipaaCompliance'] == true) ||
          (data?['auditLoggingEnabled'] == true);

      _auditEnabledCache[businessId] = enabled;
      return enabled;
    } catch (error, stackTrace) {
      // Fail open on lookup errors to avoid dropping HIPAA-required logs.
      developer.log(
        'Audit logging gate lookup failed; defaulting to enabled',
        name: 'AuditLogRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  /// Convenience method for logging with SecurityContext.
  ///
  /// Maps action string to appropriate AuditActionType.
  /// Used by AI services for HIPAA compliance logging.
  Future<void> log({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
    String? source,
  }) async {
    // Map action string to AuditActionType
    final actionType = _mapActionToType(action);

    final metadata = <String, dynamic>{};
    if (source != null) metadata['source'] = source;
    if (details != null) {
      // Only include safe scalar values from details
      details.forEach((key, value) {
        if (value is String || value is num || value is bool) {
          metadata[key] = value;
        }
      });
    }

    await logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    ));
  }

  /// Map action strings to AuditActionType.
  AuditActionType _mapActionToType(String action) {
    if (action.contains('read') || action.contains('view') || action.contains('get')) {
      return AuditActionType.phiRead;
    }
    if (action.contains('write') || action.contains('save') || action.contains('create') || action.contains('update')) {
      return AuditActionType.phiWrite;
    }
    if (action.contains('export')) {
      return AuditActionType.dataExport;
    }
    // Default to phiRead for AI operations that access data
    return AuditActionType.phiRead;
  }

  Future<void> logEvent(AuditLogEntry entry) async {
    if (entry.businessId.isEmpty) return;
    if (DemoConfig.isDemoMode) return;

    // Skip logging for non-HIPAA businesses unless explicitly enabled.
    final auditEnabled = await _isAuditLoggingEnabled(entry.businessId);
    if (!auditEnabled) return;

    // Scope down to critical action types only.
    if (!_allowedActions.contains(entry.actionType)) return;

    // Throttle per user+action+entity to cut chatty writes.
    final throttleKey =
        '${entry.businessId}:${entry.userId}:${entry.actionType}:${entry.entityType}:${entry.entityId}';
    final now = DateTime.now();
    final last = _throttle[throttleKey];
    if (last != null && now.difference(last) < _throttleWindow) {
      return;
    }
    _throttle[throttleKey] = now;

    final collection = _auditLogs(entry.businessId);
    final docRef = entry.id != null ? collection.doc(entry.id) : collection.doc();
    final data = Map<String, dynamic>.from(entry.toJson())
      ..['id'] = docRef.id
      ..remove('ipAddress') // Never trust client-supplied IP data
      ..['timestamp'] = FieldValue.serverTimestamp()
      ..removeWhere((key, value) => value == null);

    data['metadata'] = _sanitizeMetadata(data['metadata'] as Map<String, dynamic>?);

    try {
      await docRef.set(data, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to record audit log (non-blocking)',
        name: 'AuditLogRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return <String, dynamic>{};

    final sanitized = <String, dynamic>{};
    metadata.forEach((key, value) {
      if (key.isEmpty) return;
      if (value is String) {
        if (value.length > 120 || value.contains('\n')) return;
        sanitized[key] = value;
      } else if (value is num || value is bool) {
        sanitized[key] = value;
      }
      // Drop lists, maps, and other complex objects to avoid PHI leakage.
    });
    return sanitized;
  }

  CollectionReference<Map<String, dynamic>> _auditLogs(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('audit_logs');
  }
}
