import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/security_context.dart';
import '../../data/repositories/appointments_repository.dart';
import '../models/demand_forecast.dart';

/// Service for demand forecasting using time series analysis.
///
/// Predicts daily booking volume for staffing optimization
/// using Facebook Prophet (via Python server) or local fallback.
///
/// **Features:**
/// - 30-day forecast horizon
/// - Weekly pattern detection
/// - Holiday adjustment
/// - Service-specific predictions
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
class DemandForecastService {
  DemandForecastService({
    required AppointmentsRepository appointmentRepository,
    required String forecastApiUrl,
    http.Client? httpClient,
  })  : _appointmentRepository = appointmentRepository,
        _forecastApiUrl = forecastApiUrl,
        _httpClient = httpClient ?? http.Client();

  final AppointmentsRepository _appointmentRepository;
  final String _forecastApiUrl;
  final http.Client _httpClient;

  /// Cache duration for forecasts.
  static const _cacheDuration = Duration(hours: 6);

  /// Cache for forecasts.
  final Map<String, _CachedForecast> _cache = {};

  /// Get demand forecast.
  Future<DemandForecastResult> getForecast({
    required SecurityContext context,
    required DemandForecastRequest request,
  }) async {
    final cacheKey = _buildCacheKey(request);

    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.result;
    }

    // Get historical data for training
    final historicalData = await _getHistoricalData(
      context: context,
      request: request,
    );

    // Try Prophet API first, fallback to local
    List<DemandForecast> forecasts;
    try {
      forecasts = await _fetchProphetForecast(
        request: request,
        historicalData: historicalData,
      );
    } catch (e) {
      debugPrint('Prophet API failed, using local fallback: $e');
      forecasts = _generateLocalForecast(
        request: request,
        historicalData: historicalData,
      );
    }

    // Calculate staffing recommendations if requested
    List<StaffingRecommendation> staffingRecommendations = [];
    if (request.includeStaffing && request.currentCapacity != null) {
      staffingRecommendations = _generateStaffingRecommendations(
        forecasts: forecasts,
        currentCapacity: request.currentCapacity!,
      );
    }

    // Build result
    final averageDemand = forecasts.isEmpty
        ? 0.0
        : forecasts.fold(0.0, (sum, f) => sum + f.predictedCount) /
            forecasts.length;

    final sortedByDemand = List.of(forecasts)
      ..sort((a, b) => b.predictedCount.compareTo(a.predictedCount));

    final result = DemandForecastResult(
      businessId: request.businessId,
      locationId: request.locationId,
      serviceId: request.serviceId,
      startDate: request.startDate,
      endDate: request.startDate.add(Duration(days: request.forecastDays)),
      forecasts: forecasts,
      staffingRecommendations: staffingRecommendations,
      generatedAt: DateTime.now(),
      averageDemand: averageDemand,
      peakDay: sortedByDemand.isNotEmpty ? sortedByDemand.first : null,
      valleyDay: sortedByDemand.isNotEmpty ? sortedByDemand.last : null,
      highDemandDays: forecasts
          .where((f) =>
              f.demandLevel == DemandLevel.high ||
              f.demandLevel == DemandLevel.veryHigh)
          .toList(),
      urgentDays:
          staffingRecommendations.where((r) => r.isUrgent).toList(),
    );

    // Cache result
    _cache[cacheKey] = _CachedForecast(
      result: result,
      expiresAt: DateTime.now().add(_cacheDuration),
    );

