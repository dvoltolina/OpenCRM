/// Configuration for AI & Predictive Intelligence services.
///
/// All AI inference runs on a local RTX 3090 server for HIPAA compliance.
/// PHI never leaves the local infrastructure.
///
/// Supports both unified (single server) and distributed (separate services)
/// deployment modes.
///
/// **HIPAA Security:**
/// - Set [apiKey] in production for authenticated access
/// - API keys should be business-scoped for tenant isolation
/// - Never hardcode API keys - use environment variables or secure storage
class AIConfig {
  const AIConfig({
    required this.baseUrl,
    this.predictionServiceUrl,
    this.sentimentServiceUrl,
    this.routeServiceUrl,
    this.apiKey,
    this.authToken,
    this.requireHttps = true,
    this.predictionEndpoint = '/api/v1/predict/noshow',
    this.sentimentEndpoint = '/api/v1/analyze/sentiment',
    this.routeEndpoint = '/api/v1/routes/optimize',
    this.healthEndpoint = '/health',
    this.connectionTimeoutMs = 5000,
    this.readTimeoutMs = 30000,
    this.writeTimeoutMs = 30000,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.retryBackoffMultiplier = 2.0,
    this.circuitBreakerThreshold = 5,
    this.circuitBreakerResetMs = 60000,
    this.highRiskThreshold = 0.7,
    this.mediumRiskThreshold = 0.4,
    this.minConfidenceScore = 0.6,
    this.predictionCacheTtlMinutes = 15,
    this.sentimentCacheTtlMinutes = 60,
    this.batchSize = 50,
    this.enableRequestLogging = false,
  });

  // ============ Server Configuration ============

  /// Base URL for the local AI server (e.g., http://localhost:8000 or VPN URL)
  /// Used as fallback when service-specific URLs are not provided.
  final String baseUrl;

  /// Optional dedicated URL for prediction service.
  /// If null, uses baseUrl + predictionEndpoint.
  final String? predictionServiceUrl;

  /// Optional dedicated URL for sentiment service.
  /// If null, uses baseUrl + sentimentEndpoint.
  final String? sentimentServiceUrl;

  /// Optional dedicated URL for route optimization service.
  /// If null, uses baseUrl + routeEndpoint.
  final String? routeServiceUrl;

  // ============ Authentication ============

  /// API key for authentication with AI services.
  ///
  /// **HIPAA:** Required in production for HIPAA compliance.
  /// The API key should be business-scoped (format: "key:business_id")
  /// to ensure proper tenant isolation on the server side.
  ///
  /// Set this from environment variables or secure storage:
  /// ```dart
  /// final config = AIConfig.production(
  ///   baseUrl: 'https://ai.example.com',
  ///   apiKey: Platform.environment['AI_API_KEY'],
  /// );
  /// ```
  final String? apiKey;

  /// Optional bearer token (tenant-scoped JWT). Preferred over apiKey.
  final String? authToken;

  /// Enforce HTTPS (disable only for local development).
  final bool requireHttps;

  /// Endpoint for no-show prediction requests
  final String predictionEndpoint;

  /// Endpoint for sentiment analysis requests
  final String sentimentEndpoint;

  /// Endpoint for route optimization requests
  final String routeEndpoint;

  /// Endpoint for health checks
  final String healthEndpoint;

  // ============ Timeout Configuration ============

  /// Connection timeout in milliseconds
  final int connectionTimeoutMs;

  /// Read timeout in milliseconds (time to wait for response)
  final int readTimeoutMs;

  /// Write timeout in milliseconds (time to wait for request to send)
  final int writeTimeoutMs;

  // ============ Retry Configuration ============

  /// Maximum number of retry attempts for failed requests
  final int maxRetries;

  /// Initial delay between retries in milliseconds
  final int retryDelayMs;

  /// Multiplier for exponential backoff (delay * multiplier^attempt)
  final double retryBackoffMultiplier;

  // ============ Circuit Breaker Configuration ============

  /// Number of consecutive failures before circuit opens
  final int circuitBreakerThreshold;

  /// Time in milliseconds before attempting to close circuit
  final int circuitBreakerResetMs;

