import 'package:flutter/foundation.dart';

import '../../core/config/ai_config.dart';
import '../models/ai_exceptions.dart';
import '../models/noshow_prediction.dart';
import '../models/prediction_explanation.dart';
import 'ai_client.dart';

/// Service for fetching and managing prediction explanations.
///
/// Provides human-readable explanations for no-show predictions,
/// helping staff understand *why* an appointment is flagged as high-risk.
///
/// Uses SHAP (SHapley Additive exPlanations) on the backend to identify
/// which features contributed most to each prediction.
///
/// **Key Features:**
/// - Top 3 factors per prediction (configurable)
/// - Human-readable explanations (not raw feature names)
/// - Caching to avoid redundant API calls
/// - Graceful fallback when explanations unavailable
///
/// Agent AI-19: Prediction Explainability
class ExplanationService {
  ExplanationService({
    required AIClient aiClient,
    AIConfig? config,
  })  : _aiClient = aiClient,
        _config = config;

  final AIClient _aiClient;
  final AIConfig? _config;

  /// Cache for explanations to avoid redundant API calls
  final Map<String, CachedExplanation> _cache = {};

  /// Default cache duration in minutes
  static const int _defaultCacheDurationMinutes = 15;

  /// Statistics
  int _requestCount = 0;
  int _cacheHits = 0;
  int _apiCalls = 0;
  int _errors = 0;

  /// Get explanation for a prediction.
  ///
  /// First checks cache, then fetches from API if needed.
  /// Returns null if explanation cannot be obtained.
  Future<PredictionExplanation?> getExplanation({
    required String appointmentId,
    int numFactors = 3,
    bool forceRefresh = false,
  }) async {
    _requestCount++;

    // Check cache unless forced refresh
    if (!forceRefresh) {
      final cached = _getCached(appointmentId);
      if (cached != null) {
        _cacheHits++;
        return cached;
      }
    }

    try {
      _apiCalls++;
      final response = await _aiClient.post(
        '/predict/explain',
        {
          'appointment_id': appointmentId,
          'num_factors': numFactors,
        },
      );

      final explanation = _parseExplanationResponse(response);

      // Cache the result
      _cacheExplanation(appointmentId, explanation);

      return explanation;
    } on AIException catch (e) {
      _errors++;
      debugPrint('ExplanationService: API error: ${e.message}');
      return null;
    } catch (e) {
      _errors++;
      debugPrint('ExplanationService: Unexpected error: $e');
      return null;
    }
  }

  /// Get explanation for an existing prediction.
  ///
  /// Extracts the explanation from prediction response if available,
  /// otherwise fetches it separately.
  Future<PredictionExplanation?> getExplanationForPrediction(
    NoshowPrediction prediction, {
    int numFactors = 3,
  }) async {
    // If prediction already has embedded explanation data, use it
    if (prediction.topFeatures.isNotEmpty) {
      return _buildFromPrediction(prediction);
    }

    // Otherwise fetch explanation from API
    return getExplanation(
      appointmentId: prediction.appointmentId,
      numFactors: numFactors,
    );
  }

  /// Build explanation from prediction's top features.
  ///
  /// Converts the FeatureImportance list from prediction into
  /// a full PredictionExplanation with human-readable text.
  PredictionExplanation _buildFromPrediction(NoshowPrediction prediction) {
    final factors = prediction.topFeatures
        .map((f) => ExplanationFactor(
              feature: f.featureName,
              displayName: f.featureDisplayName,
              impact: f.impact,
              magnitude: f.importance,
              explanation: _humanizeFeature(
                f.featureName,
                f.featureValue,
                f.impact == 'increases_risk',
              ),
              featureValue: f.featureValue,
            ))
        .toList();

    final summary = _generateSummary(
      factors,
      prediction.probability,
      prediction.riskLevel.name,
    );

    return PredictionExplanation(
      appointmentId: prediction.appointmentId,
      probability: prediction.probability,
      riskLevel: prediction.riskLevel.name,
      summary: summary,
      topFactors: factors,
      modelVersion: prediction.modelVersion,
      generatedAt: DateTime.now(),
    );
  }

