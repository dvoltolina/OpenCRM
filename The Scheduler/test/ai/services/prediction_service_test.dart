@Tags(['ai'])
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_scheduler/ai/cache/prediction_cache.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/models/prediction_features.dart';
import 'package:the_scheduler/ai/services/ai_client.dart';
import 'package:the_scheduler/ai/services/prediction_service.dart';
import 'package:the_scheduler/core/config/ai_config.dart';
import 'package:the_scheduler/data/models/security_context.dart';

/// Tests for PredictionService
///
/// Agent AI-4: Flutter Prediction Integration
void main() {
  late AIConfig config;
  late PredictionFeatures sampleFeatures;
  late SecurityContext sampleContext;

  setUp(() {
    config = const AIConfig(
      baseUrl: 'http://localhost:8001',
      requireHttps: false,
      apiKey: 'test-api-key',
    );

    sampleContext = const SecurityContext(
      businessId: 'business_456',
      userId: 'user_123',
      role: UserRole.admin,
      authToken: 'test-jwt-token',
    );

    sampleFeatures = PredictionFeatures(
      appointmentId: 'test_123',
      businessId: 'business_456',
      extractedAt: DateTime.now(),
      featureSchemaVersion: 1,
      clientHistoricalNoshowRate: 0.1,
      clientHistoricalCancelRate: 0.05,
      clientTotalAppointments: 10,
      clientDaysSinceLastVisit: 30,
      clientLifetimeValueCents: 50000,
      clientLifecycleStage: 'active',
      clientHasPaymentMethod: true,
      bookingLeadDays: 7,
      dayOfWeek: 2,
      hourOfDay: 14,
      isRecurring: false,
      isGroupSession: false,
      serviceDurationMinutes: 60,
      servicePriceCents: 10000,
      requiresPayment: true,
      paymentCollected: true,
      hasIntakeForm: true,
      providerHistoricalNoshowRate: 0.08,
      providerTotalAppointments: 500,
      slotHistoricalNoshowRate: 0.12,
      isFirstAppointmentOfDay: false,
      isLastAppointmentOfDay: false,
    );
  });

  Map<String, dynamic> _createSuccessResponse({
    String appointmentId = 'test_123',
    double probability = 0.35,
    String riskLevel = 'medium',
  }) {
    return {
      'appointment_id': appointmentId,
      'probability': probability,
      'risk_level': riskLevel,
      'confidence': 0.85,
      'recommended_actions': [
        {
          'action_id': 'send_reminder',
          'title': 'Send Reminder',
          'description': 'Send a reminder to the client',
          'priority': 'medium',
          'automatable': true,
          'icon_name': 'notifications',
          'estimated_impact': 0.1,
        }
      ],
      'top_features': [
        {
          'feature_name': 'clientHistoricalNoshowRate',
          'feature_display_name': "Client's Past No-Show Rate",
          'importance': 0.25,
          'feature_value': 0.1,
          'impact': 'increases_risk',
        }
      ],
      'model_version': '1.0.0',
      'predicted_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      'request_id': 'req_123',
    };
  }

  group('PredictionService', () {
    test('returns prediction on successful API call', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/predict/noshow');
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: PredictionCache(),
      );

      final prediction = await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );

      expect(prediction.appointmentId, 'test_123');
      expect(prediction.probability, 0.35);
      expect(prediction.riskLevel, RiskLevel.medium);
      expect(prediction.confidence, 0.85);
      expect(prediction.recommendedActions.length, 1);
      expect(prediction.topFeatures.length, 1);
    });

    test('returns unavailable on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: PredictionCache(),
      );

      // Need multiple failures to trip circuit breaker
      for (var i = 0; i < 6; i++) {
        await service.predictNoshow(
          context: sampleContext,
          features: sampleFeatures,
          bypassCache: true,
        );
      }

      final prediction = await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
        bypassCache: true,
      );

      expect(prediction.riskLevel, RiskLevel.unknown);
    });

    test('uses cache on second call', () async {
      int callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final cache = PredictionCache();
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: cache,
      );

      // First call
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );
      expect(callCount, 1);

      // Second call should use cache
      final prediction = await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );
      expect(callCount, 1); // Still 1, no new HTTP call
      expect(prediction.appointmentId, 'test_123');
    });

    test('bypasses cache when requested', () async {
      int callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final cache = PredictionCache();
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: cache,
      );

      // First call
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );
      expect(callCount, 1);

      // Second call with bypass
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
        bypassCache: true,
      );
      expect(callCount, 2); // Made another call
    });

    test('batch prediction returns multiple results', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('batch')) {
          return http.Response(
            jsonEncode({
              'predictions': [
                _createSuccessResponse(appointmentId: 'appt_1'),
                _createSuccessResponse(appointmentId: 'appt_2'),
              ],
              'total_processed': 2,
              'processing_time_ms': 50.0,
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: PredictionCache(),
      );

      final features1 = sampleFeatures.copyWith(appointmentId: 'appt_1');
      final features2 = sampleFeatures.copyWith(appointmentId: 'appt_2');

      final predictions = await service.predictNoshowBatch(
        context: sampleContext,
        featuresList: [features1, features2],
      );

      expect(predictions.length, 2);
      expect(predictions[0].appointmentId, 'appt_1');
      expect(predictions[1].appointmentId, 'appt_2');
    });

    test('batch prediction uses cache for some results', () async {
      int batchCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('batch')) {
          batchCallCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final appointments = body['appointments'] as List;

          return http.Response(
            jsonEncode({
              'predictions': appointments.map((a) {
                return _createSuccessResponse(
                  appointmentId: a['appointment_id'] as String,
                );
              }).toList(),
              'total_processed': appointments.length,
              'processing_time_ms': 50.0,
            }),
            200,
          );
        }
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final cache = PredictionCache();
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: cache,
      );

      // Pre-cache one prediction
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );

      // Now batch request including cached one
      final features1 = sampleFeatures; // Already cached
      final features2 = sampleFeatures.copyWith(appointmentId: 'appt_2');

      batchCallCount = 0;
      final predictions = await service.predictNoshowBatch(
        context: sampleContext,
        featuresList: [features1, features2],
      );

      expect(predictions.length, 2);
      expect(batchCallCount, 1); // Only called for uncached
    });

    test('invalidateCache removes cached prediction', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final cache = PredictionCache();
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: cache,
      );

      // Cache a prediction
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );

      // Verify it's cached
      final cached = await cache.get('test_123');
      expect(cached, isNotNull);

      // Invalidate
      await service.invalidateCache('test_123');

      // Verify it's gone
      final afterInvalidate = await cache.get('test_123');
      expect(afterInvalidate, isNull);
    });

    test('statistics are tracked correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(_createSuccessResponse()), 200);
      });

      final aiClient = AIClient(config: config, httpClient: mockClient);
      final service = PredictionService(
        config: config,
        aiClient: aiClient,
        cache: PredictionCache(),
      );

      // Make some requests
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      );
      await service.predictNoshow(
        context: sampleContext,
        features: sampleFeatures,
      ); // Cache hit

      final stats = service.statistics;
      expect(stats['totalRequests'], 2);
      expect(stats['cacheHits'], 1);
    });
  });

  group('PredictionFeaturesApiJson', () {
    test('converts to snake_case JSON', () {
      final json = sampleFeatures.toApiJson();

      expect(json['appointment_id'], 'test_123');
      expect(json['business_id'], 'business_456');
      expect(json['client_historical_noshow_rate'], 0.1);
      expect(json['client_has_payment_method'], true);
      expect(json['is_recurring'], false);
      expect(json['day_of_week'], 2);
    });
  });
}

