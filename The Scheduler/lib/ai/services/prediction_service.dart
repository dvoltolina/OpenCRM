import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/ai_config.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../cache/prediction_cache.dart';
import '../models/ai_exceptions.dart';
import '../models/ai_health_status.dart';
import '../models/noshow_prediction.dart';
import '../models/prediction_features.dart';
import 'ai_client.dart';

/// Service for getting no-show predictions from the AI server.
///
/// Features:
/// - Automatic caching with configurable TTL
/// - Circuit breaker for failing server
/// - Batch prediction support
/// - Graceful degradation when server unavailable
/// - HIPAA-compliant audit logging
///
/// Agent AI-4: Flutter Prediction Integration
class PredictionService {
  PredictionService({
    required AIConfig config,
    AIClient? aiClient,
    PredictionCache? cache,
    AuditLogRepository? auditLogRepository,
  })  : _config = config,
        _aiClient = aiClient ?? AIClient(config: config),
        _cache = cache ?? PredictionCache(),
        _auditLogRepository = auditLogRepository;

  final AIConfig _config;
  final AIClient _aiClient;
  final PredictionCache _cache;
  final AuditLogRepository? _auditLogRepository;

  // Statistics
  int _totalRequests = 0;
  int _cacheHits = 0;
  int _serverErrors = 0;
  DateTime? _lastPredictionAt;

  /// Check if the prediction service is available.
  Future<bool> isAvailable() async {
    if (_aiClient.isCircuitOpen) return false;

    try {
      final health = await checkHealth();
      return health.predictionService.status == AIServiceHealth.healthy;
    } catch (e) {
      return false;
    }
  }

  /// Get health status of the prediction server.
  Future<AIHealthStatus> checkHealth() async {
    return _aiClient.checkHealth();
  }

  /// Predict no-show probability for an appointment.
  ///
  /// Returns cached prediction if available and not expired.
  /// Falls back to [NoshowPrediction.unavailable] if server is down.
  ///
  /// **IMPORTANT:** Logs all predictions to AuditLogRepository for HIPAA compliance.
  /// **HIPAA:** Cache is keyed by businessId + appointmentId for tenant isolation.
  Future<NoshowPrediction> predictNoshow({
    required SecurityContext context,
    required PredictionFeatures features,
    bool bypassCache = false,
  }) async {
    _totalRequests++;

    // Check cache first (HIPAA: includes businessId for tenant isolation)
    if (!bypassCache) {
      final cached = await _cache.get(
        features.appointmentId,
        businessId: features.businessId,
      );
      if (cached != null) {
        _cacheHits++;
        debugPrint(
            'PredictionService: Cache hit for ${features.appointmentId}');
        return cached;
      }
    }

    // Check circuit breaker
    if (_aiClient.isCircuitOpen) {
      debugPrint(
          'PredictionService: Circuit breaker open, returning unavailable');
      return NoshowPrediction.unavailable(features.appointmentId);
    }

    // Make API request
    try {
      final prediction = await _fetchPrediction(context, features);

      // Cache the result (HIPAA: includes businessId for tenant isolation)
      await _cache.set(
        features.appointmentId,
        prediction,
        businessId: features.businessId,
      );

      // **CRITICAL: Log prediction for HIPAA compliance**
      await _logPrediction(context, features, prediction);

      _lastPredictionAt = DateTime.now();
      return prediction;
    } on AIServerUnavailableException {
      _serverErrors++;
      return NoshowPrediction.unavailable(features.appointmentId);
    } on AITimeoutException {
      _serverErrors++;
      return NoshowPrediction.unavailable(features.appointmentId);
    } on AICircuitBreakerOpenException {
      return NoshowPrediction.unavailable(features.appointmentId);
    } catch (e) {
      _serverErrors++;
      debugPrint('PredictionService: Unexpected error: $e');
      return NoshowPrediction.unavailable(features.appointmentId);
    }
  }

