/// Service for calculating client risk scores from sentiment analysis.
///
/// Aggregates sentiment results into meaningful risk/satisfaction/VIP scores
/// with trend tracking and recommended actions.
///
/// Agent AI-7: Flutter Sentiment Integration
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/security_context.dart';
import '../models/client_risk_score.dart';
import '../models/sentiment_result.dart';
import '../models/risk_indicator.dart';
import '../models/sentiment_source.dart';
import '../repositories/client_risk_repository.dart';

/// Service for calculating and persisting client risk scores.
class ClientRiskScoringService {
  final ClientRiskRepository _riskRepo;

  static const String _scoringVersion = '1.0.0';
  static const Duration _scoreExpiry = Duration(days: 7);

  ClientRiskScoringService({
    required ClientRiskRepository riskRepo,
  }) : _riskRepo = riskRepo;

  /// Calculate and save risk score for a client based on sentiment results.
  ///
  /// Returns the calculated score.
  Future<ClientRiskScore> calculateAndSaveScore({
    required SecurityContext context,
    required String clientId,
    required List<SentimentResult> sentimentResults,
    int recentNoshowCount = 0,
    int recentCancellationCount = 0,
    int daysSinceLastVisit = 0,
    ScoreTrend? visitFrequencyTrend,
  }) async {
    // Get previous score for trend calculation
    final previousScore = await _riskRepo.getClientRiskScore(context, clientId);

    // Calculate the new score
    final newScore = calculateScore(
      clientId: clientId,
      businessId: context.businessId,
      sentimentResults: sentimentResults,
      previousScore: previousScore,
      recentNoshowCount: recentNoshowCount,
      recentCancellationCount: recentCancellationCount,
      daysSinceLastVisit: daysSinceLastVisit,
      visitFrequencyTrend: visitFrequencyTrend,
    );

    // Save to repository
    await _riskRepo.saveClientRiskScore(context, newScore);

    return newScore;
  }

