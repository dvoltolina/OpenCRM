@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/yield/overbooking_config.dart';
import 'package:the_scheduler/ai/yield/overbooking_service.dart';
import 'package:the_scheduler/ai/yield/slot_capacity_analyzer.dart';
import 'package:the_scheduler/data/models/overbooking_slot.dart';
import 'package:the_scheduler/data/models/security_context.dart';

/// Tests for OverbookingService and SlotCapacityAnalyzer
///
/// Agent AI-16: Yield Management & Overbooking Engine
void main() {
  late OverbookingConfig config;
  late OverbookingService service;
  late SecurityContext context;

  setUp(() {
    config = const OverbookingConfig(
      isEnabled: true,
      maxOverbookingPercentage: 0.2,
      confidenceFactor: 0.8,
      minNoshowProbabilityThreshold: 0.3,
      minBookingsForOverbooking: 2,
      maxOverbooksPerSlot: 2,
      minServiceValueCents: 2500,
      doubleBookPenaltyCents: 5000,
      excludedClientTags: {'vip', 'VIP'},
      excludeGroupSessions: true,
      minDaysBeforeAppointment: 1,
    );

    service = OverbookingService(config: config);

    context = const SecurityContext(
      businessId: 'test_business',
      userId: 'test_user',
      role: UserRole.admin,
    );
  });

  group('SlotCapacityAnalyzer', () {
    late SlotCapacityAnalyzer analyzer;

    setUp(() {
      analyzer = SlotCapacityAnalyzer(config: config);
    });

    test('analyzes slot with overbooking opportunity', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(days: 3, hours: 10));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_1', 0.4, 0.9),
        ),
        SlotAppointment(
          id: 'appt_2',
          clientId: 'client_2',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_2', 0.35, 0.85),
        ),
        SlotAppointment(
          id: 'appt_3',
          clientId: 'client_3',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_3', 0.45, 0.88),
        ),
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      expect(slot.currentBookings, 3);
      expect(slot.weightedNoshowProbability, greaterThan(0.35));
      expect(slot.weightedNoshowProbability, lessThan(0.45));
      expect(slot.safeOverbookCount, greaterThan(0));
      expect(slot.isOverbookingRecommended, true);
      expect(slot.status, OverbookingStatus.available);
    });

    test('excludes slots with VIP clients', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(days: 3, hours: 10));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'vip_client',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          clientTags: {'vip'}, // VIP tag
          prediction: _createPrediction('appt_1', 0.5, 0.9),
        ),
        SlotAppointment(
          id: 'appt_2',
          clientId: 'client_2',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_2', 0.5, 0.9),
        ),
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      expect(slot.hasVipClients, true);
      expect(slot.isOverbookingRecommended, false);
      expect(slot.exclusionReason, contains('VIP'));
    });

    test('excludes group sessions', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(days: 3, hours: 10));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          isGroupSession: true,
          prediction: _createPrediction('appt_1', 0.5, 0.9),
        ),
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      expect(slot.isGroupSession, true);
      expect(slot.isOverbookingRecommended, false);
      expect(slot.exclusionReason, contains('group session'));
    });

    test('excludes slots too close to appointment', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(hours: 2)); // Same day
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_1', 0.5, 0.9),
        ),
        SlotAppointment(
          id: 'appt_2',
          clientId: 'client_2',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_2', 0.5, 0.9),
        ),
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      expect(slot.isOverbookingRecommended, false);
      expect(slot.exclusionReason, contains('Too close'));
    });

    test('excludes slots with insufficient bookings', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(days: 3, hours: 10));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_1', 0.5, 0.9),
        ),
        // Only 1 appointment, below minimum of 2
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      expect(slot.isOverbookingRecommended, false);
      expect(slot.exclusionReason, contains('Insufficient bookings'));
    });

    test('calculates weighted no-show probability by service value', () {
      final now = DateTime.now();
      final slotStart = now.add(const Duration(days: 3, hours: 10));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      // High-value appointment with low no-show, low-value with high no-show
      final appointments = [
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 20000, // $200 - more weight
          prediction: _createPrediction('appt_1', 0.2, 0.9), // Low no-show
        ),
        SlotAppointment(
          id: 'appt_2',
          clientId: 'client_2',
          providerId: 'provider_1',
          startTime: slotStart,
          endTime: slotEnd,
          servicePriceCents: 5000, // $50 - less weight
          prediction: _createPrediction('appt_2', 0.8, 0.9), // High no-show
        ),
      ];

      final slot = analyzer.analyzeSlot(
        businessId: 'test_business',
        providerId: 'provider_1',
        slotStart: slotStart,
        slotEnd: slotEnd,
        appointments: appointments,
      );

      // Weighted probability should be closer to 0.2 (high-value appointment)
      // than simple average of 0.5
      expect(slot.weightedNoshowProbability, lessThan(0.4));
    });

    test('analyzes provider day correctly', () {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 3);

      final appointments = [
        // 9 AM slot
        SlotAppointment(
          id: 'appt_1',
          clientId: 'client_1',
          providerId: 'provider_1',
          startTime: DateTime(date.year, date.month, date.day, 9),
          endTime: DateTime(date.year, date.month, date.day, 10),
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_1', 0.4, 0.9),
        ),
        SlotAppointment(
          id: 'appt_2',
          clientId: 'client_2',
          providerId: 'provider_1',
          startTime: DateTime(date.year, date.month, date.day, 9, 30),
          endTime: DateTime(date.year, date.month, date.day, 10, 30),
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_2', 0.35, 0.85),
        ),
        // 10 AM slot
        SlotAppointment(
          id: 'appt_3',
          clientId: 'client_3',
          providerId: 'provider_1',
          startTime: DateTime(date.year, date.month, date.day, 10),
          endTime: DateTime(date.year, date.month, date.day, 11),
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_3', 0.5, 0.88),
        ),
        SlotAppointment(
          id: 'appt_4',
          clientId: 'client_4',
          providerId: 'provider_1',
          startTime: DateTime(date.year, date.month, date.day, 10, 30),
          endTime: DateTime(date.year, date.month, date.day, 11, 30),
          servicePriceCents: 10000,
          prediction: _createPrediction('appt_4', 0.45, 0.92),
        ),
      ];

      final slots = analyzer.analyzeProviderDay(
        businessId: 'test_business',
        providerId: 'provider_1',
        date: date,
        dayAppointments: appointments,
        slotDurationMinutes: 60,
      );

      expect(slots.length, 2); // Two hour-long slots
      expect(slots[0].currentBookings, 2);
      expect(slots[1].currentBookings, 2);
    });

    test('generates daily summary correctly', () {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 3);

      final slots = [
        OverbookingSlot(
          id: 'slot_1',
          businessId: 'test_business',
          providerId: 'provider_1',
          slotDate: date,
          slotStartTime: DateTime(date.year, date.month, date.day, 9),
          slotEndTime: DateTime(date.year, date.month, date.day, 10),
          currentBookings: 3,
          baseCapacity: 3,
          safeOverbookCount: 1,
          weightedNoshowProbability: 0.4,
          averageConfidence: 0.85,
          expectedRevenueCents: 30000,
          projectedRevenueCents: 35000,
          riskRevenueCents: 2000,
          appointmentIds: ['a1', 'a2', 'a3'],
          calculatedAt: now,
        ),
        OverbookingSlot(
          id: 'slot_2',
          businessId: 'test_business',
          providerId: 'provider_1',
          slotDate: date,
          slotStartTime: DateTime(date.year, date.month, date.day, 10),
          slotEndTime: DateTime(date.year, date.month, date.day, 11),
          currentBookings: 2,
          baseCapacity: 2,
          safeOverbookCount: 0,
          weightedNoshowProbability: 0.2,
          averageConfidence: 0.9,
          expectedRevenueCents: 20000,
          projectedRevenueCents: 20000,
          riskRevenueCents: 0,
          appointmentIds: ['a4', 'a5'],
          calculatedAt: now,
        ),
      ];

      final summary = analyzer.generateDailySummary(
        businessId: 'test_business',
        providerId: 'provider_1',
        date: date,
        slots: slots,
      );

      expect(summary.totalSlots, 2);
      expect(summary.slotsWithOpportunity, 1); // Only slot_1 has safe count > 0
      expect(summary.totalSafeOverbookCapacity, 1);
      expect(summary.expectedAdditionalRevenueCents, 5000); // 35000 - 30000
    });
  });

  group('OverbookingService', () {
    test('service is enabled when config is enabled', () {
      expect(service.isEnabled, true);
    });

    test('calculates yield metrics correctly', () {
      final result = service.calculateYieldMetrics(
        servicePriceCents: 10000,
        noshowProbability: 0.4,
        currentBookings: 5,
        predictionConfidence: 0.9,
      );

      expect(result.baselineResult, isNotNull);
      expect(result.optimalResult, isNotNull);
      expect(result.allScenarios.isNotEmpty, true);
    });

    test('tracks statistics', () {
      final stats = service.statistics;

      expect(stats['isEnabled'], true);
      expect(stats['totalAnalyzed'], 0);
      expect(stats['totalRecommended'], 0);
      expect(stats['totalAccepted'], 0);
      expect(stats['confidenceFactor'], 0.8);
    });

    test('resets statistics', () {
      service.resetStatistics();

      final stats = service.statistics;
      expect(stats['totalAnalyzed'], 0);
      expect(stats['totalAccepted'], 0);
    });
  });

  group('OverbookingSlot model', () {
    test('isOverbookingRecommended checks all conditions', () {
      final now = DateTime.now();

      // Recommended slot
      final recommendedSlot = OverbookingSlot(
        id: 'slot_1',
        businessId: 'test_business',
        providerId: 'provider_1',
        slotDate: now,
        slotStartTime: now,
        slotEndTime: now.add(const Duration(hours: 1)),
        currentBookings: 3,
        baseCapacity: 3,
        safeOverbookCount: 1,
        weightedNoshowProbability: 0.4,
        averageConfidence: 0.85,
        expectedRevenueCents: 30000,
        projectedRevenueCents: 35000,
        riskRevenueCents: 2000,
        appointmentIds: ['a1', 'a2', 'a3'],
        calculatedAt: now,
        status: OverbookingStatus.available,
        hasVipClients: false,
        isGroupSession: false,
        providerOptedOut: false,
      );

      expect(recommendedSlot.isOverbookingRecommended, true);

      // Not recommended - VIP client
      final vipSlot = recommendedSlot.copyWith(hasVipClients: true);
      expect(vipSlot.isOverbookingRecommended, false);

      // Not recommended - group session
      final groupSlot = recommendedSlot.copyWith(isGroupSession: true);
      expect(groupSlot.isOverbookingRecommended, false);

      // Not recommended - provider opted out
      final optedOutSlot = recommendedSlot.copyWith(providerOptedOut: true);
      expect(optedOutSlot.isOverbookingRecommended, false);

      // Not recommended - no safe overbook count
      final noCapacitySlot = recommendedSlot.copyWith(safeOverbookCount: 0);
      expect(noCapacitySlot.isOverbookingRecommended, false);
    });

    test('remainingOverbookCapacity calculates correctly', () {
      final now = DateTime.now();

      final slot = OverbookingSlot(
        id: 'slot_1',
        businessId: 'test_business',
        providerId: 'provider_1',
        slotDate: now,
        slotStartTime: now,
        slotEndTime: now.add(const Duration(hours: 1)),
        currentBookings: 3,
        baseCapacity: 3,
        safeOverbookCount: 2,
        acceptedOverbooks: 1,
        weightedNoshowProbability: 0.4,
        averageConfidence: 0.85,
        expectedRevenueCents: 30000,
        projectedRevenueCents: 35000,
        riskRevenueCents: 2000,
        appointmentIds: ['a1', 'a2', 'a3'],
        calculatedAt: now,
      );

      expect(slot.remainingOverbookCapacity, 1);
      expect(slot.canAcceptMoreOverbooks, true);

      // Fully utilized
      final fullSlot = slot.copyWith(acceptedOverbooks: 2);
      expect(fullSlot.remainingOverbookCapacity, 0);
      expect(fullSlot.canAcceptMoreOverbooks, false);
    });

    test('expectedYieldImprovement calculates percentage', () {
      final now = DateTime.now();

      final slot = OverbookingSlot(
        id: 'slot_1',
        businessId: 'test_business',
        providerId: 'provider_1',
        slotDate: now,
        slotStartTime: now,
        slotEndTime: now.add(const Duration(hours: 1)),
        currentBookings: 3,
        baseCapacity: 3,
        safeOverbookCount: 1,
        weightedNoshowProbability: 0.4,
        averageConfidence: 0.85,
        expectedRevenueCents: 30000,
        projectedRevenueCents: 33000, // 10% increase
        riskRevenueCents: 1000,
        appointmentIds: ['a1', 'a2', 'a3'],
        calculatedAt: now,
      );

      expect(slot.expectedYieldImprovement, closeTo(10.0, 0.1));
    });
  });

  group('OverbookingConfig', () {
    test('isProviderOptedOut returns correct value', () {
      final configWithOptOut = config.copyWith(
        optedOutProviderIds: {'provider_A', 'provider_B'},
      );

      expect(configWithOptOut.isProviderOptedOut('provider_A'), true);
      expect(configWithOptOut.isProviderOptedOut('provider_C'), false);
    });

    test('isServiceExcluded returns correct value', () {
      final configWithExclusion = config.copyWith(
        excludedServiceIds: {'service_complex', 'service_surgery'},
      );

      expect(configWithExclusion.isServiceExcluded('service_complex'), true);
      expect(configWithExclusion.isServiceExcluded('service_regular'), false);
    });

    test('hasExcludedTags detects VIP tags', () {
      expect(config.hasExcludedTags({'regular', 'returning'}), false);
      expect(config.hasExcludedTags({'vip', 'returning'}), true);
      expect(config.hasExcludedTags({'VIP'}), true);
    });

    test('toJson and fromJson are symmetric', () {
      final json = config.toJson();
      final restored = OverbookingConfig.fromJson(json);

      expect(restored.isEnabled, config.isEnabled);
      expect(restored.maxOverbookingPercentage, config.maxOverbookingPercentage);
      expect(restored.confidenceFactor, config.confidenceFactor);
      expect(restored.minNoshowProbabilityThreshold,
          config.minNoshowProbabilityThreshold);
      expect(restored.maxOverbooksPerSlot, config.maxOverbooksPerSlot);
      expect(restored.excludeGroupSessions, config.excludeGroupSessions);
    });
  });
}

/// Helper to create a mock prediction.
NoshowPrediction _createPrediction(
  String appointmentId,
  double probability,
  double confidence,
) {
  final now = DateTime.now();
  return NoshowPrediction(
    appointmentId: appointmentId,
    probability: probability,
    riskLevel: probability >= 0.5
        ? RiskLevel.high
        : probability >= 0.3
            ? RiskLevel.medium
            : RiskLevel.low,
    confidence: confidence,
    recommendedActions: const [],
    topFeatures: const [],
    modelVersion: '1.0.0',
    predictedAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
  );
}
