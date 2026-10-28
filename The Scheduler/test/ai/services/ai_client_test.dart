@Tags(['ai'])
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:the_scheduler/ai/models/ai_exceptions.dart';
import 'package:the_scheduler/ai/models/ai_health_status.dart';
import 'package:the_scheduler/ai/services/ai_client.dart';
import 'package:the_scheduler/core/config/ai_config.dart';

void main() {
  group('AIClient', () {
    late AIConfig config;

    setUp(() {
      config = AIConfig.test();
    });

    group('POST requests', () {
      test('sends request with correct headers and body', () async {
        String? capturedBody;
        Map<String, String>? capturedHeaders;

        final mockClient = MockClient((request) async {
          capturedBody = request.body;
          capturedHeaders = request.headers;
          return http.Response(
            jsonEncode({'result': 'success'}),
            200,
          );
        });

        final aiClient = AIClient(
          config: config,
          httpClient: mockClient,
        );

        final result = await aiClient.post(
          '/api/v1/predict/noshow',
          {'appointment_id': '123'},
        );

        expect(result['result'], 'success');
        expect(capturedHeaders?['Content-Type'], 'application/json');
        expect(capturedHeaders?['Accept'], 'application/json');
        expect(capturedHeaders?['X-Request-ID'], isNotNull);
        expect(capturedBody, jsonEncode({'appointment_id': '123'}));

        aiClient.close();
      });

      test('returns parsed JSON response on success', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'probability': 0.75,
              'risk_level': 'high',
              'confidence': 0.85,
            }),
            200,
          );
        });

        final aiClient = AIClient(
          config: config,
          httpClient: mockClient,
        );

        final result = await aiClient.post('/predict', {});

        expect(result['probability'], 0.75);
        expect(result['risk_level'], 'high');
        expect(result['confidence'], 0.85);

        aiClient.close();
      });

      test('throws AITimeoutException on timeout', () async {
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(seconds: 5));
          return http.Response('{}', 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            readTimeoutMs: 100,
            maxRetries: 0,
          ),
          httpClient: mockClient,
        );

        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AITimeoutException>()),
        );

        aiClient.close();
      });

      test('throws AIServerErrorException on 500 error', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'error': 'Internal server error'}),
            500,
          );
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 0),
          httpClient: mockClient,
        );

        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AIServerErrorException>()),
        );

        aiClient.close();
      });

      test('throws AIRateLimitException on 429 error', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '',
            429,
            headers: {'retry-after': '5'},
          );
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 0),
          httpClient: mockClient,
        );

        try {
          await aiClient.post('/predict', {});
          fail('Should have thrown AIRateLimitException');
        } on AIRateLimitException catch (e) {
          expect(e.retryAfterMs, 5000);
        }

        aiClient.close();
      });

      test('throws AIAuthenticationException on 401 error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 0),
          httpClient: mockClient,
        );

        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AIAuthenticationException>()),
        );

        aiClient.close();
      });

      test('throws AIInvalidResponseException on invalid JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('not valid json', 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 0),
          httpClient: mockClient,
        );

        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AIInvalidResponseException>()),
        );

        aiClient.close();
      });
    });

    group('Retry behavior', () {
      test('retries on timeout up to maxRetries', () async {
        var attempts = 0;

        final mockClient = MockClient((request) async {
          attempts++;
          if (attempts < 3) {
            await Future.delayed(const Duration(seconds: 5));
          }
          return http.Response(jsonEncode({'success': true}), 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            readTimeoutMs: 100,
            maxRetries: 3,
            retryDelayMs: 10,
          ),
          httpClient: mockClient,
        );

        final result = await aiClient.post('/predict', {});
        expect(result['success'], true);
        expect(attempts, 3);

        aiClient.close();
      });

      test('retries on 500 error up to maxRetries', () async {
        var attempts = 0;

        final mockClient = MockClient((request) async {
          attempts++;
          if (attempts < 2) {
            return http.Response('Server Error', 500);
          }
          return http.Response(jsonEncode({'success': true}), 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            maxRetries: 3,
            retryDelayMs: 10,
          ),
          httpClient: mockClient,
        );

        final result = await aiClient.post('/predict', {});
        expect(result['success'], true);
        expect(attempts, 2);

        aiClient.close();
      });

      test('does not retry on 400 client error', () async {
        var attempts = 0;

        final mockClient = MockClient((request) async {
          attempts++;
          return http.Response(
            jsonEncode({'error': 'Bad request'}),
            400,
          );
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 3),
          httpClient: mockClient,
        );

        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AIServerErrorException>()),
        );

        // Wait for any async operations
        await Future.delayed(const Duration(milliseconds: 100));
        expect(attempts, 1);

        aiClient.close();
      });
    });

    group('Circuit breaker', () {
      test('opens circuit after threshold failures', () async {
        var attempts = 0;

        final mockClient = MockClient((request) async {
          attempts++;
          return http.Response('Server Error', 500);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            maxRetries: 0,
            circuitBreakerThreshold: 3,
          ),
          httpClient: mockClient,
        );

        // Trigger failures
        for (var i = 0; i < 3; i++) {
          try {
            await aiClient.post('/predict', {});
          } catch (_) {}
        }

        expect(aiClient.isCircuitOpen, true);
        expect(aiClient.circuitResetTime, isNotNull);

        // Next request should fail immediately with circuit breaker exception
        expect(
          () => aiClient.post('/predict', {}),
          throwsA(isA<AICircuitBreakerOpenException>()),
        );

        aiClient.close();
      });

      test('resets failures on success', () async {
        var attempts = 0;

        final mockClient = MockClient((request) async {
          attempts++;
          if (attempts <= 2) {
            return http.Response('Server Error', 500);
          }
          return http.Response(jsonEncode({'success': true}), 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            maxRetries: 0,
            circuitBreakerThreshold: 5,
          ),
          httpClient: mockClient,
        );

        // Trigger 2 failures
        for (var i = 0; i < 2; i++) {
          try {
            await aiClient.post('/predict', {});
          } catch (_) {}
        }

        expect(aiClient.stats.consecutiveFailures, 2);

        // Success should reset
        await aiClient.post('/predict', {});
        expect(aiClient.stats.consecutiveFailures, 0);

        aiClient.close();
      });

      test('can be manually reset', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final aiClient = AIClient(
          config: config.copyWith(
            maxRetries: 0,
            circuitBreakerThreshold: 2,
          ),
          httpClient: mockClient,
        );

        // Trigger circuit open
        for (var i = 0; i < 2; i++) {
          try {
            await aiClient.post('/predict', {});
          } catch (_) {}
        }

        expect(aiClient.isCircuitOpen, true);

        aiClient.resetCircuitBreaker();
        expect(aiClient.isCircuitOpen, false);

        aiClient.close();
      });
    });

    group('Health check', () {
      test('returns healthy status on successful response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'prediction': {'status': 'healthy', 'response_time_ms': 50},
              'sentiment': {'status': 'healthy', 'response_time_ms': 100},
              'routing': {'status': 'healthy', 'response_time_ms': 75},
              'models': {},
              'version': '1.0.0',
              'uptime_seconds': 3600,
              'gpu_available': true,
              'gpu_memory_percent': 45.5,
            }),
            200,
          );
        });

        final aiClient = AIClient(
          config: config,
          httpClient: mockClient,
        );

        final health = await aiClient.checkHealth();

        expect(health.overallStatus, AIServiceHealth.healthy);
        expect(health.predictionService.status, AIServiceHealth.healthy);
        expect(health.sentimentService.status, AIServiceHealth.healthy);
        expect(health.routingService.status, AIServiceHealth.healthy);
        expect(health.serverVersion, '1.0.0');
        expect(health.serverUptimeSeconds, 3600);
        expect(health.gpuAvailable, true);
        expect(health.gpuMemoryUsagePercent, 45.5);

        aiClient.close();
      });

      test('returns unavailable status on error', () async {
        final mockClient = MockClient((request) async {
          throw Exception('Connection refused');
        });

        final aiClient = AIClient(
          config: config,
          httpClient: mockClient,
        );

        final health = await aiClient.checkHealth();

        expect(health.overallStatus, AIServiceHealth.unavailable);
        expect(health.errorMessage, isNotNull);

        aiClient.close();
      });

      test('calculates overall status correctly', () {
        // All healthy
        expect(
          AIHealthStatus.calculateOverallStatus(
            prediction: AIServiceHealth.healthy,
            sentiment: AIServiceHealth.healthy,
            routing: AIServiceHealth.healthy,
          ),
          AIServiceHealth.healthy,
        );

        // One degraded
        expect(
          AIHealthStatus.calculateOverallStatus(
            prediction: AIServiceHealth.healthy,
            sentiment: AIServiceHealth.degraded,
            routing: AIServiceHealth.healthy,
          ),
          AIServiceHealth.degraded,
        );

        // One unhealthy
        expect(
          AIHealthStatus.calculateOverallStatus(
            prediction: AIServiceHealth.healthy,
            sentiment: AIServiceHealth.unhealthy,
            routing: AIServiceHealth.healthy,
          ),
          AIServiceHealth.unhealthy,
        );

        // All unavailable
        expect(
          AIHealthStatus.calculateOverallStatus(
            prediction: AIServiceHealth.unavailable,
            sentiment: AIServiceHealth.unavailable,
            routing: AIServiceHealth.unavailable,
          ),
          AIServiceHealth.unavailable,
        );
      });
    });

    group('Client stats', () {
      test('tracks success and failure', () async {
        var shouldFail = true;

        final mockClient = MockClient((request) async {
          if (shouldFail) {
            return http.Response('Error', 500);
          }
          return http.Response(jsonEncode({'success': true}), 200);
        });

        final aiClient = AIClient(
          config: config.copyWith(maxRetries: 0),
          httpClient: mockClient,
        );

        // Trigger failure
        try {
          await aiClient.post('/predict', {});
        } catch (_) {}

        expect(aiClient.stats.consecutiveFailures, 1);
        expect(aiClient.stats.lastErrorAt, isNotNull);
        expect(aiClient.stats.lastSuccessAt, isNull);

        // Trigger success
        shouldFail = false;
        await aiClient.post('/predict', {});

        expect(aiClient.stats.consecutiveFailures, 0);
        expect(aiClient.stats.lastSuccessAt, isNotNull);

        aiClient.close();
      });

      test('stats serializes to JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'success': true}), 200);
        });

        final aiClient = AIClient(
          config: config,
          httpClient: mockClient,
        );

        await aiClient.post('/predict', {});

        final statsJson = aiClient.stats.toJson();

        expect(statsJson['consecutiveFailures'], 0);
        expect(statsJson['circuitOpen'], false);
        expect(statsJson['lastSuccessAt'], isNotNull);

        aiClient.close();
      });
    });
  });

  group('AIConfig', () {
    test('development factory creates localhost config', () {
      final config = AIConfig.development();
      expect(config.baseUrl, 'http://localhost:8000');
      expect(config.enableRequestLogging, true);
    });

    test('test factory creates test config', () {
      final config = AIConfig.test();
      expect(config.baseUrl, 'http://localhost:8999');
      expect(config.maxRetries, 1);
    });

    test('validates thresholds correctly', () {
      final validConfig = AIConfig.development();
      expect(validConfig.isValid, true);

      final invalidConfig = AIConfig.development().copyWith(
        highRiskThreshold: 0.3,
        mediumRiskThreshold: 0.5,
      );
      expect(invalidConfig.isValid, false);
      expect(invalidConfig.validationErrors, contains(contains('greater than')));
    });

    test('computes full URLs correctly', () {
      final config = AIConfig.development();
      expect(config.predictionUrl, 'http://localhost:8000/api/v1/predict/noshow');
      expect(config.sentimentUrl, 'http://localhost:8000/api/v1/analyze/sentiment');
      expect(config.healthUrl, 'http://localhost:8000/health');
    });

    test('getRiskLevel returns correct levels', () {
      final config = AIConfig.development();

      expect(config.getRiskLevel(0.8), AIRiskLevel.high);
      expect(config.getRiskLevel(0.5), AIRiskLevel.medium);
      expect(config.getRiskLevel(0.2), AIRiskLevel.low);
    });
  });
}
