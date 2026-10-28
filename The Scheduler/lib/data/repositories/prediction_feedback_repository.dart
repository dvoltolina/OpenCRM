import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prediction_feedback.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for storing and retrieving prediction feedback.
///
/// Collects user feedback on AI predictions to improve model quality.
/// Feedback is weighted by user role and aggregated for analysis.
///
/// HIPAA compliant: stores feedback metadata, not PHI.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class PredictionFeedbackRepository {
  PredictionFeedbackRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  // ===== FEEDBACK CRUD =====

  /// Submit feedback for a prediction.
  Future<PredictionFeedback> submitFeedback({
    required SecurityContext context,
    required PredictionFeedback feedback,
  }) async {
    final docRef = _feedbackCollection(context.businessId).doc();

    final feedbackWithId = PredictionFeedback(
      id: docRef.id,
      businessId: context.businessId,
      appointmentId: feedback.appointmentId,
      clientId: feedback.clientId,
      predictionId: feedback.predictionId,
      userId: feedback.userId,
      userRole: feedback.userRole,
      feedbackType: feedback.feedbackType,
      negativeReason: feedback.negativeReason,
      comment: feedback.comment,
      modelVersion: feedback.modelVersion,
      predictedProbability: feedback.predictedProbability,
      predictedRiskLevel: feedback.predictedRiskLevel,
      submittedAt: DateTime.now(),
      experimentId: feedback.experimentId,
      experimentVariantId: feedback.experimentVariantId,
      weight: feedback.weight,
    );

    await docRef.set(feedbackWithId.toJson());

    _logAudit(
      context: context,
      action: 'feedback_submitted',
      entityType: 'prediction_feedback',
      entityId: docRef.id,
      details: {
        'feedbackType': feedback.feedbackType.name,
        'appointmentId': feedback.appointmentId,
        'modelVersion': feedback.modelVersion,
      },
    );

    return feedbackWithId;
  }

  /// Get feedback by ID.
  Future<PredictionFeedback?> getFeedback(
    SecurityContext context,
    String feedbackId,
  ) async {
    final doc = await _feedbackCollection(context.businessId)
        .doc(feedbackId)
        .get();

    if (!doc.exists) return null;
    return PredictionFeedback.fromJson(doc.data()!);
  }

  /// Get feedback for a specific appointment.
  Future<PredictionFeedback?> getFeedbackForAppointment(
    SecurityContext context,
    String appointmentId,
  ) async {
    final snapshot = await _feedbackCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PredictionFeedback.fromJson(snapshot.docs.first.data());
  }

  /// Get feedback for a specific prediction.
  Future<List<PredictionFeedback>> getFeedbackForPrediction(
    SecurityContext context,
    String predictionId,
  ) async {
    final snapshot = await _feedbackCollection(context.businessId)
        .where('predictionId', isEqualTo: predictionId)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();
  }

  /// Get all feedback for a model version.
  Future<List<PredictionFeedback>> getFeedbackForModelVersion(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _feedbackCollection(context.businessId)
        .where('modelVersion', isEqualTo: modelVersion)
        .orderBy('submittedAt', descending: true);

    if (startDate != null) {
      query = query.where('submittedAt', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('submittedAt', isLessThanOrEqualTo: endDate);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();
  }

  /// Get feedback for an experiment variant.
  Future<List<PredictionFeedback>> getFeedbackForExperimentVariant(
    SecurityContext context, {
    required String experimentId,
    required String variantId,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _feedbackCollection(context.businessId)
        .where('experimentId', isEqualTo: experimentId)
        .where('experimentVariantId', isEqualTo: variantId)
        .orderBy('submittedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();
  }

  /// Get recent feedback for the business.
  Future<List<PredictionFeedback>> getRecentFeedback(
    SecurityContext context, {
    int limit = 50,
    FeedbackType? type,
  }) async {
    Query<Map<String, dynamic>> query = _feedbackCollection(context.businessId)
        .orderBy('submittedAt', descending: true);

    if (type != null) {
      query = query.where('feedbackType', isEqualTo: type.name);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();
  }

  /// Mark feedback as processed for training.
  Future<void> markAsProcessed(
    SecurityContext context,
    List<String> feedbackIds,
  ) async {
    final batch = _firestore.batch();

    for (final id in feedbackIds) {
      batch.update(
        _feedbackCollection(context.businessId).doc(id),
        {
          'processedForTraining': true,
          'processedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    _logAudit(
      context: context,
      action: 'feedback_processed',
      entityType: 'prediction_feedback',
      entityId: 'batch',
      details: {'count': feedbackIds.length},
    );
  }

  /// Get unprocessed feedback for training.
  Future<List<PredictionFeedback>> getUnprocessedFeedback(
    SecurityContext context, {
    int limit = 100,
  }) async {
    final snapshot = await _feedbackCollection(context.businessId)
        .where('processedForTraining', isEqualTo: false)
        .orderBy('submittedAt')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();
  }

  // ===== AGGREGATION =====

  /// Get feedback summary for a time period.
  Future<FeedbackSummary> getFeedbackSummary(
    SecurityContext context, {
    required String modelVersion,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? experimentId,
    String? variantId,
  }) async {
    Query<Map<String, dynamic>> query = _feedbackCollection(context.businessId)
        .where('modelVersion', isEqualTo: modelVersion)
        .where('submittedAt', isGreaterThanOrEqualTo: periodStart)
        .where('submittedAt', isLessThanOrEqualTo: periodEnd);

    if (experimentId != null) {
      query = query.where('experimentId', isEqualTo: experimentId);
    }

    if (variantId != null) {
      query = query.where('experimentVariantId', isEqualTo: variantId);
    }

    final snapshot = await query.get();
    final feedbackList = snapshot.docs
        .map((doc) => PredictionFeedback.fromJson(doc.data()))
        .toList();

    return _aggregateFeedback(
      feedbackList,
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      businessId: context.businessId,
      experimentId: experimentId,
      variantId: variantId,
    );
  }

  /// Get feedback summaries by day for trend analysis.
  Future<List<FeedbackSummary>> getDailyFeedbackTrends(
    SecurityContext context, {
    required String modelVersion,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summaries = <FeedbackSummary>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!currentDate.isAfter(end)) {
      final dayEnd = currentDate.add(const Duration(days: 1));

      final summary = await getFeedbackSummary(
        context,
        modelVersion: modelVersion,
        periodStart: currentDate,
        periodEnd: dayEnd,
      );

      summaries.add(summary);
      currentDate = dayEnd;
    }

    return summaries;
  }

  /// Aggregate feedback by negative reason.
  Future<Map<NegativeFeedbackReason, int>> getNegativeReasonBreakdown(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _feedbackCollection(context.businessId)
        .where('modelVersion', isEqualTo: modelVersion)
        .where('feedbackType', isEqualTo: FeedbackType.negative.name);

    if (startDate != null) {
      query = query.where('submittedAt', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('submittedAt', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    final breakdown = <NegativeFeedbackReason, int>{};

    for (final doc in snapshot.docs) {
      final feedback = PredictionFeedback.fromJson(doc.data());
      if (feedback.negativeReason != null) {
        breakdown[feedback.negativeReason!] =
            (breakdown[feedback.negativeReason!] ?? 0) + 1;
      }
    }

    return breakdown;
  }

  // ===== STREAMING =====

  /// Stream recent feedback updates.
  Stream<List<PredictionFeedback>> watchRecentFeedback(
    SecurityContext context, {
    int limit = 20,
  }) {
    return _feedbackCollection(context.businessId)
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PredictionFeedback.fromJson(doc.data()))
            .toList());
  }

  /// Stream feedback for a specific appointment.
  Stream<PredictionFeedback?> watchFeedbackForAppointment(
    SecurityContext context,
    String appointmentId,
  ) {
    return _feedbackCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return PredictionFeedback.fromJson(snapshot.docs.first.data());
    });
  }

  // ===== HELPERS =====

  CollectionReference<Map<String, dynamic>> _feedbackCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('prediction_feedback');
  }

  FeedbackSummary _aggregateFeedback(
    List<PredictionFeedback> feedbackList, {
    required String modelVersion,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? businessId,
    String? experimentId,
    String? variantId,
  }) {
    int positiveCount = 0;
    int negativeCount = 0;
    int skippedCount = 0;
    double weightedScoreSum = 0;
    double totalWeight = 0;
    final negativeReasonCounts = <String, int>{};

    for (final feedback in feedbackList) {
      switch (feedback.feedbackType) {
        case FeedbackType.positive:
          positiveCount++;
          weightedScoreSum += feedback.weight;
          totalWeight += feedback.weight;
          break;
        case FeedbackType.negative:
          negativeCount++;
          weightedScoreSum -= feedback.weight;
          totalWeight += feedback.weight;
          if (feedback.negativeReason != null) {
            final reasonName = feedback.negativeReason!.name;
            negativeReasonCounts[reasonName] =
                (negativeReasonCounts[reasonName] ?? 0) + 1;
          }
          break;
        case FeedbackType.skipped:
          skippedCount++;
          break;
      }
    }

    // Sort negative reasons by count
    final sortedReasons = negativeReasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReasons = sortedReasons.take(5).map((e) => e.key).toList();

    return FeedbackSummary(
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalFeedback: feedbackList.length,
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      skippedCount: skippedCount,
      weightedScoreSum: weightedScoreSum,
      totalWeight: totalWeight,
      negativeReasonCounts: negativeReasonCounts,
      topNegativeReasons: topReasons,
      businessId: businessId,
      experimentId: experimentId,
      variantId: variantId,
    );
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
          source: 'PredictionFeedbackRepository',
        )
        .catchError((e) {
      developer.log(
        'Audit log failed (non-blocking): $e',
        name: 'PredictionFeedbackRepository',
      );
    });
  }
}
