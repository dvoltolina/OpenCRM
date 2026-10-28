/// Base exception for all AI-related errors.
///
/// All AI exceptions include context information for debugging and logging.
class AIException implements Exception {
  const AIException({
    required this.message,
    this.endpoint,
    this.requestId,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error message
  final String message;

  /// API endpoint that was called (if applicable)
  final String? endpoint;

  /// Request ID for tracing (if available from server)
  final String? requestId;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Original exception that caused this error
  final Object? originalError;

  /// Stack trace from the original error
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('AIException: $message');
    if (endpoint != null) buffer.write(' [endpoint: $endpoint]');
    if (statusCode != null) buffer.write(' [status: $statusCode]');
    if (requestId != null) buffer.write(' [requestId: $requestId]');
    return buffer.toString();
  }

  /// Convert to map for logging
  Map<String, dynamic> toLogMap() {
    return {
      'type': runtimeType.toString(),
      'message': message,
      if (endpoint != null) 'endpoint': endpoint,
      if (requestId != null) 'requestId': requestId,
      if (statusCode != null) 'statusCode': statusCode,
      if (originalError != null) 'originalError': originalError.toString(),
    };
  }
}

/// Exception thrown when AI server is not reachable or not responding.
class AIServerUnavailableException extends AIException {
  const AIServerUnavailableException({
    String message = 'AI server is unavailable',
    super.endpoint,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  @override
  String toString() => 'AIServerUnavailableException: $message';
}

/// Exception thrown when a request times out.
class AITimeoutException extends AIException {
  const AITimeoutException({
    String message = 'AI request timed out',
    required this.timeoutMs,
    super.endpoint,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// Timeout value that was exceeded (in milliseconds)
  final int timeoutMs;

  @override
  String toString() =>
      'AITimeoutException: $message (timeout: ${timeoutMs}ms)';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'timeoutMs': timeoutMs,
    };
  }
}

/// Exception thrown when server returns an invalid or unexpected response.
class AIInvalidResponseException extends AIException {
  const AIInvalidResponseException({
    String message = 'Invalid response from AI server',
    super.endpoint,
    super.requestId,
    super.statusCode,
    this.responseBody,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// Raw response body (if available, may be truncated)
  final String? responseBody;

  @override
  String toString() =>
      'AIInvalidResponseException: $message [status: $statusCode]';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      if (responseBody != null)
        'responseBody': responseBody!.length > 500
            ? '${responseBody!.substring(0, 500)}...'
            : responseBody,
    };
  }
}

/// Exception thrown when feature extraction fails.
class AIFeatureExtractionException extends AIException {
  const AIFeatureExtractionException({
    String message = 'Failed to extract features for prediction',
    required this.missingFields,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// List of required fields that were missing or invalid
  final List<String> missingFields;

  @override
  String toString() =>
      'AIFeatureExtractionException: $message (missing: ${missingFields.join(', ')})';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'missingFields': missingFields,
    };
  }
}

/// Exception thrown when required ML model is not loaded.
class AIModelNotLoadedException extends AIException {
  const AIModelNotLoadedException({
    String message = 'Required AI model is not loaded',
    required this.modelType,
    super.endpoint,
    super.requestId,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// Type of model that was not loaded
  final String modelType;

  @override
  String toString() =>
      'AIModelNotLoadedException: $message (model: $modelType)';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'modelType': modelType,
    };
  }
}

/// Exception thrown when circuit breaker is open (too many failures).
class AICircuitBreakerOpenException extends AIException {
  const AICircuitBreakerOpenException({
    String message = 'Circuit breaker is open due to repeated failures',
    required this.resetTime,
    super.endpoint,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// When the circuit breaker will attempt to close
  final DateTime resetTime;

  @override
  String toString() =>
      'AICircuitBreakerOpenException: $message (resets at: $resetTime)';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'resetTime': resetTime.toIso8601String(),
    };
  }

  /// Time until circuit breaker resets
  Duration get timeUntilReset {
    final now = DateTime.now();
    if (resetTime.isBefore(now)) return Duration.zero;
    return resetTime.difference(now);
  }
}

/// Exception thrown when rate limit is exceeded.
class AIRateLimitException extends AIException {
  const AIRateLimitException({
    String message = 'AI request rate limit exceeded',
    required this.retryAfterMs,
    super.endpoint,
    super.requestId,
    super.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  /// Time to wait before retrying (in milliseconds)
  final int retryAfterMs;

  @override
  String toString() =>
      'AIRateLimitException: $message (retry after: ${retryAfterMs}ms)';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'retryAfterMs': retryAfterMs,
    };
  }
}

/// Exception thrown when authentication/authorization fails.
class AIAuthenticationException extends AIException {
  const AIAuthenticationException({
    String message = 'AI server authentication failed',
    super.endpoint,
    super.requestId,
    super.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(message: message);

  @override
  String toString() => 'AIAuthenticationException: $message';
}

/// Exception thrown when server returns an error response.
class AIServerErrorException extends AIException {
  const AIServerErrorException({
    required super.message,
    required this.errorCode,
    super.endpoint,
    super.requestId,
    super.statusCode,
    this.details,
    super.originalError,
    super.stackTrace,
  });

  /// Server-provided error code
  final String errorCode;

  /// Additional error details from server
  final Map<String, dynamic>? details;

  @override
  String toString() =>
      'AIServerErrorException: $message [code: $errorCode, status: $statusCode]';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'errorCode': errorCode,
      if (details != null) 'details': details,
    };
  }
}

/// Exception thrown when feature flags disable AI functionality.
class AIFeatureDisabledException extends AIException {
  const AIFeatureDisabledException({
    required this.featureName,
  }) : super(message: 'AI feature "$featureName" is disabled');

  /// Name of the disabled feature
  final String featureName;

  @override
  String toString() =>
      'AIFeatureDisabledException: $featureName is disabled';

  @override
  Map<String, dynamic> toLogMap() {
    return {
      ...super.toLogMap(),
      'featureName': featureName,
    };
  }
}
