import 'dart:developer' as developer;

import '../../data/models/prediction_feedback.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/prediction_feedback_repository.dart';
import '../experiments/experiment_tracker.dart';

/// Service for collecting user feedback on AI predictions.
///
/// Handles feedback submission, validation, and experiment tracking.
/// Feedback is used to improve model quality and measure experiment outcomes.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class PredictionFeedbackService {
  PredictionFeedbackService({
    required PredictionFeedbackRepository repository,
    ExperimentTracker? experimentTracker,
  })  : _repository = repository,
        _experimentTracker = experimentTracker;

  final PredictionFeedbackRepository _repository;
  final ExperimentTracker? _experimentTracker;

  // ===== FEEDBACK SUBMISSION =====

  /// Submit feedback for a prediction.
  ///
  /// Call this when a user provides feedback on whether a prediction
  /// was helpful or accurate.
  Future<FeedbackSubmissionResult> submitFeedback({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required FeedbackType feedbackType,
    required String modelVersion,
    required double predictedProbability,
    required String predictedRiskLevel,
    String? predictionId,
    NegativeFeedbackReason? negativeReason,
    String? comment,
    String? experimentId,
    String? experimentVariantId,
    String? experimentAssignmentId,
  }) async {
    try {
      // Validate required fields for negative feedback
      if (feedbackType == FeedbackType.negative && negativeReason == null) {
        developer.log(
          'Warning: Negative feedback without reason',
          name: 'PredictionFeedbackService',
        );
      }

      // Determine user role for weighting
      final userRole = _determineUserRole(context);

      // Create feedback with calculated weight
      final feedback = PredictionFeedback.create(
        id: '', // Will be set by repository
        businessId: context.businessId,
        appointmentId: appointmentId,
        clientId: clientId,
        userId: context.userId,
        userRole: userRole,
        feedbackType: feedbackType,
        modelVersion: modelVersion,
        predictedProbability: predictedProbability,
        predictedRiskLevel: predictedRiskLevel,
        negativeReason: negativeReason,
        comment: comment,
        predictionId: predictionId,
        experimentId: experimentId,
        experimentVariantId: experimentVariantId,
      );

      // Submit to repository
      final submitted = await _repository.submitFeedback(
        context: context,
        feedback: feedback,
      );

      // Track conversion for experiment if applicable
      if (experimentAssignmentId != null && _experimentTracker != null) {
        await _experimentTracker.trackConversion(
          context: context,
          assignmentId: experimentAssignmentId,
          conversionType: 'feedback_submitted',
          metadata: {
            'feedbackType': feedbackType.name,
            'feedbackId': submitted.id,
          },
        );
      }

      developer.log(
        'Feedback submitted: ${submitted.id} (${feedbackType.name})',
        name: 'PredictionFeedbackService',
      );

      return FeedbackSubmissionResult(
        success: true,
        feedbackId: submitted.id,
        feedback: submitted,
      );
    } catch (e) {
      developer.log(
        'Failed to submit feedback: $e',
        name: 'PredictionFeedbackService',
        error: e,
      );

      return FeedbackSubmissionResult(
        success: false,
        error: 'Failed to submit feedback: $e',
      );
    }
  }

  /// Submit positive feedback (thumbs up).
  Future<FeedbackSubmissionResult> submitPositiveFeedback({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String modelVersion,
    required double predictedProbability,
    required String predictedRiskLevel,
    String? predictionId,
    String? comment,
    String? experimentId,
    String? experimentVariantId,
    String? experimentAssignmentId,
  }) async {
    return submitFeedback(
      context: context,
      appointmentId: appointmentId,
      clientId: clientId,
      feedbackType: FeedbackType.positive,
      modelVersion: modelVersion,
      predictedProbability: predictedProbability,
      predictedRiskLevel: predictedRiskLevel,
      predictionId: predictionId,
      comment: comment,
      experimentId: experimentId,
      experimentVariantId: experimentVariantId,
      experimentAssignmentId: experimentAssignmentId,
    );
  }

  /// Submit negative feedback (thumbs down).
  Future<FeedbackSubmissionResult> submitNegativeFeedback({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String modelVersion,
    required double predictedProbability,
    required String predictedRiskLevel,
    required NegativeFeedbackReason reason,
    String? predictionId,
    String? comment,
    String? experimentId,
    String? experimentVariantId,
    String? experimentAssignmentId,
  }) async {
    return submitFeedback(
      context: context,
      appointmentId: appointmentId,
      clientId: clientId,
      feedbackType: FeedbackType.negative,
      modelVersion: modelVersion,
      predictedProbability: predictedProbability,
      predictedRiskLevel: predictedRiskLevel,
      negativeReason: reason,
      predictionId: predictionId,
      comment: comment,
      experimentId: experimentId,
      experimentVariantId: experimentVariantId,
      experimentAssignmentId: experimentAssignmentId,
    );
  }

  /// Skip feedback for a prediction.
  Future<FeedbackSubmissionResult> skipFeedback({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String modelVersion,
    required double predictedProbability,
    required String predictedRiskLevel,
    String? predictionId,
    String? experimentId,
    String? experimentVariantId,
  }) async {
    return submitFeedback(
      context: context,
      appointmentId: appointmentId,
      clientId: clientId,
      feedbackType: FeedbackType.skipped,
      modelVersion: modelVersion,
      predictedProbability: predictedProbability,
      predictedRiskLevel: predictedRiskLevel,
      predictionId: predictionId,
      experimentId: experimentId,
      experimentVariantId: experimentVariantId,
    );
  }

  // ===== FEEDBACK QUERIES =====

  /// Check if feedback has been provided for an appointment.
  Future<bool> hasFeedbackForAppointment(
    SecurityContext context,
    String appointmentId,
  ) async {
    final feedback = await _repository.getFeedbackForAppointment(
      context,
      appointmentId,
    );
    return feedback != null;
  }

  /// Get feedback for an appointment if it exists.
  Future<PredictionFeedback?> getFeedbackForAppointment(
    SecurityContext context,
    String appointmentId,
  ) async {
    return _repository.getFeedbackForAppointment(context, appointmentId);
  }

  /// Get recent feedback for the business.
  Future<List<PredictionFeedback>> getRecentFeedback(
    SecurityContext context, {
    int limit = 50,
    FeedbackType? type,
  }) async {
    return _repository.getRecentFeedback(
      context,
      limit: limit,
      type: type,
    );
  }

  /// Stream feedback for an appointment.
  Stream<PredictionFeedback?> watchFeedbackForAppointment(
    SecurityContext context,
    String appointmentId,
  ) {
    return _repository.watchFeedbackForAppointment(context, appointmentId);
  }

  // ===== FEEDBACK ANALYSIS =====

  /// Get feedback summary for a model version.
  Future<FeedbackSummary> getFeedbackSummary(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
    String? experimentId,
    String? variantId,
  }) async {
    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    return _repository.getFeedbackSummary(
      context,
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      experimentId: experimentId,
      variantId: variantId,
    );
  }

  /// Get daily feedback trends for a model.
  Future<List<FeedbackSummary>> getFeedbackTrends(
    SecurityContext context, {
    required String modelVersion,
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return _repository.getDailyFeedbackTrends(
      context,
      modelVersion: modelVersion,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get breakdown of negative feedback reasons.
  Future<NegativeFeedbackAnalysis> analyzeNegativeFeedback(
    SecurityContext context, {
    required String modelVersion,
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final breakdown = await _repository.getNegativeReasonBreakdown(
      context,
      modelVersion: modelVersion,
      startDate: startDate,
      endDate: endDate,
    );

    final total = breakdown.values.fold<int>(0, (sum, count) => sum + count);

    final percentages = <NegativeFeedbackReason, double>{};
    final ranked = <NegativeFeedbackReason>[];

    if (total > 0) {
      for (final entry in breakdown.entries) {
        percentages[entry.key] = (entry.value / total) * 100;
      }

      // Rank by frequency
      final sorted = breakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      ranked.addAll(sorted.map((e) => e.key));
    }

    return NegativeFeedbackAnalysis(
      modelVersion: modelVersion,
      periodStart: startDate,
      periodEnd: endDate,
      totalNegativeFeedback: total,
      reasonCounts: breakdown,
      reasonPercentages: percentages,
      rankedReasons: ranked,
    );
  }

  /// Check if model quality is acceptable based on feedback.
  Future<QualityAssessment> assessModelQuality(
    SecurityContext context, {
    required String modelVersion,
    int days = 7,
    double minPositiveRate = 0.7,
    int minFeedbackCount = 10,
  }) async {
    final summary = await getFeedbackSummary(
      context,
      modelVersion: modelVersion,
      startDate: DateTime.now().subtract(Duration(days: days)),
    );

    final hasEnoughFeedback = summary.actionableFeedback >= minFeedbackCount;
    final positiveRate = summary.positiveRate;
    final meetsThreshold = positiveRate >= minPositiveRate;

    String status;
    if (!hasEnoughFeedback) {
      status = 'insufficient_data';
    } else if (meetsThreshold) {
      status = 'good';
    } else if (positiveRate >= minPositiveRate * 0.8) {
      status = 'acceptable';
    } else {
      status = 'poor';
    }

    return QualityAssessment(
      modelVersion: modelVersion,
      status: status,
      positiveRate: positiveRate,
      feedbackCount: summary.actionableFeedback,
      meetsThreshold: meetsThreshold,
      hasEnoughFeedback: hasEnoughFeedback,
      netScore: summary.netScore,
      summary: summary,
    );
  }

  // ===== TRAINING DATA =====

  /// Get unprocessed feedback for training.
  Future<List<PredictionFeedback>> getUnprocessedFeedback(
    SecurityContext context, {
    int limit = 100,
  }) async {
    return _repository.getUnprocessedFeedback(context, limit: limit);
  }

  /// Mark feedback as processed for training.
  Future<void> markFeedbackProcessed(
    SecurityContext context,
    List<String> feedbackIds,
  ) async {
    await _repository.markAsProcessed(context, feedbackIds);

    developer.log(
      'Marked ${feedbackIds.length} feedback records as processed',
      name: 'PredictionFeedbackService',
    );
  }

  // ===== HELPERS =====

  FeedbackUserRole _determineUserRole(SecurityContext context) {
    // Map UserRole to FeedbackUserRole for weighting
    switch (context.role) {
      case UserRole.owner:
      case UserRole.admin:
        return FeedbackUserRole.admin;
      case UserRole.staff:
        return FeedbackUserRole.staff;
      case UserRole.client:
        return FeedbackUserRole.guest;
    }
  }
}

/// Result of a feedback submission operation.
class FeedbackSubmissionResult {
  const FeedbackSubmissionResult({
    required this.success,
    this.feedbackId,
    this.feedback,
    this.error,
  });

  final bool success;
  final String? feedbackId;
  final PredictionFeedback? feedback;
  final String? error;
}

/// Analysis of negative feedback reasons.
class NegativeFeedbackAnalysis {
  const NegativeFeedbackAnalysis({
    required this.modelVersion,
    required this.periodStart,
    required this.periodEnd,
    required this.totalNegativeFeedback,
    required this.reasonCounts,
    required this.reasonPercentages,
    required this.rankedReasons,
  });

  final String modelVersion;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalNegativeFeedback;
  final Map<NegativeFeedbackReason, int> reasonCounts;
  final Map<NegativeFeedbackReason, double> reasonPercentages;
  final List<NegativeFeedbackReason> rankedReasons;

  /// Most common reason for negative feedback.
  NegativeFeedbackReason? get topReason =>
      rankedReasons.isNotEmpty ? rankedReasons.first : null;

  /// Top 3 reasons for negative feedback.
  List<NegativeFeedbackReason> get topReasons =>
      rankedReasons.take(3).toList();

  /// Check if probability calibration issues are prevalent.
  bool get hasCalibrationIssues {
    final highCount = reasonCounts[NegativeFeedbackReason.probabilityTooHigh] ?? 0;
    final lowCount = reasonCounts[NegativeFeedbackReason.probabilityTooLow] ?? 0;
    return (highCount + lowCount) / totalNegativeFeedback > 0.3;
  }

  /// Check if wrong factors are a major issue.
  bool get hasFactorIssues {
    final count = reasonCounts[NegativeFeedbackReason.wrongFactors] ?? 0;
    return count / totalNegativeFeedback > 0.2;
  }
}

/// Assessment of model quality based on feedback.
class QualityAssessment {
  const QualityAssessment({
    required this.modelVersion,
    required this.status,
    required this.positiveRate,
    required this.feedbackCount,
    required this.meetsThreshold,
    required this.hasEnoughFeedback,
    required this.netScore,
    required this.summary,
  });

  final String modelVersion;
  final String status; // 'good', 'acceptable', 'poor', 'insufficient_data'
  final double positiveRate;
  final int feedbackCount;
  final bool meetsThreshold;
  final bool hasEnoughFeedback;
  final double netScore;
  final FeedbackSummary summary;

  bool get isGood => status == 'good';
  bool get isAcceptable => status == 'good' || status == 'acceptable';
  bool get needsImprovement => status == 'poor';
  bool get hasInsufficientData => status == 'insufficient_data';
}
