/// Client risk score model for aggregated sentiment analysis.
///
/// Aggregates sentiment across all client communications to calculate
/// churn risk, satisfaction, and VIP scores with trend tracking.
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
import 'package:freezed_annotation/freezed_annotation.dart';
import 'risk_indicator.dart';

part 'client_risk_score.freezed.dart';
part 'client_risk_score.g.dart';

/// Trend direction for scores.
enum ScoreTrend {
  /// Score is improving (good for satisfaction, bad for churn)
  improving,

  /// Score is stable
  stable,

  /// Score is declining (bad for satisfaction, good for churn)
  declining,
}

/// Priority level for recommended actions.
enum ClientActionPriority {
  critical,
  high,
  medium,
  low,
}

/// A recommended action based on client risk analysis.
@freezed
abstract class RecommendedClientAction with _$RecommendedClientAction {
  const factory RecommendedClientAction({
    required String actionId,
    required String title,
    required String description,
    required ClientActionPriority priority,
    required String reasoning,
    required bool automatable,
    String? automationRuleId,
  }) = _RecommendedClientAction;

  factory RecommendedClientAction.fromJson(Map<String, dynamic> json) =>
      _$RecommendedClientActionFromJson(json);
}

/// Risk level classification for clients.
enum ClientRiskLevel { high, medium, low }

/// Aggregated risk and satisfaction scores for a client.
@freezed
abstract class ClientRiskScore with _$ClientRiskScore {
  const factory ClientRiskScore({
    /// Unique identifier
    required String id,

    /// Client this score belongs to
    required String clientId,

    /// Business ID (multi-tenant)
    required String businessId,

    /// When this score was calculated
    required DateTime calculatedAt,

    // ============ Core Scores (0-100) ============

    /// Churn risk score (0 = no risk, 100 = high risk)
    required int churnRiskScore,

    /// Satisfaction score (0 = unsatisfied, 100 = very satisfied)
    required int satisfactionScore,

    /// VIP score (0 = regular, 100 = high-value advocate)
    required int vipScore,

    /// Overall health score (composite)
    required int overallHealthScore,

    // ============ Trends ============

    /// Trend for churn risk
    required ScoreTrend churnTrend,

    /// Trend for satisfaction
    required ScoreTrend satisfactionTrend,

    /// Trend for VIP score
    required ScoreTrend vipTrend,

    /// Change in churn score from last calculation
    @Default(0) int churnScoreChange,

    /// Change in satisfaction score from last calculation
    @Default(0) int satisfactionScoreChange,

    // ============ Indicators ============

    /// All risk indicators contributing to score
    required List<RiskIndicator> riskIndicators,

    /// All VIP indicators contributing to score
    required List<RiskIndicator> vipIndicators,

    /// Top risk factors (most impactful)
    @Default([]) List<String> topRiskFactors,

    /// Top VIP factors (most impactful)
    @Default([]) List<String> topVipFactors,

    // ============ Analysis Metadata ============

    /// Number of texts analyzed for this score
    required int textsAnalyzed,

    /// Date range of analyzed communications
    required DateTime analysisStartDate,
    required DateTime analysisEndDate,

    /// Average sentiment across all analyzed texts
    required double averageSentiment,

    /// Sentiment standard deviation (consistency)
    required double sentimentStdDev,

    // ============ Recommendations ============

    /// Recommended actions based on analysis
    @Default([]) List<RecommendedClientAction> recommendedActions,

    // ============ Behavioral Signals ============

    /// Recent no-show count (factored into churn risk)
    @Default(0) int recentNoshowCount,

    /// Recent cancellation count
    @Default(0) int recentCancellationCount,

    /// Days since last visit
    @Default(0) int daysSinceLastVisit,

    /// Visit frequency trend (increasing, stable, decreasing)
    ScoreTrend? visitFrequencyTrend,

    // ============ Model Info ============

    /// Version of scoring algorithm used
    required String scoringVersion,

    /// When this score expires
    required DateTime expiresAt,
  }) = _ClientRiskScore;

