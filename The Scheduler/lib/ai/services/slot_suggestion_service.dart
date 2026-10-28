import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/models/security_context.dart';
import '../models/client_patterns.dart';
import '../models/slot_suggestion.dart';
import 'client_patterns_service.dart';

/// Service for generating intelligent slot suggestions.
///
/// Scores available time slots for a specific client based on their
/// historical booking patterns to minimize no-show risk.
///
/// **Scoring Factors:**
/// - Day-of-week history (client's no-show rate on that day)
/// - Hour-of-day history (client's no-show rate at that hour)
/// - Provider match (client's history with the provider)
/// - Lead time (how far in advance the booking is)
///
/// Agent AI-20: Smart Scheduling Suggestions
class SlotSuggestionService {
  SlotSuggestionService({
    required ClientPatternsService clientPatternsService,
  }) : _clientPatternsService = clientPatternsService;

  final ClientPatternsService _clientPatternsService;

  /// Factor weights for scoring
  static const double _dayOfWeekWeight = 0.30;
  static const double _hourOfDayWeight = 0.20;
  static const double _providerWeight = 0.35;
  static const double _leadTimeWeight = 0.15;

  /// Thresholds for risk classification
  static const double _lowRiskThreshold = 0.20;
  static const double _highRiskThreshold = 0.40;

  /// Generate slot suggestions for a client.
  Future<SlotSuggestionResult> getSuggestions({
    required SecurityContext context,
    required SlotSuggestionRequest request,
    required List<AvailableSlot> availableSlots,
  }) async {
    // Get client patterns
    final patterns = await _clientPatternsService.getClientPatterns(
      context: context,
      clientId: request.clientId,
    );

    // Score all slots
    final scoredSlots = <ScoredSlot>[];
    for (final slot in availableSlots) {
      final scored = _scoreSlot(
        slot: slot,
        patterns: patterns,
        request: request,
      );
      scoredSlots.add(scored);
    }

    // Sort by score (higher is better)
    scoredSlots.sort((a, b) => b.score.compareTo(a.score));

    // Identify slots to avoid
    final slotsToAvoid = scoredSlots
        .where((s) => s.riskLevel == SlotRiskLevel.high)
        .toList();

    // Generate top suggestions
    final topSuggestions = _generateSuggestions(
      scoredSlots: scoredSlots,
      patterns: patterns,
      maxSuggestions: math.min(request.maxSuggestions, 3),
    );

    // Calculate average risk
    final avgRisk = scoredSlots.isNotEmpty
        ? scoredSlots.map((s) => s.predictedNoshowRisk).reduce((a, b) => a + b) /
            scoredSlots.length
        : patterns.overallNoshowRate;

    return SlotSuggestionResult(
      clientId: request.clientId,
      serviceId: request.serviceId,
      scoredSlots: request.includeHighRisk
          ? scoredSlots
          : scoredSlots
              .where((s) => s.riskLevel != SlotRiskLevel.high)
              .toList(),
      topSuggestions: topSuggestions,
      slotsToAvoid: slotsToAvoid,
      clientBaselineNoshowRate: patterns.overallNoshowRate,
      averageSlotRisk: avgRisk,
      bestSlot: scoredSlots.isNotEmpty ? scoredSlots.first : null,
      generatedAt: DateTime.now(),
      hasReliableHistory: patterns.hasReliableData,
      insufficientHistoryMessage: patterns.hasReliableData
          ? null
          : 'Limited booking history - suggestions based on general patterns',
    );
  }

