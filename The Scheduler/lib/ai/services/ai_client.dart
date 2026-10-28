import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/config/ai_config.dart';
import '../models/ai_exceptions.dart';
import '../models/ai_health_status.dart';
import '../models/model_metadata.dart';

/// HTTP client for communicating with the local AI server.
///
/// Features:
/// - Configurable timeouts
/// - Automatic retry with exponential backoff
/// - Circuit breaker pattern for failing services
/// - Request ID tracking for debugging
/// - Health check support
/// - X-Business-ID header for HIPAA multi-tenant isolation
///
/// All AI inference runs on the local RTX 3090 server for HIPAA compliance.
class AIClient {
  AIClient({
    required AIConfig config,
    http.Client? httpClient,
    String? businessId,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _businessId = businessId,
        _uuid = const Uuid();

  final AIConfig _config;
  final http.Client _httpClient;
  final String? _businessId;
  final Uuid _uuid;

  /// Update business ID for tenant isolation.
  /// Call this when user changes business context.
  AIClient withBusinessId(String businessId) {
    return AIClient(
      config: _config,
      httpClient: _httpClient,
      businessId: businessId,
    );
  }

  // Circuit breaker state
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenedAt;

  // Health tracking
  DateTime? _lastSuccessAt;
  DateTime? _lastErrorAt;
  String? _lastErrorMessage;

  /// Whether the circuit breaker is currently open
  bool get isCircuitOpen {
    if (_circuitOpenedAt == null) return false;

    final elapsed = DateTime.now().difference(_circuitOpenedAt!);
    if (elapsed >= _config.circuitBreakerResetDuration) {
      // Circuit has been open long enough, try to close it
      _circuitOpenedAt = null;
      _consecutiveFailures = 0;
      debugPrint('AIClient: Circuit breaker reset, attempting to close');
      return false;
    }
    return true;
  }

  /// Time when circuit breaker will reset (null if not open)
  DateTime? get circuitResetTime {
    if (_circuitOpenedAt == null) return null;
    return _circuitOpenedAt!.add(_config.circuitBreakerResetDuration);
  }

  /// Execute a POST request with retry and circuit breaker logic
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    int? timeoutMs,
    Map<String, String>? additionalHeaders,
  }) async {
    // Check circuit breaker
    if (isCircuitOpen) {
      throw AICircuitBreakerOpenException(
        resetTime: circuitResetTime!,
        endpoint: endpoint,
      );
    }

    final requestId = _uuid.v4();
    final uri = Uri.parse('${_config.baseUrl}$endpoint');
    _validateTransport(uri);
    final timeout = Duration(milliseconds: timeoutMs ?? _config.readTimeoutMs);

    if (_config.enableRequestLogging) {
      debugPrint('AIClient [$requestId] POST $uri');
      debugPrint('AIClient [$requestId] Body: ${jsonEncode(body)}');
    }

    Exception? lastException;

    for (var attempt = 0; attempt <= _config.maxRetries; attempt++) {
      try {
        final response = await _executeRequest(
          url: uri.toString(),
          body: body,
          timeout: timeout,
          requestId: requestId,
          additionalHeaders: additionalHeaders,
        );

        // Success - reset circuit breaker
        _recordSuccess();
        return response;
      } on AIServerUnavailableException catch (e) {
        lastException = e;
        _recordFailure(e.message);

        // Don't retry server unavailable
        break;
      } on AITimeoutException catch (e) {
        lastException = e;
        _recordFailure(e.message);

        // Retry timeouts
        if (attempt < _config.maxRetries) {
          await _waitForRetry(attempt);
          continue;
        }
      } on AIRateLimitException catch (e) {
        lastException = e;
        // Don't count rate limits as failures for circuit breaker
        // Wait and retry
        if (attempt < _config.maxRetries) {
          await Future.delayed(Duration(milliseconds: e.retryAfterMs));
          continue;
        }
      } on AIServerErrorException catch (e) {
        lastException = e;
        _recordFailure(e.message);

        // Retry 5xx errors
        if (e.statusCode != null &&
            e.statusCode! >= 500 &&
            attempt < _config.maxRetries) {
          await _waitForRetry(attempt);
          continue;
        }
        break;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        _recordFailure(e.toString());

        if (attempt < _config.maxRetries) {
          await _waitForRetry(attempt);
          continue;
        }
      }
    }

    throw lastException ??
        AIException(message: 'Request failed', endpoint: uri.toString());
  }

  /// Execute a GET request (typically for health checks)
  Future<Map<String, dynamic>> get(
    String endpoint, {
    int? timeoutMs,
    Map<String, String>? additionalHeaders,
  }) async {
    final requestId = _uuid.v4();
    final uri = Uri.parse('${_config.baseUrl}$endpoint');
    _validateTransport(uri);
    final timeout = Duration(milliseconds: timeoutMs ?? _config.readTimeoutMs);

    if (_config.enableRequestLogging) {
      debugPrint('AIClient [$requestId] GET $uri');
    }

    try {
      final response = await _httpClient
          .get(
            uri,
            headers: _buildHeaders(requestId, additionalHeaders),
          )
          .timeout(timeout);

      return _parseResponse(response, uri.toString(), requestId);
    } on TimeoutException {
      throw AITimeoutException(
        timeoutMs: timeout.inMilliseconds,
        endpoint: uri.toString(),
        requestId: requestId,
      );
    } catch (e) {
      throw AIServerUnavailableException(
        endpoint: uri.toString(),
        requestId: requestId,
        originalError: e,
      );
    }
  }

