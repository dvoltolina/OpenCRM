@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/yield/overbooking_config.dart';
import 'package:the_scheduler/ai/yield/yield_calculator.dart';

/// Tests for YieldCalculator
///
/// Agent AI-16: Yield Management & Overbooking Engine
void main() {
  group('YieldCalculator', () {
    late OverbookingConfig config;
    late YieldCalculator calculator;

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
      );
      calculator = YieldCalculator(config: config);
    });

    group('calculateBaselineRevenue', () {
      test('calculates expected revenue without overbooking', () {
        final result = calculator.calculateBaselineRevenue(
          servicePriceCents: 10000, // $100
          noshowProbability: 0.2, // 20%
          bookingCount: 5,
        );

        // Expected shows: 5 * 0.8 = 4
        // Expected revenue: 4 * $100 = $400
        expect(result.expectedRevenueCents, 40000);
        expect(result.overbookCount, 0);
        expect(result.scenarioDescription, 'No overbooking');
      });

      test('calculates loss from no-shows', () {
        final result = calculator.calculateBaselineRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.4,
          bookingCount: 10,
        );

        // Expected no-shows: 10 * 0.4 = 4
        // Expected loss: 4 * $100 = $400
        expect(result.expectedLossCents, 40000);
      });

      test('handles zero bookings', () {
        final result = calculator.calculateBaselineRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.2,
          bookingCount: 0,
        );

        expect(result.expectedRevenueCents, 0);
        expect(result.expectedLossCents, 0);
      });

      test('handles zero no-show probability', () {
        final result = calculator.calculateBaselineRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0,
          bookingCount: 5,
        );

        // All show: 5 * $100 = $500
        expect(result.expectedRevenueCents, 50000);
        expect(result.expectedLossCents, 0);
      });
    });

    group('calculateOverbookingRevenue', () {
      test('calculates revenue with overbooking', () {
        final result = calculator.calculateOverbookingRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.4,
          bookingCount: 5,
          overbookCount: 1,
        );

        expect(result.overbookCount, 1);
        expect(result.expectedRevenueCents, greaterThan(0));
        expect(result.doubleBookRisk, greaterThan(0));
        expect(result.doubleBookRisk, lessThan(1));
      });

      test('falls back to baseline when overbookCount is zero', () {
        final baseline = calculator.calculateBaselineRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.3,
          bookingCount: 5,
        );

        final result = calculator.calculateOverbookingRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.3,
          bookingCount: 5,
          overbookCount: 0,
        );

        expect(result.expectedRevenueCents, baseline.expectedRevenueCents);
        expect(result.overbookCount, 0);
      });

      test('increases double-book risk with more overbooks', () {
        final oneOverbook = calculator.calculateOverbookingRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.3,
          bookingCount: 5,
          overbookCount: 1,
        );

        final twoOverbooks = calculator.calculateOverbookingRevenue(
          servicePriceCents: 10000,
          noshowProbability: 0.3,
          bookingCount: 5,
          overbookCount: 2,
        );

        expect(twoOverbooks.doubleBookRisk, greaterThan(oneOverbook.doubleBookRisk));
      });
    });

    group('findOptimalOverbooking', () {
      test('recommends overbooking when profitable', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.4, // High no-show rate
          bookingCount: 5,
          predictionConfidence: 0.9,
        );

        expect(result.recommendation, OverbookRecommendation.recommended);
        expect(result.optimalOverbookCount, greaterThan(0));
        expect(result.expectedValueImprovement, greaterThan(0));
      });

      test('does not recommend when no-show probability too low', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.1, // Below threshold (0.3)
          bookingCount: 5,
          predictionConfidence: 0.9,
        );

        expect(result.recommendation, OverbookRecommendation.notRecommended);
        expect(result.optimalOverbookCount, 0);
        expect(result.reason, contains('below threshold'));
      });

      test('does not recommend when bookings insufficient', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.4,
          bookingCount: 1, // Below minimum (2)
          predictionConfidence: 0.9,
        );

        expect(result.recommendation, OverbookRecommendation.notRecommended);
        expect(result.reason, contains('Insufficient bookings'));
      });

      test('does not recommend when service value too low', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 1000, // $10, below minimum $25
          noshowProbability: 0.4,
          bookingCount: 5,
          predictionConfidence: 0.9,
        );

        expect(result.recommendation, OverbookRecommendation.notRecommended);
        expect(result.reason, contains('Service value'));
      });

      test('returns disabled when overbooking is disabled', () {
        final disabledConfig = OverbookingConfig.disabled();
        final disabledCalculator = YieldCalculator(config: disabledConfig);

        final result = disabledCalculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.4,
          bookingCount: 5,
          predictionConfidence: 0.9,
        );

        expect(result.recommendation, OverbookRecommendation.disabled);
        expect(result.optimalOverbookCount, 0);
      });

      test('respects max overbooks per slot', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.8, // Very high - would suggest many overbooks
          bookingCount: 10,
          predictionConfidence: 0.9,
        );

        expect(result.optimalOverbookCount, lessThanOrEqualTo(2)); // Max from config
      });

      test('provides all scenarios in result', () {
        final result = calculator.findOptimalOverbooking(
          servicePriceCents: 10000,
          noshowProbability: 0.4,
          bookingCount: 5,
          predictionConfidence: 0.9,
        );

        // Should have baseline + overbook scenarios
        expect(result.allScenarios.length, greaterThan(0));
        expect(result.allScenarios.first.overbookCount, 0); // Baseline
      });
    });

    group('calculateSafeOverbookCount', () {
      test('calculates safe count using algorithm', () {
        // safe_overbook_count = floor(
        //   slot_bookings * predicted_noshow_rate * confidence_factor * prediction_confidence
        // )
        // = floor(5 * 0.4 * 0.8 * 0.9) = floor(1.44) = 1
        final count = calculator.calculateSafeOverbookCount(
          bookingCount: 5,
          noshowProbability: 0.4,
          predictionConfidence: 0.9,
        );

        expect(count, 1);
      });

      test('returns zero when disabled', () {
        final disabledCalculator =
            YieldCalculator(config: OverbookingConfig.disabled());

        final count = disabledCalculator.calculateSafeOverbookCount(
          bookingCount: 10,
          noshowProbability: 0.5,
          predictionConfidence: 0.9,
        );

        expect(count, 0);
      });

      test('returns zero when below no-show threshold', () {
        final count = calculator.calculateSafeOverbookCount(
          bookingCount: 10,
          noshowProbability: 0.1, // Below 0.3 threshold
          predictionConfidence: 0.9,
        );

        expect(count, 0);
      });

      test('returns zero when bookings insufficient', () {
        final count = calculator.calculateSafeOverbookCount(
          bookingCount: 1, // Below min 2
          noshowProbability: 0.5,
          predictionConfidence: 0.9,
        );

        expect(count, 0);
      });

      test('respects max overbooks per slot limit', () {
        // Even with high probability, should not exceed max
        final count = calculator.calculateSafeOverbookCount(
          bookingCount: 20,
          noshowProbability: 0.8,
          predictionConfidence: 0.95,
        );

        expect(count, lessThanOrEqualTo(2)); // Max from config
      });

      test('respects max overbooking percentage', () {
        // 10 bookings * 20% max = 2 max overbooks
        final count = calculator.calculateSafeOverbookCount(
          bookingCount: 10,
          noshowProbability: 0.8,
          predictionConfidence: 0.95,
        );

        expect(count, lessThanOrEqualTo(2)); // 10 * 0.2 = 2
      });

      test('applies confidence factor', () {
        // Higher confidence = more overbooks allowed
        final lowConfidence = calculator.calculateSafeOverbookCount(
          bookingCount: 10,
          noshowProbability: 0.5,
          predictionConfidence: 0.5,
        );

        final highConfidence = calculator.calculateSafeOverbookCount(
          bookingCount: 10,
          noshowProbability: 0.5,
          predictionConfidence: 0.95,
        );

        expect(highConfidence, greaterThanOrEqualTo(lowConfidence));
      });
    });

    group('YieldResult', () {
      test('calculates risk-adjusted ROI', () {
        const result = YieldResult(
          expectedRevenueCents: 10000,
          expectedLossCents: 1000,
          netExpectedValueCents: 9000,
          overbookCount: 1,
          doubleBookRisk: 0.1,
          scenarioDescription: 'Test',
        );

        // ROI = (9000 - 1000) / 10000 = 0.8
        expect(result.riskAdjustedROI, 0.8);
      });

      test('formats double-book risk as percentage', () {
        const result = YieldResult(
          expectedRevenueCents: 10000,
          expectedLossCents: 0,
          netExpectedValueCents: 10000,
          overbookCount: 1,
          doubleBookRisk: 0.156,
          scenarioDescription: 'Test',
        );

        expect(result.doubleBookRiskPercent, '15.6%');
      });
    });

    group('OptimalOverbookResult', () {
      test('calculates improvement percentage', () {
        const baseline = YieldResult(
          expectedRevenueCents: 10000,
          expectedLossCents: 2000,
          netExpectedValueCents: 8000,
          overbookCount: 0,
          doubleBookRisk: 0,
          scenarioDescription: 'Baseline',
        );

        const optimal = YieldResult(
          expectedRevenueCents: 12000,
          expectedLossCents: 1500,
          netExpectedValueCents: 10500,
          overbookCount: 1,
          doubleBookRisk: 0.15,
          scenarioDescription: 'Optimal',
        );

        const result = OptimalOverbookResult(
          optimalOverbookCount: 1,
          baselineResult: baseline,
          optimalResult: optimal,
          allScenarios: [baseline, optimal],
          recommendation: OverbookRecommendation.recommended,
          reason: 'Test',
        );

        // Improvement: (10500 - 8000) / 8000 * 100 = 31.25%
        expect(result.improvementPercent, closeTo(31.25, 0.01));
        expect(result.expectedValueImprovement, 2500);
      });

      test('isOverbookingRecommended returns correct value', () {
        const recommended = OptimalOverbookResult(
          optimalOverbookCount: 1,
          baselineResult: YieldResult(
            expectedRevenueCents: 10000,
            expectedLossCents: 0,
            netExpectedValueCents: 10000,
            overbookCount: 0,
            doubleBookRisk: 0,
            scenarioDescription: 'Baseline',
          ),
          optimalResult: YieldResult(
            expectedRevenueCents: 12000,
            expectedLossCents: 0,
            netExpectedValueCents: 12000,
            overbookCount: 1,
            doubleBookRisk: 0.1,
            scenarioDescription: 'Optimal',
          ),
          allScenarios: [],
          recommendation: OverbookRecommendation.recommended,
          reason: 'Test',
        );

        expect(recommended.isOverbookingRecommended, true);

        const notRecommended = OptimalOverbookResult(
          optimalOverbookCount: 0,
          baselineResult: YieldResult(
            expectedRevenueCents: 10000,
            expectedLossCents: 0,
            netExpectedValueCents: 10000,
            overbookCount: 0,
            doubleBookRisk: 0,
            scenarioDescription: 'Baseline',
          ),
          optimalResult: YieldResult(
            expectedRevenueCents: 10000,
            expectedLossCents: 0,
            netExpectedValueCents: 10000,
            overbookCount: 0,
            doubleBookRisk: 0,
            scenarioDescription: 'Baseline',
          ),
          allScenarios: [],
          recommendation: OverbookRecommendation.notRecommended,
          reason: 'Test',
        );

        expect(notRecommended.isOverbookingRecommended, false);
      });
    });

    group('OverbookingConfig presets', () {
      test('conservative preset is more restrictive', () {
        final conservative = OverbookingConfig.conservative();

        expect(conservative.maxOverbookingPercentage, 0.1);
        expect(conservative.confidenceFactor, 0.7);
        expect(conservative.minNoshowProbabilityThreshold, 0.4);
        expect(conservative.maxOverbooksPerSlot, 1);
      });

      test('aggressive preset is less restrictive', () {
        final aggressive = OverbookingConfig.aggressive();

        expect(aggressive.maxOverbookingPercentage, 0.3);
        expect(aggressive.confidenceFactor, 0.9);
        expect(aggressive.minNoshowProbabilityThreshold, 0.25);
        expect(aggressive.maxOverbooksPerSlot, 3);
      });

      test('disabled preset disables overbooking', () {
        final disabled = OverbookingConfig.disabled();

        expect(disabled.isEnabled, false);
      });
    });
  });
}
