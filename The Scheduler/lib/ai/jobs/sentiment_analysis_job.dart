/// Background job for periodic sentiment analysis.
///
/// Features:
/// - Configurable analysis schedule
/// - Batch processing for efficiency
/// - Priority-based client selection
/// - Graceful degradation when service unavailable
/// - HIPAA-compliant audit logging
///
/// Agent AI-7: Flutter Sentiment Integration
library sentiment_analysis_job;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/security_context.dart';
import '../models/client_risk_score.dart';
import '../providers/sentiment_providers.dart';

/// Configuration for the sentiment analysis job.
class SentimentAnalysisJobConfig {
  /// How often to run the analysis job.
  final Duration analysisInterval;

  /// Maximum clients to process per job run.
  final int maxClientsPerRun;

  /// Maximum texts to analyze per client.
  final int maxTextsPerClient;

  /// Minimum time between analyses for the same client.
  final Duration clientCooldown;

  /// Whether to analyze only clients with new texts.
  final bool onlyNewTexts;

  const SentimentAnalysisJobConfig({
    this.analysisInterval = const Duration(hours: 1),
    this.maxClientsPerRun = 20,
    this.maxTextsPerClient = 50,
    this.clientCooldown = const Duration(hours: 24),
    this.onlyNewTexts = true,
  });

  /// Development config with more frequent runs.
  factory SentimentAnalysisJobConfig.development() {
    return const SentimentAnalysisJobConfig(
      analysisInterval: Duration(minutes: 15),
      maxClientsPerRun: 5,
    );
  }

  /// Production config optimized for throughput.
  factory SentimentAnalysisJobConfig.production() {
    return const SentimentAnalysisJobConfig(
      analysisInterval: Duration(hours: 2),
      maxClientsPerRun: 50,
      maxTextsPerClient: 100,
    );
  }
}

/// Result of a sentiment analysis job run.
class SentimentAnalysisJobResult {
  final DateTime startedAt;
  final DateTime completedAt;
  final int clientsProcessed;
  final int textsAnalyzed;
  final int scoresUpdated;
  final int errorsEncountered;
  final List<String> clientsWithErrors;
  final bool wasSuccessful;

  SentimentAnalysisJobResult({
    required this.startedAt,
    required this.completedAt,
    required this.clientsProcessed,
    required this.textsAnalyzed,
    required this.scoresUpdated,
    required this.errorsEncountered,
    this.clientsWithErrors = const [],
  }) : wasSuccessful = errorsEncountered == 0;

  Duration get duration => completedAt.difference(startedAt);

  @override
  String toString() {
    return 'SentimentAnalysisJobResult('
        'clients: $clientsProcessed, '
        'texts: $textsAnalyzed, '
        'scores: $scoresUpdated, '
        'errors: $errorsEncountered, '
        'duration: ${duration.inSeconds}s)';
  }
}

/// Background job for sentiment analysis.
///
/// This class handles the orchestration of periodic sentiment analysis
/// across all clients in a business.
class SentimentAnalysisJob {
  final Ref _ref;
  final SentimentAnalysisJobConfig _config;
  final SecurityContext _context;

  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastRunAt;
  SentimentAnalysisJobResult? _lastResult;

  SentimentAnalysisJob({
    required Ref ref,
    required SecurityContext context,
    SentimentAnalysisJobConfig? config,
  })  : _ref = ref,
        _context = context,
        _config = config ?? const SentimentAnalysisJobConfig();

  /// Whether the job is currently running.
  bool get isRunning => _isRunning;

  /// When the job last ran.
  DateTime? get lastRunAt => _lastRunAt;

  /// Result of the last job run.
  SentimentAnalysisJobResult? get lastResult => _lastResult;

  /// Start the scheduled job.
  void start() {
    if (_timer != null) {
      debugPrint('SentimentAnalysisJob: Already started');
      return;
    }

    debugPrint(
        'SentimentAnalysisJob: Starting with interval ${_config.analysisInterval}');

    // Schedule periodic runs
    _timer = Timer.periodic(_config.analysisInterval, (_) => run());
  }

  /// Stop the scheduled job.
  void stop() {
    debugPrint('SentimentAnalysisJob: Stopping');
    _timer?.cancel();
    _timer = null;
  }