  /// Score a single slot for a client.
  ScoredSlot _scoreSlot({
    required AvailableSlot slot,
    required ClientPatterns patterns,
    required SlotSuggestionRequest request,
  }) {
    final factors = <SlotScoreFactor>[];

    // Calculate lead time in days
    final leadDays = slot.startTime.difference(DateTime.now()).inDays;

    // Day of week factor
    final dayRate = patterns.getNoshowRateForDay(slot.startTime.weekday);
    final dayImpact = _calculateImpact(dayRate, patterns.overallNoshowRate);
    factors.add(SlotScoreFactor(
      factorType: 'day_of_week',
      description: _getDayDescription(slot.startTime.weekday, dayRate, dayImpact),
      impact: dayImpact,
      weight: _dayOfWeekWeight,
      iconName: 'calendar_today',
    ));

    // Hour of day factor
    final hourRate = patterns.getNoshowRateForHour(slot.startTime.hour);
    final hourImpact = _calculateImpact(hourRate, patterns.overallNoshowRate);
    factors.add(SlotScoreFactor(
      factorType: 'hour_of_day',
      description: _getHourDescription(slot.startTime.hour, hourRate, hourImpact),
      impact: hourImpact,
      weight: _hourOfDayWeight,
      iconName: 'schedule',
    ));

    // Provider factor
    final providerRate = patterns.getNoshowRateForProvider(slot.providerId);
    final providerCompleted = patterns.getCompletedCountForProvider(slot.providerId);
    final providerImpact = _calculateProviderImpact(
      providerRate,
      providerCompleted,
      patterns.overallNoshowRate,
    );
    factors.add(SlotScoreFactor(
      factorType: 'provider',
      description: _getProviderDescription(
        slot.providerName,
        providerRate,
        providerCompleted,
        providerImpact,
      ),
      impact: providerImpact,
      weight: _providerWeight,
      iconName: 'person',
    ));

    // Lead time factor
    final leadTimeRate = patterns.getNoshowRateForLeadTime(leadDays);
    final leadTimeImpact = _calculateImpact(leadTimeRate, patterns.overallNoshowRate);
    factors.add(SlotScoreFactor(
      factorType: 'lead_time',
      description: _getLeadTimeDescription(leadDays, leadTimeRate, leadTimeImpact),
      impact: leadTimeImpact,
      weight: _leadTimeWeight,
      iconName: 'event',
    ));

    // Calculate overall score
    final weightedSum = factors.fold<double>(
      0.0,
      (sum, f) => sum + (f.impact * f.weight),
    );
    // Normalize score to 0-100 range (0 impact = 50, positive = higher)
    final score = (50 + weightedSum * 50).clamp(0.0, 100.0);

    // Calculate predicted no-show risk
    final predictedRisk = _calculatePredictedRisk(
      dayRate: dayRate,
      hourRate: hourRate,
      providerRate: providerRate,
      leadTimeRate: leadTimeRate,
      baselineRate: patterns.overallNoshowRate,
    );

    // Determine risk level
    final riskLevel = _classifyRisk(predictedRisk);

    // Calculate difference from baseline
    final riskDifference = patterns.overallNoshowRate > 0
        ? ((predictedRisk - patterns.overallNoshowRate) /
                patterns.overallNoshowRate) *
            100
        : 0.0;

    return ScoredSlot(
      slotId: slot.slotId,
      providerId: slot.providerId,
      providerName: slot.providerName,
      startTime: slot.startTime,
      endTime: slot.endTime,
      predictedNoshowRisk: predictedRisk,
      score: score,
      isRecommended: score >= 60 && riskLevel != SlotRiskLevel.high,
      riskLevel: riskLevel,
      scoreFactors: factors,
      recommendationReason: _generateRecommendationReason(factors, riskLevel),
      riskDifferencePercent: riskDifference,
      serviceId: request.serviceId,
      locationId: request.locationId,
      isAvailable: slot.isAvailable,
    );
  }

  /// Calculate impact score (-1 to 1) comparing rate to baseline.
  double _calculateImpact(double rate, double baseline) {
    if (baseline == 0) return 0.0;
    final difference = baseline - rate; // Positive if rate is lower (good)
    // Scale to -1 to 1 range
    return (difference / baseline).clamp(-1.0, 1.0);
  }

  /// Calculate provider impact with history consideration.
  double _calculateProviderImpact(
    double rate,
    int completedCount,
    double baseline,
  ) {
    // Give bonus for established relationships
    var impact = _calculateImpact(rate, baseline);

    if (completedCount >= 5) {
      impact += 0.1; // Small bonus for strong history
    } else if (completedCount == 0) {
      impact *= 0.5; // Reduce confidence for no history
    }

    return impact.clamp(-1.0, 1.0);
  }

  /// Calculate predicted no-show risk for slot.
  double _calculatePredictedRisk({
    required double dayRate,
    required double hourRate,
    required double providerRate,
    required double leadTimeRate,
    required double baselineRate,
  }) {
    // Weighted average of risk factors
    final weightedRisk = dayRate * _dayOfWeekWeight +
        hourRate * _hourOfDayWeight +
        providerRate * _providerWeight +
        leadTimeRate * _leadTimeWeight;

    // Blend with baseline for stability
    return (weightedRisk * 0.7 + baselineRate * 0.3).clamp(0.0, 1.0);
  }

  /// Classify risk level.
  SlotRiskLevel _classifyRisk(double risk) {
    if (risk < _lowRiskThreshold) return SlotRiskLevel.low;
    if (risk > _highRiskThreshold) return SlotRiskLevel.high;
    return SlotRiskLevel.medium;
  }

  /// Generate description for day-of-week factor.
  String _getDayDescription(int weekday, double rate, double impact) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[weekday - 1];
    final percent = (rate * 100).toStringAsFixed(0);

