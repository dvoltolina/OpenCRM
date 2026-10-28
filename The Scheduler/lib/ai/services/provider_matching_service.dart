import 'package:flutter/foundation.dart';

import '../../data/models/provider.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/providers_repository.dart';
import '../models/client_patterns.dart';
import '../models/scored_provider.dart';
import 'client_patterns_service.dart';

/// Service for matching clients with optimal providers.
///
/// Ranks providers based on client's historical booking patterns
/// to minimize no-show risk and maximize booking success.
///
/// **Scoring Factors:**
/// - Client's no-show history with provider
/// - Number of successful appointments together
/// - Provider's overall client retention
/// - Recency of relationship
///
/// Agent AI-20: Smart Scheduling Suggestions
class ProviderMatchingService {
  ProviderMatchingService({
    required ClientPatternsService clientPatternsService,
    required ProvidersRepository providersRepository,
  })  : _clientPatternsService = clientPatternsService,
        _providersRepository = providersRepository;

  final ClientPatternsService _clientPatternsService;
  final ProvidersRepository _providersRepository;

  /// Factor weights for provider matching
  static const double _noshowHistoryWeight = 0.40;
  static const double _appointmentCountWeight = 0.30;
  static const double _overallRateWeight = 0.20;
  static const double _recencyWeight = 0.10;

  /// Minimum appointments for reliable match score
  static const int _minAppointmentsForReliability = 2;

  /// Match providers to a client.
  Future<ProviderMatchResult> matchProviders({
    required SecurityContext context,
    required ProviderMatchRequest request,
  }) async {
    // Get client patterns
    final patterns = await _clientPatternsService.getClientPatterns(
      context: context,
      clientId: request.clientId,
    );

    // Get available providers
    final providers = await _providersRepository.getProviders(
      context: context,
      serviceId: request.serviceId,
      locationId: request.locationId,
    );

    // Score each provider
    final scoredProviders = <ScoredProvider>[];
    for (final provider in providers) {
      final scored = _scoreProvider(
        provider: provider,
        patterns: patterns,
        request: request,
      );
      scoredProviders.add(scored);
    }

    // Sort by match score (highest first)
    scoredProviders.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Identify recommended providers
    final recommended = scoredProviders
        .where((p) => p.isRecommended)
        .take(request.maxResults)
        .toList();

    // Find best match
    final bestMatch = scoredProviders.isNotEmpty ? scoredProviders.first : null;

    // Find preferred provider (if client has expressed preference)
    final preferredProvider = patterns.preferredProviders.isNotEmpty
        ? scoredProviders.firstWhere(
            (p) => patterns.preferredProviders.contains(p.providerId),
            orElse: () => scoredProviders.first,
          )
        : null;

    return ProviderMatchResult(
      clientId: request.clientId,
      serviceId: request.serviceId,
      scoredProviders: scoredProviders.take(request.maxResults).toList(),
      recommendedProviders: recommended,
      bestMatch: bestMatch,
      preferredProvider: preferredProvider,
      hasProviderHistory: patterns.providerNoshowRates.isNotEmpty,
      generatedAt: DateTime.now(),
      noHistoryMessage: patterns.providerNoshowRates.isEmpty
          ? 'No booking history - all providers shown'
          : null,
    );
  }

  /// Score a single provider for a client.
  ScoredProvider _scoreProvider({
    required Provider provider,
    required ClientPatterns patterns,
    required ProviderMatchRequest request,
  }) {
    final factors = <ProviderMatchFactor>[];

    // Get client's history with this provider
    final noshowRate = patterns.getNoshowRateForProvider(provider.id);
    final completedCount = patterns.getCompletedCountForProvider(provider.id);
    final hasHistory = completedCount > 0;

    // Calculate no-show history impact
    final noshowImpact = _calculateNoshowImpact(
      noshowRate,
      patterns.overallNoshowRate,
      completedCount,
    );
    factors.add(ProviderMatchFactor(
      factorType: ProviderFactorType.clientNoshowHistory,
      description: _getNoshowDescription(noshowRate, completedCount),
      impact: noshowImpact,
      weight: _noshowHistoryWeight,
      iconName: 'history',
    ));

    // Calculate appointment history impact
    final historyImpact = _calculateHistoryImpact(completedCount);
    factors.add(ProviderMatchFactor(
      factorType: ProviderFactorType.appointmentHistory,
      description: _getHistoryDescription(completedCount),
      impact: historyImpact,
      weight: _appointmentCountWeight,
      iconName: 'event_available',
    ));

    // Provider's overall no-show rate (if available)
    // This would come from provider statistics
    const providerOverallRate = 0.10; // Placeholder
    final overallImpact = _calculateOverallImpact(providerOverallRate);
    factors.add(ProviderMatchFactor(
      factorType: ProviderFactorType.providerOverallRate,
      description: _getOverallDescription(providerOverallRate),
      impact: overallImpact,
      weight: _overallRateWeight,
      iconName: 'trending_up',
    ));

    // Recency impact (placeholder - would need last appointment date)
    const recencyImpact = 0.0;
    factors.add(ProviderMatchFactor(
      factorType: ProviderFactorType.recency,
      description: hasHistory
          ? 'Existing relationship'
          : 'New provider for this client',
      impact: recencyImpact,
      weight: _recencyWeight,
      iconName: 'update',
    ));

    // Calculate overall match score
    final matchScore = _calculateMatchScore(factors);

    // Determine match quality
    final matchQuality = _classifyMatchQuality(
      matchScore,
      completedCount,
      noshowRate,
    );

    // Determine if recommended
    final isRecommended = _shouldRecommend(
      matchScore,
      completedCount,
      noshowRate,
      patterns,
    );

    return ScoredProvider(
      providerId: provider.id,
      providerName: provider.displayName,
      profileImageUrl: provider.profileImageUrl,
      matchScore: matchScore,
      noshowRateWithClient: noshowRate,
      completedAppointments: completedCount,
      noshowCount: (completedCount * noshowRate).round(),
      cancellationCount: 0, // Would need actual data
      isRecommended: isRecommended,
      matchQuality: matchQuality,
      matchFactors: factors,
      recommendationText: _getRecommendationText(
        matchQuality,
        completedCount,
        noshowRate,
        provider.displayName,
      ),
      providerOverallNoshowRate: providerOverallRate,
      clientVsAveragePercent: patterns.overallNoshowRate > 0
          ? ((noshowRate - patterns.overallNoshowRate) /
                  patterns.overallNoshowRate) *
              100
          : null,
      specialties: provider.services.map((s) => s.name).take(3).toList(),
      isAcceptingAppointments: provider.isActive,
    );
  }