  /// Humanize a feature value into readable text.
  String _humanizeFeature(String featureName, double value, bool increasesRisk) {
    switch (featureName) {
      case 'clientHistoricalNoshowRate':
        final percent = (value * 100).toStringAsFixed(0);
        return value > 0.1
            ? 'Client has $percent% historical no-show rate'
            : 'Client has good attendance history';

      case 'clientHistoricalCancelRate':
        final percent = (value * 100).toStringAsFixed(0);
        return value > 0.1
            ? 'Client has $percent% cancellation rate'
            : 'Client rarely cancels';

      case 'bookingLeadDays':
        final days = value.toInt();
        if (days == 0) return 'Same-day booking';
        if (days == 1) return 'Booked 1 day in advance';
        return 'Booked $days days in advance';

      case 'paymentCollected':
        return value > 0.5
            ? 'Payment/deposit already collected'
            : 'No deposit collected';

      case 'clientHasPaymentMethod':
        return value > 0.5
            ? 'Has payment method on file'
            : 'No payment method on file';

      case 'isRecurring':
        return value > 0.5
            ? 'Recurring appointment (higher reliability)'
            : 'One-time appointment';

      case 'hasIntakeForm':
        return value > 0.5
            ? 'Intake form already submitted'
            : 'No intake form submitted';

      case 'clientLifecycleStage':
        return _humanizeLifecycleStage(value);

      case 'slotHistoricalNoshowRate':
        final percent = (value * 100).toStringAsFixed(0);
        return value > 0.1
            ? 'Time slot has $percent% no-show history'
            : 'Time slot has good attendance';

      case 'providerHistoricalNoshowRate':
        final percent = (value * 100).toStringAsFixed(0);
        return value > 0.1
            ? "Provider's clients have $percent% no-show rate"
            : "Provider's clients rarely miss";

      case 'clientTotalAppointments':
        final count = value.toInt();
        if (count == 0) return 'New client, no history';
        return 'Client has attended $count appointments';

      case 'clientDaysSinceLastVisit':
        final days = value.toInt();
        if (days == 0) return 'Recent visit';
        return 'Last visit was $days days ago';

      case 'dayOfWeek':
        return _humanizeDayOfWeek(value.toInt());

      case 'hourOfDay':
        final hour = value.toInt();
        return 'Appointment at ${hour.toString().padLeft(2, '0')}:00';

      case 'serviceDurationMinutes':
        return '${value.toInt()} minute service';

      case 'servicePriceCents':
        final dollars = (value / 100).toStringAsFixed(2);
        return '\$$dollars service';

      case 'requiresPayment':
        return value > 0.5 ? 'Payment required for service' : 'Free service';

      case 'isGroupSession':
        return value > 0.5
            ? 'Group session (tends to have lower no-shows)'
            : 'Individual appointment';

      case 'isFirstAppointmentOfDay':
        return value > 0.5
            ? "First appointment of provider's day"
            : 'Not first appointment';

      case 'isLastAppointmentOfDay':
        return value > 0.5
            ? "Last appointment of provider's day"
            : 'Not last appointment';

      default:
        return '$featureName: ${value.toStringAsFixed(2)}';
    }
  }

  String _humanizeLifecycleStage(double value) {
    final stage = value.toInt();
    switch (stage) {
      case 0:
        return 'New client (less predictable)';
      case 1:
        return 'Active client (regular visitor)';
      case 2:
        return 'Inactive client (has not visited recently)';
      case 3:
        return 'At-risk client (churning pattern)';
      default:
        return 'Unknown client stage';
    }
  }

