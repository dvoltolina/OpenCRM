/// HTTP client for sentiment analysis via cloud GPU.
///
/// Features:
/// - Circuit breaker for failing service
/// - Batch analysis support
/// - Graceful degradation when service unavailable
/// - HIPAA-compliant audit logging
///
/// Agent AI-7: Flutter Sentiment Integration
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/ai_config.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/models/security_context.dart';
import '../models/sentiment_result.dart';
import '../models/sentiment_source.dart';
import '../models/risk_indicator.dart';
import '../models/ai_exceptions.dart';
import '../models/ai_health_status.dart';
import '../models/model_metadata.dart';

/// A text to be sent to the sentiment API for analysis.
class SentimentAnalysisRequest {
  final String textId;
  final String businessId;
  final String clientId;
  final String text;
  final SentimentSource source;
  final String? sourceDocumentId;
  final bool deepAnalysis;

  SentimentAnalysisRequest({
    required this.textId,
    required this.businessId,
    required this.clientId,
    required this.text,
    required this.source,
    this.sourceDocumentId,
    this.deepAnalysis = false,
  });

  /// Create from an AnalyzableText (from TextAggregationService).
  factory SentimentAnalysisRequest.fromAnalyzableText({
    required String businessId,
    required String text,
    required String textId,
    required String clientId,
    required SentimentSource source,
    String? sourceDocumentId,
    bool deepAnalysis = false,
  }) {
    return SentimentAnalysisRequest(
      textId: textId,
      businessId: businessId,
      clientId: clientId,
      text: text,
      source: source,
      sourceDocumentId: sourceDocumentId,
      deepAnalysis: deepAnalysis,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'text_id': textId,
        'business_id': businessId,
        'client_id': clientId,
        'text': text,
        'source': source.name,
        'source_document_id': sourceDocumentId,
        'deep_analysis': deepAnalysis,
      };
}

/// Service for sentiment analysis via cloud GPU.
///
/// Features:
/// - Circuit breaker for failing service
/// - Batch analysis support
/// - Graceful degradation
class SentimentService {
  final AIConfig _config;
  final http.Client _httpClient;
  final AuditLogRepository _auditLogRepository;

  // Circuit breaker state
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenedAt;
  static const _circuitBreakerThreshold = 5;
  static const _circuitResetDuration = Duration(minutes: 2);

  // Statistics
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  double _totalLatencyMs = 0;