  // ============ Prediction Thresholds ============

  /// Probability threshold for high no-show risk (0.0 - 1.0)
  final double highRiskThreshold;

  /// Probability threshold for medium no-show risk (0.0 - 1.0)
  final double mediumRiskThreshold;

  /// Minimum confidence score to display predictions (0.0 - 1.0)
  final double minConfidenceScore;

  // ============ Cache Configuration ============

  /// Time-to-live for cached predictions in minutes
  final int predictionCacheTtlMinutes;

  /// Time-to-live for cached sentiment analysis in minutes
  final int sentimentCacheTtlMinutes;

  // ============ Batch Processing ============

  /// Maximum number of items to process in a single batch request
  final int batchSize;

  // ============ Debug Configuration ============

  /// Enable detailed request/response logging (debug mode only)
  final bool enableRequestLogging;

  // ============ Computed Properties ============

  /// Full URL for prediction endpoint.
  /// Uses predictionServiceUrl if set, otherwise baseUrl + endpoint.
  String get predictionUrl =>
      predictionServiceUrl ?? '$baseUrl$predictionEndpoint';

  /// Full URL for sentiment endpoint.
  /// Uses sentimentServiceUrl if set, otherwise baseUrl + endpoint.
  String get sentimentUrl =>
      sentimentServiceUrl ?? '$baseUrl$sentimentEndpoint';

  /// Full URL for route optimization endpoint.
  /// Uses routeServiceUrl if set, otherwise baseUrl + endpoint.
  String get routeUrl => routeServiceUrl ?? '$baseUrl$routeEndpoint';

  /// Full URL for health check endpoint
  String get healthUrl => '$baseUrl$healthEndpoint';

  /// Whether using distributed services (different URLs for different services).
  bool get isDistributedDeployment =>
      predictionServiceUrl != null ||
      sentimentServiceUrl != null ||
      routeServiceUrl != null;

  /// Connection timeout as Duration
  Duration get connectionTimeout => Duration(milliseconds: connectionTimeoutMs);

  /// Read timeout as Duration
  Duration get readTimeout => Duration(milliseconds: readTimeoutMs);

  /// Write timeout as Duration
  Duration get writeTimeout => Duration(milliseconds: writeTimeoutMs);

  /// Circuit breaker reset duration
  Duration get circuitBreakerResetDuration =>
      Duration(milliseconds: circuitBreakerResetMs);

  /// Prediction cache TTL as Duration
  Duration get predictionCacheTtl =>
      Duration(minutes: predictionCacheTtlMinutes);

  /// Sentiment cache TTL as Duration
  Duration get sentimentCacheTtl => Duration(minutes: sentimentCacheTtlMinutes);

  /// Legacy cache TTL alias for backward compatibility.
  int get cacheTtlMinutes => sentimentCacheTtlMinutes;

  // ============ Factory Constructors ============

  /// Development configuration (localhost)
  factory AIConfig.development() {
    return const AIConfig(
      baseUrl: 'http://localhost:8000',
      requireHttps: false,
      enableRequestLogging: true,
    );
  }

  /// Production configuration (VPN/Tailscale URL)
  /// Override baseUrl with actual production server address
  ///
  /// **HIPAA:** [apiKey] is required in production for authenticated access.
  factory AIConfig.production({
    required String baseUrl,
    required String apiKey,
    String? authToken,
  }) {
    return AIConfig(
      baseUrl: baseUrl,
      apiKey: apiKey,
      authToken: authToken,
      enableRequestLogging: false,
      // Tighter timeouts for production
      connectionTimeoutMs: 3000,
      readTimeoutMs: 20000,
    );
  }

  /// Configuration for testing with mock server
  factory AIConfig.test() {
    return const AIConfig(
      baseUrl: 'http://localhost:8999',
      requireHttps: false,
      enableRequestLogging: true,
      maxRetries: 1,
      connectionTimeoutMs: 1000,
      readTimeoutMs: 5000,
    );
  }

  /// Configuration when AI services are disabled/unavailable
  factory AIConfig.disabled() {
    return const AIConfig(
      baseUrl: '',
      requireHttps: false,
      maxRetries: 0,
      circuitBreakerThreshold: 1,
    );
  }

