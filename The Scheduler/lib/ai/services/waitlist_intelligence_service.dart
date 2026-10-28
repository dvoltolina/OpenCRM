import 'package:flutter/foundation.dart';

import '../../data/models/security_context.dart';
import '../../data/models/waitlist_entry.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/waitlist_repository.dart';
import '../models/waitlist_score.dart';

/// Service for intelligent waitlist matching.
///
/// When a cancellation occurs, ranks waitlist entries by likelihood
/// to confirm and fit the slot, considering multiple factors.
///
/// **Scoring Factors:**
/// - Time flexibility match (0-30 points)
/// - Geographic proximity (0-20 points)
/// - Historical confirm rate (0-30 points)
/// - Revenue priority (0-10 points)
/// - Wait time fairness (0-10 points)
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
class WaitlistIntelligenceService {
  WaitlistIntelligenceService({
    required WaitlistRepository waitlistRepository,
    required ClientsRepository clientRepository,
    required AppointmentsRepository appointmentRepository,
  })  : _waitlistRepository = waitlistRepository,
        _clientRepository = clientRepository,
        _appointmentRepository = appointmentRepository;

  final WaitlistRepository _waitlistRepository;
  final ClientsRepository _clientRepository;
  final AppointmentsRepository _appointmentRepository;

  /// Factor weights (sum to 100).
  static const double _timeFlexibilityMaxScore = 30.0;
  static const double _proximityMaxScore = 20.0;
  static const double _confirmRateMaxScore = 30.0;
  static const double _revenueMaxScore = 10.0;
  static const double _fairnessMaxScore = 10.0;

  /// Minimum days on waitlist for fairness bonus.
  static const int _minDaysForFairnessBonus = 7;

  /// Cache for client confirm rates.
  final Map<String, double> _confirmRateCache = {};

  /// Match waitlist entries to a cancelled slot.
  Future<WaitlistMatchResult> matchWaitlist({
    required SecurityContext context,
    required WaitlistMatchRequest request,
  }) async {
    // Get waitlist entries for this service
    final entries = await _waitlistRepository.getEntriesForService(
      context: context,
      serviceId: request.serviceId,
      locationId: request.locationId,
    );

    if (entries.isEmpty) {
      return WaitlistMatchResult(
        slotId: request.slotId,
        serviceId: request.serviceId,
        providerId: request.providerId,
        slotDateTime: request.slotDateTime,
        candidates: [],
        generatedAt: DateTime.now(),
        totalConsidered: 0,
        noMatchReason: 'No waitlist entries for this service',
      );
    }

    // Score each entry
    final rankedEntries = <RankedWaitlistEntry>[];
    for (final entry in entries) {
      final scored = await _scoreEntry(
        context: context,
        entry: entry,
        request: request,
      );

      if (scored.score.overallScore >= request.minScore) {
        rankedEntries.add(scored);
      }
    }

    // Sort by score (highest first)
    rankedEntries.sort(
      (a, b) => b.score.overallScore.compareTo(a.score.overallScore),
    );

    // Assign ranks
    for (var i = 0; i < rankedEntries.length; i++) {
      rankedEntries[i] = rankedEntries[i].copyWith(rank: i + 1);
    }

    // Get top candidates
    final topCandidates = rankedEntries.take(request.autoOfferCount).toList();

    // Limit results
    final candidates = rankedEntries.take(request.maxCandidates).toList();

    return WaitlistMatchResult(
      slotId: request.slotId,
      serviceId: request.serviceId,
      providerId: request.providerId,
      slotDateTime: request.slotDateTime,
      candidates: candidates,
      topCandidates: topCandidates,
      generatedAt: DateTime.now(),
      totalConsidered: entries.length,
      hasStrongMatches: candidates.any((c) => c.score.isStrongMatch),
    );
  }