    return result;
  }

  /// Get historical appointment data.
  Future<List<_HistoricalDataPoint>> _getHistoricalData({
    required SecurityContext context,
    required DemandForecastRequest request,
  }) async {
    // Get last 90 days of data
    final startDate = DateTime.now().subtract(const Duration(days: 90));
    final endDate = DateTime.now();

    final appointments = await _appointmentRepository.getAppointmentsInRange(
      context: context,
      startDate: startDate,
      endDate: endDate,
      locationId: request.locationId,
      serviceId: request.serviceId,
    );

    // Group by date
    final byDate = <DateTime, int>{};
    for (final apt in appointments) {
      final date = DateTime(
        apt.startTime.year,
        apt.startTime.month,
        apt.startTime.day,
      );
      byDate[date] = (byDate[date] ?? 0) + 1;
    }

    // Convert to list
    return byDate.entries
        .map((e) => _HistoricalDataPoint(date: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Fetch forecast from Prophet API.
  Future<List<DemandForecast>> _fetchProphetForecast({
    required DemandForecastRequest request,
    required List<_HistoricalDataPoint> historicalData,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_forecastApiUrl/api/v1/forecast'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'business_id': request.businessId,
        'location_id': request.locationId,
        'service_id': request.serviceId,
        'forecast_days': request.forecastDays,
        'historical_data': historicalData
            .map((d) => {
                  'date': d.date.toIso8601String().split('T')[0],
                  'count': d.count,
                })
            .toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Prophet API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final forecastList = data['forecasts'] as List;

    return forecastList.map((f) {
      final date = DateTime.parse(f['date'] as String);
      final predicted = (f['predicted'] as num).toDouble();
      final lower = (f['lower_bound'] as num).toDouble();
      final upper = (f['upper_bound'] as num).toDouble();

      return DemandForecast(
        date: date,
        predictedCount: predicted,
        lowerBound: lower,
        upperBound: upper,
        demandLevel: _classifyDemandLevel(
          predicted,
          data['average'] as double? ?? predicted,
        ),
        confidence: _calculateConfidence(lower, upper, predicted),
        dayOfWeek: date.weekday,
        isHoliday: f['is_holiday'] as bool? ?? false,
        holidayName: f['holiday_name'] as String?,
      );
    }).toList();
  }

  /// Generate local forecast (fallback).
  List<DemandForecast> _generateLocalForecast({
    required DemandForecastRequest request,
    required List<_HistoricalDataPoint> historicalData,
  }) {
    if (historicalData.isEmpty) {
      // No data - return flat forecast
      return _generateFlatForecast(request);
    }

    // Calculate averages by day of week
    final byDayOfWeek = <int, List<int>>{};
    for (final point in historicalData) {
      final dow = point.date.weekday;
      byDayOfWeek.putIfAbsent(dow, () => []).add(point.count);
    }

    final avgByDow = byDayOfWeek.map((dow, counts) {
      final avg = counts.reduce((a, b) => a + b) / counts.length;
      return MapEntry(dow, avg);
    });

    // Overall average
    final overallAvg = historicalData
            .map((p) => p.count)
            .reduce((a, b) => a + b) /
        historicalData.length;

    // Generate forecasts
    final forecasts = <DemandForecast>[];
    for (var i = 0; i < request.forecastDays; i++) {
      final date = request.startDate.add(Duration(days: i));
      final dow = date.weekday;
      final predicted = avgByDow[dow] ?? overallAvg;

      // Simple confidence interval (±20%)
      final margin = predicted * 0.2;

      forecasts.add(DemandForecast(
        date: date,
        predictedCount: predicted,
        lowerBound: predicted - margin,
        upperBound: predicted + margin,
        demandLevel: _classifyDemandLevel(predicted, overallAvg),
        confidence: 0.6, // Lower confidence for local forecast
        dayOfWeek: dow,
      ));
    }

    return forecasts;
  }

  /// Generate flat forecast when no historical data.
  List<DemandForecast> _generateFlatForecast(DemandForecastRequest request) {
    const defaultCount = 10.0;
    return List.generate(request.forecastDays, (i) {
      final date = request.startDate.add(Duration(days: i));
      return DemandForecast(
        date: date,
        predictedCount: defaultCount,
        lowerBound: defaultCount * 0.5,
        upperBound: defaultCount * 1.5,
        demandLevel: DemandLevel.normal,
        confidence: 0.3, // Low confidence
        dayOfWeek: date.weekday,
      );
    });
  }

  /// Classify demand level based on prediction vs average.
  DemandLevel _classifyDemandLevel(double predicted, double average) {
    if (average == 0) return DemandLevel.normal;

    final ratio = predicted / average;
    if (ratio < 0.25) return DemandLevel.veryLow;
    if (ratio < 0.75) return DemandLevel.low;
    if (ratio < 1.25) return DemandLevel.normal;
    if (ratio < 1.75) return DemandLevel.high;
    return DemandLevel.veryHigh;
  }

  /// Calculate confidence from interval.
  double _calculateConfidence(double lower, double upper, double predicted) {
    if (predicted == 0) return 0.5;
    final relativeWidth = (upper - lower) / predicted;
    // Narrower interval = higher confidence
    return (1 - relativeWidth / 2).clamp(0.3, 0.95);
  }

  /// Generate staffing recommendations.
  List<StaffingRecommendation> _generateStaffingRecommendations({
    required List<DemandForecast> forecasts,
    required int currentCapacity,
  }) {
    return forecasts.map((forecast) {
      final predicted = forecast.predictedCount.round();
      final gap = predicted - currentCapacity;
      final gapPercent =
          currentCapacity > 0 ? (gap / currentCapacity * 100).round() : 0;

      StaffingAction action;
      int urgency;
      String reasoning;
      final suggestions = <StaffingSuggestion>[];

      if (gap > currentCapacity * 0.5) {
        // Need 50%+ more capacity
        action = StaffingAction.addStaff;
        urgency = 5;
        reasoning =
            'Demand ($predicted) exceeds capacity ($currentCapacity) by $gapPercent%';
        suggestions.add(StaffingSuggestion(
          type: 'add_shift',
          description: 'Add extra shift or staff',
          priority: 1,
        ));
      } else if (gap > currentCapacity * 0.2) {
        // Need 20-50% more
        action = StaffingAction.addStaff;
        urgency = 3;
        reasoning =
            'Moderate demand increase ($gapPercent% over capacity)';
      } else if (gap < -currentCapacity * 0.5) {
        // 50%+ overcapacity
        action = StaffingAction.reduceStaff;
        urgency = 2;
        reasoning =
            'Low demand ($predicted) - ${-gapPercent}% under capacity';
        suggestions.add(StaffingSuggestion(
          type: 'reduce_hours',
          description: 'Consider reduced hours',
          priority: 2,
        ));
      } else if (gap < -currentCapacity * 0.3) {
        // 30-50% overcapacity
        action = StaffingAction.runPromotion;
        urgency = 2;
        reasoning = 'Lower demand - consider promotion to fill slots';
        suggestions.add(StaffingSuggestion(
          type: 'promotion',
          description: 'Run discount promotion',
          priority: 1,
        ));
      } else {
        // Within 20% of capacity
        action = StaffingAction.optimal;
        urgency = 1;
        reasoning = 'Demand matches capacity';
      }

      return StaffingRecommendation(
        date: forecast.date,
        forecast: forecast,
        currentCapacity: currentCapacity,
        recommendedCapacity: predicted,
        action: action,
        urgency: urgency,
        reasoning: reasoning,
        suggestions: suggestions,
        confidence: forecast.confidence,
      );
    }).toList();
  }

  /// Build cache key.
  String _buildCacheKey(DemandForecastRequest request) {
    return '${request.businessId}_${request.locationId}_${request.serviceId}_'
        '${request.startDate.toIso8601String()}_${request.forecastDays}';
  }

  /// Clear cache.
  void clearCache() {
    _cache.clear();
  }
}

/// Historical data point for training.
class _HistoricalDataPoint {
  _HistoricalDataPoint({required this.date, required this.count});

  final DateTime date;
  final int count;
}

/// Cached forecast.
class _CachedForecast {
  _CachedForecast({required this.result, required this.expiresAt});

  final DemandForecastResult result;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