  SentimentService({
    required AIConfig config,
    http.Client? httpClient,
    AuditLogRepository? auditLogRepository,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  /// Check if the sentiment service is available.
  Future<bool> isAvailable() async {
    if (_isCircuitOpen()) return false;

    try {
      final health = await checkHealth();
      return health.sentimentService.status == AIServiceHealth.healthy ||
          health.sentimentService.status == AIServiceHealth.degraded;
    } catch (e) {
      return false;
    }
  }

  /// Get health status of the sentiment server.
  Future<AIHealthStatus> checkHealth() async {
    try {
      final uri = Uri.parse('${_config.sentimentUrl}/health');
      _validateTransport(uri);

      final response = await _httpClient
          .get(
            uri,
            headers: _buildHealthHeaders(),
          )
          .timeout(Duration(milliseconds: _config.connectionTimeoutMs));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _resetCircuitBreaker();

        final isOllamaConnected = data['ollama_connected'] == true;
        final models =
            (data['models_available'] as List<dynamic>?)?.cast<String>() ??
                const <String>[];
        final sentimentModel = models.isNotEmpty
            ? ModelMetadata(
                modelId: models.first,
                modelType: AIModelType.llm,
                version: 'unknown',
                trainedAt: DateTime.now(),
                featureSchemaVersion: 1,
                metrics: const {},
                featureNames: const [],
              )
            : null;
        final sentimentStatus = isOllamaConnected
            ? AIServiceHealth.healthy
            : AIServiceHealth.unhealthy;

        return AIHealthStatus(
          overallStatus: data['status'] == 'healthy'
              ? AIServiceHealth.healthy
              : AIServiceHealth.degraded,
          predictionService: const ServiceHealthDetail(
            serviceName: 'prediction',
            status: AIServiceHealth.unavailable,
          ),
          sentimentService: ServiceHealthDetail(
            serviceName: 'sentiment',
            status: sentimentStatus,
            responseTimeMs: data['avg_latency_ms'] as int?,
          ),
          routingService: const ServiceHealthDetail(
            serviceName: 'routing',
            status: AIServiceHealth.unavailable,
          ),
          lastHealthCheck: DateTime.now(),
          loadedModels: LoadedModels(
            sentimentModel: sentimentModel,
            lastRefreshed: DateTime.now(),
          ),
        );
      }

      return AIHealthStatus.unavailable();
    } catch (e) {
      _recordFailure();
      return AIHealthStatus.unavailable();
    }
  }

  /// Analyze a single text for sentiment.
  ///
  /// Returns null if service is unavailable.
  ///
  /// **IMPORTANT:** Logs all sentiment analyses to AuditLogRepository for HIPAA compliance.
  Future<SentimentResult?> analyzeSentiment({
    required SecurityContext context,
    required SentimentAnalysisRequest text,
  }) async {
    _totalRequests++;

    // Check circuit breaker
    if (_isCircuitOpen()) {
      debugPrint('SentimentService: Circuit breaker open');
      return null;
    }

    try {
      final result = await _fetchAnalysis(context, text);
      _successfulRequests++;
      _resetCircuitBreaker();

      // **CRITICAL: Log sentiment analysis for HIPAA compliance**
      await _logSentimentAnalysis(context, text, result);

      return result;
    } on AIServerUnavailableException {
      _recordFailure();
      _failedRequests++;
      return null;
    } on AITimeoutException {
      _recordFailure();
      _failedRequests++;
      return null;
    } catch (e) {
      _failedRequests++;
      debugPrint('SentimentService: Unexpected error: $e');
      return null;
    }
  }

  /// Analyze multiple texts for sentiment.
  ///
  /// More efficient than calling [analyzeSentiment] multiple times.
  Future<List<SentimentResult>> analyzeSentimentBatch({
    required SecurityContext context,
    required List<SentimentAnalysisRequest> texts,
  }) async {
    if (texts.isEmpty) {
      return [];
    }

    if (_isCircuitOpen()) {
      debugPrint('SentimentService: Circuit breaker open, skipping batch');
      return [];
    }

    try {
      final results = await _fetchBatchAnalysis(context, texts);
      _resetCircuitBreaker();
      return results;
    } on AIServerUnavailableException {
      _recordFailure();
      return [];
    } on AITimeoutException {
      _recordFailure();
      return [];
    } catch (e) {
      _recordFailure();
      debugPrint('SentimentService: Batch analysis failed: $e');
      return [];
    }
  }

  /// Get service statistics.
  Map<String, dynamic> get statistics => {
        'totalRequests': _totalRequests,
        'successfulRequests': _successfulRequests,
        'failedRequests': _failedRequests,
        'successRate': _totalRequests > 0
            ? (_successfulRequests / _totalRequests * 100).toStringAsFixed(1)
            : '0',
        'avgLatencyMs': _successfulRequests > 0
            ? (_totalLatencyMs / _successfulRequests).toStringAsFixed(1)
            : '0',
        'circuitBreakerOpen': _isCircuitOpen(),
      };

  /// Dispose resources.
  void dispose() {
    _httpClient.close();
  }

  // ============ Private Methods ============

  Future<SentimentResult> _fetchAnalysis(
    SecurityContext context,
    SentimentAnalysisRequest text,
  ) async {
    final uri = Uri.parse('${_config.sentimentUrl}/analyze/sentiment');
    _validateTransport(uri);
    final startTime = DateTime.now();

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(context),
            body: jsonEncode(text.toApiJson()),
          )
          .timeout(Duration(milliseconds: _config.readTimeoutMs));

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      _totalLatencyMs += latency;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseResult(data);
      } else if (response.statusCode == 503) {
        throw const AIServerUnavailableException(
            message: 'Sentiment service unavailable');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AIAuthenticationException(
          message: 'Unauthorized sentiment request',
        );
      } else {
        throw AIInvalidResponseException(
          message: 'Unexpected status code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw AITimeoutException(
        message: 'Sentiment request timed out',
        timeoutMs: _config.readTimeoutMs,
      );
    } on http.ClientException catch (e) {
      throw AIServerUnavailableException(message: 'Network error: ${e.message}');
    }
  }