  /// Predict no-show probability for multiple appointments.
  ///
  /// More efficient than calling [predictNoshow] multiple times.
  /// **HIPAA:** Cache is keyed by businessId + appointmentId for tenant isolation.
  Future<List<NoshowPrediction>> predictNoshowBatch({
    required SecurityContext context,
    required List<PredictionFeatures> featuresList,
    bool bypassCache = false,
  }) async {
    if (featuresList.isEmpty) {
      return [];
    }

    // Separate cached vs. uncached (HIPAA: includes businessId for tenant isolation)
    final results = <String, NoshowPrediction>{};
    final uncached = <PredictionFeatures>[];

    if (!bypassCache) {
      for (final features in featuresList) {
        final cached = await _cache.get(
          features.appointmentId,
          businessId: features.businessId,
        );
        if (cached != null) {
          results[features.appointmentId] = cached;
          _cacheHits++;
        } else {
          uncached.add(features);
        }
      }
    } else {
      uncached.addAll(featuresList);
    }

    _totalRequests += uncached.length;

    // Fetch uncached predictions
    if (uncached.isNotEmpty && !_aiClient.isCircuitOpen) {
      try {
        final fetched = await _fetchBatchPredictions(context, uncached);
        for (var i = 0; i < fetched.length && i < uncached.length; i++) {
          final prediction = fetched[i];
          final features = uncached[i];
          results[prediction.appointmentId] = prediction;
          // HIPAA: includes businessId for tenant isolation
          await _cache.set(
            prediction.appointmentId,
            prediction,
            businessId: features.businessId,
          );
        }

        // Log batch predictions
        for (var i = 0; i < uncached.length; i++) {
          if (results.containsKey(uncached[i].appointmentId)) {
            await _logPrediction(
              context,
              uncached[i],
              results[uncached[i].appointmentId]!,
            );
          }
        }

        _lastPredictionAt = DateTime.now();
      } catch (e) {
        _serverErrors++;
        debugPrint('PredictionService: Batch prediction error: $e');
        // Fill with unavailable for failed fetches
        for (final features in uncached) {
          results.putIfAbsent(
            features.appointmentId,
            () => NoshowPrediction.unavailable(features.appointmentId),
          );
        }
      }
    } else {
      // Circuit open or no uncached - fill with unavailable
      for (final features in uncached) {
        results.putIfAbsent(
          features.appointmentId,
          () => NoshowPrediction.unavailable(features.appointmentId),
        );
      }
    }

    // Return in original order
    return featuresList
        .map((f) =>
            results[f.appointmentId] ??
            NoshowPrediction.unavailable(f.appointmentId))
        .toList();
  }

  /// Invalidate cached prediction for an appointment.
  ///
  /// Call this when appointment data changes significantly.
  /// **HIPAA:** Requires businessId for tenant isolation.
  Future<void> invalidateCache(
    String appointmentId, {
    String businessId = 'default',
  }) async {
    await _cache.remove(
      appointmentId,
      businessId: businessId,
    );
  }

  /// Clear all cached predictions for a business.
  ///
  /// **HIPAA:** Only clears cache for the specified business.
  Future<void> clearCacheForBusiness(String businessId) async {
    await _cache.clearForBusiness(businessId);
  }

  /// Clear all cached predictions (all businesses).
  ///
  /// Use with caution - typically prefer [clearCacheForBusiness].
  Future<void> clearAllCache() async {
    await _cache.clearAll();
  }

  /// Get service statistics.
  Map<String, dynamic> get statistics => {
        'totalRequests': _totalRequests,
        'cacheHits': _cacheHits,
        'cacheHitRate': _totalRequests > 0
            ? '${(_cacheHits / _totalRequests * 100).toStringAsFixed(1)}%'
            : '0%',
        'serverErrors': _serverErrors,
        'circuitBreakerOpen': _aiClient.isCircuitOpen,
        'lastPredictionAt': _lastPredictionAt?.toIso8601String(),
        ..._cache.stats,
      };

  /// Get AI client statistics (circuit breaker state, etc.)
  AIClientStats get clientStats => _aiClient.stats;

  // ============ Private Methods ============

  Future<NoshowPrediction> _fetchPrediction(
    SecurityContext context,
    PredictionFeatures features,
  ) async {
    final response = await _aiClient.post(
      _config.predictionEndpoint,
      features.toApiJson(),
      timeoutMs: _config.readTimeoutMs,
      additionalHeaders: _buildAuthHeaders(context),
    );

    return _parsePredictionResponse(response);
  }

  Future<List<NoshowPrediction>> _fetchBatchPredictions(
    SecurityContext context,
    List<PredictionFeatures> featuresList,
  ) async {
    final response = await _aiClient.post(
      '${_config.predictionEndpoint}/batch',
      {
        'appointments': featuresList.map((f) => f.toApiJson()).toList(),
      },
      // Longer timeout for batch
      timeoutMs: _config.readTimeoutMs * 2,
      additionalHeaders: _buildAuthHeaders(context),
    );

    final predictions = (response['predictions'] as List)
        .map((p) => _parsePredictionResponse(p as Map<String, dynamic>))
        .toList();
    return predictions;
  }

