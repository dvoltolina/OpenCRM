@Tags(['ai'])
/// Tests for SentimentTrigger.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/automation/automation_rule.dart';
import 'package:the_scheduler/ai/automation/triggers/automation_triggers.dart';
import 'package:the_scheduler/ai/models/sentiment_result.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/models/risk_indicator.dart';
import 'package:the_scheduler/ai/models/client_risk_score.dart';

void main() {
  late SentimentTrigger trigger;

  setUp(() {
    trigger = SentimentTrigger();
  });

  SentimentResult _createSentimentResult({
    double sentimentScore = -0.5,
    double confidence = 0.9,
    List<RiskIndicator>? riskIndicators,
  }) {
    return SentimentResult(
      id: 'sentiment-123',
      businessId: 'business-123',
      clientId: 'client-123',
      source: SentimentSource.smsReply,
      analyzedText: 'Test text',
      sentimentScore: sentimentScore,
      confidence: confidence,
      riskIndicators: riskIndicators ?? [],
      vipIndicators: [],
      modelVersion: '1.0.0',
      analyzedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  ClientRiskScore _createClientRiskScore({
    int satisfactionScore = 30,
    int textsAnalyzed = 5,
    List<RiskIndicator>? riskIndicators,
  }) {
    return ClientRiskScore(
      id: 'score-123',
      clientId: 'client-123',
      businessId: 'business-123',
      calculatedAt: DateTime.now(),
      churnRiskScore: 70,
      satisfactionScore: satisfactionScore,
      vipScore: 10,
      overallHealthScore: 40,
      churnTrend: ScoreTrend.declining,
      satisfactionTrend: ScoreTrend.declining,
      vipTrend: ScoreTrend.stable,
      riskIndicators: riskIndicators ?? [],
      vipIndicators: [],
      topRiskFactors: [],
      topVipFactors: [],
      textsAnalyzed: textsAnalyzed,
      analysisStartDate: DateTime.now().subtract(const Duration(days: 30)),
      analysisEndDate: DateTime.now(),
      averageSentiment: -0.3,
      sentimentStdDev: 0.2,
      recommendedActions: [],
      scoringVersion: '1.0.0',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
  }

  group('SentimentTrigger', () {
    // Scenario 1: Fire on negative sentiment
    test('should fire on negative sentiment score', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
        comparison: 'lte',
      );

      final result = trigger.evaluate(
        config: config,
        context: {'sentimentResult': _createSentimentResult(sentimentScore: -0.5)},
      );

      expect(result.shouldFire, isTrue);
      expect(result.evaluatedValue, equals(-0.5));
    });

    // Scenario 2: Skip when sentiment is above threshold
    test('should skip when sentiment is positive', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
        comparison: 'lte',
      );

      final result = trigger.evaluate(
        config: config,
        context: {'sentimentResult': _createSentimentResult(sentimentScore: 0.5)},
      );

      expect(result.shouldFire, isFalse);
    });

    // Scenario 3: Skip when confidence is low
    test('should skip when confidence is below minimum', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
        minConfidence: 0.8,
      );

      final result = trigger.evaluate(
        config: config,
        context: {
          'sentimentResult': _createSentimentResult(
            sentimentScore: -0.8,
            confidence: 0.5,
          ),
        },
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('Confidence'));
    });

    // Scenario 4: Use client risk score as fallback
    test('should use client risk score when sentiment result unavailable', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: 40, // Satisfaction score threshold
      );

      final result = trigger.evaluate(
        config: config,
        context: {
          'clientRiskScore': _createClientRiskScore(satisfactionScore: 25),
        },
      );

      expect(result.shouldFire, isTrue);
      expect(result.evaluatedValue, equals(25.0));
    });

    test('should detect specific risk indicators when configured', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
        indicatorTypes: ['dissatisfaction', 'complaint'],
      );

      final riskIndicator = RiskIndicator(
        id: 'risk-1',
        type: IndicatorType.risk,
        severity: IndicatorSeverity.high,
        category: 'dissatisfaction',
        description: 'Client is unhappy',
        confidence: 0.9,
        source: SentimentSource.smsReply,
        detectedAt: DateTime.now(),
      );

      final result = trigger.evaluate(
        config: config,
        context: {
          'sentimentResult': _createSentimentResult(
            riskIndicators: [riskIndicator],
          ),
        },
      );

      expect(result.shouldFire, isTrue);
      expect(result.reason, contains('dissatisfaction'));
    });

    test('should skip when no matching risk indicators found', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
        indicatorTypes: ['complaint'],
      );

      final riskIndicator = RiskIndicator(
        id: 'risk-1',
        type: IndicatorType.risk,
        severity: IndicatorSeverity.high,
        category: 'other_issue',
        description: 'Some other issue',
        confidence: 0.9,
        source: SentimentSource.smsReply,
        detectedAt: DateTime.now(),
      );

      final result = trigger.evaluate(
        config: config,
        context: {
          'sentimentResult': _createSentimentResult(
            riskIndicators: [riskIndicator],
          ),
        },
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('No matching risk indicators'));
    });

    test('should skip when no sentiment data available', () {
      const config = AutomationTriggerConfig(
        type: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
      );

      final result = trigger.evaluate(
        config: config,
        context: {},
      );

      expect(result.shouldFire, isFalse);
      expect(result.reason, contains('No sentiment data'));
    });
  });
}