  Future<List<SentimentResult>> _fetchBatchAnalysis(
    SecurityContext context,
    List<SentimentAnalysisRequest> texts,
  ) async {
    final uri = Uri.parse('${_config.sentimentUrl}/analyze/sentiment/batch');
    _validateTransport(uri);

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(context),
            body: jsonEncode({
              'texts': texts.map((t) => t.toApiJson()).toList(),
            }),
          )
          .timeout(Duration(milliseconds: _config.readTimeoutMs * 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List)
            .map((r) => _parseResult(r as Map<String, dynamic>))
            .toList();
        return results;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AIAuthenticationException(
          message: 'Unauthorized batch sentiment request',
        );
      } else {
        throw AIInvalidResponseException(
          message: 'Batch analysis failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw AITimeoutException(
        message: 'Batch sentiment request timed out',
        timeoutMs: _config.readTimeoutMs * 2,
      );
    }
  }

  SentimentResult _parseResult(Map<String, dynamic> data) {
    return SentimentResult(
      id: data['id'] as String,
      businessId: data['business_id'] as String,
      clientId: data['client_id'] as String,
      source: _parseSource(data['source'] as String),
      sourceDocumentId: data['source_document_id'] as String?,
      analyzedText: data['analyzed_text'] as String,
      sentimentScore: (data['sentiment_score'] as num).toDouble(),
      confidence: (data['confidence'] as num).toDouble(),
      riskIndicators: _parseIndicators(data['risk_indicators'] as List? ?? []),
      vipIndicators: _parseIndicators(data['vip_indicators'] as List? ?? []),
      summary: data['summary'] as String?,
      recommendedAction: data['recommended_action'] as String?,
      modelVersion: data['model_version'] as String,
      analyzedAt: DateTime.parse(data['analyzed_at'] as String),
      expiresAt: DateTime.parse(data['expires_at'] as String),
      processingTimeMs: data['processing_time_ms'] as int?,
    );
  }

  SentimentSource _parseSource(String source) {
    return SentimentSource.values.firstWhere(
      (s) => s.name == source,
      orElse: () => SentimentSource.smsReply,
    );
  }

  List<RiskIndicator> _parseIndicators(List<dynamic> data) {
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return RiskIndicator(
        id: map['id'] as String,
        type: IndicatorType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => IndicatorType.neutral,
        ),
        severity: IndicatorSeverity.values.firstWhere(
          (s) => s.name == map['severity'],
          orElse: () => IndicatorSeverity.medium,
        ),
        category: map['category'] as String,
        description: map['description'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        source: _parseSource(map['source'] as String),
        sourceDocumentId: map['source_document_id'] as String?,
        triggerText: map['trigger_text'] as String?,
        detectedAt: DateTime.parse(map['detected_at'] as String),
        suggestedAction: map['suggested_action'] as String?,
      );
    }).toList();
  }

  bool _isCircuitOpen() {
    if (_consecutiveFailures < _circuitBreakerThreshold) return false;
    if (_circuitOpenedAt == null) return false;

    if (DateTime.now().difference(_circuitOpenedAt!) > _circuitResetDuration) {
      _consecutiveFailures = 0;
      _circuitOpenedAt = null;
      return false;
    }

    return true;
  }

  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _circuitBreakerThreshold &&
        _circuitOpenedAt == null) {
      _circuitOpenedAt = DateTime.now();
      debugPrint('SentimentService: Circuit breaker opened');
    }
  }

  void _resetCircuitBreaker() {
    if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
      _circuitOpenedAt = null;
    }
  }

  Future<void> _logSentimentAnalysis(
    SecurityContext context,
    SentimentAnalysisRequest text,
    SentimentResult result,
  ) async {
    // Log sentiment analysis for HIPAA compliance and audit trail
    // NOTE: We don't log the actual text content (PHI) - only metadata
    try {
      await _auditLogRepository.log(
        context: context,
        action: 'ai_sentiment_analyzed',
        entityType: 'client',
        entityId: text.clientId,
        source: 'SentimentService',
        details: {
          'source_type': text.source.name,
          'sentiment_score': result.sentimentScore,
          'confidence': result.confidence,
          'risk_indicator_count': result.riskIndicators.length,
          'vip_indicator_count': result.vipIndicators.length,
          'model_version': result.modelVersion,
          'processing_time_ms': result.processingTimeMs ?? 0,
        },
      );
    } catch (e) {
      // Audit logging should never block the primary operation
      debugPrint('SentimentService: Audit log failed (non-blocking): $e');
    }
  }

  Map<String, String> _buildHealthHeaders() {
    final token = _config.authToken;
    if (token == null || token.isEmpty) return const {};
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _buildHeaders(SecurityContext context) {
    final token = context.authToken ?? _config.authToken;
    if ((token == null || token.isEmpty) && _config.apiKey == null) {
      throw const AIAuthenticationException(
        message: 'Authentication token is required for sentiment requests',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Business-ID': context.businessId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (_config.apiKey != null) 'X-API-Key': _config.apiKey!,
    };
  }

  void _validateTransport(Uri uri) {
    if (_config.requireHttps && uri.scheme != 'https') {
      throw const AIAuthenticationException(
        message: 'HTTPS is required for sentiment requests',
      );
    }
  }
}