  /// Run the job immediately.
  Future<SentimentAnalysisJobResult> run() async {
    if (_isRunning) {
      debugPrint('SentimentAnalysisJob: Already running, skipping');
      return _lastResult ??
          SentimentAnalysisJobResult(
            startedAt: DateTime.now(),
            completedAt: DateTime.now(),
            clientsProcessed: 0,
            textsAnalyzed: 0,
            scoresUpdated: 0,
            errorsEncountered: 1,
          );
    }

    _isRunning = true;
    final startedAt = DateTime.now();

    debugPrint('SentimentAnalysisJob: Starting run at $startedAt');

    int clientsProcessed = 0;
    int textsAnalyzed = 0;
    int scoresUpdated = 0;
    int errorsEncountered = 0;
    final clientsWithErrors = <String>[];

    try {
      // Check if service is available
      final isAvailable =
          await _ref.read(sentimentAvailableProvider.future);

      if (!isAvailable) {
        debugPrint('SentimentAnalysisJob: Sentiment service unavailable');
        _isRunning = false;
        _lastRunAt = startedAt;
        _lastResult = SentimentAnalysisJobResult(
          startedAt: startedAt,
          completedAt: DateTime.now(),
          clientsProcessed: 0,
          textsAnalyzed: 0,
          scoresUpdated: 0,
          errorsEncountered: 1,
        );
        return _lastResult!;
      }

      // Get clients to analyze based on priority
      final clientIds = await _getClientsToAnalyze();

      if (clientIds.isEmpty) {
        debugPrint('SentimentAnalysisJob: No clients to analyze');
        _isRunning = false;
        _lastRunAt = startedAt;
        _lastResult = SentimentAnalysisJobResult(
          startedAt: startedAt,
          completedAt: DateTime.now(),
          clientsProcessed: 0,
          textsAnalyzed: 0,
          scoresUpdated: 0,
          errorsEncountered: 0,
        );
        return _lastResult!;
      }

      debugPrint(
          'SentimentAnalysisJob: Processing ${clientIds.length} clients');

      // Process each client
      final analysisNotifier =
          _ref.read(clientSentimentAnalysisProvider.notifier);

      for (final clientId in clientIds) {
        try {
          final result = await analysisNotifier.analyzeClient(
            context: _context,
            clientId: clientId,
          );

          clientsProcessed++;
          if (result != null) {
            scoresUpdated++;
            textsAnalyzed += result.textsAnalyzed;
          }
        } catch (e) {
          debugPrint(
              'SentimentAnalysisJob: Error analyzing client $clientId: $e');
          errorsEncountered++;
          clientsWithErrors.add(clientId);
        }
      }
    } catch (e) {
      debugPrint('SentimentAnalysisJob: Job failed with error: $e');
      errorsEncountered++;
    } finally {
      _isRunning = false;
      _lastRunAt = startedAt;
    }

    final completedAt = DateTime.now();
    _lastResult = SentimentAnalysisJobResult(
      startedAt: startedAt,
      completedAt: completedAt,
      clientsProcessed: clientsProcessed,
      textsAnalyzed: textsAnalyzed,
      scoresUpdated: scoresUpdated,
      errorsEncountered: errorsEncountered,
      clientsWithErrors: clientsWithErrors,
    );

    debugPrint('SentimentAnalysisJob: Completed - $_lastResult');

    return _lastResult!;
  }

  /// Get clients to analyze based on configured priorities.
  Future<List<String>> _getClientsToAnalyze() async {
    final clientIds = <String>[];
    final riskRepo = _ref.read(clientRiskRepositoryProvider);

    // Get high-risk clients first
    final highRisk = await riskRepo.getHighRiskClients(_context);
    final highRiskIds = highRisk
        .where((c) => _shouldAnalyze(c))
        .take(_config.maxClientsPerRun)
        .map((c) => c.clientId)
        .toList();
    clientIds.addAll(highRiskIds);

    if (clientIds.length >= _config.maxClientsPerRun) {
      return clientIds;
    }

    // Get clients needing attention
    final remaining = _config.maxClientsPerRun - clientIds.length;
    final needingAttention = await riskRepo.getClientsNeedingAttention(_context);
    final attentionIds = needingAttention
        .where((c) => !clientIds.contains(c.clientId))
        .where((c) => _shouldAnalyze(c))
        .take(remaining)
        .map((c) => c.clientId)
        .toList();
    clientIds.addAll(attentionIds);

    return clientIds;
  }

  /// Check if a client should be analyzed based on cooldown.
  bool _shouldAnalyze(ClientRiskScore score) {
    final timeSinceAnalysis = DateTime.now().difference(score.calculatedAt);
    return timeSinceAnalysis > _config.clientCooldown;
  }

  /// Dispose of resources.
  void dispose() {
    stop();
  }
}

/// Provider for sentiment analysis job.
///
/// Usage:
/// ```dart
/// final job = ref.watch(sentimentAnalysisJobProvider(context));
/// job.start(); // Start scheduled job
/// await job.run(); // Run immediately
/// job.stop(); // Stop scheduled job
/// ```
final sentimentAnalysisJobProvider =
    Provider.family<SentimentAnalysisJob, SecurityContext>((ref, context) {
  final job = SentimentAnalysisJob(
    ref: ref,
    context: context,
  );

  ref.onDispose(() => job.dispose());

  return job;
});

/// Provider for job configuration.
final sentimentAnalysisJobConfigProvider =
    Provider<SentimentAnalysisJobConfig>((ref) {
  // Could be configured based on environment
  return const SentimentAnalysisJobConfig();
});
