import '../../data/models/overbooking_slot.dart';
import '../models/noshow_prediction.dart';
import 'overbooking_config.dart';
import 'yield_calculator.dart';

/// Appointment data needed for slot analysis.
class SlotAppointment {
  final String id;
  final String clientId;
  final String providerId;
  final String? serviceId;
  final DateTime startTime;
  final DateTime endTime;
  final int servicePriceCents;
  final bool isGroupSession;
  final Set<String> clientTags;
  final NoshowPrediction? prediction;

  const SlotAppointment({
    required this.id,
    required this.clientId,
    required this.providerId,
    this.serviceId,
    required this.startTime,
    required this.endTime,
    required this.servicePriceCents,
    this.isGroupSession = false,
    this.clientTags = const {},
    this.prediction,
  });

  /// No-show probability from prediction (or default)
  double get noshowProbability =>
      prediction?.probability ?? 0.15; // Default 15% if no prediction

  /// Prediction confidence (or default)
  double get predictionConfidence => prediction?.confidence ?? 0.5;

  /// Whether this appointment has a VIP client
  bool hasVipTag(Set<String> excludedTags) =>
      clientTags.any((tag) => excludedTags.contains(tag));
}

/// Analyzes time slots to determine overbooking capacity.
///
/// Groups appointments by time slot and calculates safe
/// overbooking capacity based on predictions and configuration.
///
/// Agent AI-16: Yield Management & Overbooking Engine
class SlotCapacityAnalyzer {
  final OverbookingConfig config;
  final YieldCalculator _yieldCalculator;

  SlotCapacityAnalyzer({required this.config})
      : _yieldCalculator = YieldCalculator(config: config);

  /// Analyze a single time slot for overbooking opportunity.
  ///
  /// Returns an [OverbookingSlot] with calculated capacity and recommendations.
  OverbookingSlot analyzeSlot({
    required String businessId,
    required String providerId,
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<SlotAppointment> appointments,
    String? locationId,
    double? historicalNoshowRate,
  }) {
    final now = DateTime.now();
    final slotId = _generateSlotId(providerId, slotStart);

    // Check exclusions
    final exclusionReason = _checkExclusions(
      appointments: appointments,
      slotStart: slotStart,
      providerId: providerId,
    );

    final hasVipClients =
        appointments.any((a) => a.hasVipTag(config.excludedClientTags));
    final isGroupSession = appointments.any((a) => a.isGroupSession);
    final providerOptedOut = config.isProviderOptedOut(providerId);

    // Calculate weighted no-show probability
    final weightedProbability = _calculateWeightedNoshowProbability(appointments);
    final averageConfidence = _calculateAverageConfidence(appointments);

    // Calculate revenue metrics
    final totalRevenue =
        appointments.fold<int>(0, (sum, a) => sum + a.servicePriceCents);
    final averageServicePrice = appointments.isNotEmpty
        ? (totalRevenue / appointments.length).round()
        : 0;

    // Calculate safe overbook count
    int safeOverbookCount = 0;
    int projectedRevenue = totalRevenue;
    int riskRevenue = 0;

    if (exclusionReason == null) {
      safeOverbookCount = _yieldCalculator.calculateSafeOverbookCount(
        bookingCount: appointments.length,
        noshowProbability: weightedProbability,
        predictionConfidence: averageConfidence,
      );

      // Calculate projected revenue with overbooking
      if (safeOverbookCount > 0) {
        final yieldResult = _yieldCalculator.findOptimalOverbooking(
          servicePriceCents: averageServicePrice,
          noshowProbability: weightedProbability,
          bookingCount: appointments.length,
          predictionConfidence: averageConfidence,
        );
        projectedRevenue = yieldResult.optimalResult.netExpectedValueCents;
        riskRevenue = (yieldResult.optimalResult.doubleBookRisk *
                config.doubleBookPenaltyCents *
                safeOverbookCount)
            .round();
      }
    }

    return OverbookingSlot(
      id: slotId,
      businessId: businessId,
      providerId: providerId,
      locationId: locationId,
      slotDate: DateTime(slotStart.year, slotStart.month, slotStart.day),
      slotStartTime: slotStart,
      slotEndTime: slotEnd,
      currentBookings: appointments.length,
      baseCapacity: appointments.length, // Capacity = current bookings for analysis
      safeOverbookCount: safeOverbookCount,
      weightedNoshowProbability: weightedProbability,
      averageConfidence: averageConfidence,
      historicalNoshowRate: historicalNoshowRate,
      expectedRevenueCents: totalRevenue,
      projectedRevenueCents: projectedRevenue,
      riskRevenueCents: riskRevenue,
      appointmentIds: appointments.map((a) => a.id).toList(),
      hasVipClients: hasVipClients,
      isGroupSession: isGroupSession,
      providerOptedOut: providerOptedOut,
      exclusionReason: exclusionReason,
      status: safeOverbookCount > 0
          ? OverbookingStatus.available
          : OverbookingStatus.atCapacity,
      calculatedAt: now,
    );
  }

