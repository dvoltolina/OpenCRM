import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/noshow_prediction.dart';
import '../models/prediction_features.dart';

/// Repository for storing and retrieving prediction features.
///
/// Features are stored for:
/// - Training data export (historical features + outcomes)
/// - Prediction auditing (what features led to predictions)
/// - Model performance tracking (predicted vs actual outcomes)
///
/// Collection structure:
/// ```
/// businesses/{businessId}/featureStore/{featureId}
///   - appointmentId: string
///   - features: PredictionFeatures (embedded)
///   - prediction: NoshowPrediction? (linked after prediction)
///   - actualOutcome: string? ('noshow', 'show', 'cancelled')
///   - extractedAt: timestamp
///   - createdAt: timestamp
///   - updatedAt: timestamp?
/// ```
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// **HIPAA Compliance:** All PHI access is logged to AuditLogRepository.
class FeatureStoreRepository {
  FeatureStoreRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository;

  final FirebaseFirestore _firestore;
  final AuditLogRepository? _auditLogRepository;
  final _uuid = const Uuid();

  /// Collection name for feature store
  static const String _collectionName = 'featureStore';

  /// TTL for old feature records (days)
  static const int _featureTtlDays = 365;

  /// Get the feature store collection for a business
  CollectionReference<Map<String, dynamic>> _featureCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection(_collectionName);
  }

  /// Store extracted features for an appointment
  ///
  /// **HIPAA:** Logs PHI write to audit trail.
  Future<String> storeFeatures({
    required SecurityContext context,
    required PredictionFeatures features,
  }) async {
    final featureId = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'appointmentId': features.appointmentId,
      'features': features.toJson(),
      'extractedAt': Timestamp.fromDate(features.extractedAt),
      'createdAt': Timestamp.fromDate(now),
      'featureSchemaVersion': features.featureSchemaVersion,
    };

    await _featureCollection(context.businessId).doc(featureId).set(data);

    // **CRITICAL: Log PHI write for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'feature_store_write',
      entityType: 'feature_record',
      entityId: featureId,
      details: {'appointment_id': features.appointmentId},
    );

    return featureId;
  }

  /// Store features in bulk (for batch processing)
  Future<List<String>> storeFeaturesBatch({
    required SecurityContext context,
    required List<PredictionFeatures> featuresList,
  }) async {
    if (featuresList.isEmpty) return [];

    final batch = _firestore.batch();
    final ids = <String>[];
    final now = DateTime.now();

    for (final features in featuresList) {
      final featureId = _uuid.v4();
      ids.add(featureId);

      final docRef = _featureCollection(context.businessId).doc(featureId);
      batch.set(docRef, {
        'appointmentId': features.appointmentId,
        'features': features.toJson(),
        'extractedAt': Timestamp.fromDate(features.extractedAt),
        'createdAt': Timestamp.fromDate(now),
        'featureSchemaVersion': features.featureSchemaVersion,
      });
    }

    await batch.commit();
    return ids;
  }

  /// Get stored features by appointment ID
  Future<StoredFeatureRecord?> getFeaturesByAppointmentId({
    required SecurityContext context,
    required String appointmentId,
  }) async {
    final query = await _featureCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return _parseFeatureRecord(query.docs.first);
  }

  /// Get stored features by feature ID
  Future<StoredFeatureRecord?> getFeaturesById({
    required SecurityContext context,
    required String featureId,
  }) async {
    final doc = await _featureCollection(context.businessId).doc(featureId).get();
    if (!doc.exists) return null;
    return _parseFeatureRecord(doc);
  }

  /// Link a prediction to stored features
  Future<void> linkPrediction({
    required SecurityContext context,
    required String featureId,
    required NoshowPrediction prediction,
  }) async {
    await _featureCollection(context.businessId).doc(featureId).update({
      'prediction': prediction.toJson(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update the actual outcome after an appointment is completed
  Future<void> updateActualOutcome({
    required SecurityContext context,
    required String appointmentId,
    required AppointmentOutcome outcome,
  }) async {
    // Find the feature record for this appointment
    final query = await _featureCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .get();

    if (query.docs.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());

    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'actualOutcome': outcome.name,
        'outcomeUpdatedAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  /// Query features by date range (for training data export)
  Future<List<StoredFeatureRecord>> queryFeaturesByDateRange({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    bool withOutcomesOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _featureCollection(context.businessId)
        .where('extractedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('extractedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('extractedAt', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    final records = snapshot.docs.map(_parseFeatureRecord).toList();

    // Filter for outcomes if requested
    if (withOutcomesOnly) {
      return records.where((r) => r.actualOutcome != null).toList();
    }

    return records;
  }

  /// Query features with known outcomes (for model training)
  Future<List<StoredFeatureRecord>> queryTrainingData({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    return queryFeaturesByDateRange(
      context: context,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      withOutcomesOnly: true,
    );
  }

  /// Export training data as CSV-ready format
  ///
  /// **HIPAA:** Logs data export to audit trail.
  Future<List<Map<String, dynamic>>> exportTrainingData({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await queryTrainingData(
      context: context,
      startDate: startDate,
      endDate: endDate,
    );

    // **CRITICAL: Log data export for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'feature_store_export',
      entityType: 'training_data',
      entityId: 'batch_export',
      details: {
        'record_count': records.length,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );

    return records.map((record) {
      final features = record.features;
      return {
        // Feature columns
        ...features.toJson(),
        // Target column
        'actualOutcome': record.actualOutcome?.name,
        'isNoShow': record.actualOutcome == AppointmentOutcome.noshow ? 1 : 0,
        // Metadata
        'predictionProbability': record.prediction?.probability,
        'predictionRiskLevel': record.prediction?.riskLevel.name,
        'appointmentId': record.appointmentId,
        'extractedAt': record.extractedAt.toIso8601String(),
      };
    }).toList();
  }

  /// Delete old feature records (TTL cleanup)
  Future<int> cleanupOldFeatures({
    required SecurityContext context,
    DateTime? olderThan,
  }) async {
    final cutoff = olderThan ??
        DateTime.now().subtract(Duration(days: _featureTtlDays));

    final query = await _featureCollection(context.businessId)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .limit(500) // Process in batches
        .get();

    if (query.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return query.docs.length;
  }

  /// Get statistics about the feature store
  Future<FeatureStoreStats> getStats({
    required SecurityContext context,
  }) async {
    // Get counts using aggregation queries
    final totalSnapshot = await _featureCollection(context.businessId).count().get();
    final total = totalSnapshot.count ?? 0;

    // Count with outcomes
    final withOutcomesSnapshot = await _featureCollection(context.businessId)
        .where('actualOutcome', isNull: false)
        .count()
        .get();
    final withOutcomes = withOutcomesSnapshot.count ?? 0;

    // Count with predictions
    final withPredictionsSnapshot = await _featureCollection(context.businessId)
        .where('prediction', isNull: false)
        .count()
        .get();
    final withPredictions = withPredictionsSnapshot.count ?? 0;

    // Get most recent record
    final recentSnapshot = await _featureCollection(context.businessId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    DateTime? lastExtractedAt;
    if (recentSnapshot.docs.isNotEmpty) {
      final data = recentSnapshot.docs.first.data();
      final timestamp = data['createdAt'] as Timestamp?;
      lastExtractedAt = timestamp?.toDate();
    }

    return FeatureStoreStats(
      totalRecords: total,
      recordsWithOutcomes: withOutcomes,
      recordsWithPredictions: withPredictions,
      lastExtractedAt: lastExtractedAt,
    );
  }

  // ============ Private Methods ============

  StoredFeatureRecord _parseFeatureRecord(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    // Parse features
    final featuresData = data['features'] as Map<String, dynamic>;
    final features = PredictionFeatures.fromJson(featuresData);

    // Parse prediction if present
    NoshowPrediction? prediction;
    if (data['prediction'] != null) {
      prediction = NoshowPrediction.fromJson(
        data['prediction'] as Map<String, dynamic>,
      );
    }

    // Parse outcome if present
    AppointmentOutcome? outcome;
    if (data['actualOutcome'] != null) {
      final outcomeStr = data['actualOutcome'] as String;
      outcome = AppointmentOutcome.values.firstWhere(
        (o) => o.name == outcomeStr,
        orElse: () => AppointmentOutcome.show,
      );
    }

    return StoredFeatureRecord(
      id: doc.id,
      appointmentId: data['appointmentId'] as String,
      features: features,
      prediction: prediction,
      actualOutcome: outcome,
      extractedAt: (data['extractedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

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
        source: 'FeatureStoreRepository',
      );
    } catch (e) {
      // Don't fail the operation if audit logging fails
      debugPrint('FeatureStoreRepository: Failed to log audit: $e');
    }
  }
}

/// Actual outcome after an appointment
enum AppointmentOutcome {
  /// Client showed up
  show,

  /// Client did not show up
  noshow,

  /// Appointment was cancelled
  cancelled,
}

/// A stored feature record with optional prediction and outcome
class StoredFeatureRecord {
  const StoredFeatureRecord({
    required this.id,
    required this.appointmentId,
    required this.features,
    required this.extractedAt,
    required this.createdAt,
    this.prediction,
    this.actualOutcome,
    this.updatedAt,
  });

  final String id;
  final String appointmentId;
  final PredictionFeatures features;
  final NoshowPrediction? prediction;
  final AppointmentOutcome? actualOutcome;
  final DateTime extractedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Check if this record has both prediction and outcome (for accuracy analysis)
  bool get hasCompleteFeedbackLoop =>
      prediction != null && actualOutcome != null;

  /// Check if prediction was correct (if we have both prediction and outcome)
  bool? get predictionWasCorrect {
    if (!hasCompleteFeedbackLoop) return null;

    final predictedNoshow = prediction!.riskLevel == RiskLevel.high;
    final actualNoshow = actualOutcome == AppointmentOutcome.noshow;

    return predictedNoshow == actualNoshow;
  }
}

/// Statistics about the feature store
class FeatureStoreStats {
  const FeatureStoreStats({
    required this.totalRecords,
    required this.recordsWithOutcomes,
    required this.recordsWithPredictions,
    this.lastExtractedAt,
  });

  final int totalRecords;
  final int recordsWithOutcomes;
  final int recordsWithPredictions;
  final DateTime? lastExtractedAt;

  /// Percentage of records with outcomes
  double get outcomeCompletionRate =>
      totalRecords > 0 ? recordsWithOutcomes / totalRecords : 0.0;

  /// Percentage of records with predictions
  double get predictionCoverageRate =>
      totalRecords > 0 ? recordsWithPredictions / totalRecords : 0.0;
}
