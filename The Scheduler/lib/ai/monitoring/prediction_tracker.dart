import 'dart:developer' as developer;

import '../../data/models/security_context.dart';
import '../../data/repositories/prediction_outcomes_repository.dart';
import '../models/noshow_prediction.dart';
import '../models/prediction_outcome.dart';

/// Service for tracking predictions and their outcomes.
///
/// Records every prediction made and links it to the eventual appointment
/// outcome for model performance evaluation.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class PredictionTracker {
  PredictionTracker({
    required PredictionOutcomesRepository outcomesRepository,
  }) : _outcomesRepository = outcomesRepository;

  final PredictionOutcomesRepository _outcomesRepository;

  /// Record a new prediction for tracking.
  ///
  /// Should be called whenever a no-show prediction is made.
  Future<PredictionOutcome?> recordPrediction({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required NoshowPrediction prediction,
    required DateTime appointmentTime,
    String? providerId,
    String? serviceId,
  }) async {
    // Don't track unavailable predictions
    if (!prediction.isAvailable) {
      developer.log(
        'Skipping unavailable prediction for appointment: $appointmentId',
        name: 'PredictionTracker',
      );
      return null;
    }

    try {
      final outcome = await _outcomesRepository.recordPrediction(
        context: context,
        appointmentId: appointmentId,
        clientId: clientId,
        predictedProbability: prediction.probability,
        predictedRiskLevel: prediction.riskLevel.name,
        modelVersion: prediction.modelVersion,
        confidence: prediction.confidence,
        appointmentTime: appointmentTime,
        topFeatures: prediction.topFeatures
            .take(5)
            .map((f) => f.featureName)
            .toList(),
        providerId: providerId,
        serviceId: serviceId,
      );

      developer.log(
        'Recorded prediction for appointment: $appointmentId '
        '(probability: ${prediction.probabilityPercent}%, '
        'risk: ${prediction.riskLevel.name})',
        name: 'PredictionTracker',
      );

      return outcome;
    } catch (e) {
      developer.log(
        'Failed to record prediction: $e',
        name: 'PredictionTracker',
        error: e,
      );
      return null;
    }
  }

  /// Record the outcome of an appointment.
  ///
  /// Should be called when an appointment is marked as completed, no-show,
  /// cancelled, or rescheduled.
  Future<PredictionOutcome?> recordOutcome({
    required SecurityContext context,
    required String appointmentId,
    required AppointmentOutcome outcome,
  }) async {
    try {
      final updated = await _outcomesRepository.recordOutcome(
        context: context,
        appointmentId: appointmentId,
        outcome: outcome,
      );

      if (updated != null) {
        developer.log(
          'Recorded outcome for appointment: $appointmentId '
          '(outcome: ${outcome.name}, '
          'correct: ${updated.predictionCorrect})',
          name: 'PredictionTracker',
        );
      } else {
        developer.log(
          'No pending prediction found for appointment: $appointmentId',
          name: 'PredictionTracker',
        );
      }

      return updated;
    } catch (e) {
      developer.log(
        'Failed to record outcome: $e',
        name: 'PredictionTracker',
        error: e,
      );
      return null;
    }
  }

  /// Record outcome from appointment status change.
  ///
  /// Convenience method that maps appointment status strings to outcomes.
  Future<PredictionOutcome?> recordOutcomeFromStatus({
    required SecurityContext context,
    required String appointmentId,
    required String status,
  }) async {
    final outcome = _mapStatusToOutcome(status);
    if (outcome == null || outcome == AppointmentOutcome.pending) {
      return null;
    }

    return recordOutcome(
      context: context,
      appointmentId: appointmentId,
      outcome: outcome,
    );
  }

  /// Get pending predictions that need outcome recording.
  Future<List<PredictionOutcome>> getPendingOutcomes(
    SecurityContext context, {
    int limit = 100,
  }) async {
    return _outcomesRepository.getPendingOutcomes(context, limit: limit);
  }

  /// Process pending outcomes by checking appointment statuses.
  ///
  /// Returns the number of outcomes processed.
  Future<int> processPendingOutcomes({
    required SecurityContext context,
    required Future<String?> Function(String appointmentId) getAppointmentStatus,
    int batchSize = 50,
  }) async {
    final pending =
        await _outcomesRepository.getPendingOutcomes(context, limit: batchSize);

    if (pending.isEmpty) {
      developer.log(
        'No pending outcomes to process',
        name: 'PredictionTracker',
      );
      return 0;
    }

    int processed = 0;

    for (final outcome in pending) {
      // Skip if appointment time is in the future
      if (outcome.appointmentTime.isAfter(DateTime.now())) {
        continue;
      }

      final status = await getAppointmentStatus(outcome.appointmentId);
      if (status == null) continue;

      final appointmentOutcome = _mapStatusToOutcome(status);
      if (appointmentOutcome == null ||
          appointmentOutcome == AppointmentOutcome.pending) {
        continue;
      }

      await recordOutcome(
        context: context,
        appointmentId: outcome.appointmentId,
        outcome: appointmentOutcome,
      );
      processed++;
    }

    developer.log(
      'Processed $processed pending outcomes',
      name: 'PredictionTracker',
    );

    return processed;
  }

  /// Get summary statistics for predictions.
  Future<PredictionOutcomeSummary> getSummary({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _outcomesRepository.calculateSummary(
      context: context,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Count total evaluable outcomes since a date.
  Future<int> countEvaluableOutcomes(
    SecurityContext context, {
    DateTime? since,
  }) async {
    return _outcomesRepository.countEvaluableOutcomes(
      context,
      since: since,
    );
  }

  AppointmentOutcome? _mapStatusToOutcome(String status) {
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == 'completed' ||
        normalizedStatus == 'attended' ||
        normalizedStatus == 'checked_in' ||
        normalizedStatus == 'checked_out') {
      return AppointmentOutcome.attended;
    }

    if (normalizedStatus == 'no_show' ||
        normalizedStatus == 'noshow' ||
        normalizedStatus == 'no-show') {
      return AppointmentOutcome.noshow;
    }

    if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled') {
      return AppointmentOutcome.cancelled;
    }

    if (normalizedStatus == 'rescheduled') {
      return AppointmentOutcome.rescheduled;
    }

    // Still pending or unknown status
    return null;
  }
}