  /// Score a single waitlist entry.
  Future<RankedWaitlistEntry> _scoreEntry({
    required SecurityContext context,
    required WaitlistEntry entry,
    required WaitlistMatchRequest request,
  }) async {
    final factors = <WaitlistScoreFactor>[];

    // 1. Time flexibility score
    final timeScore = _calculateTimeFlexibilityScore(
      entry: entry,
      slotDateTime: request.slotDateTime,
    );
    factors.add(WaitlistScoreFactor(
      factorType: WaitlistFactorType.timeFlexibility,
      description: _getTimeFlexibilityDescription(timeScore),
      impact: timeScore,
      maxImpact: _timeFlexibilityMaxScore,
      iconName: 'schedule',
    ));

    // 2. Proximity score (if location-based)
    final proximityScore = await _calculateProximityScore(
      context: context,
      entry: entry,
      locationId: request.locationId,
    );
    factors.add(WaitlistScoreFactor(
      factorType: WaitlistFactorType.proximity,
      description: _getProximityDescription(proximityScore),
      impact: proximityScore,
      maxImpact: _proximityMaxScore,
      iconName: 'location_on',
    ));

    // 3. Historical confirm rate
    final confirmRate = await _getClientConfirmRate(
      context: context,
      clientId: entry.clientId,
    );
    final confirmScore = _calculateConfirmRateScore(confirmRate);
    factors.add(WaitlistScoreFactor(
      factorType: WaitlistFactorType.confirmRate,
      description: _getConfirmRateDescription(confirmRate),
      impact: confirmScore,
      maxImpact: _confirmRateMaxScore,
      iconName: 'check_circle',
    ));

    // 4. Revenue score
    final revenueScore = _calculateRevenueScore(
      estimatedRevenue: entry.estimatedValue ?? 0,
    );
    factors.add(WaitlistScoreFactor(
      factorType: WaitlistFactorType.revenue,
      description: _getRevenueDescription(entry.estimatedValue ?? 0),
      impact: revenueScore,
      maxImpact: _revenueMaxScore,
      iconName: 'attach_money',
    ));

    // 5. Fairness score (time on waitlist)
    final daysOnWaitlist = DateTime.now().difference(entry.createdAt).inDays;
    final fairnessScore = _calculateFairnessScore(daysOnWaitlist);
    factors.add(WaitlistScoreFactor(
      factorType: WaitlistFactorType.fairness,
      description: _getFairnessDescription(daysOnWaitlist),
      impact: fairnessScore,
      maxImpact: _fairnessMaxScore,
      iconName: 'hourglass_empty',
    ));

    // Calculate overall score
    final overallScore =
        timeScore + proximityScore + confirmScore + revenueScore + fairnessScore;

    // Get client info for display
    final client = await _clientRepository.getById(
      context: context,
      id: entry.clientId,
    );

    return RankedWaitlistEntry(
      entryId: entry.id,
      clientId: entry.clientId,
      clientName: client?.displayName ?? 'Unknown Client',
      clientPhone: client?.phone,
      serviceId: entry.serviceId,
      serviceName: entry.serviceName ?? 'Service',
      score: WaitlistScore(
        overallScore: overallScore,
        timeFlexibilityScore: timeScore,
        proximityScore: proximityScore,
        confirmRateScore: confirmScore,
        revenueScore: revenueScore,
        fairnessScore: fairnessScore,
        factors: factors,
      ),
      rank: 0, // Will be assigned after sorting
      addedAt: entry.createdAt,
      preferredTimes: _parsePreferredTimes(entry.preferredTimes),
      historicalConfirmRate: confirmRate,
      estimatedRevenue: entry.estimatedValue,
      notes: entry.notes,
      matchReasoning: _generateMatchReasoning(factors, overallScore),
    );
  }

