import 'package:flutter/foundation.dart';

import '../../data/models/appointment.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/appointments_repository.dart';
import '../models/client_patterns.dart';

/// Service for extracting and analyzing client booking patterns.
///
/// Analyzes historical appointments to identify:
/// - Day-of-week no-show patterns
/// - Hour-of-day no-show patterns
/// - Provider-specific no-show rates
/// - Lead time correlations
///
/// Used by SlotSuggestionService and ProviderMatchingService to
/// make intelligent recommendations.
///
/// Agent AI-20: Smart Scheduling Suggestions
class ClientPatternsService {
  ClientPatternsService({
    required AppointmentsRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentsRepository _appointmentRepository;

  /// Cache of computed patterns (client ID -> patterns)
  final Map<String, _CachedPatterns> _cache = {};

  /// Cache duration
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Minimum appointments needed for reliable patterns
  static const int _minAppointmentsForReliability = 5;

  /// Extract booking patterns for a client.
  ///
  /// Returns cached patterns if available and fresh, otherwise
  /// computes new patterns from appointment history.
  Future<ClientPatterns> getClientPatterns({
    required SecurityContext context,
    required String clientId,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh) {
      final cached = _cache[clientId];
      if (cached != null && !cached.isExpired) {
        return cached.patterns;
      }
    }

    // Fetch appointment history
    final appointments = await _appointmentRepository.getClientAppointments(
      context: context,
      clientId: clientId,
      // Look back 2 years for pattern analysis
      startDate: DateTime.now().subtract(const Duration(days: 730)),
      endDate: DateTime.now(),
    );

    // Compute patterns
    final patterns = _computePatterns(
      clientId: clientId,
      businessId: context.businessId,
      appointments: appointments,
    );

    // Cache result
    _cache[clientId] = _CachedPatterns(
      patterns: patterns,
      computedAt: DateTime.now(),
    );

    return patterns;
  }

  /// Compute patterns from appointment list.
  ClientPatterns _computePatterns({
    required String clientId,
    required String businessId,
    required List<Appointment> appointments,
  }) {
    if (appointments.isEmpty) {
      return ClientPatterns.empty(
        clientId: clientId,
        businessId: businessId,
      );
    }

    // Initialize counters
    final dayOfWeekCounts = <int, int>{};
    final dayOfWeekNoshows = <int, int>{};
    final hourOfDayCounts = <int, int>{};
    final hourOfDayNoshows = <int, int>{};
    final providerCounts = <String, int>{};
    final providerNoshows = <String, int>{};
    final providerCompleted = <String, int>{};
    final leadTimeCounts = <String, int>{};
    final leadTimeNoshows = <String, int>{};

    int totalAppointments = 0;
    int totalNoshows = 0;
    int totalCancellations = 0;

    for (final appt in appointments) {
      // Only count completed, no-show, or cancelled appointments
      if (!_isRelevantStatus(appt.status)) continue;

      totalAppointments++;
      final isNoshow = appt.status == AppointmentStatus.noShow;
      final isCancelled = appt.status == AppointmentStatus.cancelled;

      if (isNoshow) totalNoshows++;
      if (isCancelled) totalCancellations++;

      // Day of week patterns
      final dayOfWeek = appt.startTime.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
      if (isNoshow) {
        dayOfWeekNoshows[dayOfWeek] = (dayOfWeekNoshows[dayOfWeek] ?? 0) + 1;
      }

      // Hour of day patterns
      final hour = appt.startTime.hour;
      hourOfDayCounts[hour] = (hourOfDayCounts[hour] ?? 0) + 1;
      if (isNoshow) {
        hourOfDayNoshows[hour] = (hourOfDayNoshows[hour] ?? 0) + 1;
      }

      // Provider patterns
      final providerId = appt.providerId;
      providerCounts[providerId] = (providerCounts[providerId] ?? 0) + 1;
      if (isNoshow) {
        providerNoshows[providerId] = (providerNoshows[providerId] ?? 0) + 1;
      }
      if (appt.status == AppointmentStatus.completed) {
        providerCompleted[providerId] =
            (providerCompleted[providerId] ?? 0) + 1;
      }

      // Lead time patterns
      if (appt.createdAt != null) {
        final leadDays = appt.startTime.difference(appt.createdAt!).inDays;
        final bucket = _getLeadTimeBucket(leadDays);
        leadTimeCounts[bucket] = (leadTimeCounts[bucket] ?? 0) + 1;
        if (isNoshow) {
          leadTimeNoshows[bucket] = (leadTimeNoshows[bucket] ?? 0) + 1;
        }
      }
    }

    // Calculate rates
    final dayOfWeekRates = _calculateRates(dayOfWeekCounts, dayOfWeekNoshows);
    final hourOfDayRates = _calculateRates(hourOfDayCounts, hourOfDayNoshows);
    final providerRates = _calculateProviderRates(providerCounts, providerNoshows);
    final leadTimeRates = _calculateStringRates(leadTimeCounts, leadTimeNoshows);

    final overallNoshowRate =
        totalAppointments > 0 ? totalNoshows / totalAppointments : 0.0;

    // Determine preferred patterns
    final preferredDays = _findPreferredDays(dayOfWeekRates);
    final preferredHours = _findPreferredHours(hourOfDayRates);
    final preferredProviders = _findPreferredProviders(
      providerRates,
      providerCompleted,
    );

    return ClientPatterns(
      clientId: clientId,
      businessId: businessId,
      dayOfWeekNoshowRates: dayOfWeekRates,
      hourOfDayNoshowRates: hourOfDayRates,
      providerNoshowRates: providerRates,
      providerCompletedCounts: providerCompleted,
      leadTimeNoshowRates: leadTimeRates,
      totalAppointments: totalAppointments,
      totalNoshows: totalNoshows,
      totalCancellations: totalCancellations,
      overallNoshowRate: overallNoshowRate,
      preferredDaysOfWeek: preferredDays,
      preferredHours: preferredHours,
      preferredProviders: preferredProviders,
      calculatedAt: DateTime.now(),
      sampleSize: appointments.length,
    );
  }

  /// Check if appointment status is relevant for pattern analysis.
  bool _isRelevantStatus(AppointmentStatus status) {
    return status == AppointmentStatus.completed ||
        status == AppointmentStatus.noShow ||
        status == AppointmentStatus.cancelled;
  }

  /// Calculate rates from counts.
  Map<int, double> _calculateRates(
    Map<int, int> counts,
    Map<int, int> noshows,
  ) {
    final rates = <int, double>{};
    for (final entry in counts.entries) {
      final noshowCount = noshows[entry.key] ?? 0;
      rates[entry.key] = entry.value > 0 ? noshowCount / entry.value : 0.0;
    }
    return rates;
  }

  /// Calculate provider-specific rates.
  Map<String, double> _calculateProviderRates(
    Map<String, int> counts,
    Map<String, int> noshows,
  ) {
    final rates = <String, double>{};
    for (final entry in counts.entries) {
      final noshowCount = noshows[entry.key] ?? 0;
      rates[entry.key] = entry.value > 0 ? noshowCount / entry.value : 0.0;
    }
    return rates;
  }

  /// Calculate string-keyed rates.
  Map<String, double> _calculateStringRates(
    Map<String, int> counts,
    Map<String, int> noshows,
  ) {
    final rates = <String, double>{};
    for (final entry in counts.entries) {
      final noshowCount = noshows[entry.key] ?? 0;
      rates[entry.key] = entry.value > 0 ? noshowCount / entry.value : 0.0;
    }
    return rates;
  }

  /// Get lead time bucket name.
  String _getLeadTimeBucket(int leadDays) {
    if (leadDays <= 0) return 'same_day';
    if (leadDays <= 3) return '1-3_days';
    if (leadDays <= 7) return '4-7_days';
    if (leadDays <= 14) return '8-14_days';
    return '15+_days';
  }

  /// Find preferred days (below average no-show rate).
  List<int> _findPreferredDays(Map<int, double> rates) {
    if (rates.isEmpty) return [];
    final avg = rates.values.reduce((a, b) => a + b) / rates.length;
    return rates.entries
        .where((e) => e.value < avg)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  /// Find preferred hours (below average no-show rate).
  List<int> _findPreferredHours(Map<int, double> rates) {
    if (rates.isEmpty) return [];
    final avg = rates.values.reduce((a, b) => a + b) / rates.length;
    return rates.entries
        .where((e) => e.value < avg)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  /// Find preferred providers (low no-show rate + enough history).
  List<String> _findPreferredProviders(
    Map<String, double> rates,
    Map<String, int> completedCounts,
  ) {
    if (rates.isEmpty) return [];
    return rates.entries
        .where((e) =>
            e.value < 0.20 && // Less than 20% no-show rate
            (completedCounts[e.key] ?? 0) >= 2) // At least 2 completed
        .map((e) => e.key)
        .toList();
  }

  /// Get day-of-week statistics for detailed display.
  List<DayOfWeekStats> getDayOfWeekStats(ClientPatterns patterns) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return List.generate(7, (index) {
      final day = index + 1;
      final rate = patterns.dayOfWeekNoshowRates[day] ?? 0.0;
      return DayOfWeekStats(
        dayOfWeek: day,
        dayName: dayNames[index],
        appointmentCount: 0, // Would need to track this separately
        noshowCount: 0,
        noshowRate: rate,
        isPreferred: patterns.preferredDaysOfWeek.contains(day),
      );
    });
  }

  /// Clear cache for a specific client.
  void clearCacheForClient(String clientId) {
    _cache.remove(clientId);
  }

  /// Clear entire cache.
  void clearCache() {
    _cache.clear();
    debugPrint('ClientPatternsService: Cache cleared');
  }

  /// Get cache statistics.
  Map<String, dynamic> get cacheStats => {
        'cachedClients': _cache.length,
        'expiredEntries':
            _cache.values.where((c) => c.isExpired).length,
      };
}

/// Cached patterns with expiry.
class _CachedPatterns {
  _CachedPatterns({
    required this.patterns,
    required this.computedAt,
  });

  final ClientPatterns patterns;
  final DateTime computedAt;

  bool get isExpired =>
      DateTime.now().difference(computedAt) > ClientPatternsService._cacheDuration;
}
