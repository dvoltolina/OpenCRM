import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../data/models/security_context.dart';
import '../../data/repositories/model_metrics_repository.dart';
import '../../data/repositories/prediction_outcomes_repository.dart';
import '../models/model_performance_snapshot.dart';
import 'drift_detector.dart';
import 'model_performance_service.dart';

/// Reason for triggering retraining.
enum RetrainReason {
  /// AUC dropped below threshold
  lowAuc,

  /// Calibration error exceeded threshold
  highCalibrationError,

  /// Significant drift detected
  driftDetected,

  /// Sufficient new data accumulated
  newDataAccumulated,

  /// Scheduled periodic retraining
  scheduledInterval,

  /// Manually triggered by admin
  manualTrigger,
}

extension RetrainReasonExtension on RetrainReason {
  String get displayName {
    switch (this) {
      case RetrainReason.lowAuc:
        return 'Low AUC';
      case RetrainReason.highCalibrationError:
        return 'High Calibration Error';
      case RetrainReason.driftDetected:
        return 'Drift Detected';
      case RetrainReason.newDataAccumulated:
        return 'New Data Available';
      case RetrainReason.scheduledInterval:
        return 'Scheduled Interval';
      case RetrainReason.manualTrigger:
        return 'Manual Trigger';
    }
  }

  String get description {
    switch (this) {
      case RetrainReason.lowAuc:
        return 'Model AUC-ROC has dropped below acceptable threshold';
      case RetrainReason.highCalibrationError:
        return 'Model calibration error exceeds threshold';
      case RetrainReason.driftDetected:
        return 'Significant data or concept drift detected';
      case RetrainReason.newDataAccumulated:
        return 'Sufficient new labeled data is available';
      case RetrainReason.scheduledInterval:
        return 'Regular scheduled retraining interval reached';
      case RetrainReason.manualTrigger:
        return 'Administrator manually triggered retraining';
    }
  }
}

/// Result of a retraining trigger evaluation or request.
class RetrainTriggerResult {
  final bool shouldRetrain;
  final List<RetrainReason> reasons;
  final ModelPerformanceSnapshot? snapshot;
  final DriftAnalysis? driftAnalysis;
  final int newOutcomesCount;
  final DateTime evaluatedAt;
  final bool retrainRequested;
  final String? retrainJobId;
  final String? error;

  RetrainTriggerResult({
    required this.shouldRetrain,
    required this.reasons,
    this.snapshot,
    this.driftAnalysis,
    required this.newOutcomesCount,
    required this.evaluatedAt,
    this.retrainRequested = false,
    this.retrainJobId,
    this.error,
  });

  String get summaryText {
    if (!shouldRetrain) return 'No retraining needed';
    if (error != null) return 'Retraining evaluation failed: $error';
    if (retrainRequested) {
      return 'Retraining triggered (job: ${retrainJobId ?? "unknown"})';
    }
    return 'Retraining recommended: ${reasons.map((r) => r.displayName).join(", ")}';
  }
}