  /// Calculate time flexibility score (0-30).
  double _calculateTimeFlexibilityScore({
    required WaitlistEntry entry,
    required DateTime slotDateTime,
  }) {
    // Check if entry has flexible times
    if (entry.isFlexible) {
      return _timeFlexibilityMaxScore; // Full score for flexible
    }

    // Check if slot matches preferred times
    final preferredTimes = _parsePreferredTimes(entry.preferredTimes);
    if (preferredTimes.isEmpty) {
      return _timeFlexibilityMaxScore * 0.5; // Half score if no preference
    }

    // Check if slot falls within any preferred window
    for (final window in preferredTimes) {
      if (window.contains(slotDateTime)) {
        return _timeFlexibilityMaxScore; // Full score for exact match
      }
    }

    // Check for same day match
    final sameDayMatch = preferredTimes.any(
      (w) => w.dayOfWeek == slotDateTime.weekday,
    );
    if (sameDayMatch) {
      return _timeFlexibilityMaxScore * 0.6; // Partial for day match
    }

    return _timeFlexibilityMaxScore * 0.2; // Minimal score for no match
  }

  /// Calculate proximity score (0-20).
  Future<double> _calculateProximityScore({
    required SecurityContext context,
    required WaitlistEntry entry,
    String? locationId,
  }) async {
    // If no location context, give neutral score
    if (locationId == null) {
      return _proximityMaxScore * 0.5;
    }

    // For mobile services, would calculate actual distance
    // For now, use location match as proxy
    if (entry.preferredLocationId == locationId) {
      return _proximityMaxScore;
    } else if (entry.preferredLocationId == null) {
      return _proximityMaxScore * 0.7;
    }

    return _proximityMaxScore * 0.3;
  }

  /// Get client's historical confirm rate.
  Future<double> _getClientConfirmRate({
    required SecurityContext context,
    required String clientId,
  }) async {
    // Check cache
    if (_confirmRateCache.containsKey(clientId)) {
      return _confirmRateCache[clientId]!;
    }

    // Calculate from history
    final offers = await _waitlistRepository.getClientOfferHistory(
      context: context,
      clientId: clientId,
      limit: 20,
    );

    if (offers.isEmpty) {
      return 0.5; // Default for no history
    }

    final accepted = offers.where((o) => o.wasAccepted).length;
    final rate = accepted / offers.length;

    // Cache result
    _confirmRateCache[clientId] = rate;

    return rate;
  }

  /// Calculate confirm rate score (0-30).
  double _calculateConfirmRateScore(double rate) {
    // Higher rate = higher score
    return _confirmRateMaxScore * rate;
  }

  /// Calculate revenue score (0-10).
  double _calculateRevenueScore({required double estimatedRevenue}) {
    // Tier-based scoring
    if (estimatedRevenue >= 200) return _revenueMaxScore;
    if (estimatedRevenue >= 100) return _revenueMaxScore * 0.8;
    if (estimatedRevenue >= 50) return _revenueMaxScore * 0.5;
    return _revenueMaxScore * 0.3;
  }

  /// Calculate fairness score (0-10).
  double _calculateFairnessScore(int daysOnWaitlist) {
    if (daysOnWaitlist >= 30) return _fairnessMaxScore;
    if (daysOnWaitlist >= _minDaysForFairnessBonus) {
      return _fairnessMaxScore *
          (daysOnWaitlist - _minDaysForFairnessBonus + 1) /
          (30 - _minDaysForFairnessBonus);
    }
    return 0;
  }

  /// Parse preferred times from string list.
  List<TimeWindow> _parsePreferredTimes(List<String>? times) {
    if (times == null || times.isEmpty) return [];

    final windows = <TimeWindow>[];
    for (final time in times) {
      // Expected format: "Mon 9-12" or "1 9 12" (day startHour endHour)
      final parts = time.split(RegExp(r'[\s-]+'));
      if (parts.length >= 3) {
        try {
          final day = _parseDayOfWeek(parts[0]);
          final startHour = int.tryParse(parts[1]) ?? 9;
          final endHour = int.tryParse(parts[2]) ?? 17;
          if (day != null) {
            windows.add(TimeWindow(
              dayOfWeek: day,
              startHour: startHour,
              endHour: endHour,
            ));
          }
        } catch (e) {
          debugPrint('Failed to parse time window: $time');
        }
      }
    }
    return windows;
  }

