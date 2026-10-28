/// Riverpod providers for sentiment analysis and client risk scoring.
///
/// Provides:
/// - SentimentService singleton
/// - ClientRiskScoringService
/// - Client risk score providers (single and batch)
/// - High-risk and VIP client lists
/// - Analysis triggering
///
/// Agent AI-7: Flutter Sentiment Integration
library sentiment_providers;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/ai_config.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/models/security_context.dart';
import '../models/client_risk_score.dart';
import '../models/ai_health_status.dart';
import '../services/sentiment_service.dart';
import '../services/client_risk_scoring_service.dart';
import '../repositories/client_risk_repository.dart';

// ============ Configuration Providers ============

/// Provider for AI configuration.
///
/// HIPAA: Must be overridden with a production config (HTTPS + auth token) at app
/// startup. Throws if not provided to avoid accidental HTTP/unauthenticated calls.
final aiConfigProvider = Provider<AIConfig>((ref) {
  throw StateError(
    'AIConfig must be provided by the app (HTTPS baseUrl + auth token/API key)',
  );
});

// ============ Repository Providers ============

/// Provider for the client risk repository.
final clientRiskRepositoryProvider = Provider<ClientRiskRepository>((ref) {
  return ClientRiskRepository(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  );
});

// ============ Service Providers ============

/// Provider for the sentiment service singleton.
final sentimentServiceProvider = Provider<SentimentService>((ref) {
  final config = ref.watch(aiConfigProvider);
  final auditRepo = ref.watch(auditLogRepositoryProvider);

  final service = SentimentService(
    config: config,
    auditLogRepository: auditRepo,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

/// Provider for the client risk scoring service.
final clientRiskScoringServiceProvider =
    Provider<ClientRiskScoringService>((ref) {
  return ClientRiskScoringService(
    riskRepo: ref.watch(clientRiskRepositoryProvider),
  );
});

// ============ Health Check Providers ============

/// Provider to check if sentiment analysis is available.
final sentimentAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(sentimentServiceProvider);
  return service.isAvailable();
});

/// Provider for sentiment service health status.
final sentimentHealthProvider = FutureProvider<AIHealthStatus>((ref) async {
  final service = ref.watch(sentimentServiceProvider);
  return service.checkHealth();
});

/// Provider for sentiment service statistics.
final sentimentStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(sentimentServiceProvider);
  return service.statistics;
});

// ============ Data Providers ============

/// Parameters for client risk score lookup.
typedef ClientRiskParams = ({SecurityContext context, String clientId});

/// Family provider for client risk scores.
///
/// Usage:
/// ```dart
/// final riskScore = ref.watch(clientRiskScoreProvider((
///   context: securityContext,
///   clientId: clientId,
/// )));
/// ```
final clientRiskScoreProvider =
    FutureProvider.family<ClientRiskScore, ClientRiskParams>(
        (ref, params) async {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);

  // Try to get existing score first
  final existing = await riskRepo.getClientRiskScore(
    params.context,
    params.clientId,
  );

  if (existing != null && !existing.isExpired) {
    return existing;
  }

  // If no valid score, return empty (analysis happens separately)
  return ClientRiskScore.empty(
    clientId: params.clientId,
    businessId: params.context.businessId,
  );
});

/// Parameters for batch client risk scores lookup.
typedef BatchRiskParams = ({SecurityContext context, List<String> clientIds});

/// Family provider for batch client risk scores.
final batchClientRiskScoresProvider =
    FutureProvider.family<Map<String, ClientRiskScore>, BatchRiskParams>(
        (ref, params) async {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);

  return riskRepo.getClientRiskScoresBatch(
    params.context,
    params.clientIds,
  );
});

/// Provider for high-risk clients list.
final highRiskClientsProvider =
    FutureProvider.family<List<ClientRiskScore>, SecurityContext>(
        (ref, context) async {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);
  return riskRepo.getHighRiskClients(context);
});

/// Provider for VIP clients list.
final vipClientsProvider =
    FutureProvider.family<List<ClientRiskScore>, SecurityContext>(
        (ref, context) async {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);
  return riskRepo.getVipClients(context);
});

/// Provider for clients needing attention.
final clientsNeedingAttentionProvider =
    FutureProvider.family<List<ClientRiskScore>, SecurityContext>(
        (ref, context) async {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);
  return riskRepo.getClientsNeedingAttention(context);
});

// ============ Stream Providers ============

/// Stream provider for real-time high-risk client updates.
final highRiskClientsStreamProvider =
    StreamProvider.family<List<ClientRiskScore>, SecurityContext>(
        (ref, context) {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);
  return riskRepo.watchHighRiskClients(context);
});

/// Stream provider for a single client's risk score.
final clientRiskScoreStreamProvider =
    StreamProvider.family<ClientRiskScore?, ClientRiskParams>((ref, params) {
  final riskRepo = ref.watch(clientRiskRepositoryProvider);
  return riskRepo.watchClientRiskScore(params.context, params.clientId);
});

// ============ Action Providers ============

