/// Unified AI providers for The Scheduler.
///
/// Provides:
/// - AI service initialization
/// - Background job management
/// - Provider exports for all AI functionality
///
/// Agent AI-7: Flutter Sentiment Integration
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/security_context.dart';
import '../models/ai_health_status.dart';
import 'sentiment_providers.dart';

// ============ Re-export Sentiment Providers ============

export 'sentiment_providers.dart';

// ============ Client Risk Score Provider ============

import '../models/client_risk_score.dart';
import '../repositories/client_risk_repository.dart';

/// Parameters for client risk score lookup.
typedef ClientRiskScoreParams = ({
  SecurityContext context,
  String clientId,
});

/// Provider for client risk repository.
final clientRiskRepositoryProvider = Provider<ClientRiskRepository>((ref) {
  return ClientRiskRepository();
});

/// Provider for client risk score.
final clientRiskScoreProvider = FutureProvider.family<
    ClientRiskScore?,
    ClientRiskScoreParams>((ref, params) async {
  final repo = ref.watch(clientRiskRepositoryProvider);
  return repo.getClientRiskScore(params.context, params.clientId);
});

/// Stream provider for real-time client risk score updates.
final clientRiskScoreStreamProvider = StreamProvider.family<
    ClientRiskScore?,
    ClientRiskScoreParams>((ref, params) {
  final repo = ref.watch(clientRiskRepositoryProvider);
  return repo.watchClientRiskScore(params.context, params.clientId);
});

// ============ Unified Health Provider ============

/// Provider for combined AI health status across all services.
final aiHealthProvider = FutureProvider<AIHealthStatus>((ref) async {
  // Get sentiment service health
  final sentimentHealth = await ref.watch(sentimentHealthProvider.future);

  // In the future, combine with other service health checks:
  // final predictionHealth = await ref.watch(predictionHealthProvider.future);
  // final routingHealth = await ref.watch(routingHealthProvider.future);

  // For now, return sentiment health directly
  // Future: combine into unified health status
  return sentimentHealth;
});

/// Provider to check if any AI services are available.
final aiAvailableProvider = FutureProvider<bool>((ref) async {
  final health = await ref.watch(aiHealthProvider.future);
  return health.hasAnyHealthyService;
});

// ============ Initialization ============

/// AI initialization state.
class AIInitializationState {
  final bool isInitialized;
  final bool sentimentServiceReady;
  final bool predictionServiceReady;
  final bool routingServiceReady;
  final String? error;

  const AIInitializationState({
    this.isInitialized = false,
    this.sentimentServiceReady = false,
    this.predictionServiceReady = false,
    this.routingServiceReady = false,
    this.error,
  });

  AIInitializationState copyWith({
    bool? isInitialized,
    bool? sentimentServiceReady,
    bool? predictionServiceReady,
    bool? routingServiceReady,
    String? error,
  }) {
    return AIInitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      sentimentServiceReady:
          sentimentServiceReady ?? this.sentimentServiceReady,
      predictionServiceReady:
          predictionServiceReady ?? this.predictionServiceReady,
      routingServiceReady: routingServiceReady ?? this.routingServiceReady,
      error: error,
    );
  }

  bool get anyServiceReady =>
      sentimentServiceReady || predictionServiceReady || routingServiceReady;
}

/// Notifier for AI initialization.
class AIInitializationNotifier extends StateNotifier<AIInitializationState> {
  final Ref _ref;
  bool _disposed = false;

  AIInitializationNotifier(this._ref)
      : super(const AIInitializationState());