  /// Parse day of week from string or number.
  int? _parseDayOfWeek(String input) {
    final num = int.tryParse(input);
    if (num != null && num >= 1 && num <= 7) return num;

    final lower = input.toLowerCase();
    const days = {
      'mon': 1, 'monday': 1,
      'tue': 2, 'tuesday': 2,
      'wed': 3, 'wednesday': 3,
      'thu': 4, 'thursday': 4,
      'fri': 5, 'friday': 5,
      'sat': 6, 'saturday': 6,
      'sun': 7, 'sunday': 7,
    };
    return days[lower];
  }

  /// Generate match reasoning text.
  String _generateMatchReasoning(
    List<WaitlistScoreFactor> factors,
    double overallScore,
  ) {
    // Find top 2 positive factors
    final sortedFactors = List.of(factors)
      ..sort((a, b) => b.percentOfMax.compareTo(a.percentOfMax));

    final topFactors = sortedFactors.take(2).toList();
    final reasons = topFactors.map((f) => f.description).join('; ');

    if (overallScore >= 70) {
      return 'Excellent match: $reasons';
    } else if (overallScore >= 50) {
      return 'Good match: $reasons';
    } else {
      return 'Partial match: $reasons';
    }
  }

  // Description generators
  String _getTimeFlexibilityDescription(double score) {
    final percent = (score / _timeFlexibilityMaxScore * 100).round();
    if (percent >= 90) return 'Perfect time match';
    if (percent >= 60) return 'Good time compatibility';
    return 'Time preference mismatch';
  }

  String _getProximityDescription(double score) {
    final percent = (score / _proximityMaxScore * 100).round();
    if (percent >= 90) return 'Preferred location';
    if (percent >= 50) return 'Location flexible';
    return 'Different location preference';
  }

  String _getConfirmRateDescription(double rate) {
    final percent = (rate * 100).round();
    if (percent >= 80) return 'High acceptance rate ($percent%)';
    if (percent >= 50) return 'Moderate acceptance rate ($percent%)';
    if (percent > 0) return 'Lower acceptance rate ($percent%)';
    return 'No prior offer history';
  }

  String _getRevenueDescription(double revenue) {
    if (revenue >= 200) return 'High-value booking';
    if (revenue >= 100) return 'Standard booking value';
    return 'Entry-level booking';
  }

  String _getFairnessDescription(int days) {
    if (days >= 30) return 'Long wait ($days days)';
    if (days >= 14) return 'Moderate wait ($days days)';
    if (days >= 7) return 'Recent addition ($days days)';
    return 'Just added';
  }

  /// Send offers to top candidates.
  Future<void> sendOffersToTopCandidates({
    required SecurityContext context,
    required WaitlistMatchResult result,
  }) async {
    for (final candidate in result.topCandidates) {
      await _waitlistRepository.sendOffer(
        context: context,
        entryId: candidate.entryId,
        slotId: result.slotId,
        slotDateTime: result.slotDateTime,
        providerId: result.providerId,
      );
    }
  }

  /// Track offer response for model improvement.
  Future<void> recordOfferResponse({
    required SecurityContext context,
    required String entryId,
    required String slotId,
    required bool accepted,
  }) async {
    await _waitlistRepository.recordOfferResponse(
      context: context,
      entryId: entryId,
      slotId: slotId,
      accepted: accepted,
      respondedAt: DateTime.now(),
    );

    // Invalidate confirm rate cache
    _confirmRateCache.clear();
  }

  /// Clear caches.
  void clearCache() {
    _confirmRateCache.clear();
  }
}
