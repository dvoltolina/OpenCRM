@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/waitlist_score.dart';

/// Tests for WaitlistIntelligenceService and related models
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
void main() {
  group('WaitlistScore', () {
    test('isStrongMatch returns true for score >= 70', () {
      final strong = _createScore(overallScore: 75);
      final weak = _createScore(overallScore: 60);

      expect(strong.isStrongMatch, true);
      expect(weak.isStrongMatch, false);
    });

    test('isGoodMatch returns true for score >= 50', () {
      final good = _createScore(overallScore: 55);
      final poor = _createScore(overallScore: 40);

      expect(good.isGoodMatch, true);
      expect(poor.isGoodMatch, false);
    });

    test('primaryFactor returns highest impact factor', () {
      final score = WaitlistScore(
        overallScore: 70,
        timeFlexibilityScore: 25,
        proximityScore: 15,
        confirmRateScore: 20,
        revenueScore: 5,
        fairnessScore: 5,
        factors: [
          _createFactor(type: WaitlistFactorType.timeFlexibility, impact: 25),
          _createFactor(type: WaitlistFactorType.proximity, impact: 15),
          _createFactor(type: WaitlistFactorType.confirmRate, impact: 20),
        ],
      );

      expect(score.primaryFactor?.factorType, WaitlistFactorType.timeFlexibility);
    });

    test('scoreDisplay formats correctly', () {
      final score = _createScore(overallScore: 78.5);
      expect(score.scoreDisplay, '79%');
    });
  });

  group('WaitlistScoreFactor', () {
    test('percentOfMax calculates correctly', () {
      final factor = WaitlistScoreFactor(
        factorType: WaitlistFactorType.timeFlexibility,
        description: 'Perfect time match',
        impact: 24,
        maxImpact: 30,
      );

      expect(factor.percentOfMax, 80);
    });

    test('isPositive returns true when > 50% of max', () {
      final positive = _createFactor(impact: 20, maxImpact: 30);
      final negative = _createFactor(impact: 10, maxImpact: 30);

      expect(positive.isPositive, true);
      expect(negative.isPositive, false);
    });
  });

  group('TimeWindow', () {
    test('contains returns true for matching datetime', () {
      final window = TimeWindow(
        dayOfWeek: 1, // Monday
        startHour: 9,
        endHour: 12,
      );

      // Monday at 10 AM
      final matching = DateTime(2024, 3, 18, 10, 0); // Monday
      // Monday at 2 PM
      final wrongHour = DateTime(2024, 3, 18, 14, 0);
      // Tuesday at 10 AM
      final wrongDay = DateTime(2024, 3, 19, 10, 0);

      expect(window.contains(matching), true);
      expect(window.contains(wrongHour), false);
      expect(window.contains(wrongDay), false);
    });

    test('display formats correctly', () {
      final window = TimeWindow(
        dayOfWeek: 1,
        startHour: 9,
        endHour: 17,
      );

      expect(window.display, 'Mon 9 AM-5 PM');
    });
  });

  group('RankedWaitlistEntry', () {
    test('daysOnWaitlist calculates correctly', () {
      final entry = _createEntry(
        addedAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(entry.daysOnWaitlist, 10);
    });

    test('isTopCandidate returns true for rank <= 3', () {
      final top = _createEntry(rank: 2);
      final notTop = _createEntry(rank: 5);

      expect(top.isTopCandidate, true);
      expect(notTop.isTopCandidate, false);
    });

    test('distanceDisplay formats correctly', () {
      final withDistance = _createEntry(distanceKm: 5.5);
      final noDistance = _createEntry();

      expect(withDistance.distanceDisplay, '5.5 km');
      expect(noDistance.distanceDisplay, null);
    });

    test('confirmRateDisplay formats correctly', () {
      final withRate = _createEntry(historicalConfirmRate: 0.85);
      final noRate = _createEntry();

      expect(withRate.confirmRateDisplay, '85%');
      expect(noRate.confirmRateDisplay, null);
    });
  });

  group('WaitlistMatchResult', () {
    test('candidateCount returns correct count', () {
      final result = _createResult(candidateCount: 5);
      expect(result.candidateCount, 5);
    });

    test('hasCandidates returns correct value', () {
      final withCandidates = _createResult(candidateCount: 3);
      final noCandidates = _createResult(candidateCount: 0);

      expect(withCandidates.hasCandidates, true);
      expect(noCandidates.hasCandidates, false);
    });

    test('bestMatchScore returns first candidate score', () {
      final result = WaitlistMatchResult(
        slotId: 'slot_1',
        serviceId: 'service_1',
        providerId: 'provider_1',
        slotDateTime: DateTime.now(),
        candidates: [
          _createEntry(score: _createScore(overallScore: 85)),
          _createEntry(score: _createScore(overallScore: 70)),
        ],
        generatedAt: DateTime.now(),
        totalConsidered: 10,
      );

      expect(result.bestMatchScore, 85);
    });

    test('bestMatchScore returns null for empty candidates', () {
      final result = _createResult(candidateCount: 0);
      expect(result.bestMatchScore, null);
    });
  });

  group('WaitlistMatchRequest', () {
    test('default values are applied', () {
      final request = WaitlistMatchRequest(
        slotId: 'slot_1',
        serviceId: 'service_1',
        providerId: 'provider_1',
        slotDateTime: DateTime.now(),
      );

      expect(request.maxCandidates, 10);
      expect(request.autoOfferCount, 3);
      expect(request.minScore, 30);
    });

    test('serialization works correctly', () {
      final request = WaitlistMatchRequest(
        slotId: 'slot_1',
        serviceId: 'service_1',
        providerId: 'provider_1',
        slotDateTime: DateTime(2024, 3, 15, 10, 0),
        locationId: 'loc_1',
        maxCandidates: 5,
        autoOfferCount: 2,
        minScore: 40,
      );

      final json = request.toJson();
      final restored = WaitlistMatchRequest.fromJson(json);

      expect(restored.slotId, 'slot_1');
      expect(restored.maxCandidates, 5);
      expect(restored.autoOfferCount, 2);
      expect(restored.minScore, 40);
    });
  });

  group('WaitlistFactorType', () {
    test('all factor types are accessible', () {
      expect(WaitlistFactorType.timeFlexibility.name, 'timeFlexibility');
      expect(WaitlistFactorType.proximity.name, 'proximity');
      expect(WaitlistFactorType.confirmRate.name, 'confirmRate');
      expect(WaitlistFactorType.revenue.name, 'revenue');
      expect(WaitlistFactorType.fairness.name, 'fairness');
      expect(WaitlistFactorType.serviceMatch.name, 'serviceMatch');
      expect(WaitlistFactorType.providerPreference.name, 'providerPreference');
    });
  });
}

/// Helper to create test scores
WaitlistScore _createScore({
  double overallScore = 70,
}) {
  return WaitlistScore(
    overallScore: overallScore,
    timeFlexibilityScore: 25,
    proximityScore: 15,
    confirmRateScore: 20,
    revenueScore: 5,
    fairnessScore: 5,
    factors: [],
  );
}

/// Helper to create test factors
WaitlistScoreFactor _createFactor({
  WaitlistFactorType type = WaitlistFactorType.timeFlexibility,
  double impact = 20,
  double maxImpact = 30,
}) {
  return WaitlistScoreFactor(
    factorType: type,
    description: 'Test factor',
    impact: impact,
    maxImpact: maxImpact,
  );
}

/// Helper to create test entries
RankedWaitlistEntry _createEntry({
  int rank = 1,
  DateTime? addedAt,
  double? distanceKm,
  double? historicalConfirmRate,
  WaitlistScore? score,
}) {
  return RankedWaitlistEntry(
    entryId: 'entry_${DateTime.now().millisecondsSinceEpoch}',
    clientId: 'client_1',
    clientName: 'Test Client',
    serviceId: 'service_1',
    serviceName: 'Test Service',
    score: score ?? _createScore(),
    rank: rank,
    addedAt: addedAt ?? DateTime.now().subtract(const Duration(days: 5)),
    distanceKm: distanceKm,
    historicalConfirmRate: historicalConfirmRate,
  );
}

/// Helper to create test results
WaitlistMatchResult _createResult({
  int candidateCount = 3,
}) {
  return WaitlistMatchResult(
    slotId: 'slot_1',
    serviceId: 'service_1',
    providerId: 'provider_1',
    slotDateTime: DateTime.now(),
    candidates: List.generate(candidateCount, (i) => _createEntry(rank: i + 1)),
    generatedAt: DateTime.now(),
    totalConsidered: candidateCount + 5,
  );
}
