import 'package:flutter/foundation.dart';

import '../../data/models/overbooking_slot.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../services/prediction_service.dart';
import 'overbooking_config.dart';
import 'slot_capacity_analyzer.dart';
import 'yield_calculator.dart';

/// Core service for yield management and overbooking recommendations.
///
/// Calculates safe overbooking capacity per time slot based on
/// historical no-show patterns and real-time predictions.
///
/// **Key Principles:**
/// - Conservative: Only overbook when expected no-shows >= 1.0
/// - Staff decision: Provides recommendations, never auto-books
/// - Respects exclusions: VIPs, group sessions, provider opt-outs
/// - Audit logged: All decisions tracked for HIPAA compliance
///
/// Agent AI-16: Yield Management & Overbooking Engine
class OverbookingService {
  final OverbookingConfig _config;
  final PredictionService? _predictionService;
  final AuditLogRepository? _auditLogRepository;
  final OverbookingRepository? _overbookingRepository;

  late final SlotCapacityAnalyzer _slotAnalyzer;
  late final YieldCalculator _yieldCalculator;

  // Statistics
  int _totalAnalyzed = 0;
  int _totalRecommended = 0;
  int _totalAccepted = 0;
  int _totalDeclined = 0;

  OverbookingService({
    required OverbookingConfig config,
    PredictionService? predictionService,
    AuditLogRepository? auditLogRepository,
    OverbookingRepository? overbookingRepository,
  })  : _config = config,
        _predictionService = predictionService,
        _auditLogRepository = auditLogRepository,
        _overbookingRepository = overbookingRepository {
    _slotAnalyzer = SlotCapacityAnalyzer(config: config);
    _yieldCalculator = YieldCalculator(config: config);
  }

  /// Get current configuration.
  OverbookingConfig get config => _config;

  /// Check if overbooking is enabled.
  bool get isEnabled => _config.isEnabled;

  // ============ Main API ============

