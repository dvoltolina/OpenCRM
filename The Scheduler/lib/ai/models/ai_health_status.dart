import 'package:freezed_annotation/freezed_annotation.dart';

import 'model_metadata.dart';

part 'ai_health_status.freezed.dart';
part 'ai_health_status.g.dart';

/// Health status for individual AI services
enum AIServiceHealth {
  /// Service is operational and responding normally
  @JsonValue('healthy')
  healthy,

  /// Service is operational but experiencing issues (slow, partial failures)
  @JsonValue('degraded')
  degraded,

  /// Service is not responding or returning errors
  @JsonValue('unhealthy')
  unhealthy,

  /// Service has not been checked or is not configured
  @JsonValue('unavailable')
  unavailable,
}

/// Extension methods for AIServiceHealth
extension AIServiceHealthExtension on AIServiceHealth {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case AIServiceHealth.healthy:
        return 'Healthy';
      case AIServiceHealth.degraded:
        return 'Degraded';
      case AIServiceHealth.unhealthy:
        return 'Unhealthy';
      case AIServiceHealth.unavailable:
        return 'Unavailable';
    }
  }

  /// Color value for UI indicators
  int get colorValue {
    switch (this) {
      case AIServiceHealth.healthy:
        return 0xFF4CAF50; // Green
      case AIServiceHealth.degraded:
        return 0xFFFFC107; // Amber
      case AIServiceHealth.unhealthy:
        return 0xFFF44336; // Red
      case AIServiceHealth.unavailable:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Check if service is operational (healthy or degraded)
  bool get isOperational =>
      this == AIServiceHealth.healthy || this == AIServiceHealth.degraded;

  /// Check if service needs attention
  bool get needsAttention =>
      this == AIServiceHealth.degraded || this == AIServiceHealth.unhealthy;
}

/// Health status for an individual AI service with details
@freezed
abstract class ServiceHealthDetail with _$ServiceHealthDetail {
  const factory ServiceHealthDetail({
    /// Service name (prediction, sentiment, routing)
    required String serviceName,

    /// Current health status
    required AIServiceHealth status,

    /// Response time in milliseconds (if available)
    int? responseTimeMs,

    /// Last successful request timestamp
    DateTime? lastSuccessAt,

    /// Last error timestamp
    DateTime? lastErrorAt,

    /// Last error message (if any)
    String? lastErrorMessage,

    /// Number of consecutive failures
    @Default(0) int consecutiveFailures,

    /// Whether circuit breaker is open
    @Default(false) bool circuitBreakerOpen,

    /// Number of requests in the last minute
    @Default(0) int requestsLastMinute,

    /// Number of errors in the last minute
    @Default(0) int errorsLastMinute,
  }) = _ServiceHealthDetail;

  factory ServiceHealthDetail.fromJson(Map<String, dynamic> json) =>
      _$ServiceHealthDetailFromJson(json);

  const ServiceHealthDetail._();

  /// Error rate percentage (0-100)
  double get errorRate {
    if (requestsLastMinute == 0) return 0.0;
    return (errorsLastMinute / requestsLastMinute) * 100;
  }

  /// Check if error rate is acceptable (< 5%)
  bool get hasAcceptableErrorRate => errorRate < 5.0;

  /// Check if response time is acceptable (< 500ms)
  bool get hasAcceptableResponseTime =>
      responseTimeMs == null || responseTimeMs! < 500;
}

/// Comprehensive health status for all AI services
@freezed
abstract class AIHealthStatus with _$AIHealthStatus {
  const factory AIHealthStatus({
    /// Overall health across all services
    required AIServiceHealth overallStatus,

    /// Prediction service health details
    required ServiceHealthDetail predictionService,

    /// Sentiment service health details
    required ServiceHealthDetail sentimentService,

    /// Routing service health details
    required ServiceHealthDetail routingService,

    /// When this health check was performed
    DateTime? lastHealthCheck,

    /// Last successful prediction timestamp (any service)
    DateTime? lastSuccessfulPrediction,

    /// Overall error message if unhealthy
    String? errorMessage,

    /// Currently loaded models
    required LoadedModels loadedModels,

    /// Server version (if reported)
    String? serverVersion,

    /// Server uptime in seconds
    int? serverUptimeSeconds,

    /// GPU availability status
    @Default(false) bool gpuAvailable,

    /// GPU memory usage percentage (0-100)
    double? gpuMemoryUsagePercent,
  }) = _AIHealthStatus;

  factory AIHealthStatus.fromJson(Map<String, dynamic> json) =>
      _$AIHealthStatusFromJson(json);

  /// Create an unavailable status (when server can't be reached)
  factory AIHealthStatus.unavailable({String? errorMessage}) {
    return AIHealthStatus(
      overallStatus: AIServiceHealth.unavailable,
      predictionService: const ServiceHealthDetail(
        serviceName: 'prediction',
        status: AIServiceHealth.unavailable,
      ),
      sentimentService: const ServiceHealthDetail(
        serviceName: 'sentiment',
        status: AIServiceHealth.unavailable,
      ),
      routingService: const ServiceHealthDetail(
        serviceName: 'routing',
        status: AIServiceHealth.unavailable,
      ),
      loadedModels: const LoadedModels(),
      errorMessage: errorMessage,
    );
  }

  const AIHealthStatus._();

  /// Check if AI services are operational
  bool get isOperational => overallStatus.isOperational;

  /// Check if all services are healthy
  bool get allServicesHealthy =>
      predictionService.status == AIServiceHealth.healthy &&
      sentimentService.status == AIServiceHealth.healthy &&
      routingService.status == AIServiceHealth.healthy;

  /// Check if at least one service is healthy
  bool get hasAnyHealthyService =>
      predictionService.status == AIServiceHealth.healthy ||
      sentimentService.status == AIServiceHealth.healthy ||
      routingService.status == AIServiceHealth.healthy;

  /// Get list of services that need attention
  List<String> get servicesNeedingAttention {
    final services = <String>[];
    if (predictionService.status.needsAttention) {
      services.add('prediction');
    }
    if (sentimentService.status.needsAttention) {
      services.add('sentiment');
    }
    if (routingService.status.needsAttention) {
      services.add('routing');
    }
    return services;
  }

  /// Calculate overall status from individual service statuses
  static AIServiceHealth calculateOverallStatus({
    required AIServiceHealth prediction,
    required AIServiceHealth sentiment,
    required AIServiceHealth routing,
  }) {
    final statuses = [prediction, sentiment, routing];

    // If all unavailable, overall is unavailable
    if (statuses.every((s) => s == AIServiceHealth.unavailable)) {
      return AIServiceHealth.unavailable;
    }

    // If any unhealthy, overall is unhealthy
    if (statuses.any((s) => s == AIServiceHealth.unhealthy)) {
      return AIServiceHealth.unhealthy;
    }

    // If any degraded, overall is degraded
    if (statuses.any((s) => s == AIServiceHealth.degraded)) {
      return AIServiceHealth.degraded;
    }

    // If at least one is healthy and rest are unavailable, degraded
    final healthyCount =
        statuses.where((s) => s == AIServiceHealth.healthy).length;
    if (healthyCount < statuses.length &&
        statuses.any((s) => s == AIServiceHealth.unavailable)) {
      return AIServiceHealth.degraded;
    }

    return AIServiceHealth.healthy;
  }

  /// Time since last health check
  Duration? get timeSinceLastCheck {
    if (lastHealthCheck == null) return null;
    return DateTime.now().difference(lastHealthCheck!);
  }

  /// Check if health data is stale (older than 1 minute)
  bool get isStale {
    final elapsed = timeSinceLastCheck;
    return elapsed == null || elapsed.inMinutes >= 1;
  }

  /// Server uptime as Duration
  Duration? get serverUptime {
    if (serverUptimeSeconds == null) return null;
    return Duration(seconds: serverUptimeSeconds!);
  }

  /// Human-readable uptime string
  String? get uptimeDisplay {
    final uptime = serverUptime;
    if (uptime == null) return null;

    if (uptime.inDays > 0) {
      return '${uptime.inDays}d ${uptime.inHours % 24}h';
    } else if (uptime.inHours > 0) {
      return '${uptime.inHours}h ${uptime.inMinutes % 60}m';
    } else {
      return '${uptime.inMinutes}m';
    }
  }
}

/// Convenience helpers for service health detail values.
extension ServiceHealthDetailX on ServiceHealthDetail {
  /// True when the service reports a healthy status.
  bool get isHealthy => status == AIServiceHealth.healthy;

  /// True when the service is at least operational (healthy or degraded).
  bool get isOperational => status.isOperational;
}