// Extension for copyWith in tests
extension PredictionFeaturesCopyWith on PredictionFeatures {
  PredictionFeatures copyWith({String? appointmentId}) {
    return PredictionFeatures(
      appointmentId: appointmentId ?? this.appointmentId,
      businessId: businessId,
      extractedAt: extractedAt,
      featureSchemaVersion: featureSchemaVersion,
      clientHistoricalNoshowRate: clientHistoricalNoshowRate,
      clientHistoricalCancelRate: clientHistoricalCancelRate,
      clientTotalAppointments: clientTotalAppointments,
      clientDaysSinceLastVisit: clientDaysSinceLastVisit,
      clientLifetimeValueCents: clientLifetimeValueCents,
      clientLifecycleStage: clientLifecycleStage,
      clientHasPaymentMethod: clientHasPaymentMethod,
      bookingLeadDays: bookingLeadDays,
      dayOfWeek: dayOfWeek,
      hourOfDay: hourOfDay,
      isRecurring: isRecurring,
      isGroupSession: isGroupSession,
      serviceDurationMinutes: serviceDurationMinutes,
      servicePriceCents: servicePriceCents,
      requiresPayment: requiresPayment,
      paymentCollected: paymentCollected,
      hasIntakeForm: hasIntakeForm,
      providerHistoricalNoshowRate: providerHistoricalNoshowRate,
      providerTotalAppointments: providerTotalAppointments,
      slotHistoricalNoshowRate: slotHistoricalNoshowRate,
      isFirstAppointmentOfDay: isFirstAppointmentOfDay,
      isLastAppointmentOfDay: isLastAppointmentOfDay,
    );
  }
}
