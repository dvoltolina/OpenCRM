import 'dart:math' as math;

import 'overbooking_config.dart';

/// Calculates expected revenue and optimal overbooking strategy.
///
/// Uses probability-weighted revenue calculations to determine
/// the optimal number of overbooks that maximizes expected value
/// while minimizing double-booking risk.
///
/// Agent AI-16: Yield Management & Overbooking Engine
class YieldCalculator {
  final OverbookingConfig config;

  const YieldCalculator({required this.config});

  /// Calculate expected revenue without overbooking.
  ///
  /// [servicePriceCents] - Price of the service in cents
  /// [noshowProbability] - Probability of no-show (0.0 - 1.0)
  /// [bookingCount] - Number of appointments in slot
  YieldResult calculateBaselineRevenue({
    required int servicePriceCents,
    required double noshowProbability,
    required int bookingCount,
  }) {
    // Expected shows = bookings * (1 - no-show probability)
    final expectedShows = bookingCount * (1 - noshowProbability);

    // Expected revenue = expected shows * service price
    final expectedRevenue = (expectedShows * servicePriceCents).round();

    // No-show cost = expected no-shows * (service price or configured cost)
    final noshowCost = config.noshowCostCents > 0
        ? config.noshowCostCents
        : servicePriceCents;
    final expectedNoshowLoss =
        (bookingCount * noshowProbability * noshowCost).round();

    return YieldResult(
      expectedRevenueCents: expectedRevenue,
      expectedLossCents: expectedNoshowLoss,
      netExpectedValueCents: expectedRevenue - expectedNoshowLoss,
      overbookCount: 0,
      doubleBookRisk: 0,
      scenarioDescription: 'No overbooking',
    );
  }

  /// Calculate expected revenue with overbooking.
  ///
  /// Uses expected value calculation:
  /// EV = P(no-show) * overbook_revenue - P(show) * double_book_penalty
  YieldResult calculateOverbookingRevenue({
    required int servicePriceCents,
    required double noshowProbability,
    required int bookingCount,
    required int overbookCount,
  }) {
    if (overbookCount <= 0) {
      return calculateBaselineRevenue(
        servicePriceCents: servicePriceCents,
        noshowProbability: noshowProbability,
        bookingCount: bookingCount,
      );
    }

    // Probability calculations
    final showProbability = 1 - noshowProbability;

    // Expected shows from original bookings
    final expectedOriginalShows = bookingCount * showProbability;

    // Expected shows from overbooks (assuming same no-show rate)
    final expectedOverbookShows = overbookCount * showProbability;

    // Total expected shows
    final totalExpectedShows = expectedOriginalShows + expectedOverbookShows;

    // Calculate probability of double-booking
    // P(double-book) = P(all original show AND at least one overbook shows)
    // Simplified: P(at least one no-show) ^ -1 when everyone shows
    final doubleBookProbability = _calculateDoubleBookProbability(
      bookingCount: bookingCount,
      overbookCount: overbookCount,
      showProbability: showProbability,
    );

    // Expected revenue from all appointments
    final grossRevenue = (totalExpectedShows * servicePriceCents).round();

    // Expected penalty from double-booking
    final expectedPenalty =
        (doubleBookProbability * config.doubleBookPenaltyCents * overbookCount)
            .round();

    // Revenue gained from filling no-show slots
    final expectedNoshowFillRevenue =
        (bookingCount * noshowProbability * servicePriceCents *
         math.min(overbookCount / bookingCount, noshowProbability))
            .round();

    // Net expected value
    final netExpectedValue =
        grossRevenue + expectedNoshowFillRevenue - expectedPenalty;

    return YieldResult(
      expectedRevenueCents: grossRevenue,
      expectedLossCents: expectedPenalty,
      netExpectedValueCents: netExpectedValue,
      overbookCount: overbookCount,
      doubleBookRisk: doubleBookProbability,
      additionalRevenueCents: expectedNoshowFillRevenue,
      scenarioDescription: 'Overbooking by $overbookCount',
    );
  }