  /// Analyze a provider's schedule for overbooking opportunities.
  ///
  /// Returns list of slots with overbooking recommendations.
  Future<List<OverbookingSlot>> analyzeProviderSchedule({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
    required List<SlotAppointment> appointments,
    String? locationId,
    int slotDurationMinutes = 60,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    _totalAnalyzed++;

    // Analyze slots
    final slots = _slotAnalyzer.analyzeProviderDay(
      businessId: context.businessId,
      providerId: providerId,
      date: date,
      dayAppointments: appointments,
      locationId: locationId,
      slotDurationMinutes: slotDurationMinutes,
    );

    // Count recommendations
    _totalRecommended +=
        slots.where((s) => s.isOverbookingRecommended).length;

    // Log analysis for audit
    await _logAnalysis(
      context: context,
      providerId: providerId,
      date: date,
      slotsAnalyzed: slots.length,
      slotsWithOpportunity:
          slots.where((s) => s.isOverbookingRecommended).length,
    );

    // Persist slots if repository available
    if (_overbookingRepository != null) {
      for (final slot in slots) {
        await _overbookingRepository!.saveSlot(context, slot);
      }
    }

    return slots;
  }

  /// Get overbooking recommendation for a specific slot.
  Future<OverbookingSlot?> getSlotRecommendation({
    required SecurityContext context,
    required String providerId,
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<SlotAppointment> appointments,
    String? locationId,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    final slot = _slotAnalyzer.analyzeSlot(
      businessId: context.businessId,
      providerId: providerId,
      slotStart: slotStart,
      slotEnd: slotEnd,
      appointments: appointments,
      locationId: locationId,
    );

    return slot;
  }

  /// Calculate yield metrics for a potential overbooking decision.
  OptimalOverbookResult calculateYieldMetrics({
    required int servicePriceCents,
    required double noshowProbability,
    required int currentBookings,
    required double predictionConfidence,
  }) {
    return _yieldCalculator.findOptimalOverbooking(
      servicePriceCents: servicePriceCents,
      noshowProbability: noshowProbability,
      bookingCount: currentBookings,
      predictionConfidence: predictionConfidence,
    );
  }

  /// Accept an overbooking for a slot.
  ///
  /// Updates slot status and logs the decision.
  Future<OverbookingSlot> acceptOverbook({
    required SecurityContext context,
    required String slotId,
    required String overbookAppointmentId,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    // Get current slot
    final slot = await _overbookingRepository?.getSlot(context, slotId);
    if (slot == null) {
      throw StateError('Slot not found: $slotId');
    }

    if (!slot.canAcceptMoreOverbooks) {
      throw StateError('Slot cannot accept more overbooks');
    }

    // Update slot
    final updatedSlot = slot.copyWith(
      acceptedOverbooks: slot.acceptedOverbooks + 1,
      overbookedAppointmentIds: [
        ...slot.overbookedAppointmentIds,
        overbookAppointmentId
      ],
      status: slot.acceptedOverbooks + 1 >= slot.safeOverbookCount
          ? OverbookingStatus.filled
          : OverbookingStatus.available,
      updatedAt: DateTime.now(),
    );

    // Persist
    await _overbookingRepository?.saveSlot(context, updatedSlot);

    // Log decision
    await _logDecision(
      context: context,
      slot: updatedSlot,
      decision: 'accepted',
      appointmentId: overbookAppointmentId,
    );

    _totalAccepted++;
    return updatedSlot;
  }

  /// Decline an overbooking opportunity for a slot.
  Future<OverbookingSlot> declineOverbook({
    required SecurityContext context,
    required String slotId,
    String? reason,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    final slot = await _overbookingRepository?.getSlot(context, slotId);
    if (slot == null) {
      throw StateError('Slot not found: $slotId');
    }

    final updatedSlot = slot.copyWith(
      status: OverbookingStatus.declined,
      exclusionReason: reason ?? 'Staff declined',
      updatedAt: DateTime.now(),
    );

    await _overbookingRepository?.saveSlot(context, updatedSlot);

    await _logDecision(
      context: context,
      slot: updatedSlot,
      decision: 'declined',
      reason: reason,
    );

    _totalDeclined++;
    return updatedSlot;
  }

  /// Record the outcome of an overbooking decision.
  ///
  /// Used for model improvement and tracking accuracy.
  Future<void> recordOutcome({
    required SecurityContext context,
    required String slotId,
    required OverbookingOutcome outcome,
    required int actualNoshowCount,
    required int revenueImpactCents,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    final slot = await _overbookingRepository?.getSlot(context, slotId);
    if (slot == null) return;

    // Update slot with outcome
    final updatedSlot = slot.copyWith(
      outcome: outcome,
      updatedAt: DateTime.now(),
    );
    await _overbookingRepository?.saveSlot(context, updatedSlot);

    // Create outcome record
    final predictionAccurate = _evaluatePredictionAccuracy(
      predictedNoshowProbability: slot.weightedNoshowProbability,
      bookingCount: slot.currentBookings,
      actualNoshowCount: actualNoshowCount,
    );

    final outcomeRecord = OverbookingOutcomeRecord(
      id: 'outcome_${slotId}_${DateTime.now().millisecondsSinceEpoch}',
      overbookingSlotId: slotId,
      businessId: context.businessId,
      providerId: slot.providerId,
      slotDateTime: slot.slotStartTime,
      predictedNoshowProbability: slot.weightedNoshowProbability,
      actualOutcome: outcome,
      predictionAccurate: predictionAccurate,
      revenueImpactCents: revenueImpactCents,
      overbookedCount: slot.acceptedOverbooks,
      actualNoshowCount: actualNoshowCount,
      algorithmVersion: slot.algorithmVersion,
      recordedAt: DateTime.now(),
    );

    await _overbookingRepository?.saveOutcomeRecord(context, outcomeRecord);

    // Log outcome
    await _logOutcome(context: context, slot: slot, outcome: outcome);
  }

  /// Generate daily summary report.
  Future<DailyOverbookingSummary> getDailySummary({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
  }) async {
    context.verifyBusinessAccess(context.businessId);

    final slots = await _overbookingRepository?.getSlotsForProviderDate(
          context,
          providerId,
          date,
        ) ??
        [];

    return _slotAnalyzer.generateDailySummary(
      businessId: context.businessId,
      providerId: providerId,
      date: date,
      slots: slots,
    );
  }

  /// Get service statistics.
  Map<String, dynamic> get statistics => {
        'totalAnalyzed': _totalAnalyzed,
        'totalRecommended': _totalRecommended,
        'totalAccepted': _totalAccepted,
        'totalDeclined': _totalDeclined,
        'acceptanceRate': _totalRecommended > 0
            ? '${(_totalAccepted / _totalRecommended * 100).toStringAsFixed(1)}%'
            : '0%',
        'isEnabled': _config.isEnabled,
        'confidenceFactor': _config.confidenceFactor,
        'maxOverbookPercentage': _config.maxOverbookingPercentage,
      };

  /// Reset statistics (for testing).
  void resetStatistics() {
    _totalAnalyzed = 0;
    _totalRecommended = 0;
    _totalAccepted = 0;
    _totalDeclined = 0;
  }

  // ============ Private Methods ============

  bool _evaluatePredictionAccuracy({
    required double predictedNoshowProbability,
    required int bookingCount,
    required int actualNoshowCount,
  }) {
    // Prediction is "accurate" if actual no-shows were within expected range
    final expectedNoshows = bookingCount * predictedNoshowProbability;
    final tolerance = bookingCount * 0.1; // 10% tolerance

    return (actualNoshowCount - expectedNoshows).abs() <= tolerance;
  }

  Future<void> _logAnalysis({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
    required int slotsAnalyzed,
    required int slotsWithOpportunity,
  }) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository!.log(
        context: context,
        action: 'yield_analysis_performed',
        entityType: 'provider',
        entityId: providerId,
        source: 'OverbookingService',
        details: {
          'date': date.toIso8601String(),
          'slots_analyzed': slotsAnalyzed,
          'slots_with_opportunity': slotsWithOpportunity,
          'config_confidence_factor': _config.confidenceFactor,
        },
      );
    } catch (e) {
      debugPrint('OverbookingService: Audit log failed (non-blocking): $e');
    }
  }

  Future<void> _logDecision({
    required SecurityContext context,
    required OverbookingSlot slot,
    required String decision,
    String? appointmentId,
    String? reason,
  }) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository!.log(
        context: context,
        action: 'yield_overbook_$decision',
        entityType: 'overbookingSlot',
        entityId: slot.id,
        source: 'OverbookingService',
        details: {
          'provider_id': slot.providerId,
          'slot_time': slot.slotStartTime.toIso8601String(),
          'safe_overbook_count': slot.safeOverbookCount,
          'accepted_overbooks': slot.acceptedOverbooks,
          'weighted_noshow_probability': slot.weightedNoshowProbability,
          if (appointmentId != null) 'appointment_id': appointmentId,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('OverbookingService: Audit log failed (non-blocking): $e');
    }
  }

  Future<void> _logOutcome({
    required SecurityContext context,
    required OverbookingSlot slot,
    required OverbookingOutcome outcome,
  }) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository!.log(
        context: context,
        action: 'yield_outcome_recorded',
        entityType: 'overbookingSlot',
        entityId: slot.id,
        source: 'OverbookingService',
        details: {
          'provider_id': slot.providerId,
          'outcome': outcome.name,
          'accepted_overbooks': slot.acceptedOverbooks,
          'predicted_noshow_rate': slot.weightedNoshowProbability,
        },
      );
    } catch (e) {
      debugPrint('OverbookingService: Audit log failed (non-blocking): $e');
    }
  }
}

/// Repository interface for overbooking data persistence.
///
/// Implemented by OverbookingRepository in data layer.
abstract class OverbookingRepository {
  Future<void> saveSlot(SecurityContext context, OverbookingSlot slot);
  Future<OverbookingSlot?> getSlot(SecurityContext context, String slotId);
  Future<List<OverbookingSlot>> getSlotsForProviderDate(
    SecurityContext context,
    String providerId,
    DateTime date,
  );
  Future<void> saveOutcomeRecord(
    SecurityContext context,
    OverbookingOutcomeRecord record,
  );
  Future<List<OverbookingOutcomeRecord>> getOutcomeHistory(
    SecurityContext context,
    String providerId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}
