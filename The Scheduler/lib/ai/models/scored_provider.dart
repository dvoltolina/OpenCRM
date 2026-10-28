import 'package:freezed_annotation/freezed_annotation.dart';

part 'scored_provider.freezed.dart';
part 'scored_provider.g.dart';

/// A provider scored for a specific client based on historical patterns.
///
/// Used to rank providers and suggest the best match for a client
/// based on their booking history together.
///
/// Agent AI-20: Smart Scheduling Suggestions
@freezed
abstract class ScoredProvider with _$ScoredProvider {
  const ScoredProvider._();

  const factory ScoredProvider({
    /// Provider ID
    required String providerId,

    /// Provider display name
    required String providerName,

    /// Provider profile image URL (optional)
    String? profileImageUrl,

    /// Overall match score (0-100, higher is better)
    required double matchScore,

    /// No-show rate for this client with this provider
    required double noshowRateWithClient,

    /// Number of completed appointments together
    required int completedAppointments,

    /// Number of no-shows with this provider
    required int noshowCount,

    /// Number of cancellations with this provider
    required int cancellationCount,

    /// Whether this provider is recommended for the client
    required bool isRecommended,

    /// Match quality classification
    required ProviderMatchQuality matchQuality,

    /// Factors contributing to match score
    required List<ProviderMatchFactor> matchFactors,

    /// Human-readable recommendation text
    String? recommendationText,

    /// Provider's overall no-show rate (across all clients)
    double? providerOverallNoshowRate,

    /// How this client's rate compares to provider average
    double? clientVsAveragePercent,

    /// Last appointment date with this provider
    DateTime? lastAppointmentDate,

    /// Provider's specialties (if relevant)
    @Default([]) List<String> specialties,

    /// Whether provider is currently accepting new appointments
    @Default(true) bool isAcceptingAppointments,
  }) = _ScoredProvider;

  factory ScoredProvider.fromJson(Map<String, dynamic> json) =>
      _$ScoredProviderFromJson(json);

  /// Check if there's established history with this provider.
  bool get hasEstablishedHistory => completedAppointments >= 3;

  /// Check if this is a strong match (many successful appointments, low no-show).
  bool get isStrongMatch =>
      completedAppointments >= 5 && noshowRateWithClient < 0.15;

  /// Get completion rate with this provider.
  double get completionRate {
    final total = completedAppointments + noshowCount + cancellationCount;
    if (total == 0) return 1.0;
    return completedAppointments / total;
  }

  /// Format no-show rate as percentage.
  String get noshowRatePercent =>
      '${(noshowRateWithClient * 100).toStringAsFixed(0)}%';

  /// Format match score for display.
  String get matchScoreDisplay => '${matchScore.toStringAsFixed(0)}%';
}

/// Provider match quality classification.
enum ProviderMatchQuality {
  /// Excellent match - strong history, low no-show rate
  excellent,

  /// Good match - decent history, reasonable no-show rate
  good,

  /// Fair match - some history, moderate no-show rate
  fair,

  /// Poor match - limited history or high no-show rate
  poor,

  /// Unknown - no history with this provider
  unknown,
}

/// A factor contributing to provider match score.
@freezed
abstract class ProviderMatchFactor with _$ProviderMatchFactor {
  const factory ProviderMatchFactor({
    /// Factor type
    required ProviderFactorType factorType,

    /// Human-readable description
    required String description,

    /// Impact on score (-100 to 100)
    required double impact,

    /// Weight of this factor (0.0-1.0)
    required double weight,

    /// Icon name for UI
    String? iconName,
  }) = _ProviderMatchFactor;

  factory ProviderMatchFactor.fromJson(Map<String, dynamic> json) =>
      _$ProviderMatchFactorFromJson(json);
}

/// Types of factors that affect provider matching.
enum ProviderFactorType {
  /// Client's no-show history with this provider
  clientNoshowHistory,

  /// Number of successful appointments together
  appointmentHistory,

  /// Provider's overall no-show rate
  providerOverallRate,

  /// Recency of last appointment
  recency,

  /// Client preference (if expressed)
  clientPreference,

  /// Specialty match
  specialtyMatch,

  /// Availability
  availability,
}

/// Result of provider matching for a client.
@freezed
abstract class ProviderMatchResult with _$ProviderMatchResult {
  const ProviderMatchResult._();

  const factory ProviderMatchResult({
    /// Client ID
    required String clientId,

    /// Service being booked
    required String serviceId,

    /// All providers scored, sorted by match score
    required List<ScoredProvider> scoredProviders,

    /// Top recommended providers
    required List<ScoredProvider> recommendedProviders,

    /// Best matching provider
    ScoredProvider? bestMatch,

    /// Client's preferred provider (if they have one)
    ScoredProvider? preferredProvider,

    /// Whether client has history with any providers
    required bool hasProviderHistory,

    /// When this result was generated
    required DateTime generatedAt,

    /// Message for clients with no history
    String? noHistoryMessage,
  }) = _ProviderMatchResult;

  factory ProviderMatchResult.fromJson(Map<String, dynamic> json) =>
      _$ProviderMatchResultFromJson(json);

  /// Get providers with excellent match quality.
  List<ScoredProvider> get excellentMatches => scoredProviders
      .where((p) => p.matchQuality == ProviderMatchQuality.excellent)
      .toList();

  /// Get providers with good or better match quality.
  List<ScoredProvider> get goodOrBetterMatches => scoredProviders
      .where((p) =>
          p.matchQuality == ProviderMatchQuality.excellent ||
          p.matchQuality == ProviderMatchQuality.good)
      .toList();

  /// Check if there are any recommended providers.
  bool get hasRecommendations => recommendedProviders.isNotEmpty;

  /// Get count by match quality.
  Map<ProviderMatchQuality, int> get matchQualityCounts {
    final counts = <ProviderMatchQuality, int>{};
    for (final provider in scoredProviders) {
      counts[provider.matchQuality] =
          (counts[provider.matchQuality] ?? 0) + 1;
    }
    return counts;
  }
}

/// Request for provider matching.
@freezed
abstract class ProviderMatchRequest with _$ProviderMatchRequest {
  const factory ProviderMatchRequest({
    /// Client to match providers for
    required String clientId,

    /// Service being booked
    required String serviceId,

    /// Location filter (optional)
    String? locationId,

    /// Date for availability check (optional)
    DateTime? date,

    /// Maximum number of results
    @Default(10) int maxResults,

    /// Minimum appointments for reliable score
    @Default(2) int minAppointmentsForReliability,
  }) = _ProviderMatchRequest;

  factory ProviderMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$ProviderMatchRequestFromJson(json);
}
