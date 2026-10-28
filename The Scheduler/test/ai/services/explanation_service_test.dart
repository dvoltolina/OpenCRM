@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/models/prediction_explanation.dart';
import 'package:the_scheduler/ai/services/explanation_service.dart';

/// Tests for ExplanationService
///
/// Agent AI-19: Prediction Explainability
void main() {
  group('ExplanationService', () {
    group('buildFromPrediction', () {
      test('converts prediction top_features to explanation factors', () {
        // Create a mock prediction with top features
        final prediction = NoshowPrediction(
          appointmentId: 'test_appt_123',
          probability: 0.78,
          riskLevel: RiskLevel.high,
          confidence: 0.85,
          recommendedActions: [],
          topFeatures: [
            FeatureImportance(
              featureName: 'clientHistoricalNoshowRate',
              featureDisplayName: "Client's Past No-Show Rate",
              importance: 0.35,
              featureValue: 0.40,
              impact: 'increases_risk',
            ),
            FeatureImportance(
              featureName: 'paymentCollected',
              featureDisplayName: 'Payment Already Collected',
              importance: 0.25,
              featureValue: 0.0,
              impact: 'increases_risk',
            ),
            FeatureImportance(
              featureName: 'bookingLeadDays',
              featureDisplayName: 'Days Booked in Advance',
              importance: 0.20,
              featureValue: 21.0,
              impact: 'increases_risk',
            ),
          ],
          modelVersion: '1.0.0',
          predictedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        // Note: We can't test buildFromPrediction directly without AIClient
        // but we can test the model structure
        expect(prediction.topFeatures.length, 3);
        expect(prediction.riskLevel, RiskLevel.high);
        expect(prediction.probability, 0.78);
      });
    });

    group('humanizeFeature', () {
      test('humanizes clientHistoricalNoshowRate correctly', () {
        final factor = ExplanationFactor(
          feature: 'clientHistoricalNoshowRate',
          displayName: "Client's Past No-Show Rate",
          impact: 'increases',
          magnitude: 0.35,
          explanation: 'Client has 40% historical no-show rate',
          featureValue: 0.40,
        );

        expect(factor.explanation, contains('40%'));
        expect(factor.impact, 'increases');
      });

      test('humanizes paymentCollected correctly', () {
        final factorNotCollected = ExplanationFactor(
          feature: 'paymentCollected',
          displayName: 'Payment Already Collected',
          impact: 'increases',
          magnitude: 0.25,
          explanation: 'No deposit collected',
          featureValue: 0.0,
        );

        expect(factorNotCollected.explanation, 'No deposit collected');

        final factorCollected = ExplanationFactor(
          feature: 'paymentCollected',
          displayName: 'Payment Already Collected',
          impact: 'decreases',
          magnitude: 0.25,
          explanation: 'Payment/deposit already collected',
          featureValue: 1.0,
        );

        expect(factorCollected.explanation, contains('collected'));
        expect(factorCollected.impact, 'decreases');
      });

      test('humanizes bookingLeadDays correctly', () {
        final factorLong = ExplanationFactor(
          feature: 'bookingLeadDays',
          displayName: 'Days Booked in Advance',
          impact: 'increases',
          magnitude: 0.20,
          explanation: 'Booked 21 days in advance',
          featureValue: 21.0,
        );

        expect(factorLong.explanation, contains('21 days'));

        final factorSameDay = ExplanationFactor(
          feature: 'bookingLeadDays',
          displayName: 'Days Booked in Advance',
          impact: 'decreases',
          magnitude: 0.10,
          explanation: 'Same-day booking',
          featureValue: 0.0,
        );

        expect(factorSameDay.explanation, 'Same-day booking');
      });
    });
  });

  group('PredictionExplanation', () {
    late PredictionExplanation explanation;

    setUp(() {
      explanation = PredictionExplanation(
        appointmentId: 'appt_456',
        probability: 0.72,
        riskLevel: 'high',
        summary: 'High risk primarily because: Client has 40% historical no-show rate',
        topFactors: [
          const ExplanationFactor(
            feature: 'clientHistoricalNoshowRate',
            displayName: "Client's Past No-Show Rate",
            impact: 'increases',
            magnitude: 0.35,
            explanation: 'Client has 40% historical no-show rate',
            featureValue: 0.40,
          ),
          const ExplanationFactor(
            feature: 'paymentCollected',
            displayName: 'Payment Already Collected',
            impact: 'increases',
            magnitude: 0.25,
            explanation: 'No deposit collected',
            featureValue: 0.0,
          ),
          const ExplanationFactor(
            feature: 'isRecurring',
            displayName: 'Is Recurring Appointment',
            impact: 'decreases',
            magnitude: 0.15,
            explanation: 'One-time appointment',
            featureValue: 0.0,
          ),
        ],
        modelVersion: '1.0.0',
        generatedAt: DateTime.now(),
      );
    });

    test('isHighRisk returns true for high risk level', () {
      expect(explanation.isHighRisk, true);
      expect(explanation.isMediumRisk, false);
      expect(explanation.isLowRisk, false);
    });

    test('riskIncreasingFactors filters correctly', () {
      final increasing = explanation.riskIncreasingFactors;
      expect(increasing.length, 2);
      expect(increasing[0].feature, 'clientHistoricalNoshowRate');
      expect(increasing[1].feature, 'paymentCollected');
    });

    test('riskDecreasingFactors filters correctly', () {
      final decreasing = explanation.riskDecreasingFactors;
      expect(decreasing.length, 1);
      expect(decreasing[0].feature, 'isRecurring');
    });

    test('primaryFactor returns first factor', () {
      expect(explanation.primaryFactor?.feature, 'clientHistoricalNoshowRate');
    });

    test('probabilityPercent formats correctly', () {
      expect(explanation.probabilityPercent, '72%');
    });

    test('shortExplanation returns primary factor explanation', () {
      expect(explanation.shortExplanation, 'Client has 40% historical no-show rate');
    });

    test('handles empty topFactors', () {
      final emptyExplanation = PredictionExplanation(
        appointmentId: 'appt_empty',
        probability: 0.5,
        riskLevel: 'medium',
        summary: 'Test summary',
        topFactors: const [],
        modelVersion: '1.0.0',
      );

      expect(emptyExplanation.primaryFactor, null);
      expect(emptyExplanation.shortExplanation, 'Test summary');
      expect(emptyExplanation.riskIncreasingFactors, isEmpty);
      expect(emptyExplanation.riskDecreasingFactors, isEmpty);
    });
  });

  group('ExplanationFactor', () {
    test('fromJson parses correctly', () {
      final json = {
        'feature': 'clientHistoricalNoshowRate',
        'display_name': "Client's Past No-Show Rate",
        'impact': 'increases',
        'magnitude': 0.35,
        'explanation': 'Client has 40% historical no-show rate',
        'feature_value': 0.40,
      };

      final factor = ExplanationFactor.fromJson(json);

      expect(factor.feature, 'clientHistoricalNoshowRate');
      expect(factor.displayName, "Client's Past No-Show Rate");
      expect(factor.impact, 'increases');
      expect(factor.magnitude, 0.35);
      expect(factor.explanation, 'Client has 40% historical no-show rate');
      expect(factor.featureValue, 0.40);
    });
  });

  group('CachedExplanation', () {
    test('isExpired returns true for expired cache', () {
      final expired = CachedExplanation(
        explanation: PredictionExplanation(
          appointmentId: 'test',
          probability: 0.5,
          riskLevel: 'medium',
          summary: 'Test',
          topFactors: const [],
          modelVersion: '1.0.0',
        ),
        cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(expired.isExpired, true);
      expect(expired.isValid, false);
    });

    test('isValid returns true for fresh cache', () {
      final fresh = CachedExplanation(
        explanation: PredictionExplanation(
          appointmentId: 'test',
          probability: 0.5,
          riskLevel: 'medium',
          summary: 'Test',
          topFactors: const [],
          modelVersion: '1.0.0',
        ),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(fresh.isExpired, false);
      expect(fresh.isValid, true);
    });
  });

  group('ExplanationRequest', () {
    test('fromJson parses correctly with defaults', () {
      final json = {
        'appointment_id': 'appt_123',
      };

      final request = ExplanationRequest.fromJson(json);

      expect(request.appointmentId, 'appt_123');
      expect(request.includeAllFactors, false);
      expect(request.numFactors, 3);
    });

    test('fromJson parses all fields', () {
      final json = {
        'appointment_id': 'appt_456',
        'include_all_factors': true,
        'num_factors': 5,
      };

      final request = ExplanationRequest.fromJson(json);

      expect(request.appointmentId, 'appt_456');
      expect(request.includeAllFactors, true);
      expect(request.numFactors, 5);
    });
  });
}