  factory ClientRiskScore.fromJson(Map<String, dynamic> json) =>
      _$ClientRiskScoreFromJson(json);

  /// Create an empty/default score for clients with no data
  factory ClientRiskScore.empty({
    required String clientId,
    required String businessId,
  }) =>
      ClientRiskScore(
        id: 'empty_$clientId',
        clientId: clientId,
        businessId: businessId,
        calculatedAt: DateTime.now(),
        churnRiskScore: 0,
        satisfactionScore: 50,
        vipScore: 0,
        overallHealthScore: 50,
        churnTrend: ScoreTrend.stable,
        satisfactionTrend: ScoreTrend.stable,
        vipTrend: ScoreTrend.stable,
        riskIndicators: [],
        vipIndicators: [],
        topRiskFactors: [],
        topVipFactors: [],
        textsAnalyzed: 0,
        analysisStartDate: DateTime.now(),
        analysisEndDate: DateTime.now(),
        averageSentiment: 0,
        sentimentStdDev: 0,
        recommendedActions: [],
        scoringVersion: '1.0.0',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
}

extension ClientRiskScoreHelpers on ClientRiskScore {
  /// Whether this score has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this is an empty/default score
  bool get isEmpty => id.startsWith('empty_');

  /// Risk level classification
  ClientRiskLevel get riskLevel {
    if (churnRiskScore >= 70) return ClientRiskLevel.high;
    if (churnRiskScore >= 40) return ClientRiskLevel.medium;
    return ClientRiskLevel.low;
  }

  /// Whether client needs immediate attention
  bool get needsAttention =>
      churnRiskScore >= 70 ||
      riskIndicators.any((i) => i.severity == IndicatorSeverity.critical);

  /// Whether client is a potential VIP
  bool get isPotentialVip => vipScore >= 70;

  /// Has enough data for reliable scoring
  bool get hasReliableData => textsAnalyzed >= 3;

  /// Color for UI display based on risk
  String get riskColorHex => switch (riskLevel) {
        ClientRiskLevel.high => '#EF4444',
        ClientRiskLevel.medium => '#F59E0B',
        ClientRiskLevel.low => '#22C55E',
      };

  /// Risk level label for UI
  String get riskLabel => switch (riskLevel) {
        ClientRiskLevel.high => 'High Risk',
        ClientRiskLevel.medium => 'Medium Risk',
        ClientRiskLevel.low => 'Low Risk',
      };

  /// Satisfaction label for UI
  String get satisfactionLabel {
    if (satisfactionScore >= 80) return 'Very Satisfied';
    if (satisfactionScore >= 60) return 'Satisfied';
    if (satisfactionScore >= 40) return 'Neutral';
    if (satisfactionScore >= 20) return 'Dissatisfied';
    return 'Very Dissatisfied';
  }

  /// Overall health label for UI
  String get healthLabel {
    if (overallHealthScore >= 80) return 'Excellent';
    if (overallHealthScore >= 60) return 'Good';
    if (overallHealthScore >= 40) return 'Fair';
    if (overallHealthScore >= 20) return 'Poor';
    return 'Critical';
  }

  /// Count of unacknowledged risk indicators
  int get unacknowledgedRiskCount =>
      riskIndicators.where((i) => !i.acknowledged).length;

  /// Count of critical/high priority actions
  int get urgentActionCount => recommendedActions
      .where((a) =>
          a.priority == ClientActionPriority.critical ||
          a.priority == ClientActionPriority.high)
      .length;

  /// Trend icon for UI (arrow direction)
  String trendIcon(ScoreTrend trend) => switch (trend) {
        ScoreTrend.improving => '↑',
        ScoreTrend.stable => '→',
        ScoreTrend.declining => '↓',
      };

  /// Trend color for UI
  String trendColorHex(ScoreTrend trend, {bool inverseForRisk = false}) {
    final isPositive =
        inverseForRisk ? trend == ScoreTrend.declining : trend == ScoreTrend.improving;
    if (isPositive) return '#22C55E';
    if (trend == ScoreTrend.stable) return '#6B7280';
    return '#EF4444';
  }
}