    if (impact > 0.15) {
      return '${(impact * 100).toStringAsFixed(0)}% lower risk on ${dayName}s';
    } else if (impact < -0.15) {
      return '${(-impact * 100).toStringAsFixed(0)}% higher risk on ${dayName}s';
    }
    return '$percent% no-show rate on ${dayName}s';
  }

  /// Generate description for hour-of-day factor.
  String _getHourDescription(int hour, double rate, double impact) {
    final timeStr = _formatHour(hour);

    if (impact > 0.15) {
      return '${(impact * 100).toStringAsFixed(0)}% lower risk at $timeStr';
    } else if (impact < -0.15) {
      return '${(-impact * 100).toStringAsFixed(0)}% higher risk at $timeStr';
    }
    return 'Average risk at $timeStr';
  }

  /// Generate description for provider factor.
  String _getProviderDescription(
    String providerName,
    double rate,
    int completedCount,
    double impact,
  ) {
    if (completedCount == 0) {
      return 'No history with $providerName';
    }
    if (completedCount >= 5 && rate < 0.15) {
      return 'Strong track record with $providerName';
    }
    if (impact > 0.15) {
      return '${(impact * 100).toStringAsFixed(0)}% lower risk with $providerName';
    }
    if (impact < -0.15) {
      return '${(-impact * 100).toStringAsFixed(0)}% higher risk with $providerName';
    }
    return '$completedCount appointments with $providerName';
  }

  /// Generate description for lead time factor.
  String _getLeadTimeDescription(int days, double rate, double impact) {
    if (days == 0) {
      return 'Same-day booking';
    }
    if (impact > 0.15) {
      return 'Better attendance when booking $days days ahead';
    }
    if (impact < -0.15) {
      return 'Higher no-show risk when booking $days+ days ahead';
    }
    return 'Booking $days days in advance';
  }

  /// Format hour for display.
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  /// Generate recommendation reason from factors.
  String? _generateRecommendationReason(
    List<SlotScoreFactor> factors,
    SlotRiskLevel riskLevel,
  ) {
    if (riskLevel == SlotRiskLevel.high) {
      final worstFactor = factors.reduce(
        (a, b) => a.impact < b.impact ? a : b,
      );
      return worstFactor.description;
    }

    if (riskLevel == SlotRiskLevel.low) {
      final bestFactor = factors.reduce(
        (a, b) => a.impact > b.impact ? a : b,
      );
      if (bestFactor.impact > 0.1) {
        return bestFactor.description;
      }
    }

    return null;
  }

  /// Generate top suggestions with detailed reasoning.
  List<SlotSuggestion> _generateSuggestions({
    required List<ScoredSlot> scoredSlots,
    required ClientPatterns patterns,
    required int maxSuggestions,
  }) {
    final suggestions = <SlotSuggestion>[];
    final recommendedSlots =
        scoredSlots.where((s) => s.isRecommended).take(maxSuggestions);

    var rank = 1;
    for (final slot in recommendedSlots) {
      final headline = _generateHeadline(slot, rank);
      final reasoning = _generateReasoning(slot, patterns);
      final comparison = _generateComparison(slot, patterns);

      // Find alternatives if this slot is risky
      final alternatives = slot.riskLevel == SlotRiskLevel.medium
          ? scoredSlots
              .where((s) =>
                  s.slotId != slot.slotId &&
                  s.riskLevel == SlotRiskLevel.low &&
                  s.startTime.day == slot.startTime.day)
              .take(2)
              .toList()
          : <ScoredSlot>[];

      suggestions.add(SlotSuggestion(
        slot: slot,
        rank: rank,
        headline: headline,
        reasoning: reasoning,
        comparisonText: comparison,
        alternatives: alternatives,
        confidence: _calculateConfidence(slot, patterns),
      ));

      rank++;
    }

    return suggestions;
  }

  /// Generate headline for suggestion.
  String _generateHeadline(ScoredSlot slot, int rank) {
    if (rank == 1) {
      return 'Best Time for You';
    }
    if (slot.riskLevel == SlotRiskLevel.low) {
      return 'Great Alternative';
    }
    return 'Available Option';
  }

  /// Generate reasoning text.
  String _generateReasoning(ScoredSlot slot, ClientPatterns patterns) {
    final positiveFactor = slot.scoreFactors
        .where((f) => f.impact > 0.1)
        .toList()
      ..sort((a, b) => b.impact.compareTo(a.impact));

    if (positiveFactor.isNotEmpty) {
      return positiveFactor.first.description;
    }

    if (slot.riskLevel == SlotRiskLevel.low) {
      return 'Low no-show risk based on your history';
    }

    return 'Available time slot';
  }

  /// Generate comparison text.
  String? _generateComparison(ScoredSlot slot, ClientPatterns patterns) {
    if (slot.riskDifferencePercent == null) return null;

    final diff = slot.riskDifferencePercent!;
    if (diff < -15) {
      return '${(-diff).toStringAsFixed(0)}% lower risk than your average';
    }
    if (diff > 15) {
      return '${diff.toStringAsFixed(0)}% higher risk than your average';
    }
    return null;
  }

  /// Calculate confidence in suggestion.
  double _calculateConfidence(ScoredSlot slot, ClientPatterns patterns) {
    // Base confidence on data reliability
    var confidence = patterns.hasReliableData ? 0.7 : 0.4;

    // Increase confidence for clear signals
    final strongFactors =
        slot.scoreFactors.where((f) => f.impact.abs() > 0.2).length;
    confidence += strongFactors * 0.1;

    return confidence.clamp(0.3, 0.95);
  }
}

/// Represents an available time slot from the scheduling system.
class AvailableSlot {
  const AvailableSlot({
    required this.slotId,
    required this.providerId,
    required this.providerName,
    required this.startTime,
    required this.endTime,
    this.serviceId,
    this.locationId,
    this.isAvailable = true,
  });

  final String slotId;
  final String providerId;
  final String providerName;
  final DateTime startTime;
  final DateTime endTime;
  final String? serviceId;
  final String? locationId;
  final bool isAvailable;
}
