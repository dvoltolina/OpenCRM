import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ai/models/prediction_outcome.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for storing and retrieving prediction outcomes.
///
/// Tracks predictions vs actual outcomes for model performance monitoring.
/// HIPAA compliant: stores only IDs, no PHI in outcome records.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class PredictionOutcomesRepository {
  PredictionOutcomesRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Record a new prediction for later outcome tracking.
  Future<PredictionOutcome> recordPrediction({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required double predictedProbability,
    required String predictedRiskLevel,
    required String modelVersion,
    required double confidence,
    required DateTime appointmentTime,
    List<String>? topFeatures,
    String? providerId,
    String? serviceId,
  }) async {
    final docRef = _outcomesCollection(context.businessId).doc();

    final outcome = PredictionOutcome(
      id: docRef.id,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      predictedProbability: predictedProbability,
      predictedRiskLevel: predictedRiskLevel,
      modelVersion: modelVersion,
      confidence: confidence,
      predictedAt: DateTime.now(),
      appointmentTime: appointmentTime,
      topFeatures: topFeatures ?? [],
      providerId: providerId,
      serviceId: serviceId,
    );

    final data = outcome.toJson();
    data['predictedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);

    // Audit log (non-blocking)
    _logAudit(
      context: context,
      action: 'prediction_recorded',
      entityType: 'prediction_outcome',
      entityId: docRef.id,
      details: {
        'appointmentId': appointmentId,
        'modelVersion': modelVersion,
        'riskLevel': predictedRiskLevel,
      },
    );

    return outcome;
  }

  /// Record the actual outcome for an appointment.
  Future<PredictionOutcome?> recordOutcome({
    required SecurityContext context,
    required String appointmentId,
    required AppointmentOutcome outcome,
  }) async {
    // Find the prediction record for this appointment
    final query = await _outcomesCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .where('outcome', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      developer.log(
        'No pending prediction found for appointment: $appointmentId',
        name: 'PredictionOutcomesRepository',
      );
      return null;
    }

    final doc = query.docs.first;
    final existingOutcome = PredictionOutcome.fromJson(doc.data());

    // Calculate evaluation metrics if outcome is usable
    final updatedOutcome = existingOutcome
        .copyWith(
          outcome: outcome,
          outcomeRecordedAt: DateTime.now(),
        )
        .withEvaluation();

    final updateData = <String, dynamic>{
      'outcome': outcome.name,
      'outcomeRecordedAt': FieldValue.serverTimestamp(),
    };

    if (updatedOutcome.predictionCorrect != null) {
      updateData['predictionCorrect'] = updatedOutcome.predictionCorrect;
    }
    if (updatedOutcome.predictionError != null) {
      updateData['predictionError'] = updatedOutcome.predictionError;
    }

    await doc.reference.update(updateData);

    // Audit log (non-blocking)
    _logAudit(
      context: context,
      action: 'outcome_recorded',
      entityType: 'prediction_outcome',
      entityId: doc.id,
      details: {
        'appointmentId': appointmentId,
        'outcome': outcome.name,
        'predictionCorrect': updatedOutcome.predictionCorrect,
      },
    );

    return updatedOutcome;
  }

  /// Get a prediction outcome by appointment ID.
  Future<PredictionOutcome?> getByAppointmentId(
    SecurityContext context,
    String appointmentId,
  ) async {
    final query = await _outcomesCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return PredictionOutcome.fromJson(query.docs.first.data());
  }

  /// Get all outcomes for a time period (for metrics calculation).
  Future<List<PredictionOutcome>> getOutcomesForPeriod({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    String? modelVersion,
  }) async {
    Query<Map<String, dynamic>> query = _outcomesCollection(context.businessId)
        .where('appointmentTime', isGreaterThanOrEqualTo: startDate)
        .where('appointmentTime', isLessThan: endDate);

    if (modelVersion != null) {
      query = query.where('modelVersion', isEqualTo: modelVersion);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PredictionOutcome.fromJson(doc.data()))
        .toList();
  }

  /// Get outcomes with recorded results (for evaluation).
  Future<List<PredictionOutcome>> getEvaluableOutcomes({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    String? modelVersion,
    int limit = 1000,
  }) async {
    Query<Map<String, dynamic>> query = _outcomesCollection(context.businessId)
        .where('appointmentTime', isGreaterThanOrEqualTo: startDate)
        .where('appointmentTime', isLessThan: endDate)
        .where('outcome', whereIn: ['attended', 'noshow']);

    if (modelVersion != null) {
      query = query.where('modelVersion', isEqualTo: modelVersion);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => PredictionOutcome.fromJson(doc.data()))
        .toList();
  }

  /// Get pending outcomes (appointments with predictions but no outcome yet).
  Future<List<PredictionOutcome>> getPendingOutcomes(
    SecurityContext context, {
    int limit = 100,
  }) async {
    final snapshot = await _outcomesCollection(context.businessId)
        .where('outcome', isEqualTo: 'pending')
        .where('appointmentTime', isLessThan: DateTime.now())
        .orderBy('appointmentTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => PredictionOutcome.fromJson(doc.data()))
        .toList();
  }

  /// Calculate summary metrics for a time period.
  Future<PredictionOutcomeSummary> calculateSummary({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final outcomes = await getOutcomesForPeriod(
      context: context,
      startDate: startDate,
      endDate: endDate,
    );

    final evaluable = outcomes.where((o) => o.canEvaluate).toList();
    final modelVersions = outcomes.map((o) => o.modelVersion).toSet().toList();

    int truePositives = 0;
    int trueNegatives = 0;
    int falsePositives = 0;
    int falseNegatives = 0;
    int actualNoShows = 0;

    for (final outcome in evaluable) {
      final isNoShow = outcome.actualNoShow!;
      final isHighRisk = outcome.predictedRiskLevel == 'high' ||
          outcome.predictedRiskLevel == 'medium';

      if (isNoShow) actualNoShows++;

      if (isHighRisk && isNoShow) {
        truePositives++;
      } else if (!isHighRisk && !isNoShow) {
        trueNegatives++;
      } else if (isHighRisk && !isNoShow) {
        falsePositives++;
      } else {
        falseNegatives++;
      }
    }

    return PredictionOutcomeSummary(
      periodStart: startDate,
      periodEnd: endDate,
      totalPredictions: outcomes.length,
      evaluatedPredictions: evaluable.length,
      correctPredictions: truePositives + trueNegatives,
      actualNoShows: actualNoShows,
      truePositives: truePositives,
      trueNegatives: trueNegatives,
      falsePositives: falsePositives,
      falseNegatives: falseNegatives,
      modelVersions: modelVersions,
    );
  }

  /// Count outcomes available for evaluation.
  Future<int> countEvaluableOutcomes(
    SecurityContext context, {
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = _outcomesCollection(context.businessId)
        .where('outcome', whereIn: ['attended', 'noshow']);

    if (since != null) {
      query = query.where('outcomeRecordedAt', isGreaterThan: since);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  CollectionReference<Map<String, dynamic>> _outcomesCollection(
      String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('prediction_outcomes');
  }

  void _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) {
    // Non-blocking audit log
    _auditLogRepository
        .log(
          context: context,
          action: action,
          entityType: entityType,
          entityId: entityId,
          details: details,
          source: 'PredictionOutcomesRepository',
        )
        .catchError((e) {
      developer.log(
        'Audit log failed (non-blocking): $e',
        name: 'PredictionOutcomesRepository',
      );
    });
  }
}