  /// Hybrid cloud configuration with separate service URLs.
  ///
  /// Use this when services are deployed on different servers:
  /// - Prediction on main AI server
  /// - Sentiment on cloud GPU (RunPod, Lambda Labs)
  /// - Route optimization on separate instance
  ///
  /// **HIPAA:** [apiKey] is required in production for authenticated access.
  ///
  /// Example:
  /// ```dart
  /// final config = AIConfig.hybridCloud(
  ///   predictionUrl: 'http://localhost:8000',
  ///   sentimentUrl: 'https://runpod-xxx-8002.proxy.runpod.net',
  ///   routeUrl: 'http://localhost:8001',
  ///   apiKey: Platform.environment['AI_API_KEY'],
  /// );
  /// ```
  factory AIConfig.hybridCloud({
    String? predictionUrl,
    String? sentimentUrl,
    String? routeUrl,
    String? apiKey,
    bool enableRequestLogging = false,
  }) {
    return AIConfig(
      baseUrl: predictionUrl ?? sentimentUrl ?? routeUrl ?? '',
      predictionServiceUrl: predictionUrl,
      sentimentServiceUrl: sentimentUrl,
      routeServiceUrl: routeUrl,
      apiKey: apiKey,
      enableRequestLogging: enableRequestLogging,
    );
  }

  // ============ Validation ============

  /// Validate configuration values are within acceptable ranges.
  /// For hybrid deployments, at least one service URL must be valid.
  bool get isValid {
    final hasValidUrl = baseUrl.isNotEmpty ||
        (predictionServiceUrl?.isNotEmpty ?? false) ||
        (sentimentServiceUrl?.isNotEmpty ?? false) ||
        (routeServiceUrl?.isNotEmpty ?? false);

    return hasValidUrl &&
        highRiskThreshold > mediumRiskThreshold &&
        highRiskThreshold <= 1.0 &&
        mediumRiskThreshold >= 0.0 &&
        minConfidenceScore >= 0.0 &&
        minConfidenceScore <= 1.0 &&
        maxRetries >= 0 &&
        batchSize > 0;
  }

  /// Get validation errors if configuration is invalid
  List<String> get validationErrors {
    final errors = <String>[];

    final hasValidUrl = baseUrl.isNotEmpty ||
        (predictionServiceUrl?.isNotEmpty ?? false) ||
        (sentimentServiceUrl?.isNotEmpty ?? false) ||
        (routeServiceUrl?.isNotEmpty ?? false);

    if (!hasValidUrl) {
      errors.add(
          'At least one URL must be set (baseUrl or service-specific URLs)');
    }
    if (highRiskThreshold <= mediumRiskThreshold) {
      errors.add('highRiskThreshold must be greater than mediumRiskThreshold');
    }
    if (highRiskThreshold > 1.0 || highRiskThreshold < 0.0) {
      errors.add('highRiskThreshold must be between 0.0 and 1.0');
    }
    if (mediumRiskThreshold > 1.0 || mediumRiskThreshold < 0.0) {
      errors.add('mediumRiskThreshold must be between 0.0 and 1.0');
    }
    if (minConfidenceScore > 1.0 || minConfidenceScore < 0.0) {
      errors.add('minConfidenceScore must be between 0.0 and 1.0');
    }
    if (maxRetries < 0) {
      errors.add('maxRetries cannot be negative');
    }
    if (batchSize <= 0) {
      errors.add('batchSize must be positive');
    }
    return errors;
  }

  // ============ Risk Level Helpers ============

  /// Determine risk level from probability
  AIRiskLevel getRiskLevel(double probability) {
    if (probability >= highRiskThreshold) return AIRiskLevel.high;
    if (probability >= mediumRiskThreshold) return AIRiskLevel.medium;
    return AIRiskLevel.low;
  }

  // ============ Copy With ============