  /// Analyze multiple slots for a provider's day.
  ///
  /// Groups appointments into slots and analyzes each.
  List<OverbookingSlot> analyzeProviderDay({
    required String businessId,
    required String providerId,
    required DateTime date,
    required List<SlotAppointment> dayAppointments,
    String? locationId,
    int slotDurationMinutes = 60,
    Map<int, double>? hourlyHistoricalRates,
  }) {
    if (dayAppointments.isEmpty) return [];

    // Group appointments by time slot
    final slots = _groupAppointmentsBySlot(
      appointments: dayAppointments,
      date: date,
      slotDurationMinutes: slotDurationMinutes,
    );

    // Analyze each slot
    return slots.entries.map((entry) {
      final slotStart = entry.key;
      final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));
      final slotAppointments = entry.value;

      // Get historical rate for this hour if available
      final historicalRate = hourlyHistoricalRates?[slotStart.hour];

      return analyzeSlot(
        businessId: businessId,
        providerId: providerId,
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: slotAppointments,
        locationId: locationId,
        historicalNoshowRate: historicalRate,
      );
    }).toList()
      ..sort((a, b) => a.slotStartTime.compareTo(b.slotStartTime));
  }

  /// Generate daily summary from analyzed slots.
  DailyOverbookingSummary generateDailySummary({
    required String businessId,
    required String providerId,
    required DateTime date,
    required List<OverbookingSlot> slots,
  }) {
    final slotsWithOpportunity =
        slots.where((s) => s.isOverbookingRecommended).length;
    final totalCapacity =
        slots.fold<int>(0, (sum, s) => sum + s.safeOverbookCount);
    final totalAccepted =
        slots.fold<int>(0, (sum, s) => sum + s.acceptedOverbooks);
    final additionalRevenue = slots.fold<int>(
        0, (sum, s) => sum + (s.projectedRevenueCents - s.expectedRevenueCents));
    final avgNoshowProb = slots.isNotEmpty
        ? slots.fold<double>(0, (sum, s) => sum + s.weightedNoshowProbability) /
            slots.length
        : 0.0;
    final excludedSlots =
        slots.where((s) => s.exclusionReason != null).length;

    return DailyOverbookingSummary(
      providerId: providerId,
      businessId: businessId,
      date: date,
      totalSlots: slots.length,
      slotsWithOpportunity: slotsWithOpportunity,
      totalSafeOverbookCapacity: totalCapacity,
      totalAcceptedOverbooks: totalAccepted,
      expectedAdditionalRevenueCents: additionalRevenue,
      averageNoshowProbability: avgNoshowProb,
      excludedSlots: excludedSlots,
      calculatedAt: DateTime.now(),
    );
  }

  // ============ Private Methods ============

  /// Generate unique slot ID.
  String _generateSlotId(String providerId, DateTime slotStart) {
    final dateStr =
        '${slotStart.year}${slotStart.month.toString().padLeft(2, '0')}${slotStart.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${slotStart.hour.toString().padLeft(2, '0')}${slotStart.minute.toString().padLeft(2, '0')}';
    return 'slot_${providerId}_${dateStr}_$timeStr';
  }

  /// Check for exclusions that prevent overbooking.
  String? _checkExclusions({
    required List<SlotAppointment> appointments,
    required DateTime slotStart,
    required String providerId,
  }) {
    if (!config.isEnabled) {
      return 'Overbooking is disabled';
    }

    if (config.isProviderOptedOut(providerId)) {
      return 'Provider opted out of overbooking';
    }

    // Group sessions are excluded before any volume-based checks
    if (config.excludeGroupSessions &&
        appointments.any((a) => a.isGroupSession)) {
      return 'Contains group session';
    }

    if (appointments.length < config.minBookingsForOverbooking) {
      return 'Insufficient bookings (${appointments.length} < ${config.minBookingsForOverbooking})';
    }

    // Check for VIP clients
    if (appointments.any((a) => a.hasVipTag(config.excludedClientTags))) {
      return 'Contains VIP client';
    }

    // Check for excluded services
    for (final appointment in appointments) {
      if (appointment.serviceId != null &&
          config.isServiceExcluded(appointment.serviceId!)) {
        return 'Contains excluded service';
      }
    }

    // Check time constraints
    final now = DateTime.now();
    final daysUntil = slotStart.difference(now).inDays;
    if (daysUntil < config.minDaysBeforeAppointment) {
      return 'Too close to appointment ($daysUntil days)';
    }

    // Check excluded hours
    if (config.isHourExcluded(slotStart.hour)) {
      return 'Hour ${slotStart.hour} excluded from overbooking';
    }

    // Check excluded days
    if (config.isDayExcluded(slotStart.weekday)) {
      return 'Day ${slotStart.weekday} excluded from overbooking';
    }

    // Check minimum service value
    final avgPrice = appointments.isNotEmpty
        ? appointments.fold<int>(0, (sum, a) => sum + a.servicePriceCents) ~/
            appointments.length
        : 0;
    if (avgPrice < config.minServiceValueCents) {
      return 'Service value below minimum';
    }

    return null; // No exclusion
  }

  /// Calculate weighted no-show probability across appointments.
  double _calculateWeightedNoshowProbability(
    List<SlotAppointment> appointments,
  ) {
    if (appointments.isEmpty) return 0;

    // Weight by service price (higher value = more weight)
    final totalValue =
        appointments.fold<int>(0, (sum, a) => sum + a.servicePriceCents);

    if (totalValue <= 0) {
      // Simple average if no price info
      return appointments.fold<double>(0, (sum, a) => sum + a.noshowProbability) /
          appointments.length;
    }

    // Weighted average
    var weightedSum = 0.0;
    for (final appointment in appointments) {
      final weight = appointment.servicePriceCents / totalValue;
      weightedSum += appointment.noshowProbability * weight;
    }

    return weightedSum;
  }

  /// Calculate average prediction confidence.
  double _calculateAverageConfidence(List<SlotAppointment> appointments) {
    if (appointments.isEmpty) return 0;

    return appointments.fold<double>(
            0, (sum, a) => sum + a.predictionConfidence) /
        appointments.length;
  }

  /// Group appointments into time slots.
  Map<DateTime, List<SlotAppointment>> _groupAppointmentsBySlot({
    required List<SlotAppointment> appointments,
    required DateTime date,
    required int slotDurationMinutes,
  }) {
    final slots = <DateTime, List<SlotAppointment>>{};

    for (final appointment in appointments) {
      // Round down to nearest slot boundary
      final slotMinute =
          (appointment.startTime.minute ~/ slotDurationMinutes) *
              slotDurationMinutes;
      final slotStart = DateTime(
        appointment.startTime.year,
        appointment.startTime.month,
        appointment.startTime.day,
        appointment.startTime.hour,
        slotMinute,
      );

      slots.putIfAbsent(slotStart, () => []);
      slots[slotStart]!.add(appointment);
    }

    return slots;
  }
}