  /// Check the health of the AI server
  Future<AIHealthStatus> checkHealth() async {
    try {
      final response = await get(
        _config.healthEndpoint,
        timeoutMs: _config.connectionTimeoutMs,
      );

      return _parseHealthResponse(response);
    } on AIException catch (e) {
      debugPrint('AIClient: Health check failed: ${e.message}');
      return AIHealthStatus.unavailable(errorMessage: e.message);
    } catch (e) {
      debugPrint('AIClient: Health check failed: $e');
      return AIHealthStatus.unavailable(errorMessage: e.toString());
    }
  }

  /// Get current client statistics
  AIClientStats get stats => AIClientStats(
        consecutiveFailures: _consecutiveFailures,
        circuitOpen: isCircuitOpen,
        circuitResetTime: circuitResetTime,
        lastSuccessAt: _lastSuccessAt,
        lastErrorAt: _lastErrorAt,
        lastErrorMessage: _lastErrorMessage,
      );

  /// Reset circuit breaker manually (use with caution)
  void resetCircuitBreaker() {
    _consecutiveFailures = 0;
    _circuitOpenedAt = null;
    debugPrint('AIClient: Circuit breaker manually reset');
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }

  // ============ Private Methods ============

  Future<Map<String, dynamic>> _executeRequest({
    required String url,
    required Map<String, dynamic> body,
    required Duration timeout,
    required String requestId,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: _buildHeaders(requestId, additionalHeaders),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _parseResponse(response, url, requestId);
    } on TimeoutException {
      throw AITimeoutException(
        timeoutMs: timeout.inMilliseconds,
        endpoint: url,
        requestId: requestId,
      );
    } on http.ClientException catch (e) {
      throw AIServerUnavailableException(
        endpoint: url,
        requestId: requestId,
        originalError: e,
      );
    }
  }

