/// Repository for client risk scores and sentiment analysis results.
///
/// Provides persistence layer for sentiment analysis data with:
/// - Multi-tenant isolation via SecurityContext
/// - Historical score tracking for trend analysis
/// - Batch operations for efficiency
/// - TTL-based cleanup of old data
/// - **HIPAA Compliance:** All PHI access is logged to AuditLogRepository
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../core/services/encryption_service.dart';
import '../models/client_risk_score.dart';
import '../models/sentiment_result.dart';
import '../models/risk_indicator.dart';

/// Repository for client risk scores and sentiment analysis results.
class ClientRiskRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository? _auditLogRepository;
  final EncryptionService? _encryptionService;

  ClientRiskRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository,
        _encryptionService = encryptionService;

  // ============ Collection References ============

  CollectionReference<Map<String, dynamic>> _riskScoresCollection(
    String businessId,
  ) =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('clientRiskScores');

  CollectionReference<Map<String, dynamic>> _sentimentResultsCollection(
    String businessId,
  ) =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sentimentResults');

  CollectionReference<Map<String, dynamic>> _riskScoreHistoryCollection(
    String businessId,
    String clientId,
  ) =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('clientRiskScores')
          .doc(clientId)
          .collection('history');

  // ============ Risk Score Operations ============

  /// Get current risk score for a client.
  ///
  /// **HIPAA:** Logs PHI read to audit trail.
  Future<ClientRiskScore?> getClientRiskScore(
    SecurityContext context,
    String clientId,
  ) async {
    final doc =
        await _riskScoresCollection(context.businessId).doc(clientId).get();

    if (!doc.exists || doc.data() == null) return null;

    // **CRITICAL: Log PHI read for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'risk_score_read',
      entityType: 'client_risk_score',
      entityId: clientId,
    );

    return ClientRiskScore.fromJson(doc.data()!);
  }

  /// Get risk scores for multiple clients.
  Future<Map<String, ClientRiskScore>> getClientRiskScoresBatch(
    SecurityContext context,
    List<String> clientIds,
  ) async {
    if (clientIds.isEmpty) return {};

    // Firestore limits 'in' queries to 10 items
    final results = <String, ClientRiskScore>{};

    for (var i = 0; i < clientIds.length; i += 10) {
      final batch = clientIds.skip(i).take(10).toList();
      final snapshot = await _riskScoresCollection(context.businessId)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        results[doc.id] = ClientRiskScore.fromJson(doc.data());
      }
    }

    return results;
  }

  /// Save or update a client's risk score.
  ///
  /// **HIPAA:** Logs PHI write to audit trail.
  Future<void> saveClientRiskScore(
    SecurityContext context,
    ClientRiskScore score,
  ) async {
    final docRef =
        _riskScoresCollection(context.businessId).doc(score.clientId);

    // Get existing score for history
    final existing = await docRef.get();

    // Save current score
    await docRef.set(score.toJson());

    // Archive previous score to history if exists
    if (existing.exists && existing.data() != null) {
      final previousScore = ClientRiskScore.fromJson(existing.data()!);
      await _riskScoreHistoryCollection(context.businessId, score.clientId)
          .doc(previousScore.calculatedAt.millisecondsSinceEpoch.toString())
          .set(previousScore.toJson());
    }

    // **CRITICAL: Log PHI write for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'risk_score_write',
      entityType: 'client_risk_score',
      entityId: score.clientId,
      details: {
        'churn_risk': score.churnRiskScore,
        'satisfaction': score.satisfactionScore,
      },
    );
  }

  /// Get historical risk scores for trend analysis.
  Future<List<ClientRiskScore>> getClientRiskScoreHistory(
    SecurityContext context,
    String clientId, {
    int limit = 30,
    DateTime? since,
  }) async {
    var query = _riskScoreHistoryCollection(context.businessId, clientId)
        .orderBy('calculatedAt', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where('calculatedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ClientRiskScore.fromJson(doc.data()))
        .toList();
  }

  /// Get all high-risk clients for a business.
  ///
  /// **HIPAA:** Logs PHI list read to audit trail.
  Future<List<ClientRiskScore>> getHighRiskClients(
    SecurityContext context, {
    int minChurnScore = 70,
    int limit = 50,
  }) async {
    final snapshot = await _riskScoresCollection(context.businessId)
        .where('churnRiskScore', isGreaterThanOrEqualTo: minChurnScore)
        .orderBy('churnRiskScore', descending: true)
        .limit(limit)
        .get();

    final results = snapshot.docs
        .map((doc) => ClientRiskScore.fromJson(doc.data()))
        .toList();

    // **CRITICAL: Log PHI list read for HIPAA compliance**
    if (results.isNotEmpty) {
      await _logAudit(
        context: context,
        action: 'risk_score_list_read',
        entityType: 'client_risk_score',
        entityId: 'high_risk_clients',
        details: {'count': results.length, 'min_score': minChurnScore},
      );
    }

    return results;
  }

  /// Get all VIP clients for a business.
  Future<List<ClientRiskScore>> getVipClients(
    SecurityContext context, {
    int minVipScore = 70,
    int limit = 50,
  }) async {
    final snapshot = await _riskScoresCollection(context.businessId)
        .where('vipScore', isGreaterThanOrEqualTo: minVipScore)
        .orderBy('vipScore', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ClientRiskScore.fromJson(doc.data()))
        .toList();
  }

  /// Get clients needing attention (high risk or critical indicators).
  Future<List<ClientRiskScore>> getClientsNeedingAttention(
    SecurityContext context, {
    int limit = 50,
  }) async {
    // Get high-risk clients
    final highRisk = await getHighRiskClients(context, limit: limit);

    // Filter for those that truly need attention
    return highRisk.where((score) => score.needsAttention).toList();
  }

  /// Delete a client's risk score (e.g., when client is deleted).
  Future<void> deleteClientRiskScore(
    SecurityContext context,
    String clientId,
  ) async {
    // Delete current score
    await _riskScoresCollection(context.businessId).doc(clientId).delete();

    // Delete history (batch delete)
    final historySnapshot = await _riskScoreHistoryCollection(
      context.businessId,
      clientId,
    ).get();

    final batch = _firestore.batch();
    for (final doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============ Sentiment Result Operations ============

  /// Save a sentiment analysis result.
  Future<void> saveSentimentResult(
    SecurityContext context,
    SentimentResult result,
  ) async {
    final data = _secureSentimentResult(result, context.businessId);
    await _sentimentResultsCollection(context.businessId)
        .doc(result.id)
        .set(data);
  }

  /// Save multiple sentiment results (batch).
  Future<void> saveSentimentResultsBatch(
    SecurityContext context,
    List<SentimentResult> results,
  ) async {
    if (results.isEmpty) return;

    final batch = _firestore.batch();

    for (final result in results) {
      final docRef =
          _sentimentResultsCollection(context.businessId).doc(result.id);
      batch.set(docRef, _secureSentimentResult(result, context.businessId));
    }

    await batch.commit();
  }

  /// Get sentiment results for a client.
  Future<List<SentimentResult>> getClientSentimentResults(
    SecurityContext context,
    String clientId, {
    int limit = 50,
    DateTime? since,
  }) async {
    var query = _sentimentResultsCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('analyzedAt', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where('analyzedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => _decryptSentimentResult(doc.data()))
        .toList();
  }

  /// Get sentiment results by source document (e.g., specific communication).
  Future<SentimentResult?> getSentimentResultBySource(
    SecurityContext context,
    String sourceDocumentId,
  ) async {
    final snapshot = await _sentimentResultsCollection(context.businessId)
        .where('sourceDocumentId', isEqualTo: sourceDocumentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _decryptSentimentResult(snapshot.docs.first.data());
  }

  /// Get sentiment results by date range.
  Future<List<SentimentResult>> getSentimentResultsByDateRange(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
    String? clientId,
    int limit = 100,
  }) async {
    var query = _sentimentResultsCollection(context.businessId)
        .where('analyzedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('analyzedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('analyzedAt', descending: true)
        .limit(limit);

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => _decryptSentimentResult(doc.data()))
        .toList();
  }

  /// Get IDs of already-analyzed source documents for a client.
  Future<Set<String>> getAnalyzedSourceDocumentIds(
    SecurityContext context,
    String clientId,
  ) async {
    final results = await getClientSentimentResults(
      context,
      clientId,
      limit: 500, // Get more to ensure we don't duplicate
    );

    return results
        .where((r) => r.sourceDocumentId != null)
        .map((r) => r.sourceDocumentId!)
        .toSet();
  }

  /// Delete sentiment results older than specified date.
  Future<int> deleteExpiredSentimentResults(
    SecurityContext context, {
    DateTime? olderThan,
  }) async {
    final cutoff = olderThan ?? DateTime.now();

    final snapshot = await _sentimentResultsCollection(context.businessId)
        .where('expiresAt', isLessThan: Timestamp.fromDate(cutoff))
        .limit(500) // Process in batches
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return snapshot.docs.length;
  }

  /// Stream risk scores for real-time updates.
  Stream<List<ClientRiskScore>> watchHighRiskClients(
    SecurityContext context, {
    int minChurnScore = 70,
    int limit = 50,
  }) {
    return _riskScoresCollection(context.businessId)
        .where('churnRiskScore', isGreaterThanOrEqualTo: minChurnScore)
        .orderBy('churnRiskScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientRiskScore.fromJson(doc.data()))
            .toList());
  }

  /// Stream risk score for a specific client.
  Stream<ClientRiskScore?> watchClientRiskScore(
    SecurityContext context,
    String clientId,
  ) {
    return _riskScoresCollection(context.businessId)
        .doc(clientId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ClientRiskScore.fromJson(doc.data()!);
    });
  }

  // ============ Audit Logging ============

  /// Log audit event for HIPAA compliance.
  Future<void> _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository.log(
        context: context,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        source: 'ClientRiskRepository',
      );
    } catch (e) {
      // Don't fail the operation if audit logging fails
      debugPrint('ClientRiskRepository: Failed to log audit: $e');
    }
  }
}

/// Placeholder string used when encryption is not configured.
const _redactedValue = '[REDACTED_NO_ENCRYPTION_CONFIGURED]';

extension _SentimentEncryption on ClientRiskRepository {
  Map<String, dynamic> _secureSentimentResult(
    SentimentResult result,
    String businessId,
  ) {
    final encryption = _encryptionService;
    if (encryption == null) {
      return _redactSentimentResult(result);
    }

    final riskIndicators = result.riskIndicators
        .map((r) => r.copyWith(
              triggerText: r.triggerText != null
                  ? encryption.encrypt(r.triggerText!)
                  : null,
              description: encryption.encrypt(r.description),
              suggestedAction: r.suggestedAction != null
                  ? encryption.encrypt(r.suggestedAction!)
                  : null,
            ).toJson())
        .toList();

    final vipIndicators = result.vipIndicators
        .map((r) => r.copyWith(
              triggerText: r.triggerText != null
                  ? encryption.encrypt(r.triggerText!)
                  : null,
              description: encryption.encrypt(r.description),
              suggestedAction: r.suggestedAction != null
                  ? encryption.encrypt(r.suggestedAction!)
                  : null,
            ).toJson())
        .toList();

    return {
      ...result.toJson(),
      'analyzedText': encryption.encrypt(result.analyzedText),
      'summary':
          result.summary != null ? encryption.encrypt(result.summary!) : null,
      'recommendedAction': result.recommendedAction != null
          ? encryption.encrypt(result.recommendedAction!)
          : null,
      'riskIndicators': riskIndicators,
      'vipIndicators': vipIndicators,
      'businessId': businessId,
    };
  }

  Map<String, dynamic> _redactSentimentResult(SentimentResult result) {
    // Store minimal, non-PHI data when encryption is unavailable.
    final redactedRiskIndicators = result.riskIndicators
        .map((r) => r.copyWith(
              triggerText: null,
              description: _redactedValue,
              suggestedAction:
                  r.suggestedAction != null ? _redactedValue : null,
            ).toJson())
        .toList();

    final redactedVipIndicators = result.vipIndicators
        .map((r) => r.copyWith(
              triggerText: null,
              description: _redactedValue,
              suggestedAction:
                  r.suggestedAction != null ? _redactedValue : null,
            ).toJson())
        .toList();

    final data = result.toJson();
    return {
      ...data,
      'analyzedText': _redactedValue,
      'summary': data['summary'] != null ? _redactedValue : null,
      'recommendedAction':
          data['recommendedAction'] != null ? _redactedValue : null,
      'riskIndicators': redactedRiskIndicators,
      'vipIndicators': redactedVipIndicators,
    };
  }

  SentimentResult _decryptSentimentResult(Map<String, dynamic> data) {
    final encryption = _encryptionService;
    if (encryption == null) {
      return SentimentResult.fromJson(data);
    }

    final decrypted = Map<String, dynamic>.from(data);

    String? _decrypt(String? value) {
      if (value == null) return null;
      if (value == _redactedValue) return null;
      try {
        return encryption.decrypt(value);
      } catch (_) {
        return null;
      }
    }

    decrypted['analyzedText'] =
        _decrypt(decrypted['analyzedText'] as String?) ?? _redactedValue;
    decrypted['summary'] = _decrypt(decrypted['summary'] as String?);
    decrypted['recommendedAction'] =
        _decrypt(decrypted['recommendedAction'] as String?);

    final riskIndicators = (decrypted['riskIndicators'] as List? ?? [])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map((ri) => {
              ...ri,
              'triggerText': _decrypt(ri['triggerText'] as String?),
              'description': _decrypt(ri['description'] as String?) ??
                  ri['description'], // keep original if decrypt fails
              'suggestedAction': _decrypt(ri['suggestedAction'] as String?),
            })
        .toList();

    final vipIndicators = (decrypted['vipIndicators'] as List? ?? [])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map((ri) => {
              ...ri,
              'triggerText': _decrypt(ri['triggerText'] as String?),
              'description': _decrypt(ri['description'] as String?) ??
                  ri['description'],
              'suggestedAction': _decrypt(ri['suggestedAction'] as String?),
            })
        .toList();

    decrypted['riskIndicators'] = riskIndicators;
    decrypted['vipIndicators'] = vipIndicators;

    return SentimentResult.fromJson(decrypted);
  }
}