/// Notifier for triggering sentiment analysis on a client.
///
/// Note: This requires the TextAggregationService to be properly configured
/// with all its repository dependencies. For now, this provides a simplified
/// interface that works with the sentiment service directly.
class ClientSentimentAnalysisNotifier
    extends StateNotifier<AsyncValue<ClientRiskScore?>> {
  final SentimentService _sentimentService;
  final ClientRiskScoringService _scoringService;
  final ClientRiskRepository _riskRepo;

  ClientSentimentAnalysisNotifier({
    required SentimentService sentimentService,
    required ClientRiskScoringService scoringService,
    required ClientRiskRepository riskRepo,
  })  : _sentimentService = sentimentService,
        _scoringService = scoringService,
        _riskRepo = riskRepo,
        super(const AsyncValue.data(null));

  /// Analyze sentiment for a client and update their risk score.
  ///
  /// This method requires sentiment results to already exist in the repository.
  /// For full text aggregation and analysis, use the SentimentAnalysisJob.
  Future<ClientRiskScore?> analyzeClient({
    required SecurityContext context,
    required String clientId,
    bool forceReanalyze = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Check if service is available
      final isAvailable = await _sentimentService.isAvailable();
      if (!isAvailable) {
        debugPrint('Sentiment service unavailable');
        final existing = await _riskRepo.getClientRiskScore(context, clientId);
        state = AsyncValue.data(existing);
        return existing;
      }

      // Get existing sentiment results for this client
      final existingResults = await _riskRepo.getClientSentimentResults(
        context,
        clientId,
        limit: 100,
      );

      if (existingResults.isEmpty) {
        debugPrint('No sentiment results for client $clientId');
        final existing = await _riskRepo.getClientRiskScore(context, clientId);
        state = AsyncValue.data(existing);
        return existing;
      }

      // Calculate and save risk score
      final riskScore = await _scoringService.calculateAndSaveScore(
        context: context,
        clientId: clientId,
        sentimentResults: existingResults,
      );

      state = AsyncValue.data(riskScore);
      return riskScore;
    } catch (e, stack) {
      debugPrint('Sentiment analysis failed: $e');
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Analyze text directly for a client (bypasses text aggregation).
  Future<ClientRiskScore?> analyzeText({
    required SecurityContext context,
    required String clientId,
    required SentimentAnalysisRequest request,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Analyze the text
      final result = await _sentimentService.analyzeSentiment(
        context: context,
        text: request,
      );

      if (result == null) {
        debugPrint('Sentiment analysis returned null');
        final existing = await _riskRepo.getClientRiskScore(context, clientId);
        state = AsyncValue.data(existing);
        return existing;
      }

      // Save the result
      await _riskRepo.saveSentimentResult(context, result);

      // Get all results and recalculate score
      final allResults = await _riskRepo.getClientSentimentResults(
        context,
        clientId,
        limit: 100,
      );

      final riskScore = await _scoringService.calculateAndSaveScore(
        context: context,
        clientId: clientId,
        sentimentResults: allResults,
      );

      state = AsyncValue.data(riskScore);
      return riskScore;
    } catch (e, stack) {
      debugPrint('Sentiment analysis failed: $e');
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

final clientSentimentAnalysisProvider = StateNotifierProvider<
    ClientSentimentAnalysisNotifier, AsyncValue<ClientRiskScore?>>((ref) {
  return ClientSentimentAnalysisNotifier(
    sentimentService: ref.watch(sentimentServiceProvider),
    scoringService: ref.watch(clientRiskScoringServiceProvider),
    riskRepo: ref.watch(clientRiskRepositoryProvider),
  );
});

/// Provider for batch sentiment analysis (multiple clients).
class BatchSentimentAnalysisNotifier
    extends StateNotifier<AsyncValue<Map<String, ClientRiskScore>>> {
  final Ref _ref;

  BatchSentimentAnalysisNotifier(this._ref)
      : super(const AsyncValue.data({}));

  /// Analyze sentiment for multiple clients.
  Future<Map<String, ClientRiskScore>> analyzeClients({
    required SecurityContext context,
    required List<String> clientIds,
  }) async {
    state = const AsyncValue.loading();

    final results = <String, ClientRiskScore>{};
    final analysisNotifier =
        _ref.read(clientSentimentAnalysisProvider.notifier);

    // Process in batches to avoid overwhelming the service
    const batchSize = 5;
    for (var i = 0; i < clientIds.length; i += batchSize) {
      final batch = clientIds.skip(i).take(batchSize).toList();

      final futures = batch.map((clientId) => analysisNotifier.analyzeClient(
            context: context,
            clientId: clientId,
          ));

      final batchResults = await Future.wait(futures);

      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j] != null) {
          results[batch[j]] = batchResults[j]!;
        }
      }
    }

    state = AsyncValue.data(results);
    return results;
  }
}

final batchSentimentAnalysisProvider = StateNotifierProvider<
    BatchSentimentAnalysisNotifier, AsyncValue<Map<String, ClientRiskScore>>>(
    (ref) {
  return BatchSentimentAnalysisNotifier(ref);
});
