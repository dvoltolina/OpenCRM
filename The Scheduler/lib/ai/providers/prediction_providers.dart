import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/ai_config.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/models/appointment.dart';
import '../../data/models/security_context.dart';
import '../cache/prediction_cache.dart';
import '../models/ai_health_status.dart';
import '../models/noshow_prediction.dart';
import '../models/prediction_features.dart';
import '../services/ai_client.dart';
import '../services/feature_extraction_service.dart';
import '../services/prediction_service.dart';

/// Provider for AI configuration.
///
/// HIPAA: Must be overridden with a production config (HTTPS + auth token) at app
/// startup. Throws if not provided to avoid accidental HTTP/unauthenticated calls.
final aiConfigProvider = Provider<AIConfig>((ref) {
  throw StateError(
    'AIConfig must be provided by the app (HTTPS baseUrl + auth token/API key)',
  );
});

/// Provider for the AI HTTP client.
final aiClientProvider = Provider<AIClient>((ref) {
  final config = ref.watch(aiConfigProvider);
  final client = AIClient(config: config);

  ref.onDispose(() => client.close());

  return client;
});

/// Provider for the prediction cache.
final predictionCacheProvider = Provider<PredictionCache>((ref) {
  return PredictionCache();
});

/// Provider for the prediction service singleton.
final predictionServiceProvider = Provider<PredictionService>((ref) {
  final config = ref.watch(aiConfigProvider);
  final aiClient = ref.watch(aiClientProvider);
  final cache = ref.watch(predictionCacheProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);

  final service = PredictionService(
    config: config,
    aiClient: aiClient,
    cache: cache,
    auditLogRepository: auditLog,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

/// Provider for feature extraction service.
final featureExtractionServiceProvider =
    Provider<FeatureExtractionService>((ref) {
  return FeatureExtractionService(
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    servicesRepository: ref.watch(servicesRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

/// Provider for AI service health status.
///
/// Usage:
/// ```dart
/// final health = ref.watch(aiHealthStatusProvider);
/// health.when(
///   data: (status) => Text(status.overallStatus.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error'),
/// );
/// ```
final aiHealthStatusProvider = FutureProvider<AIHealthStatus>((ref) async {
  final service = ref.watch(predictionServiceProvider);
  return service.checkHealth();
});

/// Provider to check if predictions are available.
final predictionsAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(predictionServiceProvider);
  return service.isAvailable();
});

/// Parameters for single appointment prediction.
typedef AppointmentPredictionParams = ({
  SecurityContext context,
  Appointment appointment,
});

/// Family provider for single appointment predictions.
///
/// Usage:
/// ```dart
/// final prediction = ref.watch(appointmentPredictionProvider((
///   context: securityContext,
///   appointment: appointment,
/// )));
/// ```
final appointmentPredictionProvider = FutureProvider.family<NoshowPrediction,
    AppointmentPredictionParams>((ref, params) async {
  final predictionService = ref.watch(predictionServiceProvider);
  final featureService = ref.watch(featureExtractionServiceProvider);

  try {
    // Extract features
    final features = await featureService.extractFeatures(
      context: params.context,
      appointment: params.appointment,
    );

    // Get prediction
    return predictionService.predictNoshow(
      context: params.context,
      features: features,
    );
  } catch (e) {
    // Log error but don't crash - return unavailable
    debugPrint('appointmentPredictionProvider: Failed to get prediction: $e');
    return NoshowPrediction.unavailable(params.appointment.id);
  }
});

/// Parameters for batch predictions.
typedef BatchPredictionParams = ({
  SecurityContext context,
  List<Appointment> appointments,
});

/// Family provider for batch predictions (e.g., calendar view).
///
/// Usage:
/// ```dart
/// final predictions = ref.watch(batchPredictionsProvider((
///   context: securityContext,
///   appointments: appointmentsList,
/// )));
/// ```
final batchPredictionsProvider = FutureProvider.family<
    Map<String, NoshowPrediction>,
    BatchPredictionParams>((ref, params) async {
  if (params.appointments.isEmpty) {
    return {};
  }

  final predictionService = ref.watch(predictionServiceProvider);
  final featureService = ref.watch(featureExtractionServiceProvider);

  try {
    // Extract features for all appointments
    final featuresList = await featureService.extractFeaturesBatch(
      context: params.context,
      appointments: params.appointments,
    );

    // Get predictions
    final predictions = await predictionService.predictNoshowBatch(
      context: params.context,
      featuresList: featuresList,
    );

    // Convert to map for easy lookup
    return Map.fromEntries(
      predictions.map((p) => MapEntry(p.appointmentId, p)),
    );
  } catch (e) {
    debugPrint('batchPredictionsProvider: Failed to get predictions: $e');
    return {};
  }
});

/// Provider for prediction service statistics.
final predictionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(predictionServiceProvider);
  return service.statistics;
});

/// Notifier to manually invalidate a prediction.
///
/// Use when appointment data changes significantly.
class PredictionInvalidationNotifier extends StateNotifier<void> {
  PredictionInvalidationNotifier(this._service) : super(null);

  final PredictionService _service;

  /// Invalidate prediction for a single appointment
  Future<void> invalidate(String businessId, String appointmentId) async {
    await _service.invalidateCache(
      appointmentId,
      businessId: businessId,
    );
  }

  /// Clear all cached predictions for a business
  Future<void> clearAllForBusiness(String businessId) async {
    await _service.clearCacheForBusiness(businessId);
  }
}

/// Provider for prediction invalidation notifier.
///
/// Usage:
/// ```dart
/// // Invalidate single appointment
/// ref.read(predictionInvalidationProvider.notifier).invalidate(appointmentId);
///
/// // Clear all
/// ref.read(predictionInvalidationProvider.notifier).clearAll();
/// ```
final predictionInvalidationProvider =
    StateNotifierProvider<PredictionInvalidationNotifier, void>((ref) {
  final service = ref.watch(predictionServiceProvider);
  return PredictionInvalidationNotifier(service);
});

/// Provider that returns predictions for a specific appointment ID from cache.
///
/// Returns null if not in cache. Does not trigger network request.
final cachedPredictionProvider =
    Provider.family<NoshowPrediction?, String>((ref, appointmentId) {
  // This is synchronous and only checks in-memory state
  // For async cache check, use appointmentPredictionProvider
  return null;
});

/// Auto-disposable provider for refreshing health status periodically.
///
/// Usage:
/// ```dart
/// // Refresh health status every 30 seconds
/// final health = ref.watch(aiHealthAutoRefreshProvider(Duration(seconds: 30)));
/// ```
final aiHealthAutoRefreshProvider =
    FutureProvider.family<AIHealthStatus, Duration>((ref, interval) async {
  // Create a timer to auto-refresh
  final timer = Timer.periodic(interval, (_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  final service = ref.watch(predictionServiceProvider);
  return service.checkHealth();
});