  Map<String, String> _buildAuthHeaders(SecurityContext context) {
    final token = context.authToken ?? _config.authToken;
    if ((token == null || token.isEmpty) && _config.apiKey == null) {
      throw const AIAuthenticationException(
        message: 'Authentication token is required for AI requests',
      );
    }

    return {
      'X-Business-ID': context.businessId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  NoshowPrediction _parsePredictionResponse(Map<String, dynamic> data) {
    // Parse risk level
    final riskLevelStr = data['risk_level'] as String? ?? 'unknown';
    final riskLevel = RiskLevel.values.firstWhere(
      (r) => r.name == riskLevelStr,
      orElse: () => RiskLevel.unknown,
    );

    // Parse recommended actions
    final actionsData = data['recommended_actions'] as List? ?? [];
    final recommendedActions = actionsData.map((a) {
      final actionData = a as Map<String, dynamic>;
      return RecommendedAction(
        actionId: actionData['action_id'] as String,
        title: actionData['title'] as String,
        description: actionData['description'] as String,
        priority: ActionPriority.values.firstWhere(
          (p) => p.name == (actionData['priority'] as String),
          orElse: () => ActionPriority.low,
        ),
        automatable: actionData['automatable'] as bool? ?? false,
        iconName: actionData['icon_name'] as String?,
        estimatedImpact: (actionData['estimated_impact'] as num?)?.toDouble(),
      );
    }).toList();

    // Parse feature importances
    final featuresData = data['top_features'] as List? ?? [];
    final topFeatures = featuresData.map((f) {
      final featureData = f as Map<String, dynamic>;
      return FeatureImportance(
        featureName: featureData['feature_name'] as String,
        featureDisplayName: featureData['feature_display_name'] as String,
        importance: (featureData['importance'] as num).toDouble(),
        featureValue: (featureData['feature_value'] as num).toDouble(),
        impact: featureData['impact'] as String? ?? 'increases_risk',
      );
    }).toList();

    // Parse timestamps
    final predictedAtStr = data['predicted_at'] as String?;
    final expiresAtStr = data['expires_at'] as String?;

    return NoshowPrediction(
      appointmentId: data['appointment_id'] as String,
      probability: (data['probability'] as num).toDouble(),
      riskLevel: riskLevel,
      confidence: (data['confidence'] as num).toDouble(),
      recommendedActions: recommendedActions,
      topFeatures: topFeatures,
      modelVersion: data['model_version'] as String? ?? 'unknown',
      predictedAt: predictedAtStr != null
          ? DateTime.parse(predictedAtStr)
          : DateTime.now(),
      expiresAt: expiresAtStr != null
          ? DateTime.parse(expiresAtStr)
          : DateTime.now().add(Duration(minutes: _config.predictionCacheTtlMinutes)),
      requestId: data['request_id'] as String?,
    );
  }

  Future<void> _logPrediction(
    SecurityContext context,
    PredictionFeatures features,
    NoshowPrediction prediction,
  ) async {
    // Log AI prediction for HIPAA compliance and audit trail
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository!.log(
        context: context,
        action: 'ai_prediction_generated',
        entityType: 'appointment',
        entityId: features.appointmentId,
        details: {
          'model_version': prediction.modelVersion,
          'probability': prediction.probability,
          'risk_level': prediction.riskLevel.name,
          'confidence': prediction.confidence,
          'predicted_at': prediction.predictedAt.toIso8601String(),
          'top_feature': prediction.topFeatures.isNotEmpty
              ? prediction.topFeatures.first.featureName
              : null,
        },
        source: 'PredictionService',
      );
    } catch (e) {
      // Don't fail the prediction if audit logging fails
      debugPrint('PredictionService: Failed to log prediction: $e');
    }
  }

  /// Dispose resources.
  void dispose() {
    _aiClient.close();
  }
}

/// Extension to add API JSON conversion to PredictionFeatures.
extension PredictionFeaturesApiJson on PredictionFeatures {
  /// Convert to JSON format expected by Python API (snake_case).
  Map<String, dynamic> toApiJson() {
    return {
      'appointment_id': appointmentId,
      'business_id': businessId,
      'feature_schema_version': featureSchemaVersion,
      'client_historical_noshow_rate': clientHistoricalNoshowRate,
      'client_historical_cancel_rate': clientHistoricalCancelRate,
      'client_total_appointments': clientTotalAppointments,
      'client_days_since_last_visit': clientDaysSinceLastVisit,
      'client_lifetime_value_cents': clientLifetimeValueCents,
      'client_lifecycle_stage': clientLifecycleStage,
      'client_has_payment_method': clientHasPaymentMethod,
      'booking_lead_days': bookingLeadDays,
      'day_of_week': dayOfWeek,
      'hour_of_day': hourOfDay,
      'is_recurring': isRecurring,
      'is_group_session': isGroupSession,
      'service_duration_minutes': serviceDurationMinutes,
      'service_price_cents': servicePriceCents,
      'requires_payment': requiresPayment,
      'payment_collected': paymentCollected,
      'has_intake_form': hasIntakeForm,
      'provider_historical_noshow_rate': providerHistoricalNoshowRate,
      'provider_total_appointments': providerTotalAppointments,
      'slot_historical_noshow_rate': slotHistoricalNoshowRate,
      'is_first_appointment_of_day': isFirstAppointmentOfDay,
      'is_last_appointment_of_day': isLastAppointmentOfDay,
    };
  }
}