  Map<String, String> _buildHeaders(
    String requestId,
    Map<String, String>? additional,
  ) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Request-ID': requestId,
      // HIPAA: Include API key for authenticated access
      if (_config.apiKey != null) 'X-API-Key': _config.apiKey!,
      if (_config.authToken != null)
        'Authorization': 'Bearer ${_config.authToken}',
      // HIPAA: Multi-tenant isolation via business ID header
      if (_businessId != null) 'X-Business-ID': _businessId!,
      ...?additional,
    };
  }

  Map<String, dynamic> _parseResponse(
    http.Response response,
    String endpoint,
    String requestId,
  ) {
    if (_config.enableRequestLogging) {
      debugPrint('AIClient [$requestId] Response: ${response.statusCode}');
      debugPrint('AIClient [$requestId] Body: ${response.body}');
    }

    // Handle rate limiting
    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      throw AIRateLimitException(
        retryAfterMs: retryAfter != null ? int.parse(retryAfter) * 1000 : 5000,
        endpoint: endpoint,
        requestId: requestId,
        statusCode: 429,
      );
    }

    // Handle auth errors
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIAuthenticationException(
        endpoint: endpoint,
        requestId: requestId,
        statusCode: response.statusCode,
      );
    }

    // Handle server errors
    if (response.statusCode >= 500) {
      throw AIServerErrorException(
        message: 'Server error',
        errorCode: 'SERVER_ERROR',
        endpoint: endpoint,
        requestId: requestId,
        statusCode: response.statusCode,
      );
    }

    // Handle client errors
    if (response.statusCode >= 400) {
      Map<String, dynamic>? errorBody;
      try {
        errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      throw AIServerErrorException(
        message: errorBody?['message'] as String? ?? 'Request failed',
        errorCode: errorBody?['code'] as String? ?? 'CLIENT_ERROR',
        endpoint: endpoint,
        requestId: requestId,
        statusCode: response.statusCode,
        details: errorBody,
      );
    }

    // Parse successful response
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw AIInvalidResponseException(
        message: 'Expected JSON object, got ${data.runtimeType}',
        endpoint: endpoint,
        requestId: requestId,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIInvalidResponseException(
        message: 'Failed to parse response: $e',
        endpoint: endpoint,
        requestId: requestId,
        statusCode: response.statusCode,
        responseBody: response.body,
        originalError: e,
      );
    }
  }

  AIHealthStatus _parseHealthResponse(Map<String, dynamic> response) {
    // Parse individual service statuses
    final predictionStatus = _parseServiceHealth(
      response['prediction'] as Map<String, dynamic>?,
      'prediction',
    );
    final sentimentStatus = _parseServiceHealth(
      response['sentiment'] as Map<String, dynamic>?,
      'sentiment',
    );
    final routingStatus = _parseServiceHealth(
      response['routing'] as Map<String, dynamic>?,
      'routing',
    );

    // Parse loaded models
    final modelsData = response['models'] as Map<String, dynamic>?;
    final loadedModels = LoadedModels(
      predictionModel: modelsData?['prediction'] != null
          ? ModelMetadata.fromJson(
              modelsData!['prediction'] as Map<String, dynamic>)
          : null,
      sentimentModel: modelsData?['sentiment'] != null
          ? ModelMetadata.fromJson(
              modelsData!['sentiment'] as Map<String, dynamic>)
          : null,
      routeModel: modelsData?['routing'] != null
          ? ModelMetadata.fromJson(
              modelsData!['routing'] as Map<String, dynamic>)
          : null,
      lastRefreshed: DateTime.now(),
    );

    // Calculate overall status
    final overallStatus = AIHealthStatus.calculateOverallStatus(
      prediction: predictionStatus.status,
      sentiment: sentimentStatus.status,
      routing: routingStatus.status,
    );

    return AIHealthStatus(
      overallStatus: overallStatus,
      predictionService: predictionStatus,
      sentimentService: sentimentStatus,
      routingService: routingStatus,
      lastHealthCheck: DateTime.now(),
      loadedModels: loadedModels,
      serverVersion: response['version'] as String?,
      serverUptimeSeconds: response['uptime_seconds'] as int?,
      gpuAvailable: response['gpu_available'] as bool? ?? false,
      gpuMemoryUsagePercent: (response['gpu_memory_percent'] as num?)?.toDouble(),
    );
  }

  ServiceHealthDetail _parseServiceHealth(
    Map<String, dynamic>? data,
    String serviceName,
  ) {
    if (data == null) {
      return ServiceHealthDetail(
        serviceName: serviceName,
        status: AIServiceHealth.unavailable,
      );
    }

    final statusStr = data['status'] as String? ?? 'unavailable';
    final status = AIServiceHealth.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AIServiceHealth.unavailable,
    );

    return ServiceHealthDetail(
      serviceName: serviceName,
      status: status,
      responseTimeMs: data['response_time_ms'] as int?,
      consecutiveFailures: data['consecutive_failures'] as int? ?? 0,
      circuitBreakerOpen: data['circuit_breaker_open'] as bool? ?? false,
    );
  }

  void _recordSuccess() {
    _consecutiveFailures = 0;
    _lastSuccessAt = DateTime.now();
    if (_circuitOpenedAt != null) {
      debugPrint('AIClient: Circuit breaker closed after successful request');
      _circuitOpenedAt = null;
    }
  }

  void _recordFailure(String message) {
    _consecutiveFailures++;
    _lastErrorAt = DateTime.now();
    _lastErrorMessage = message;

    if (_consecutiveFailures >= _config.circuitBreakerThreshold) {
      _circuitOpenedAt = DateTime.now();
      debugPrint(
        'AIClient: Circuit breaker opened after $_consecutiveFailures failures',
      );
    }
  }

  Future<void> _waitForRetry(int attempt) async {
    final delay = _calculateBackoff(attempt);
    if (_config.enableRequestLogging) {
      debugPrint('AIClient: Waiting ${delay.inMilliseconds}ms before retry $attempt');
    }
    await Future.delayed(delay);
  }

  Duration _calculateBackoff(int attempt) {
    final baseDelay = _config.retryDelayMs;
    final multiplier = pow(_config.retryBackoffMultiplier, attempt);
    final delayMs = (baseDelay * multiplier).round();
    // Cap at 30 seconds
    return Duration(milliseconds: min(delayMs, 30000));
  }

  void _validateTransport(Uri uri) {
    if (_config.requireHttps && uri.scheme != 'https') {
      throw const AIAuthenticationException(
        message: 'HTTPS is required for AI requests',
      );
    }
  }
}

/// Statistics about the AI client's state
class AIClientStats {
  const AIClientStats({
    required this.consecutiveFailures,
    required this.circuitOpen,
    this.circuitResetTime,
    this.lastSuccessAt,
    this.lastErrorAt,
    this.lastErrorMessage,
  });

  final int consecutiveFailures;
  final bool circuitOpen;
  final DateTime? circuitResetTime;
  final DateTime? lastSuccessAt;
  final DateTime? lastErrorAt;
  final String? lastErrorMessage;

  Map<String, dynamic> toJson() => {
        'consecutiveFailures': consecutiveFailures,
        'circuitOpen': circuitOpen,
        if (circuitResetTime != null)
          'circuitResetTime': circuitResetTime!.toIso8601String(),
        if (lastSuccessAt != null)
          'lastSuccessAt': lastSuccessAt!.toIso8601String(),
        if (lastErrorAt != null)
          'lastErrorAt': lastErrorAt!.toIso8601String(),
        if (lastErrorMessage != null) 'lastErrorMessage': lastErrorMessage,
      };
}