  AIConfig copyWith({
    String? baseUrl,
    String? predictionServiceUrl,
    String? sentimentServiceUrl,
    String? routeServiceUrl,
    String? apiKey,
    String? authToken,
    bool? requireHttps,
    String? predictionEndpoint,
    String? sentimentEndpoint,
    String? routeEndpoint,
    String? healthEndpoint,
    int? connectionTimeoutMs,
    int? readTimeoutMs,
    int? writeTimeoutMs,
    int? maxRetries,
    int? retryDelayMs,
    double? retryBackoffMultiplier,
    int? circuitBreakerThreshold,
    int? circuitBreakerResetMs,
    double? highRiskThreshold,
    double? mediumRiskThreshold,
    double? minConfidenceScore,
    int? predictionCacheTtlMinutes,
    int? sentimentCacheTtlMinutes,
    int? batchSize,
    bool? enableRequestLogging,
  }) {
    return AIConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      predictionServiceUrl: predictionServiceUrl ?? this.predictionServiceUrl,
      sentimentServiceUrl: sentimentServiceUrl ?? this.sentimentServiceUrl,
      routeServiceUrl: routeServiceUrl ?? this.routeServiceUrl,
      apiKey: apiKey ?? this.apiKey,
      authToken: authToken ?? this.authToken,
      requireHttps: requireHttps ?? this.requireHttps,
      predictionEndpoint: predictionEndpoint ?? this.predictionEndpoint,
      sentimentEndpoint: sentimentEndpoint ?? this.sentimentEndpoint,
      routeEndpoint: routeEndpoint ?? this.routeEndpoint,
      healthEndpoint: healthEndpoint ?? this.healthEndpoint,
      connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
      readTimeoutMs: readTimeoutMs ?? this.readTimeoutMs,
      writeTimeoutMs: writeTimeoutMs ?? this.writeTimeoutMs,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      retryBackoffMultiplier:
          retryBackoffMultiplier ?? this.retryBackoffMultiplier,
      circuitBreakerThreshold:
          circuitBreakerThreshold ?? this.circuitBreakerThreshold,
      circuitBreakerResetMs:
          circuitBreakerResetMs ?? this.circuitBreakerResetMs,
      highRiskThreshold: highRiskThreshold ?? this.highRiskThreshold,
      mediumRiskThreshold: mediumRiskThreshold ?? this.mediumRiskThreshold,
      minConfidenceScore: minConfidenceScore ?? this.minConfidenceScore,
      predictionCacheTtlMinutes:
          predictionCacheTtlMinutes ?? this.predictionCacheTtlMinutes,
      sentimentCacheTtlMinutes:
          sentimentCacheTtlMinutes ?? this.sentimentCacheTtlMinutes,
      batchSize: batchSize ?? this.batchSize,
      enableRequestLogging: enableRequestLogging ?? this.enableRequestLogging,
    );
  }

  @override
  String toString() {
    if (isDistributedDeployment) {
      return 'AIConfig.hybrid('
          'prediction: $predictionUrl, '
          'sentiment: $sentimentUrl, '
          'route: $routeUrl)';
    }
    return 'AIConfig(baseUrl: $baseUrl, '
        'predictions: $predictionEndpoint, '
        'sentiment: $sentimentEndpoint, '
        'routes: $routeEndpoint)';
  }
}

/// Risk levels for AI predictions
enum AIRiskLevel {
  /// Low risk (probability below medium threshold)
  low,

  /// Medium risk (probability between medium and high thresholds)
  medium,

  /// High risk (probability above high threshold)
  high,
}

/// Extension methods for AIRiskLevel
extension AIRiskLevelExtension on AIRiskLevel {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case AIRiskLevel.low:
        return 'Low';
      case AIRiskLevel.medium:
        return 'Medium';
      case AIRiskLevel.high:
        return 'High';
    }
  }

  /// Color value for UI (as int for cross-platform compatibility)
  int get colorValue {
    switch (this) {
      case AIRiskLevel.low:
        return 0xFF4CAF50; // Green
      case AIRiskLevel.medium:
        return 0xFFFFC107; // Amber
      case AIRiskLevel.high:
        return 0xFFF44336; // Red
    }
  }

  /// Icon name suggestion for UI
  String get iconName {
    switch (this) {
      case AIRiskLevel.low:
        return 'check_circle';
      case AIRiskLevel.medium:
        return 'warning';
      case AIRiskLevel.high:
        return 'error';
    }
  }
}