/// Service for evaluating and triggering model retraining.
///
/// Automatically evaluates when retraining is needed based on:
/// - AUC dropping below threshold (e.g., 0.75)
/// - Sufficient new training data (e.g., 1000+ outcomes)
/// - Scheduled interval (e.g., monthly)
/// - Significant drift detected
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class RetrainTrigger {
  RetrainTrigger({
    required ModelPerformanceService performanceService,
    required DriftDetector driftDetector,
    required PredictionOutcomesRepository outcomesRepository,
    required ModelMetricsRepository metricsRepository,
    String? retrainEndpoint,
  })  : _performanceService = performanceService,
        _driftDetector = driftDetector,
        _outcomesRepository = outcomesRepository,
        _metricsRepository = metricsRepository,
        _retrainEndpoint = retrainEndpoint;

  final ModelPerformanceService _performanceService;
  final DriftDetector _driftDetector;
  final PredictionOutcomesRepository _outcomesRepository;
  final ModelMetricsRepository _metricsRepository;
  final String? _retrainEndpoint;

  /// Evaluate whether retraining is needed.
  Future<RetrainTriggerResult> evaluateRetraining({
    required SecurityContext context,
    required String modelVersion,
    DateTime? lastRetrainDate,
  }) async {
    final reasons = <RetrainReason>[];
    final thresholds = await _metricsRepository.getThresholds(context);

    try {
      // 1. Check performance metrics
      final snapshot = await _performanceService.calculateRollingMetrics(
        context: context,
        modelVersion: modelVersion,
      );

      if (snapshot != null) {
        if (snapshot.aucRoc < thresholds.minAuc) {
          reasons.add(RetrainReason.lowAuc);
        }
        if (snapshot.calibrationError > thresholds.maxCalibrationError) {
          reasons.add(RetrainReason.highCalibrationError);
        }
      }

      // 2. Check for drift
      final driftAnalysis = await _driftDetector.detectDrift(
        context: context,
        modelVersion: modelVersion,
      );

      if (driftAnalysis.hasDrift && driftAnalysis.overallScore > thresholds.driftThreshold) {
        reasons.add(RetrainReason.driftDetected);
      }

      // 3. Check for new data accumulation
      final newOutcomesCount = await _outcomesRepository.countEvaluableOutcomes(
        context,
        since: lastRetrainDate,
      );

      if (newOutcomesCount >= thresholds.minOutcomesForRetraining) {
        reasons.add(RetrainReason.newDataAccumulated);
      }

      // 4. Check scheduled interval (default: 30 days)
      if (lastRetrainDate != null) {
        final daysSinceRetrain = DateTime.now().difference(lastRetrainDate).inDays;
        if (daysSinceRetrain >= 30) {
          reasons.add(RetrainReason.scheduledInterval);
        }
      }

      return RetrainTriggerResult(
        shouldRetrain: reasons.isNotEmpty,
        reasons: reasons,
        snapshot: snapshot,
        driftAnalysis: driftAnalysis,
        newOutcomesCount: newOutcomesCount,
        evaluatedAt: DateTime.now(),
      );
    } catch (e) {
      developer.log(
        'Error evaluating retraining: $e',
        name: 'RetrainTrigger',
        error: e,
      );
      return RetrainTriggerResult(
        shouldRetrain: false,
        reasons: [],
        newOutcomesCount: 0,
        evaluatedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Trigger retraining if conditions are met.
  Future<RetrainTriggerResult> triggerIfNeeded({
    required SecurityContext context,
    required String modelVersion,
    DateTime? lastRetrainDate,
    bool forceRetrain = false,
  }) async {
    final evaluation = await evaluateRetraining(
      context: context,
      modelVersion: modelVersion,
      lastRetrainDate: lastRetrainDate,
    );

    if (forceRetrain) {
      return _triggerRetraining(
        context: context,
        modelVersion: modelVersion,
        evaluation: evaluation.copyWith(
          shouldRetrain: true,
          reasons: [...evaluation.reasons, RetrainReason.manualTrigger],
        ),
      );
    }

    if (!evaluation.shouldRetrain) {
      developer.log(
        'Retraining not needed for $modelVersion',
        name: 'RetrainTrigger',
      );
      return evaluation;
    }

    return _triggerRetraining(
      context: context,
      modelVersion: modelVersion,
      evaluation: evaluation,
    );
  }

  /// Manually trigger retraining.
  Future<RetrainTriggerResult> manualTrigger({
    required SecurityContext context,
    required String modelVersion,
  }) async {
    return triggerIfNeeded(
      context: context,
      modelVersion: modelVersion,
      forceRetrain: true,
    );
  }

  Future<RetrainTriggerResult> _triggerRetraining({
    required SecurityContext context,
    required String modelVersion,
    required RetrainTriggerResult evaluation,
  }) async {
    developer.log(
      'Triggering retraining for $modelVersion. '
      'Reasons: ${evaluation.reasons.map((r) => r.name).join(", ")}',
      name: 'RetrainTrigger',
    );

    // Mark snapshot as having triggered retraining
    if (evaluation.snapshot != null && evaluation.snapshot!.id.isNotEmpty) {
      await _metricsRepository.markRetrainingTriggered(
        context,
        evaluation.snapshot!.id,
      );
    }

    // Trigger retraining job (if endpoint configured)
    String? jobId;
    String? error;

    if (_retrainEndpoint != null) {
      try {
        jobId = await _sendRetrainRequest(
          context: context,
          modelVersion: modelVersion,
          reasons: evaluation.reasons,
        );
      } catch (e) {
        error = e.toString();
        developer.log(
          'Failed to send retrain request: $e',
          name: 'RetrainTrigger',
          error: e,
        );
      }
    } else {
      developer.log(
        'No retrain endpoint configured, skipping HTTP request',
        name: 'RetrainTrigger',
      );
    }

    return evaluation.copyWith(
      retrainRequested: true,
      retrainJobId: jobId,
      error: error,
    );
  }

  Future<String?> _sendRetrainRequest({
    required SecurityContext context,
    required String modelVersion,
    required List<RetrainReason> reasons,
  }) async {
    if (_retrainEndpoint == null) return null;

    final response = await http.post(
      Uri.parse(_retrainEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Business-ID': context.businessId,
      },
      body: jsonEncode({
        'business_id': context.businessId,
        'model_version': modelVersion,
        'triggered_by': context.userId,
        'reasons': reasons.map((r) => r.name).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['job_id'] as String?;
    } else {
      throw Exception('Retrain request failed: ${response.statusCode}');
    }
  }
}

extension _RetrainTriggerResultCopyWith on RetrainTriggerResult {
  RetrainTriggerResult copyWith({
    bool? shouldRetrain,
    List<RetrainReason>? reasons,
    ModelPerformanceSnapshot? snapshot,
    DriftAnalysis? driftAnalysis,
    int? newOutcomesCount,
    DateTime? evaluatedAt,
    bool? retrainRequested,
    String? retrainJobId,
    String? error,
  }) {
    return RetrainTriggerResult(
      shouldRetrain: shouldRetrain ?? this.shouldRetrain,
      reasons: reasons ?? this.reasons,
      snapshot: snapshot ?? this.snapshot,
      driftAnalysis: driftAnalysis ?? this.driftAnalysis,
      newOutcomesCount: newOutcomesCount ?? this.newOutcomesCount,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      retrainRequested: retrainRequested ?? this.retrainRequested,
      retrainJobId: retrainJobId ?? this.retrainJobId,
      error: error ?? this.error,
    );
  }
}