  /// Find the optimal number of overbooks to maximize expected value.
  ///
  /// Iteratively calculates expected value for different overbook counts
  /// and returns the one with highest expected value, respecting config limits.
  OptimalOverbookResult findOptimalOverbooking({
    required int servicePriceCents,
    required double noshowProbability,
    required int bookingCount,
    required double predictionConfidence,
  }) {
    // Check if overbooking should be considered
    if (!config.isEnabled) {
      return OptimalOverbookResult(
        optimalOverbookCount: 0,
        baselineResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        optimalResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        allScenarios: [],
        recommendation: OverbookRecommendation.disabled,
        reason: 'Overbooking is disabled',
      );
    }

    if (noshowProbability < config.minNoshowProbabilityThreshold) {
      return OptimalOverbookResult(
        optimalOverbookCount: 0,
        baselineResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        optimalResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        allScenarios: [],
        recommendation: OverbookRecommendation.notRecommended,
        reason: 'No-show probability (${(noshowProbability * 100).toStringAsFixed(1)}%) '
            'below threshold (${(config.minNoshowProbabilityThreshold * 100).toStringAsFixed(1)}%)',
      );
    }

    if (bookingCount < config.minBookingsForOverbooking) {
      return OptimalOverbookResult(
        optimalOverbookCount: 0,
        baselineResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        optimalResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        allScenarios: [],
        recommendation: OverbookRecommendation.notRecommended,
        reason: 'Insufficient bookings ($bookingCount < ${config.minBookingsForOverbooking})',
      );
    }

    if (servicePriceCents < config.minServiceValueCents) {
      return OptimalOverbookResult(
        optimalOverbookCount: 0,
        baselineResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        optimalResult: calculateBaselineRevenue(
          servicePriceCents: servicePriceCents,
          noshowProbability: noshowProbability,
          bookingCount: bookingCount,
        ),
        allScenarios: [],
        recommendation: OverbookRecommendation.notRecommended,
        reason: 'Service value (\$${(servicePriceCents / 100).toStringAsFixed(2)}) '
            'below minimum (\$${(config.minServiceValueCents / 100).toStringAsFixed(2)})',
      );
    }

    // Calculate baseline (no overbooking)
    final baseline = calculateBaselineRevenue(
      servicePriceCents: servicePriceCents,
      noshowProbability: noshowProbability,
      bookingCount: bookingCount,
    );

    // Calculate maximum possible overbooks
    final maxOverbooks = _calculateMaxOverbooks(
      bookingCount: bookingCount,
      noshowProbability: noshowProbability,
      confidence: predictionConfidence,
    );

    if (maxOverbooks <= 0) {
      return OptimalOverbookResult(
        optimalOverbookCount: 0,
        baselineResult: baseline,
        optimalResult: baseline,
        allScenarios: [baseline],
        recommendation: OverbookRecommendation.notRecommended,
        reason: 'Expected no-shows too low for safe overbooking',
      );
    }

    // Calculate expected value for each overbook count
    final scenarios = <YieldResult>[baseline];
    var bestResult = baseline;
    var bestOverbookCount = 0;

    for (var i = 1; i <= maxOverbooks; i++) {
      final result = calculateOverbookingRevenue(
        servicePriceCents: servicePriceCents,
        noshowProbability: noshowProbability,
        bookingCount: bookingCount,
        overbookCount: i,
      );
      scenarios.add(result);

      if (result.netExpectedValueCents > bestResult.netExpectedValueCents) {
        bestResult = result;
        bestOverbookCount = i;
      }
    }

    // Determine recommendation
    final recommendation = bestOverbookCount > 0
        ? OverbookRecommendation.recommended
        : OverbookRecommendation.notRecommended;

    final improvementPercent = baseline.netExpectedValueCents > 0
        ? ((bestResult.netExpectedValueCents - baseline.netExpectedValueCents) /
                baseline.netExpectedValueCents *
                100)
            .toStringAsFixed(1)
        : '0';

    final reason = bestOverbookCount > 0
        ? 'Overbooking by $bestOverbookCount increases expected value by $improvementPercent%'
        : 'Overbooking would not improve expected value';

    return OptimalOverbookResult(
      optimalOverbookCount: bestOverbookCount,
      baselineResult: baseline,
      optimalResult: bestResult,
      allScenarios: scenarios,
      recommendation: recommendation,
      reason: reason,
    );
  }

  /// Calculate safe overbooking count using the algorithm from spec.
  ///
  /// safe_overbook_count = floor(
  ///   slot_bookings * predicted_noshow_rate * confidence_factor
  /// )
  int calculateSafeOverbookCount({
    required int bookingCount,
    required double noshowProbability,
    required double predictionConfidence,
  }) {
    if (!config.isEnabled) return 0;
    if (noshowProbability < config.minNoshowProbabilityThreshold) return 0;
    if (bookingCount < config.minBookingsForOverbooking) return 0;

    // Apply confidence factor and prediction confidence
    final adjustedConfidence = config.confidenceFactor * predictionConfidence;

    // Calculate safe count
    final rawCount = bookingCount * noshowProbability * adjustedConfidence;
    final safeCount = rawCount.round();

    // Apply limits
    final percentCap =
        (bookingCount * config.maxOverbookingPercentage).ceil();
    final adjustedPercentCap = config.maxOverbookingPercentage > 0
        ? math.max(1, percentCap)
        : 0;

    return math.min(
      safeCount,
      math.min(
        config.maxOverbooksPerSlot,
        adjustedPercentCap,
      ),
    );
  }