  /// Initialize all AI services.
  ///
  /// Returns true if at least one service is ready.
  Future<bool> initialize() async {
    if (_disposed) return false;

    try {
      debugPrint('AIInitializationNotifier: Starting AI service initialization');

      // Check sentiment service
      final sentimentReady =
          await _ref.read(sentimentAvailableProvider.future);

      if (_disposed) return false;

      state = state.copyWith(
        sentimentServiceReady: sentimentReady,
        isInitialized: true,
      );

      debugPrint(
          'AIInitializationNotifier: Sentiment service ${sentimentReady ? "ready" : "unavailable"}');

      // Future: Initialize prediction and routing services
      // state = state.copyWith(
      //   predictionServiceReady: await _ref.read(predictionAvailableProvider.future),
      //   routingServiceReady: await _ref.read(routingAvailableProvider.future),
      // );

      return state.anyServiceReady;
    } catch (e) {
      if (_disposed) return false;

      debugPrint('AIInitializationNotifier: Initialization failed: $e');
      state = state.copyWith(
        isInitialized: true,
        error: e.toString(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final aiInitializationProvider =
    StateNotifierProvider<AIInitializationNotifier, AIInitializationState>(
        (ref) {
  return AIInitializationNotifier(ref);
});

// ============ Background Job Management ============

/// State for background AI jobs.
class AIBackgroundJobState {
  final bool isRunning;
  final DateTime? lastSentimentAnalysisRun;
  final DateTime? nextSentimentAnalysisRun;
  final int textsAnalyzedTotal;
  final int clientsScored;
  final String? lastError;

  const AIBackgroundJobState({
    this.isRunning = false,
    this.lastSentimentAnalysisRun,
    this.nextSentimentAnalysisRun,
    this.textsAnalyzedTotal = 0,
    this.clientsScored = 0,
    this.lastError,
  });

  AIBackgroundJobState copyWith({
    bool? isRunning,
    DateTime? lastSentimentAnalysisRun,
    DateTime? nextSentimentAnalysisRun,
    int? textsAnalyzedTotal,
    int? clientsScored,
    String? lastError,
  }) {
    return AIBackgroundJobState(
      isRunning: isRunning ?? this.isRunning,
      lastSentimentAnalysisRun:
          lastSentimentAnalysisRun ?? this.lastSentimentAnalysisRun,
      nextSentimentAnalysisRun:
          nextSentimentAnalysisRun ?? this.nextSentimentAnalysisRun,
      textsAnalyzedTotal: textsAnalyzedTotal ?? this.textsAnalyzedTotal,
      clientsScored: clientsScored ?? this.clientsScored,
      lastError: lastError,
    );
  }
}

/// Notifier for managing background AI jobs.
class AIBackgroundJobNotifier extends StateNotifier<AIBackgroundJobState> {
  final Ref _ref;
  Timer? _sentimentAnalysisTimer;
  SecurityContext? _currentContext;
  bool _disposed = false;

  // Job configuration
  static const Duration _sentimentAnalysisInterval = Duration(hours: 1);
  static const int _clientBatchSize = 10;

  AIBackgroundJobNotifier(this._ref)
      : super(const AIBackgroundJobState());

  /// Start background AI jobs.
  ///
  /// [context] is required for multi-tenant isolation.
  void start(SecurityContext context) {
    if (_disposed) return;

    _currentContext = context;

    debugPrint('AIBackgroundJobNotifier: Starting background jobs');

    // Start sentiment analysis job
    _startSentimentAnalysisJob();

    state = state.copyWith(isRunning: true);
  }

  /// Stop all background jobs.
  void stop() {
    debugPrint('AIBackgroundJobNotifier: Stopping background jobs');

    _sentimentAnalysisTimer?.cancel();
    _sentimentAnalysisTimer = null;
    _currentContext = null;

    if (!_disposed) {
      state = state.copyWith(isRunning: false);
    }
  }

  /// Run sentiment analysis job immediately (for testing or manual trigger).
  Future<void> runSentimentAnalysisNow() async {
    if (_disposed || _currentContext == null) return;
    await _runSentimentAnalysis();
  }

  void _startSentimentAnalysisJob() {
    // Cancel existing timer
    _sentimentAnalysisTimer?.cancel();

    // Schedule periodic runs
    _sentimentAnalysisTimer = Timer.periodic(
      _sentimentAnalysisInterval,
      (_) => _runSentimentAnalysis(),
    );

    // Calculate next run time
    final nextRun = DateTime.now().add(_sentimentAnalysisInterval);
    state = state.copyWith(nextSentimentAnalysisRun: nextRun);

    debugPrint(
        'AIBackgroundJobNotifier: Sentiment analysis scheduled for $nextRun');
  }

  Future<void> _runSentimentAnalysis() async {
    if (_disposed || _currentContext == null) return;

    debugPrint('AIBackgroundJobNotifier: Running sentiment analysis job');

    try {
      // Check if service is available
      final isAvailable = await _ref.read(sentimentAvailableProvider.future);

      if (!isAvailable) {
        debugPrint(
            'AIBackgroundJobNotifier: Sentiment service unavailable, skipping');
        return;
      }

      // Get clients needing analysis
      final clientsNeedingAttention = await _ref.read(
        clientsNeedingAttentionProvider(_currentContext!).future,
      );

      if (clientsNeedingAttention.isEmpty) {
        debugPrint('AIBackgroundJobNotifier: No clients need attention');
        if (!_disposed) {
          state = state.copyWith(
            lastSentimentAnalysisRun: DateTime.now(),
            nextSentimentAnalysisRun:
                DateTime.now().add(_sentimentAnalysisInterval),
          );
        }
        return;
      }

      // Process clients in batches
      final clientIds = clientsNeedingAttention
          .take(_clientBatchSize)
          .map((c) => c.clientId)
          .toList();

      debugPrint(
          'AIBackgroundJobNotifier: Analyzing ${clientIds.length} clients');

      // Run batch analysis
      final results = await _ref
          .read(batchSentimentAnalysisProvider.notifier)
          .analyzeClients(
            context: _currentContext!,
            clientIds: clientIds,
          );

      if (!_disposed) {
        state = state.copyWith(
          lastSentimentAnalysisRun: DateTime.now(),
          nextSentimentAnalysisRun:
              DateTime.now().add(_sentimentAnalysisInterval),
          textsAnalyzedTotal: state.textsAnalyzedTotal + results.length,
          clientsScored: state.clientsScored + results.length,
          lastError: null,
        );
      }

      debugPrint(
          'AIBackgroundJobNotifier: Analyzed ${results.length} clients successfully');
    } catch (e) {
      debugPrint('AIBackgroundJobNotifier: Sentiment analysis failed: $e');

      if (!_disposed) {
        state = state.copyWith(
          lastSentimentAnalysisRun: DateTime.now(),
          nextSentimentAnalysisRun:
              DateTime.now().add(_sentimentAnalysisInterval),
          lastError: e.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}

final aiBackgroundJobProvider =
    StateNotifierProvider<AIBackgroundJobNotifier, AIBackgroundJobState>((ref) {
  final notifier = AIBackgroundJobNotifier(ref);
  ref.onDispose(() => notifier.stop());
  return notifier;
});

// ============ Convenience Functions ============

/// Initialize AI services on app startup.
///
/// Call this in your app's initialization flow.
/// Returns true if at least one AI service is available.
///
/// Example:
/// ```dart
/// final aiReady = await initializeAIServices(ref);
/// if (aiReady) {
///   startAIBackgroundJobs(ref, securityContext);
/// }
/// ```
Future<bool> initializeAIServices(WidgetRef ref) async {
  return ref.read(aiInitializationProvider.notifier).initialize();
}

/// Alternative for use with Ref (in providers).
Future<bool> initializeAIServicesWithRef(Ref ref) async {
  return ref.read(aiInitializationProvider.notifier).initialize();
}

/// Start background AI jobs.
///
/// Call after [initializeAIServices] succeeds.
/// Requires a [SecurityContext] for multi-tenant isolation.
void startAIBackgroundJobs(WidgetRef ref, SecurityContext context) {
  ref.read(aiBackgroundJobProvider.notifier).start(context);
}

/// Alternative for use with Ref (in providers).
void startAIBackgroundJobsWithRef(Ref ref, SecurityContext context) {
  ref.read(aiBackgroundJobProvider.notifier).start(context);
}

/// Stop background AI jobs.
///
/// Call when user logs out or app is backgrounded.
void stopAIBackgroundJobs(WidgetRef ref) {
  ref.read(aiBackgroundJobProvider.notifier).stop();
}

/// Alternative for use with Ref (in providers).
void stopAIBackgroundJobsWithRef(Ref ref) {
  ref.read(aiBackgroundJobProvider.notifier).stop();
}

/// Manually trigger sentiment analysis.
///
/// Useful for testing or admin-triggered analysis.
Future<void> triggerSentimentAnalysis(WidgetRef ref) async {
  await ref.read(aiBackgroundJobProvider.notifier).runSentimentAnalysisNow();
}
