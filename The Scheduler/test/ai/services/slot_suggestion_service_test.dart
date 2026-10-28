@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/client_patterns.dart';
import 'package:the_scheduler/ai/models/slot_suggestion.dart';

/// Tests for SlotSuggestionService and related models
///
/// Agent AI-20: Smart Scheduling Suggestions
void main() {
  group('ClientPatterns', () {
    late ClientPatterns patterns;

    setUp(() {
      patterns = ClientPatterns(
        clientId: 'client_123',
        businessId: 'biz_456',
        dayOfWeekNoshowRates: {
          1: 0.10, // Monday - best
          2: 0.15,
          3: 0.20,
          4: 0.18,
          5: 0.35, // Friday - worst
          6: 0.25,
          7: 0.30,
        },
        hourOfDayNoshowRates: {
          9: 0.08,  // Morning - best
          10: 0.10,
          11: 0.12,
          12: 0.25, // Lunch - high
          14: 0.15,
          15: 0.12,
          16: 0.18,
        },
        providerNoshowRates: {
          'provider_a': 0.05, // Best
          'provider_b': 0.20,
          'provider_c': 0.35, // Worst
        },
        providerCompletedCounts: {
          'provider_a': 10,
          'provider_b': 3,
          'provider_c': 5,
        },
        leadTimeNoshowRates: {
          'same_day': 0.05,
          '1-3_days': 0.10,
          '4-7_days': 0.15,
          '8-14_days': 0.25,
          '15+_days': 0.40,
        },
        totalAppointments: 50,
        totalNoshows: 8,
        totalCancellations: 5,
        overallNoshowRate: 0.16,
        preferredDaysOfWeek: [1, 2, 4],
        preferredHours: [9, 10, 11, 15],
        preferredProviders: ['provider_a'],
        calculatedAt: DateTime.now(),
        sampleSize: 50,
      );
    });

    test('hasReliableData returns true when sample size >= 5', () {
      expect(patterns.hasReliableData, true);

      final unreliable = ClientPatterns.empty(
        clientId: 'new_client',
        businessId: 'biz',
      );
      expect(unreliable.hasReliableData, false);
    });

    test('getNoshowRateForDay returns correct rate', () {
      expect(patterns.getNoshowRateForDay(1), 0.10);
      expect(patterns.getNoshowRateForDay(5), 0.35);
    });

    test('getNoshowRateForDay returns overall rate for unknown day', () {
      // Day 0 doesn't exist in our data
      final emptyPatterns = ClientPatterns.empty(
        clientId: 'test',
        businessId: 'biz',
      ).copyWith(overallNoshowRate: 0.20);

      expect(emptyPatterns.getNoshowRateForDay(3), 0.20);
    });

    test('getNoshowRateForHour returns correct rate', () {
      expect(patterns.getNoshowRateForHour(9), 0.08);
      expect(patterns.getNoshowRateForHour(12), 0.25);
    });

    test('getNoshowRateForProvider returns correct rate', () {
      expect(patterns.getNoshowRateForProvider('provider_a'), 0.05);
      expect(patterns.getNoshowRateForProvider('provider_c'), 0.35);
    });

    test('getNoshowRateForProvider returns overall rate for unknown provider', () {
      expect(patterns.getNoshowRateForProvider('unknown'), 0.16);
    });

    test('getCompletedCountForProvider returns correct count', () {
      expect(patterns.getCompletedCountForProvider('provider_a'), 10);
      expect(patterns.getCompletedCountForProvider('unknown'), 0);
    });

    test('getNoshowRateForLeadTime returns correct rate by bucket', () {
      expect(patterns.getNoshowRateForLeadTime(0), 0.05); // same_day
      expect(patterns.getNoshowRateForLeadTime(2), 0.10); // 1-3_days
      expect(patterns.getNoshowRateForLeadTime(7), 0.15); // 4-7_days
      expect(patterns.getNoshowRateForLeadTime(14), 0.25); // 8-14_days
      expect(patterns.getNoshowRateForLeadTime(30), 0.40); // 15+_days
    });

    test('bestDayOfWeek returns day with lowest no-show rate', () {
      expect(patterns.bestDayOfWeek, 1); // Monday has 0.10
    });

    test('worstDayOfWeek returns day with highest no-show rate', () {
      expect(patterns.worstDayOfWeek, 5); // Friday has 0.35
    });

    test('bestHour returns hour with lowest no-show rate', () {
      expect(patterns.bestHour, 9); // 9 AM has 0.08
    });

    test('bestProvider returns provider with lowest rate and enough history', () {
      expect(patterns.bestProvider, 'provider_a');
    });

    test('empty patterns have null for best values', () {
      final empty = ClientPatterns.empty(
        clientId: 'new',
        businessId: 'biz',
      );

      expect(empty.bestDayOfWeek, null);
      expect(empty.worstDayOfWeek, null);
      expect(empty.bestHour, null);
      expect(empty.bestProvider, null);
    });
  });

  group('ScoredSlot', () {
    test('formattedTime returns correct format', () {
      final slot = ScoredSlot(
        slotId: 'slot_1',
        providerId: 'prov_1',
        providerName: 'Dr. Smith',
        startTime: DateTime(2024, 3, 15, 14, 30),
        endTime: DateTime(2024, 3, 15, 15, 30),
        predictedNoshowRisk: 0.15,
        score: 75.0,
        isRecommended: true,
        riskLevel: SlotRiskLevel.low,
        scoreFactors: [],
      );

      expect(slot.formattedTime, '2:30 PM');
    });

    test('dayName returns correct day', () {
      // March 15, 2024 is a Friday
      final slot = ScoredSlot(
        slotId: 'slot_1',
        providerId: 'prov_1',
        providerName: 'Dr. Smith',
        startTime: DateTime(2024, 3, 15, 14, 30),
        endTime: DateTime(2024, 3, 15, 15, 30),
        predictedNoshowRisk: 0.15,
        score: 75.0,
        isRecommended: true,
        riskLevel: SlotRiskLevel.low,
        scoreFactors: [],
      );

      expect(slot.dayName, 'Fri');
    });

    test('isSignificantlyBetter detects improvement > 15%', () {
      final better = ScoredSlot(
        slotId: 'slot_1',
        providerId: 'prov_1',
        providerName: 'Test',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        predictedNoshowRisk: 0.10,
        score: 80.0,
        isRecommended: true,
        riskLevel: SlotRiskLevel.low,
        scoreFactors: [],
        riskDifferencePercent: -25.0, // 25% better
      );

      expect(better.isSignificantlyBetter, true);
      expect(better.isSignificantlyWorse, false);
    });

    test('isSignificantlyWorse detects degradation > 15%', () {
      final worse = ScoredSlot(
        slotId: 'slot_1',
        providerId: 'prov_1',
        providerName: 'Test',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        predictedNoshowRisk: 0.40,
        score: 35.0,
        isRecommended: false,
        riskLevel: SlotRiskLevel.high,
        scoreFactors: [],
        riskDifferencePercent: 30.0, // 30% worse
      );

      expect(worse.isSignificantlyBetter, false);
      expect(worse.isSignificantlyWorse, true);
    });
  });

  group('SlotSuggestionResult', () {
    test('recommendedSlots filters correctly', () {
      final result = SlotSuggestionResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredSlots: [
          _createSlot('1', isRecommended: true, riskLevel: SlotRiskLevel.low),
          _createSlot('2', isRecommended: false, riskLevel: SlotRiskLevel.high),
          _createSlot('3', isRecommended: true, riskLevel: SlotRiskLevel.low),
        ],
        topSuggestions: [],
        slotsToAvoid: [],
        clientBaselineNoshowRate: 0.20,
        averageSlotRisk: 0.18,
        generatedAt: DateTime.now(),
        hasReliableHistory: true,
      );

      expect(result.recommendedSlots.length, 2);
      expect(result.hasRecommendations, true);
    });

    test('lowRiskSlotCount counts correctly', () {
      final result = SlotSuggestionResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredSlots: [
          _createSlot('1', riskLevel: SlotRiskLevel.low),
          _createSlot('2', riskLevel: SlotRiskLevel.medium),
          _createSlot('3', riskLevel: SlotRiskLevel.low),
          _createSlot('4', riskLevel: SlotRiskLevel.high),
        ],
        topSuggestions: [],
        slotsToAvoid: [],
        clientBaselineNoshowRate: 0.20,
        averageSlotRisk: 0.25,
        generatedAt: DateTime.now(),
        hasReliableHistory: true,
      );

      expect(result.lowRiskSlotCount, 2);
      expect(result.highRiskSlotCount, 1);
    });

    test('bestSlotImprovementPercent calculates correctly', () {
      final bestSlot = _createSlot(
        'best',
        riskLevel: SlotRiskLevel.low,
        predictedNoshowRisk: 0.10,
      );

      final result = SlotSuggestionResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredSlots: [bestSlot],
        topSuggestions: [],
        slotsToAvoid: [],
        clientBaselineNoshowRate: 0.20,
        averageSlotRisk: 0.18,
        bestSlot: bestSlot,
        generatedAt: DateTime.now(),
        hasReliableHistory: true,
      );

      // (0.20 - 0.10) / 0.20 * 100 = 50%
      expect(result.bestSlotImprovementPercent, 50.0);
    });
  });

  group('SlotScoreFactor', () {
    test('serialization works correctly', () {
      const factor = SlotScoreFactor(
        factorType: 'day_of_week',
        description: '30% lower risk on Tuesdays',
        impact: 0.30,
        weight: 0.25,
        iconName: 'calendar_today',
      );

      final json = factor.toJson();
      final restored = SlotScoreFactor.fromJson(json);

      expect(restored.factorType, 'day_of_week');
      expect(restored.impact, 0.30);
      expect(restored.weight, 0.25);
    });
  });

  group('SlotSuggestion', () {
    test('shouldShowAlternatives returns true for high risk with alternatives', () {
      final highRiskSlot = _createSlot(
        'high',
        riskLevel: SlotRiskLevel.high,
      );

      final suggestion = SlotSuggestion(
        slot: highRiskSlot,
        rank: 1,
        headline: 'Test',
        reasoning: 'Test reason',
        alternatives: [
          _createSlot('alt1', riskLevel: SlotRiskLevel.low),
        ],
        confidence: 0.8,
      );

      expect(suggestion.shouldShowAlternatives, true);
    });

    test('shouldShowAlternatives returns false for low risk', () {
      final lowRiskSlot = _createSlot(
        'low',
        riskLevel: SlotRiskLevel.low,
      );

      final suggestion = SlotSuggestion(
        slot: lowRiskSlot,
        rank: 1,
        headline: 'Test',
        reasoning: 'Test reason',
        alternatives: [
          _createSlot('alt1', riskLevel: SlotRiskLevel.low),
        ],
        confidence: 0.8,
      );

      expect(suggestion.shouldShowAlternatives, false);
    });
  });
}

/// Helper to create test slots
ScoredSlot _createSlot(
  String id, {
  bool isRecommended = false,
  SlotRiskLevel riskLevel = SlotRiskLevel.medium,
  double predictedNoshowRisk = 0.20,
}) {
  return ScoredSlot(
    slotId: id,
    providerId: 'provider_$id',
    providerName: 'Provider $id',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 1)),
    predictedNoshowRisk: predictedNoshowRisk,
    score: isRecommended ? 75.0 : 40.0,
    isRecommended: isRecommended,
    riskLevel: riskLevel,
    scoreFactors: [],
  );
}