  /// Calculate no-show history impact.
  double _calculateNoshowImpact(
    double rate,
    double baseline,
    int completedCount,
  ) {
    if (completedCount == 0) {
      return 0.0; // Neutral for no history
    }

    // Lower rate than baseline = positive impact
    if (baseline == 0) return rate < 0.15 ? 0.5 : 0.0;

    final improvement = (baseline - rate) / baseline;
    // Scale and clamp
    return (improvement * 100).clamp(-100.0, 100.0);
  }

  /// Calculate appointment history impact.
  double _calculateHistoryImpact(int completedCount) {
    if (completedCount == 0) return -20.0;
    if (completedCount == 1) return 0.0;
    if (completedCount <= 3) return 20.0;
    if (completedCount <= 5) return 40.0;
    if (completedCount <= 10) return 60.0;
    return 80.0;
  }

  /// Calculate provider overall rate impact.
  double _calculateOverallImpact(double overallRate) {
    // Lower overall rate = better
    if (overallRate < 0.05) return 40.0;
    if (overallRate < 0.10) return 20.0;
    if (overallRate < 0.15) return 0.0;
    if (overallRate < 0.25) return -20.0;
    return -40.0;
  }

  /// Calculate overall match score (0-100).
  double _calculateMatchScore(List<ProviderMatchFactor> factors) {
    final weightedSum = factors.fold<double>(
      0.0,
      (sum, f) => sum + (f.impact * f.weight),
    );
    // Normalize to 0-100 range
    return (50 + weightedSum * 0.5).clamp(0.0, 100.0);
  }

  /// Classify match quality.
  ProviderMatchQuality _classifyMatchQuality(
    double score,
    int completedCount,
    double noshowRate,
  ) {
    if (completedCount == 0) return ProviderMatchQuality.unknown;
    if (score >= 80 && noshowRate < 0.15) return ProviderMatchQuality.excellent;
    if (score >= 60 && noshowRate < 0.25) return ProviderMatchQuality.good;
    if (score >= 40) return ProviderMatchQuality.fair;
    return ProviderMatchQuality.poor;
  }

  /// Determine if provider should be recommended.
  bool _shouldRecommend(
    double score,
    int completedCount,
    double noshowRate,
    ClientPatterns patterns,
  ) {
    // Recommend if:
    // 1. Good match score (>= 50)
    // 2. Either has history with low no-show, OR no history but good score
    if (score < 50) return false;

    if (completedCount >= _minAppointmentsForReliability) {
      return noshowRate <= patterns.overallNoshowRate + 0.1;
    }

    // New provider - recommend if good score
    return score >= 60;
  }

  /// Generate no-show description.
  String _getNoshowDescription(double rate, int count) {
    if (count == 0) return 'No booking history';
    final percent = (rate * 100).toStringAsFixed(0);
    if (rate < 0.10) return 'Excellent attendance ($percent% no-show)';
    if (rate < 0.20) return 'Good attendance ($percent% no-show)';
    if (rate < 0.30) return 'Fair attendance ($percent% no-show)';
    return 'Higher no-show rate ($percent%)';
  }

  /// Generate history description.
  String _getHistoryDescription(int count) {
    if (count == 0) return 'First time with this provider';
    if (count == 1) return '1 previous appointment';
    if (count <= 5) return '$count appointments together';
    return '$count+ appointments - established relationship';
  }

  /// Generate overall rate description.
  String _getOverallDescription(double rate) {
    final percent = (rate * 100).toStringAsFixed(0);
    if (rate < 0.10) return "Provider's clients rarely no-show ($percent%)";
    if (rate < 0.15) return "Good client retention ($percent% no-show)";
    return "Average retention ($percent% no-show)";
  }

  /// Generate recommendation text.
  String? _getRecommendationText(
    ProviderMatchQuality quality,
    int completedCount,
    double noshowRate,
    String providerName,
  ) {
    switch (quality) {
      case ProviderMatchQuality.excellent:
        return 'Best match - strong track record together';
      case ProviderMatchQuality.good:
        return 'Great option - good history with $providerName';
      case ProviderMatchQuality.fair:
        return 'Available option';
      case ProviderMatchQuality.unknown:
        return completedCount == 0 ? 'New provider for you' : null;
      case ProviderMatchQuality.poor:
        return null;
    }
  }
}