  // ============ Private Methods ============

  /// Calculate probability of double-booking occurring.
  double _calculateDoubleBookProbability({
    required int bookingCount,
    required int overbookCount,
    required double showProbability,
  }) {
    // P(double-book) = P(all original show) * P(at least one overbook shows)
    // Simplified model assuming independence

    // P(all original show)
    final allShowProbability = math.pow(showProbability, bookingCount).toDouble();

    // P(at least one overbook shows) = 1 - P(all overbooks no-show)
    final atLeastOneOverbookShows =
        1 - math.pow(1 - showProbability, overbookCount).toDouble();

    return allShowProbability * atLeastOneOverbookShows;
  }

  /// Calculate maximum overbooks based on expected no-shows.
  int _calculateMaxOverbooks({
    required int bookingCount,
    required double noshowProbability,
    required double confidence,
  }) {
    // Expected no-shows
    final expectedNoshows = bookingCount * noshowProbability;

    // Apply confidence factor
    final adjustedNoshows = expectedNoshows * config.confidenceFactor * confidence;

    // Floor and apply limits
    final maxFromExpected = adjustedNoshows.floor();

    return math.min(
      maxFromExpected,
      math.min(
        config.maxOverbooksPerSlot,
        (bookingCount * config.maxOverbookingPercentage).ceil(),
      ),
    );
  }
}

/// Result of a yield calculation for a specific scenario.
class YieldResult {
  /// Expected revenue in cents
  final int expectedRevenueCents;

  /// Expected loss/penalty in cents
  final int expectedLossCents;

  /// Net expected value (revenue - loss)
  final int netExpectedValueCents;

  /// Number of overbooks in this scenario
  final int overbookCount;

  /// Probability of double-booking
  final double doubleBookRisk;

  /// Additional revenue from filling no-show slots
  final int additionalRevenueCents;

  /// Human-readable description
  final String scenarioDescription;

  const YieldResult({
    required this.expectedRevenueCents,
    required this.expectedLossCents,
    required this.netExpectedValueCents,
    required this.overbookCount,
    required this.doubleBookRisk,
    this.additionalRevenueCents = 0,
    required this.scenarioDescription,
  });

  /// Risk-adjusted return on investment
  double get riskAdjustedROI {
    if (expectedRevenueCents <= 0) return 0;
    return (netExpectedValueCents - expectedLossCents) / expectedRevenueCents;
  }

  /// Double-book risk as percentage
  String get doubleBookRiskPercent =>
      '${(doubleBookRisk * 100).toStringAsFixed(1)}%';
}

/// Result of finding optimal overbooking strategy.
class OptimalOverbookResult {
  /// Optimal number of overbooks
  final int optimalOverbookCount;

  /// Result without overbooking
  final YieldResult baselineResult;

  /// Result with optimal overbooking
  final YieldResult optimalResult;

  /// All scenarios calculated
  final List<YieldResult> allScenarios;

  /// Recommendation type
  final OverbookRecommendation recommendation;

  /// Human-readable reason for recommendation
  final String reason;

  const OptimalOverbookResult({
    required this.optimalOverbookCount,
    required this.baselineResult,
    required this.optimalResult,
    required this.allScenarios,
    required this.recommendation,
    required this.reason,
  });

  /// Expected value improvement from overbooking
  int get expectedValueImprovement =>
      optimalResult.netExpectedValueCents - baselineResult.netExpectedValueCents;

  /// Whether overbooking is recommended
  bool get isOverbookingRecommended =>
      recommendation == OverbookRecommendation.recommended;

  /// Improvement percentage
  double get improvementPercent {
    if (baselineResult.netExpectedValueCents <= 0) return 0;
    return (expectedValueImprovement / baselineResult.netExpectedValueCents) * 100;
  }
}

/// Overbooking recommendation type.
enum OverbookRecommendation {
  /// Overbooking is recommended
  recommended,

  /// Overbooking is not recommended
  notRecommended,

  /// Overbooking is disabled
  disabled,
}
