@Tags(['ai'])
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/core/config/ai_config.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/ai/services/sentiment_service.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/models/ai_health_status.dart';

@GenerateMocks([AuditLogRepository])
import 'sentiment_service_test.mocks.dart';

void main() {
  late SentimentService service;
  late MockAuditLogRepository mockAuditRepo;
  late AIConfig config;

  setUp(() {
    mockAuditRepo = MockAuditLogRepository();
    config = AIConfig.test().copyWith(
      sentimentServiceUrl: 'http://localhost:8002',
      authToken: 'test-token',
    );

    when(mockAuditRepo.log(
      context: anyNamed('context'),
      action: anyNamed('action'),
      entityType: anyNamed('entityType'),
      entityId: anyNamed('entityId'),
      source: anyNamed('source'),
      details: anyNamed('details'),
    )).thenAnswer((_) async {});
  });

  tearDown(() {
    service.dispose();
  });

  group('SentimentService', () {
    group('isAvailable', () {
      test('returns true when health check succeeds', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/health') {
            return http.Response(
              jsonEncode({
                'status': 'healthy',
                'ollama_connected': true,
                'models_available': ['phi3:mini'],
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final result = await service.isAvailable();
        expect(result, isTrue);
      });

      test('returns false when health check fails', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Service unavailable', 503);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final result = await service.isAvailable();
        expect(result, isFalse);
      });
    });

    group('checkHealth', () {
      test('returns healthy status when service responds', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'healthy',
              'ollama_connected': true,
              'models_available': ['phi3:mini', 'llama3.1:8b'],
            }),
            200,
          );
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final health = await service.checkHealth();
        expect(health.overallStatus, AIServiceHealth.healthy);
        expect(health.sentimentService.status, AIServiceHealth.healthy);
        expect(health.loadedModels.sentimentModel, isNotNull);
      });

      test('returns degraded when ollama not connected', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'degraded',
              'ollama_connected': false,
              'models_available': [],
            }),
            200,
          );
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final health = await service.checkHealth();
        expect(health.sentimentService.status, AIServiceHealth.unhealthy);
      });

      test('returns unavailable on network error', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final health = await service.checkHealth();
        expect(health.overallStatus, AIServiceHealth.unavailable);
      });
    });

    group('analyzeSentiment', () {
      test('returns result on successful analysis', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/analyze/sentiment') {
            return http.Response(
              jsonEncode({
                'id': 'sentiment_123',
                'business_id': 'biz_001',
                'client_id': 'client_001',
                'source': 'smsReply',
                'analyzed_text': 'Thank you so much!',
                'sentiment_score': 0.85,
                'confidence': 0.92,
                'risk_indicators': [],
                'vip_indicators': [
                  {
                    'id': 'vip_1',
                    'type': 'positive',
                    'severity': 'low',
                    'category': 'gratitude',
                    'description': 'Expression of thanks',
                    'confidence': 0.9,
                    'source': 'smsReply',
                    'detected_at': DateTime.now().toIso8601String(),
                  }
                ],
                'summary': 'Very positive feedback',
                'model_version': 'phi3:mini',
                'analyzed_at': DateTime.now().toIso8601String(),
                'expires_at':
                    DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                'processing_time_ms': 450,
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

      final context = SecurityContext(
        userId: 'user_1',
        businessId: 'biz_001',
        role: UserRole.admin,
        authToken: 'test-token',
      );

        final text = SentimentAnalysisRequest(
          textId: 'text_1',
          businessId: 'biz_001',
          clientId: 'client_001',
          text: 'Thank you so much!',
          source: SentimentSource.smsReply,
        );

        final result = await service.analyzeSentiment(
          context: context,
          text: text,
        );

        expect(result, isNotNull);
        expect(result!.sentimentScore, 0.85);
        expect(result.confidence, 0.92);
        expect(result.vipIndicators, hasLength(1));
        expect(result.vipIndicators.first.category, 'gratitude');
      });

      test('returns null when service unavailable', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Service unavailable', 503);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final context = SecurityContext(
          userId: 'user_1',
          businessId: 'biz_001',
          role: UserRole.staff,
        );

        final text = SentimentAnalysisRequest(
          textId: 'text_1',
          businessId: 'biz_001',
          clientId: 'client_001',
          text: 'Test message',
          source: SentimentSource.smsReply,
        );

        final result = await service.analyzeSentiment(
          context: context,
          text: text,
        );

        expect(result, isNull);
      });

      test('logs analysis to audit repository', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/analyze/sentiment') {
            return http.Response(
              jsonEncode({
                'id': 'sentiment_123',
                'business_id': 'biz_001',
                'client_id': 'client_001',
                'source': 'smsReply',
                'analyzed_text': 'Great service!',
                'sentiment_score': 0.75,
                'confidence': 0.88,
                'risk_indicators': [],
                'vip_indicators': [],
                'model_version': 'phi3:mini',
                'analyzed_at': DateTime.now().toIso8601String(),
                'expires_at':
                    DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final context = SecurityContext(
          userId: 'user_1',
          businessId: 'biz_001',
          role: UserRole.staff,
        );

        final text = SentimentAnalysisRequest(
          textId: 'text_1',
          businessId: 'biz_001',
          clientId: 'client_001',
          text: 'Great service!',
          source: SentimentSource.smsReply,
        );

        await service.analyzeSentiment(context: context, text: text);

        verify(mockAuditRepo.log(
          context: anyNamed('context'),
          action: 'ai_sentiment_analyzed',
          entityType: 'client',
          entityId: 'client_001',
          source: 'SentimentService',
          details: anyNamed('details'),
        )).called(1);
      });
    });

    group('analyzeSentimentBatch', () {
      test('returns results for batch analysis', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/analyze/sentiment/batch') {
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 'sentiment_1',
                    'business_id': 'biz_001',
                    'client_id': 'client_001',
                    'source': 'smsReply',
                    'analyzed_text': 'Good',
                    'sentiment_score': 0.6,
                    'confidence': 0.85,
                    'risk_indicators': [],
                    'vip_indicators': [],
                    'model_version': 'phi3:mini',
                    'analyzed_at': DateTime.now().toIso8601String(),
                    'expires_at': DateTime.now()
                        .add(const Duration(days: 7))
                        .toIso8601String(),
                  },
                  {
                    'id': 'sentiment_2',
                    'business_id': 'biz_001',
                    'client_id': 'client_002',
                    'source': 'emailReply',
                    'analyzed_text': 'Bad',
                    'sentiment_score': -0.4,
                    'confidence': 0.78,
                    'risk_indicators': [],
                    'vip_indicators': [],
                    'model_version': 'phi3:mini',
                    'analyzed_at': DateTime.now().toIso8601String(),
                    'expires_at': DateTime.now()
                        .add(const Duration(days: 7))
                        .toIso8601String(),
                  },
                ],
                'total_processed': 2,
                'processing_time_ms': 850.5,
                'errors': [],
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final texts = [
          SentimentAnalysisRequest(
            textId: 'text_1',
            businessId: 'biz_001',
            clientId: 'client_001',
            text: 'Good',
            source: SentimentSource.smsReply,
          ),
          SentimentAnalysisRequest(
            textId: 'text_2',
            businessId: 'biz_001',
            clientId: 'client_002',
            text: 'Bad',
            source: SentimentSource.emailReply,
          ),
        ];

        final results = await service.analyzeSentimentBatch(
          context: SecurityContext(
            userId: 'user_1',
            businessId: 'biz_001',
            role: UserRole.admin,
            authToken: 'test-token',
          ),
          texts: texts,
        );

        expect(results, hasLength(2));
        expect(results[0].sentimentScore, 0.6);
        expect(results[1].sentimentScore, -0.4);
      });

      test('returns empty list when service unavailable', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final texts = [
          SentimentAnalysisRequest(
            textId: 'text_1',
            businessId: 'biz_001',
            clientId: 'client_001',
            text: 'Test',
            source: SentimentSource.smsReply,
          ),
        ];

        final results = await service.analyzeSentimentBatch(
          context: SecurityContext(
            userId: 'user_1',
            businessId: 'biz_001',
            role: UserRole.admin,
            authToken: 'test-token',
          ),
          texts: texts,
        );
      expect(results, isEmpty);
      });
    });

    group('circuit breaker', () {
      test('opens after consecutive failures', () async {
        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('Service unavailable', 503);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final context = SecurityContext(
          userId: 'user_1',
          businessId: 'biz_001',
          role: UserRole.staff,
        );

        final text = SentimentAnalysisRequest(
          textId: 'text_1',
          businessId: 'biz_001',
          clientId: 'client_001',
          text: 'Test',
          source: SentimentSource.smsReply,
        );

        // Make multiple failed requests to trigger circuit breaker
        for (var i = 0; i < 10; i++) {
          await service.analyzeSentiment(context: context, text: text);
        }

        // Circuit should open after 5 failures (threshold), so calls should stop
        // First 5 calls hit the server, then circuit opens
        expect(callCount, lessThanOrEqualTo(6));
      });
    });

    group('statistics', () {
      test('tracks request statistics', () async {
        var successCount = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path == '/analyze/sentiment') {
            successCount++;
            return http.Response(
              jsonEncode({
                'id': 'sentiment_$successCount',
                'business_id': 'biz_001',
                'client_id': 'client_001',
                'source': 'smsReply',
                'analyzed_text': 'Test',
                'sentiment_score': 0.5,
                'confidence': 0.8,
                'risk_indicators': [],
                'vip_indicators': [],
                'model_version': 'phi3:mini',
                'analyzed_at': DateTime.now().toIso8601String(),
                'expires_at':
                    DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        service = SentimentService(
          config: config,
          httpClient: mockClient,
          auditLogRepository: mockAuditRepo,
        );

        final context = SecurityContext(
          userId: 'user_1',
          businessId: 'biz_001',
          role: UserRole.staff,
        );

        final text = SentimentAnalysisRequest(
          textId: 'text_1',
          businessId: 'biz_001',
          clientId: 'client_001',
          text: 'Test',
          source: SentimentSource.smsReply,
        );

        await service.analyzeSentiment(context: context, text: text);
        await service.analyzeSentiment(context: context, text: text);

        final stats = service.statistics;
        expect(stats['totalRequests'], 2);
        expect(stats['successfulRequests'], 2);
        expect(stats['failedRequests'], 0);
      });
    });
  });
}