  String _humanizeDayOfWeek(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (day >= 1 && day <= 7) {
      return '${days[day - 1]} appointment';
    }
    return 'Day $day appointment';
  }

  /// Generate a summary sentence for the explanation.
  String _generateSummary(
    List<ExplanationFactor> factors,
    double probability,
    String riskLevel,
  ) {
    if (factors.isEmpty) {
      return 'This appointment has a $riskLevel no-show risk.';
    }

    final increasing = factors.where((f) => f.impact == 'increases').toList();
    final decreasing = factors.where((f) => f.impact == 'decreases').toList();

    final riskLevelLower = riskLevel.toLowerCase();

    if (riskLevelLower == 'high') {
      if (increasing.isNotEmpty) {
        return 'High risk primarily because: ${increasing.first.explanation}';
      }
      return 'High no-show risk based on multiple factors.';
    }

    if (riskLevelLower == 'medium') {
      if (increasing.isNotEmpty && decreasing.isNotEmpty) {
        return 'Mixed signals: ${increasing.first.explanation}, '
            'but ${decreasing.first.explanation}';
      }
      return 'Moderate risk based on client and appointment patterns.';
    }

    // Low risk
    if (decreasing.isNotEmpty) {
      return 'Low risk because: ${decreasing.first.explanation}';
    }
    return 'Low no-show risk based on positive indicators.';
  }

  /// Parse API response into PredictionExplanation.
  PredictionExplanation _parseExplanationResponse(Map<String, dynamic> response) {
    final topFactorsJson = response['top_factors'] as List<dynamic>? ?? [];
    final topFactors = topFactorsJson
        .map((f) => ExplanationFactor.fromJson(f as Map<String, dynamic>))
        .toList();

    return PredictionExplanation(
      appointmentId: response['appointment_id'] as String,
      probability: (response['probability'] as num).toDouble(),
      riskLevel: response['risk_level'] as String,
      summary: response['summary'] as String? ?? '',
      topFactors: topFactors,
      modelVersion: response['model_version'] as String? ?? 'unknown',
      explanationVersion: response['explanation_version'] as String? ?? '1.0.0',
      generatedAt: DateTime.now(),
    );
  }

  /// Get cached explanation if valid.
  PredictionExplanation? _getCached(String appointmentId) {
    final cached = _cache[appointmentId];
    if (cached == null) return null;

    if (cached.isExpired) {
      _cache.remove(appointmentId);
      return null;
    }

    return cached.explanation;
  }

  /// Cache an explanation.
  void _cacheExplanation(String appointmentId, PredictionExplanation explanation) {
    final now = DateTime.now();
    final cacheDuration = Duration(
      minutes: _config?.cacheTtlMinutes ?? _defaultCacheDurationMinutes,
    );

    _cache[appointmentId] = CachedExplanation(
      explanation: explanation,
      cachedAt: now,
      expiresAt: now.add(cacheDuration),
    );
  }

  /// Clear all cached explanations.
  void clearCache() {
    _cache.clear();
    debugPrint('ExplanationService: Cache cleared');
  }

  /// Clear expired entries from cache.
  void cleanupExpiredCache() {
    final expiredKeys = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    if (expiredKeys.isNotEmpty) {
      debugPrint('ExplanationService: Removed ${expiredKeys.length} expired cache entries');
    }
  }

  /// Get service statistics.
  Map<String, dynamic> get statistics => {
        'requestCount': _requestCount,
        'cacheHits': _cacheHits,
        'apiCalls': _apiCalls,
        'errors': _errors,
        'cacheSize': _cache.length,
        'cacheHitRate': _requestCount > 0
            ? '${(_cacheHits / _requestCount * 100).toStringAsFixed(1)}%'
            : '0%',
      };

  /// Reset statistics (for testing).
  void resetStatistics() {
    _requestCount = 0;
    _cacheHits = 0;
    _apiCalls = 0;
    _errors = 0;
  }
}