  /// Calculate risk score without saving (for preview/testing).
  ClientRiskScore calculateScore({
    required String clientId,
    required String businessId,
    required List<SentimentResult> sentimentResults,
    ClientRiskScore? previousScore,
    int recentNoshowCount = 0,
    int recentCancellationCount = 0,
    int daysSinceLastVisit = 0,
    ScoreTrend? visitFrequencyTrend,
  }) {
    if (sentimentResults.isEmpty) {
      return ClientRiskScore.empty(clientId: clientId, businessId: businessId);
    }

    // Sort by date, newest first
    final sortedResults = List<SentimentResult>.from(sentimentResults)
      ..sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));

    // Calculate weighted sentiment average (newer = more weight)
    final weightedSentiment = _calculateWeightedSentiment(sortedResults);
    final sentimentStdDev = _calculateSentimentStdDev(sortedResults);

    // Aggregate indicators
    final allRiskIndicators = <RiskIndicator>[];
    final allVipIndicators = <RiskIndicator>[];

    for (final result in sortedResults) {
      allRiskIndicators.addAll(result.riskIndicators);
      allVipIndicators.addAll(result.vipIndicators);
    }

    // Calculate core scores
    final churnRiskScore = _calculateChurnRiskScore(
      weightedSentiment: weightedSentiment,
      riskIndicators: allRiskIndicators,
      recentNoshowCount: recentNoshowCount,
      recentCancellationCount: recentCancellationCount,
      daysSinceLastVisit: daysSinceLastVisit,
    );

    final satisfactionScore = _calculateSatisfactionScore(
      weightedSentiment: weightedSentiment,
      sentimentStdDev: sentimentStdDev,
      riskIndicators: allRiskIndicators,
    );

    final vipScore = _calculateVipScore(
      weightedSentiment: weightedSentiment,
      vipIndicators: allVipIndicators,
    );

    final overallHealthScore = _calculateOverallHealth(
      churnRiskScore: churnRiskScore,
      satisfactionScore: satisfactionScore,
      vipScore: vipScore,
    );

    // Calculate trends
    final churnTrend = _calculateTrend(
      current: churnRiskScore,
      previous: previousScore?.churnRiskScore,
      invertForRisk: true,
    );
    final satisfactionTrend = _calculateTrend(
      current: satisfactionScore,
      previous: previousScore?.satisfactionScore,
    );
    final vipTrend = _calculateTrend(
      current: vipScore,
      previous: previousScore?.vipScore,
    );

    // Get top factors
    final topRiskFactors = _getTopRiskFactors(allRiskIndicators);
    final topVipFactors = _getTopVipFactors(allVipIndicators);

    // Generate recommended actions
    final recommendedActions = _generateRecommendedActions(
      churnRiskScore: churnRiskScore,
      satisfactionScore: satisfactionScore,
      vipScore: vipScore,
      riskIndicators: allRiskIndicators,
      vipIndicators: allVipIndicators,
    );

    // Calculate date range
    final analysisStartDate = sortedResults.last.analyzedAt;
    final analysisEndDate = sortedResults.first.analyzedAt;

    final now = DateTime.now();

    return ClientRiskScore(
      id: 'risk_${clientId}_${now.millisecondsSinceEpoch}',
      clientId: clientId,
      businessId: businessId,
      calculatedAt: now,
      churnRiskScore: churnRiskScore,
      satisfactionScore: satisfactionScore,
      vipScore: vipScore,
      overallHealthScore: overallHealthScore,
      churnTrend: churnTrend,
      satisfactionTrend: satisfactionTrend,
      vipTrend: vipTrend,
      churnScoreChange: previousScore != null
          ? churnRiskScore - previousScore.churnRiskScore
          : 0,
      satisfactionScoreChange: previousScore != null
          ? satisfactionScore - previousScore.satisfactionScore
          : 0,
      riskIndicators: allRiskIndicators,
      vipIndicators: allVipIndicators,
      topRiskFactors: topRiskFactors,
      topVipFactors: topVipFactors,
      textsAnalyzed: sentimentResults.length,
      analysisStartDate: analysisStartDate,
      analysisEndDate: analysisEndDate,
      averageSentiment: weightedSentiment,
      sentimentStdDev: sentimentStdDev,
      recommendedActions: recommendedActions,
      recentNoshowCount: recentNoshowCount,
      recentCancellationCount: recentCancellationCount,
      daysSinceLastVisit: daysSinceLastVisit,
      visitFrequencyTrend: visitFrequencyTrend,
      scoringVersion: _scoringVersion,
      expiresAt: now.add(_scoreExpiry),
    );
  }

  // ============ Private Calculation Methods ============

  double _calculateWeightedSentiment(List<SentimentResult> results) {
    if (results.isEmpty) return 0;

    double weightedSum = 0;
    double totalWeight = 0;

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      // Exponential decay: newer results have more weight
      // Weight = 1.0 for newest, decays by 0.9^position
      final recencyWeight = pow(0.4, i).toDouble();
      // Also factor in source weight
      final sourceWeight = result.source.weight;
      // And confidence
      final confidenceWeight = result.confidence;

      final totalItemWeight = recencyWeight * sourceWeight * confidenceWeight;

      weightedSum += result.sentimentScore * totalItemWeight;
      totalWeight += totalItemWeight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  double _calculateSentimentStdDev(List<SentimentResult> results) {
    if (results.length <= 1) return 0;

    final mean =
        results.map((r) => r.sentimentScore).reduce((a, b) => a + b) /
            results.length;
    final squaredDiffs =
        results.map((r) => pow(r.sentimentScore - mean, 2).toDouble());
    final variance = squaredDiffs.reduce((a, b) => a + b) / results.length;

    return sqrt(variance);
  }

  int _calculateChurnRiskScore({
    required double weightedSentiment,
    required List<RiskIndicator> riskIndicators,
    required int recentNoshowCount,
    required int recentCancellationCount,
    required int daysSinceLastVisit,
  }) {
    // Base score from sentiment (inverted: negative sentiment = high risk)
    // Sentiment ranges -1 to 1, convert to 0-70 base risk
    var score = ((1 - weightedSentiment) / 2 * 70).round();

    // Add points for risk indicators
    for (final indicator in riskIndicators) {
      switch (indicator.severity) {
        case IndicatorSeverity.critical:
          score += 20;
        case IndicatorSeverity.high:
          score += 12;
        case IndicatorSeverity.medium:
          score += 6;
        case IndicatorSeverity.low:
          score += 2;
      }
    }

    // Add points for behavioral signals
    score += recentNoshowCount * 8;
    score += recentCancellationCount * 4;

    // Add points for inactivity
    if (daysSinceLastVisit > 90) {
      score += 15;
    } else if (daysSinceLastVisit > 60) {
      score += 10;
    } else if (daysSinceLastVisit > 30) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  int _calculateSatisfactionScore({
    required double weightedSentiment,
    required double sentimentStdDev,
    required List<RiskIndicator> riskIndicators,
  }) {
    // Base from sentiment: -1 to 1 maps to 0-100
    var score = ((weightedSentiment + 1) / 2 * 100).round();

    // Reduce for inconsistency (high std dev = less reliable satisfaction)
    if (sentimentStdDev > 0.5) {
      score -= 10;
    } else if (sentimentStdDev > 0.3) {
      score -= 5;
    }

    // Reduce for risk indicators
    for (final indicator in riskIndicators) {
      if (indicator.category == 'dissatisfaction' ||
          indicator.category == 'service_complaint') {
        score -= 8;
      } else if (indicator.category == 'price_complaint') {
        score -= 5;
      }
    }

    return score.clamp(0, 100);
  }

  int _calculateVipScore({
    required double weightedSentiment,
    required List<RiskIndicator> vipIndicators,
  }) {
    // Base from positive sentiment only
    var score = weightedSentiment > 0 ? (weightedSentiment * 30).round() : 0;

    // Add points for VIP indicators
    for (final indicator in vipIndicators) {
      switch (indicator.category) {
        case 'referral_intent':
          score += 25;
        case 'loyalty':
          score += 20;
        case 'positive_review':
          score += 15;
        case 'advocate_signal':
          score += 20;
        case 'gratitude':
          score += 10;
        case 'engagement':
          score += 8;
        case 'premium_interest':
          score += 12;
        default:
          score += 5;
      }
    }

    return score.clamp(0, 100);
  }

  int _calculateOverallHealth({
    required int churnRiskScore,
    required int satisfactionScore,
    required int vipScore,
  }) {
    // Overall health is a composite:
    // - High satisfaction and low churn = healthy
    // - VIP status boosts health
    final invertedChurn = 100 - churnRiskScore;

    return ((invertedChurn * 0.4) + (satisfactionScore * 0.4) + (vipScore * 0.2))
        .round()
        .clamp(0, 100);
  }

  ScoreTrend _calculateTrend({
    required int current,
    int? previous,
    bool invertForRisk = false,
  }) {
    if (previous == null) return ScoreTrend.stable;

    final diff = current - previous;
    const threshold = 5;

    if (diff > threshold) {
      return invertForRisk ? ScoreTrend.declining : ScoreTrend.improving;
    } else if (diff < -threshold) {
      return invertForRisk ? ScoreTrend.improving : ScoreTrend.declining;
    }
    return ScoreTrend.stable;
  }

  List<String> _getTopRiskFactors(List<RiskIndicator> indicators) {
    // Group by category and count
    final categoryCount = <String, int>{};
    for (final ind in indicators) {
      categoryCount[ind.category] = (categoryCount[ind.category] ?? 0) + 1;
    }

    // Sort by count and return top 3
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  List<String> _getTopVipFactors(List<RiskIndicator> indicators) {
    final categoryCount = <String, int>{};
    for (final ind in indicators) {
      categoryCount[ind.category] = (categoryCount[ind.category] ?? 0) + 1;
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  List<RecommendedClientAction> _generateRecommendedActions({
    required int churnRiskScore,
    required int satisfactionScore,
    required int vipScore,
    required List<RiskIndicator> riskIndicators,
    required List<RiskIndicator> vipIndicators,
  }) {
    final actions = <RecommendedClientAction>[];

    // High churn risk actions
    if (churnRiskScore >= 70) {
      // Check for specific issues
      final hasServiceComplaint =
          riskIndicators.any((i) => i.category == 'service_complaint');
      final hasPriceComplaint =
          riskIndicators.any((i) => i.category == 'price_complaint');
      final hasChurnIntent =
          riskIndicators.any((i) => i.category == 'churn_intent');

      if (hasChurnIntent) {
        actions.add(const RecommendedClientAction(
          actionId: 'urgent_outreach',
          title: 'Urgent Personal Outreach',
          description:
              'Client has expressed intent to leave. Immediate personal contact recommended.',
          priority: ClientActionPriority.critical,
          reasoning: 'Churn intent detected in recent communication',
          automatable: false,
        ));
      }

      if (hasServiceComplaint) {
        actions.add(const RecommendedClientAction(
          actionId: 'service_recovery',
          title: 'Service Recovery',
          description: 'Offer complimentary service or discount to address concerns',
          priority: ClientActionPriority.high,
          reasoning: 'Service complaint detected',
          automatable: true,
          automationRuleId: 'service_recovery_offer',
        ));
      }

      if (hasPriceComplaint) {
        actions.add(const RecommendedClientAction(
          actionId: 'loyalty_discount',
          title: 'Loyalty Discount',
          description: 'Offer loyalty discount to retain client',
          priority: ClientActionPriority.high,
          reasoning: 'Price sensitivity detected',
          automatable: true,
          automationRuleId: 'loyalty_discount_offer',
        ));
      }
    } else if (churnRiskScore >= 40) {
      actions.add(const RecommendedClientAction(
        actionId: 'check_in_message',
        title: 'Send Check-in Message',
        description: 'Send a personalized message asking about their experience',
        priority: ClientActionPriority.medium,
        reasoning: 'Moderate churn risk - proactive engagement recommended',
        automatable: true,
        automationRuleId: 'client_check_in',
      ));
    }

    // VIP opportunity actions
    if (vipIndicators.any((i) => i.category == 'referral_intent')) {
      actions.add(const RecommendedClientAction(
        actionId: 'referral_program',
        title: 'Invite to Referral Program',
        description: 'Send referral program invitation with incentive',
        priority: ClientActionPriority.high,
        reasoning: 'Client expressed interest in referring others',
        automatable: true,
        automationRuleId: 'referral_invite',
      ));
    }

    if (vipScore >= 70) {
      actions.add(const RecommendedClientAction(
        actionId: 'vip_recognition',
        title: 'VIP Recognition',
        description: 'Send thank you note or small gift',
        priority: ClientActionPriority.medium,
        reasoning: 'High VIP score indicates loyal, valuable client',
        automatable: true,
        automationRuleId: 'vip_thank_you',
      ));
    }

    // Low satisfaction actions
    if (satisfactionScore < 40) {
      actions.add(const RecommendedClientAction(
        actionId: 'satisfaction_survey',
        title: 'Request Detailed Feedback',
        description: 'Send satisfaction survey to understand concerns',
        priority: ClientActionPriority.medium,
        reasoning: 'Low satisfaction score - need more information',
        automatable: true,
        automationRuleId: 'satisfaction_survey',
      ));
    }

    return actions;
  }
}
