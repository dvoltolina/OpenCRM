@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/scored_provider.dart';

/// Tests for ProviderMatchingService and related models
///
/// Agent AI-20: Smart Scheduling Suggestions
void main() {
  group('ScoredProvider', () {
    test('hasEstablishedHistory returns true for 3+ appointments', () {
      final established = _createProvider(completedAppointments: 5);
      final notEstablished = _createProvider(completedAppointments: 2);

      expect(established.hasEstablishedHistory, true);
      expect(notEstablished.hasEstablishedHistory, false);
    });

    test('isStrongMatch requires 5+ appointments and <15% no-show', () {
      final strong = _createProvider(
        completedAppointments: 8,
        noshowRate: 0.10,
      );
      final weakHistory = _createProvider(
        completedAppointments: 3,
        noshowRate: 0.10,
      );
      final highNoshow = _createProvider(
        completedAppointments: 10,
        noshowRate: 0.25,
      );

      expect(strong.isStrongMatch, true);
      expect(weakHistory.isStrongMatch, false);
      expect(highNoshow.isStrongMatch, false);
    });

    test('completionRate calculates correctly', () {
      final provider = ScoredProvider(
        providerId: 'prov_1',
        providerName: 'Test Provider',
        matchScore: 75.0,
        noshowRateWithClient: 0.10,
        completedAppointments: 8,
        noshowCount: 1,
        cancellationCount: 1,
        isRecommended: true,
        matchQuality: ProviderMatchQuality.good,
        matchFactors: [],
      );

      // 8 / (8 + 1 + 1) = 0.8
      expect(provider.completionRate, 0.8);
    });

    test('completionRate returns 1.0 for no history', () {
      final newProvider = _createProvider(
        completedAppointments: 0,
        noshowCount: 0,
        cancellationCount: 0,
      );

      expect(newProvider.completionRate, 1.0);
    });

    test('noshowRatePercent formats correctly', () {
      final provider = _createProvider(noshowRate: 0.156);
      expect(provider.noshowRatePercent, '16%');
    });

    test('matchScoreDisplay formats correctly', () {
      final provider = _createProvider(matchScore: 78.5);
      expect(provider.matchScoreDisplay, '79%');
    });
  });

  group('ProviderMatchQuality', () {
    test('all values are accessible', () {
      expect(ProviderMatchQuality.excellent.name, 'excellent');
      expect(ProviderMatchQuality.good.name, 'good');
      expect(ProviderMatchQuality.fair.name, 'fair');
      expect(ProviderMatchQuality.poor.name, 'poor');
      expect(ProviderMatchQuality.unknown.name, 'unknown');
    });
  });

  group('ProviderMatchFactor', () {
    test('serialization works correctly', () {
      const factor = ProviderMatchFactor(
        factorType: ProviderFactorType.clientNoshowHistory,
        description: 'Excellent attendance (5% no-show)',
        impact: 50.0,
        weight: 0.40,
        iconName: 'history',
      );

      final json = factor.toJson();
      final restored = ProviderMatchFactor.fromJson(json);

      expect(restored.factorType, ProviderFactorType.clientNoshowHistory);
      expect(restored.impact, 50.0);
      expect(restored.weight, 0.40);
    });
  });

  group('ProviderMatchResult', () {
    test('excellentMatches filters correctly', () {
      final result = ProviderMatchResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredProviders: [
          _createProvider(matchQuality: ProviderMatchQuality.excellent),
          _createProvider(matchQuality: ProviderMatchQuality.good),
          _createProvider(matchQuality: ProviderMatchQuality.excellent),
          _createProvider(matchQuality: ProviderMatchQuality.fair),
        ],
        recommendedProviders: [],
        hasProviderHistory: true,
        generatedAt: DateTime.now(),
      );

      expect(result.excellentMatches.length, 2);
    });

    test('goodOrBetterMatches includes excellent and good', () {
      final result = ProviderMatchResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredProviders: [
          _createProvider(matchQuality: ProviderMatchQuality.excellent),
          _createProvider(matchQuality: ProviderMatchQuality.good),
          _createProvider(matchQuality: ProviderMatchQuality.fair),
          _createProvider(matchQuality: ProviderMatchQuality.poor),
        ],
        recommendedProviders: [],
        hasProviderHistory: true,
        generatedAt: DateTime.now(),
      );

      expect(result.goodOrBetterMatches.length, 2);
    });

    test('hasRecommendations returns correct value', () {
      final withRecs = ProviderMatchResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredProviders: [],
        recommendedProviders: [_createProvider()],
        hasProviderHistory: true,
        generatedAt: DateTime.now(),
      );

      final noRecs = ProviderMatchResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredProviders: [],
        recommendedProviders: [],
        hasProviderHistory: true,
        generatedAt: DateTime.now(),
      );

      expect(withRecs.hasRecommendations, true);
      expect(noRecs.hasRecommendations, false);
    });

    test('matchQualityCounts returns correct breakdown', () {
      final result = ProviderMatchResult(
        clientId: 'client_1',
        serviceId: 'service_1',
        scoredProviders: [
          _createProvider(matchQuality: ProviderMatchQuality.excellent),
          _createProvider(matchQuality: ProviderMatchQuality.excellent),
          _createProvider(matchQuality: ProviderMatchQuality.good),
          _createProvider(matchQuality: ProviderMatchQuality.fair),
          _createProvider(matchQuality: ProviderMatchQuality.fair),
          _createProvider(matchQuality: ProviderMatchQuality.fair),
        ],
        recommendedProviders: [],
        hasProviderHistory: true,
        generatedAt: DateTime.now(),
      );

      final counts = result.matchQualityCounts;
      expect(counts[ProviderMatchQuality.excellent], 2);
      expect(counts[ProviderMatchQuality.good], 1);
      expect(counts[ProviderMatchQuality.fair], 3);
      expect(counts[ProviderMatchQuality.poor], null);
    });
  });

  group('ProviderMatchRequest', () {
    test('default values are applied', () {
      const request = ProviderMatchRequest(
        clientId: 'client_1',
        serviceId: 'service_1',
      );

      expect(request.maxResults, 10);
      expect(request.minAppointmentsForReliability, 2);
      expect(request.locationId, null);
      expect(request.date, null);
    });

    test('serialization works correctly', () {
      final request = ProviderMatchRequest(
        clientId: 'client_1',
        serviceId: 'service_1',
        locationId: 'loc_1',
        date: DateTime(2024, 3, 15),
        maxResults: 5,
        minAppointmentsForReliability: 3,
      );

      final json = request.toJson();
      final restored = ProviderMatchRequest.fromJson(json);

      expect(restored.clientId, 'client_1');
      expect(restored.serviceId, 'service_1');
      expect(restored.locationId, 'loc_1');
      expect(restored.maxResults, 5);
    });
  });

  group('ProviderFactorType', () {
    test('all factor types are accessible', () {
      expect(ProviderFactorType.clientNoshowHistory.name, 'clientNoshowHistory');
      expect(ProviderFactorType.appointmentHistory.name, 'appointmentHistory');
      expect(ProviderFactorType.providerOverallRate.name, 'providerOverallRate');
      expect(ProviderFactorType.recency.name, 'recency');
      expect(ProviderFactorType.clientPreference.name, 'clientPreference');
      expect(ProviderFactorType.specialtyMatch.name, 'specialtyMatch');
      expect(ProviderFactorType.availability.name, 'availability');
    });
  });
}

/// Helper to create test providers
ScoredProvider _createProvider({
  String? providerId,
  int completedAppointments = 5,
  double noshowRate = 0.10,
  int noshowCount = 1,
  int cancellationCount = 0,
  double matchScore = 75.0,
  ProviderMatchQuality matchQuality = ProviderMatchQuality.good,
}) {
  return ScoredProvider(
    providerId: providerId ?? 'provider_${DateTime.now().millisecondsSinceEpoch}',
    providerName: 'Test Provider',
    matchScore: matchScore,
    noshowRateWithClient: noshowRate,
    completedAppointments: completedAppointments,
    noshowCount: noshowCount,
    cancellationCount: cancellationCount,
    isRecommended: matchQuality == ProviderMatchQuality.excellent ||
        matchQuality == ProviderMatchQuality.good,
    matchQuality: matchQuality,
    matchFactors: [],
  );
}
