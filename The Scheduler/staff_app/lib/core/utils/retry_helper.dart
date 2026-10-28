// Retry Logic with Exponential Backoff
//
// Provides robust retry logic for network operations and other
// fallible async operations. Essential for reliable offline-first apps.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Configuration for retry behavior.
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitter = true,
    this.retryIf,
  });

  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Initial delay before first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Whether to add random jitter to delays.
  final bool jitter;

  /// Custom predicate to determine if an exception should be retried.
  /// If null, all exceptions are retried.
  final bool Function(Exception)? retryIf;

  /// Default configuration for network operations.
  static const network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
    jitter: true,
  );

  /// Aggressive retry for critical operations.
  static const critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 60),
    backoffMultiplier: 2.0,
    jitter: true,
  );

  /// Quick retry for fast-failing operations.
  static const quick = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    jitter: false,
  );
}

/// Result of a retry operation.
class RetryResult<T> {
  const RetryResult._({
    required this.success,
    this.value,
    this.error,
    required this.attempts,
    required this.totalDuration,
  });

  factory RetryResult.success(T value, int attempts, Duration duration) {
    return RetryResult._(
      success: true,
      value: value,
      attempts: attempts,
      totalDuration: duration,
    );
  }

  factory RetryResult.failure(Object error, int attempts, Duration duration) {
    return RetryResult._(
      success: false,
      error: error,
      attempts: attempts,
      totalDuration: duration,
    );
  }

  /// Whether the operation eventually succeeded.
  final bool success;

  /// The result value if successful.
  final T? value;

  /// The final error if failed.
  final Object? error;

  /// Number of attempts made.
  final int attempts;

  /// Total time spent including delays.
  final Duration totalDuration;

  /// Get value or throw error.
  T get valueOrThrow {
    if (success) return value as T;
    throw error!;
  }
}

/// Retry helper for async operations.
class RetryHelper {
  RetryHelper._();

  static final _random = Random();

  /// Execute an async operation with retry logic.
  ///
  /// Returns [RetryResult] containing the outcome.
  static Future<RetryResult<T>> execute<T>({
    required Future<T> Function() action,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error, Duration nextDelay)? onRetry,
  }) async {
    final stopwatch = Stopwatch()..start();
    Object? lastError;

    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        final result = await action();
        stopwatch.stop();
        return RetryResult.success(result, attempt, stopwatch.elapsed);
      } catch (e) {
        lastError = e;

        // Check if we should retry this exception
        if (e is Exception && config.retryIf != null && !config.retryIf!(e)) {
          stopwatch.stop();
          return RetryResult.failure(e, attempt, stopwatch.elapsed);
        }

        // Check if we have more attempts
        if (attempt >= config.maxAttempts) {
          stopwatch.stop();
          return RetryResult.failure(e, attempt, stopwatch.elapsed);
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt, config);

        debugPrint(
          'Retry attempt $attempt/${config.maxAttempts} failed: $e. '
          'Retrying in ${delay.inMilliseconds}ms',
        );

        onRetry?.call(attempt, e, delay);

        await Future.delayed(delay);
      }
    }

    stopwatch.stop();
    return RetryResult.failure(
      lastError ?? Exception('Unknown error'),
      config.maxAttempts,
      stopwatch.elapsed,
    );
  }

  /// Execute with retry and return value directly (throws on failure).
  static Future<T> withRetry<T>({
    required Future<T> Function() action,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error, Duration nextDelay)? onRetry,
  }) async {
    final result = await execute(
      action: action,
      config: config,
      onRetry: onRetry,
    );
    return result.valueOrThrow;
  }

  /// Calculate delay for a given attempt.
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Exponential backoff: initialDelay * (multiplier ^ (attempt - 1))
    final exponentialMs =
        config.initialDelay.inMilliseconds *
        pow(config.backoffMultiplier, attempt - 1);

    // Cap at maxDelay
    var delayMs = min(exponentialMs.toInt(), config.maxDelay.inMilliseconds);

    // Add jitter (±25% randomness)
    if (config.jitter) {
      final jitterRange = delayMs * 0.25;
      final jitterOffset = (_random.nextDouble() - 0.5) * 2 * jitterRange;
      delayMs = (delayMs + jitterOffset).toInt();
    }

    return Duration(milliseconds: max(delayMs, 0));
  }
}

/// Extension for easy retry on Future.
extension RetryExtension<T> on Future<T> Function() {
  /// Retry this function with the given configuration.
  Future<T> withRetry({
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error, Duration nextDelay)? onRetry,
  }) {
    return RetryHelper.withRetry(
      action: this,
      config: config,
      onRetry: onRetry,
    );
  }

  /// Retry this function and get detailed result.
  Future<RetryResult<T>> withRetryResult({
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error, Duration nextDelay)? onRetry,
  }) {
    return RetryHelper.execute(
      action: this,
      config: config,
      onRetry: onRetry,
    );
  }
}

/// Common retry predicates.
class RetryPredicates {
  RetryPredicates._();

  /// Retry on network errors only.
  static bool networkErrors(Exception e) {
    final message = e.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('network') ||
        message.contains('host');
  }

  /// Retry on server errors (5xx).
  static bool serverErrors(Exception e) {
    final message = e.toString();
    return message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504');
  }

  /// Retry on transient errors (network + server).
  static bool transientErrors(Exception e) {
    return networkErrors(e) || serverErrors(e);
  }

  /// Never retry (fail immediately).
  static bool never(Exception e) => false;
}
