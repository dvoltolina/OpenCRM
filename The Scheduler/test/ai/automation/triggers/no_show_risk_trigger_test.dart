@Tags(['ai'])
/// Tests for NoShowRiskTrigger.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/automation/automation_rule.dart';
import 'package:the_scheduler/ai/automation/triggers/automation_triggers.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';

void main() {
  late NoShowRiskTrigger trigger;

  setUp(() {
    trigger = NoShowRiskTrigger();
  });

  NoshowPrediction _createPrediction({
    double probability = 0.8,
    double confidence = 0.9,
    RiskLevel riskLevel = RiskLevel.high,
    String modelVersion = '1.0.0',
  }) {
    return NoshowPrediction(
      appointmentId: 'appt-123',
      probability: probability,
      riskLevel: riskLevel,
      confidence: confidence,
      recommendedActions: [],
      topFeatures: [],
      modelVersion: modelVersion,
      predictedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  group('NoShowRiskTrigger', () {
    // Scenario 1: Fire when probability exceeds threshold
    test('should fire when probability >= threshold (gte)', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
        comparison: 'gte',
      );

      final result = trigger.evaluate(
        config: config,
        context: {'prediction': _createPrediction(probability: 0.8)},
      );

      expect(result.shouldFire, isTrue);
      expect(result.evaluatedValue, equals(0.8));
      expect(result.threshold, equals(0.7));
      expect(result.reason, contains('80%'));
    });

    // Scenario 2: Skip when probability is below threshold
    test('should skip when probability < threshold', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
        comparison: 'gte',
      );

      final result = trigger.evaluate(
        config: config,
        context: {'prediction': _createPrediction(probability: 0.5)},
      );

      expect(result.shouldFire, isFalse);
      expect(result.evaluatedValue, equals(0.5));
      expect(result.reason, contains('does not meet'));
    });

    // Scenario 3: Skip when confidence is too low
    test('should skip when confidence is below minimum', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
        minConfidence: 0.8,
      );

      final result = trigger.evaluate(
        config: config,
        context: {'prediction': _createPrediction(probability: 0.9, confidence: 0.5)},
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('Confidence'));
      expect(result.reason, contains('below minimum'));
    });

    // Scenario 4: Skip when prediction is unavailable
    test('should skip when prediction service is unavailable', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
      );

      final unavailablePrediction = NoshowPrediction.unavailable('appt-123');

      final result = trigger.evaluate(
        config: config,
        context: {'prediction': unavailablePrediction},
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('unavailable'));
    });

    test('should skip when no prediction data provided', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
      );

      final result = trigger.evaluate(
        config: config,
        context: {},
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('No prediction data'));
    });

    test('should support different comparison operators', () {
      final prediction = _createPrediction(probability: 0.7);

      // Test 'gt' (greater than)
      final gtConfig = const AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
        comparison: 'gt',
      );
      final gtResult = trigger.evaluate(
        config: gtConfig,
        context: {'prediction': prediction},
      );
      expect(gtResult.shouldFire, isFalse); // 0.7 is not > 0.7

      // Test 'gte' (greater than or equal)
      const gteConfig = AutomationTriggerConfig(
        type: AutomationTriggerType.noShowRisk,
        threshold: 0.7,
        comparison: 'gte',
      );
      final gteResult = trigger.evaluate(
        config: gteConfig,
        context: {'prediction': prediction},
      );
      expect(gteResult.shouldFire, isTrue); // 0.7 >= 0.7
    });
  });
}
