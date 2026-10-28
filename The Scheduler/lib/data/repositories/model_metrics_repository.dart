import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ai/models/model_performance_snapshot.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for storing and retrieving model performance metrics.
///
/// Stores performance snapshots and baseline metrics for model monitoring.
/// HIPAA compliant: stores only aggregate metrics, no PHI.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class ModelMetricsRepository {
  ModelMetricsRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Save a performance snapshot.
  Future<ModelPerformanceSnapshot> saveSnapshot({
    required SecurityContext context,
    required ModelPerformanceSnapshot snapshot,
  }) async {
    final docRef = snapshot.id.isEmpty
        ? _snapshotsCollection(context.businessId).doc()
        : _snapshotsCollection(context.businessId).doc(snapshot.id);

    final snapshotWithId = snapshot.copyWith(id: docRef.id);
    final data = snapshotWithId.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);

    // Audit log for model monitoring (non-blocking)
    _logAudit(
      context: context,
      action: 'snapshot_saved',
      entityType: 'model_performance_snapshot',
      entityId: docRef.id,
      details: {
        'modelVersion': snapshot.modelVersion,
        'aucRoc': snapshot.aucRoc,
        'status': snapshot.status.name,
        'sampleSize': snapshot.sampleSize,
      },
    );

    return snapshotWithId;
  }

  /// Get the latest performance snapshot for a model version.
  Future<ModelPerformanceSnapshot?> getLatestSnapshot(
    SecurityContext context, {
    String? modelVersion,
  }) async {
    Query<Map<String, dynamic>> query =
        _snapshotsCollection(context.businessId)
            .orderBy('createdAt', descending: true);

    if (modelVersion != null) {
      query = query.where('modelVersion', isEqualTo: modelVersion);
    }

    final snapshot = await query.limit(1).get();
    if (snapshot.docs.isEmpty) return null;

    return ModelPerformanceSnapshot.fromJson(snapshot.docs.first.data());
  }

  /// Get performance snapshots for a time period.
  Future<List<ModelPerformanceSnapshot>> getSnapshots({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    String? modelVersion,
  }) async {
    Query<Map<String, dynamic>> query =
        _snapshotsCollection(context.businessId)
            .where('createdAt', isGreaterThanOrEqualTo: startDate)
            .where('createdAt', isLessThan: endDate)
            .orderBy('createdAt', descending: true);

    if (modelVersion != null) {
      query = query.where('modelVersion', isEqualTo: modelVersion);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ModelPerformanceSnapshot.fromJson(doc.data()))
        .toList();
  }

  /// Get snapshots that triggered retraining.
  Future<List<ModelPerformanceSnapshot>> getRetrainingTriggerSnapshots(
    SecurityContext context, {
    int limit = 10,
  }) async {
    final snapshot = await _snapshotsCollection(context.businessId)
        .where('retrainingTriggered', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ModelPerformanceSnapshot.fromJson(doc.data()))
        .toList();
  }

  /// Save baseline metrics for a model version.
  Future<void> saveBaseline({
    required SecurityContext context,
    required ModelBaselineMetrics baseline,
  }) async {
    final docRef = _baselinesCollection(context.businessId)
        .doc(baseline.modelVersion);

    await docRef.set(baseline.toJson());

    _logAudit(
      context: context,
      action: 'baseline_saved',
      entityType: 'model_baseline',
      entityId: baseline.modelVersion,
      details: {
        'aucRoc': baseline.aucRoc,
        'trainingSampleSize': baseline.trainingSampleSize,
      },
    );
  }

  /// Get baseline metrics for a model version.
  Future<ModelBaselineMetrics?> getBaseline(
    SecurityContext context,
    String modelVersion,
  ) async {
    final doc = await _baselinesCollection(context.businessId)
        .doc(modelVersion)
        .get();

    if (!doc.exists) return null;
    return ModelBaselineMetrics.fromJson(doc.data()!);
  }

  /// Get monitoring thresholds for a business.
  Future<MonitoringThresholds> getThresholds(SecurityContext context) async {
    final doc = await _configCollection(context.businessId)
        .doc('monitoring_thresholds')
        .get();

    if (!doc.exists) return const MonitoringThresholds();
    return MonitoringThresholds.fromJson(doc.data()!);
  }

  /// Save monitoring thresholds for a business.
  Future<void> saveThresholds({
    required SecurityContext context,
    required MonitoringThresholds thresholds,
  }) async {
    await _configCollection(context.businessId)
        .doc('monitoring_thresholds')
        .set(thresholds.toJson());

    _logAudit(
      context: context,
      action: 'thresholds_updated',
      entityType: 'monitoring_config',
      entityId: 'monitoring_thresholds',
      details: {
        'minAuc': thresholds.minAuc,
        'maxCalibrationError': thresholds.maxCalibrationError,
      },
    );
  }

  /// Mark a snapshot as having triggered retraining.
  Future<void> markRetrainingTriggered(
    SecurityContext context,
    String snapshotId,
  ) async {
    await _snapshotsCollection(context.businessId)
        .doc(snapshotId)
        .update({'retrainingTriggered': true});

    _logAudit(
      context: context,
      action: 'retraining_triggered',
      entityType: 'model_performance_snapshot',
      entityId: snapshotId,
      details: {},
    );
  }

  /// Get AUC trend over time (for dashboard display).
  Future<List<Map<String, dynamic>>> getAucTrend({
    required SecurityContext context,
    required int days,
    String? modelVersion,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    Query<Map<String, dynamic>> query =
        _snapshotsCollection(context.businessId)
            .where('createdAt', isGreaterThanOrEqualTo: startDate)
            .orderBy('createdAt');

    if (modelVersion != null) {
      query = query.where('modelVersion', isEqualTo: modelVersion);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['createdAt'] as Timestamp).toDate(),
        'aucRoc': data['aucRoc'],
        'status': data['status'],
        'sampleSize': data['sampleSize'],
      };
    }).toList();
  }

  /// Delete old snapshots (retention policy).
  Future<int> deleteOldSnapshots(
    SecurityContext context, {
    required int retentionDays,
  }) async {
    final cutoffDate =
        DateTime.now().subtract(Duration(days: retentionDays));

    final snapshot = await _snapshotsCollection(context.businessId)
        .where('createdAt', isLessThan: cutoffDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    developer.log(
      'Deleted ${snapshot.docs.length} old snapshots',
      name: 'ModelMetricsRepository',
    );

    return snapshot.docs.length;
  }

  CollectionReference<Map<String, dynamic>> _snapshotsCollection(
      String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('model_performance_snapshots');
  }

  CollectionReference<Map<String, dynamic>> _baselinesCollection(
      String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('model_baselines');
  }

  CollectionReference<Map<String, dynamic>> _configCollection(
      String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('ai_config');
  }

  void _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) {
    _auditLogRepository
        .log(
          context: context,
          action: action,
          entityType: entityType,
          entityId: entityId,
          details: details,
          source: 'ModelMetricsRepository',
        )
        .catchError((e) {
      developer.log(
        'Audit log failed (non-blocking): $e',
        name: 'ModelMetricsRepository',
      );
    });
  }
}
