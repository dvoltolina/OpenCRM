@Tags(['ai'])
/// Tests for AutomationEngine.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/automation/automation_engine.dart';
import 'package:the_scheduler/ai/automation/automation_rule.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/models/client_risk_score.dart';
import 'package:the_scheduler/ai/models/sentiment_result.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/models/risk_indicator.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';

void main() {
  late AutomationEngine engine;
  late SecurityContext testContext;

  setUp(() {
    engine = AutomationEngine();
    testContext = const SecurityContext(
      businessId: 'test-business-123',
      userId: 'test-user-456',
      role: UserRole.admin,
    );
  });

  tearDown(() {
    engine.clearCooldownState();
    engine.resetStatistics();
  });

  AutomationRule _createTestRule({
    String id = 'rule-1',
    AutomationTriggerType triggerType = AutomationTriggerType.noShowRisk,
    double threshold = 0.7,
    bool isEnabled = true,
  }) {
    return AutomationRule(
      id: id,
      businessId: testContext.businessId,
      name: 'Test Rule',
      isEnabled: isEnabled,
      trigger: AutomationTriggerConfig(
        type: triggerType,
        threshold: threshold,
      ),
      actions: [
        const AutomationActionConfig(
          type: AutomationActionType.createTask,
          taskTitle: 'Follow up with {{clientName}}',
        ),
      ],
      createdAt: DateTime.now(),
      createdBy: testContext.userId,
    );
  }

  NoshowPrediction _createPrediction({
    double probability = 0.8,
    double confidence = 0.9,
    RiskLevel riskLevel = RiskLevel.high,
  }) {
    return NoshowPrediction(
      appointmentId: 'appt-123',
      probability: probability,
      riskLevel: riskLevel,
      confidence: confidence,
      recommendedActions: [],
      topFeatures: [],
      modelVersion: '1.0.0',
      predictedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Client _createTestClient() {
    return Client(
      id: 'client-123',
      businessId: testContext.businessId,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '+15551234567',
      tags: [],
      createdAt: DateTime.now(),
    );
  }

  group('AutomationEngine - Core Functionality', () {
    // Scenario 1: Rule triggers when prediction exceeds threshold
    test('should trigger rule when no-show probability exceeds threshold', () async {
      final rule = _createTestRule(threshold: 0.7);
      final prediction = _createPrediction(probability: 0.8);

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: prediction,
          client: _createTestClient(),
        ),
        dryRun: true,
      );

      expect(result.triggerResult.shouldFire, isTrue);
      expect(result.triggerResult.evaluatedValue, equals(0.8));
      expect(result.actionResults.length, equals(1));
    });

    // Scenario 2: Rule does not trigger when below threshold
    test('should not trigger rule when prediction is below threshold', () async {
      final rule = _createTestRule(threshold: 0.7);
      final prediction = _createPrediction(probability: 0.5);

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: prediction,
        ),
        dryRun: true,
      );

      expect(result.triggerResult.shouldFire, isFalse);
      expect(result.actionResults, isEmpty);
    });

    // Scenario 3: Disabled rule is skipped
    test('should skip disabled rules', () async {
      final rule = _createTestRule(isEnabled: false);
      final prediction = _createPrediction(probability: 0.9);

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: prediction,
        ),
        dryRun: true,
      );

      expect(result.wasSkipped, isTrue);
      expect(result.skippedReason, contains('disabled'));
    });

    // Scenario 4: Cooldown prevents duplicate triggers
    test('should enforce cooldown between triggers for same client', () async {
      final rule = _createTestRule();
      final prediction = _createPrediction(probability: 0.9);
      final client = _createTestClient();

      // First trigger
      final result1 = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-1',
          prediction: prediction,
          client: client,
        ),
        dryRun: false,
      );
      expect(result1.triggerResult.shouldFire, isTrue);

      // Second trigger should be blocked by cooldown
      final result2 = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-2',
          prediction: prediction,
          client: client,
        ),
        dryRun: false,
      );
      expect(result2.wasSkipped, isTrue);
      expect(result2.skippedReason, contains('cooldown'));
    });

    // Scenario 5: Dry run mode doesn't update cooldown state
    test('dry run should not affect cooldown state', () async {
      final rule = _createTestRule();
      final prediction = _createPrediction(probability: 0.9);
      final client = _createTestClient();

      // First trigger in dry run mode
      await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-1',
          prediction: prediction,
          client: client,
        ),
        dryRun: true,
      );

      // Second trigger should not be blocked
      final result2 = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-1',
          prediction: prediction,
          client: client,
        ),
        dryRun: true,
      );
      expect(result2.triggerResult.shouldFire, isTrue);
    });
  });

  group('AutomationEngine - Condition Evaluation', () {
    // Scenario 6: Skip if client has excluded tag
    test('should skip if client has excluded tag', () async {
      final rule = AutomationRule(
        id: 'rule-1',
        businessId: testContext.businessId,
        name: 'Test Rule',
        trigger: const AutomationTriggerConfig(
          type: AutomationTriggerType.noShowRisk,
          threshold: 0.7,
        ),
        actions: [
          const AutomationActionConfig(type: AutomationActionType.createTask),
        ],
        conditions: const AutomationConditions(
          excludeClientTags: ['VIP', 'no-automation'],
        ),
        createdAt: DateTime.now(),
        createdBy: testContext.userId,
      );

      final client = Client(
        id: 'client-123',
        businessId: testContext.businessId,
        firstName: 'Jane',
        lastName: 'Doe',
        tags: ['VIP'],
        createdAt: DateTime.now(),
      );

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: _createPrediction(probability: 0.9),
          client: client,
        ),
        dryRun: true,
      );

      expect(result.wasSkipped, isTrue);
      expect(result.skippedReason, contains('excluded tag'));
    });

    // Scenario 7: Skip if payment already collected
    test('should skip if payment already collected', () async {
      final rule = AutomationRule(
        id: 'rule-1',
        businessId: testContext.businessId,
        name: 'Test Rule',
        trigger: const AutomationTriggerConfig(
          type: AutomationTriggerType.noShowRisk,
          threshold: 0.7,
        ),
        actions: [
          const AutomationActionConfig(type: AutomationActionType.createTask),
        ],
        conditions: const AutomationConditions(
          skipIfPaymentCollected: true,
        ),
        createdAt: DateTime.now(),
        createdBy: testContext.userId,
      );

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: _createPrediction(probability: 0.9),
          paymentCollected: true,
        ),
        dryRun: true,
      );

      expect(result.wasSkipped, isTrue);
      expect(result.skippedReason, contains('Payment'));
    });
  });

  group('AutomationEngine - Batch Processing', () {
    // Scenario 8: Process multiple rules in priority order
    test('should process rules in priority order', () async {
      final highPriorityRule = AutomationRule(
        id: 'high-priority',
        businessId: testContext.businessId,
        name: 'High Priority Rule',
        priority: AutomationPriority.high,
        trigger: const AutomationTriggerConfig(
          type: AutomationTriggerType.noShowRisk,
          threshold: 0.8,
        ),
        actions: [
          const AutomationActionConfig(type: AutomationActionType.createTask),
        ],
        createdAt: DateTime.now(),
        createdBy: testContext.userId,
      );

      final lowPriorityRule = AutomationRule(
        id: 'low-priority',
        businessId: testContext.businessId,
        name: 'Low Priority Rule',
        priority: AutomationPriority.low,
        trigger: const AutomationTriggerConfig(
          type: AutomationTriggerType.noShowRisk,
          threshold: 0.5,
        ),
        actions: [
          const AutomationActionConfig(type: AutomationActionType.createTask),
        ],
        createdAt: DateTime.now(),
        createdBy: testContext.userId,
      );

      final results = await engine.processRules(
        context: testContext,
        rules: [lowPriorityRule, highPriorityRule],
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: _createPrediction(probability: 0.9),
        ),
        dryRun: true,
      );

      expect(results.length, equals(2));
      // High priority should be processed first
      expect(results[0].ruleId, equals('high-priority'));
      expect(results[1].ruleId, equals('low-priority'));
    });

    // Scenario 9: Stop on first trigger when configured
    test('should stop on first trigger when stopOnFirstTrigger is true', () async {
      final rule1 = _createTestRule(id: 'rule-1', threshold: 0.5);
      final rule2 = _createTestRule(id: 'rule-2', threshold: 0.6);

      final results = await engine.processRules(
        context: testContext,
        rules: [rule1, rule2],
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-123',
          prediction: _createPrediction(probability: 0.9),
        ),
        dryRun: true,
        stopOnFirstTrigger: true,
      );

      // Should only have one result since we stop on first trigger
      expect(results.length, equals(1));
      expect(results[0].triggerResult.shouldFire, isTrue);
    });
  });

  group('AutomationEngine - Statistics', () {
    // Scenario 10: Statistics are tracked correctly
    test('should track execution statistics', () async {
      final rule = _createTestRule(threshold: 0.5);

      // Process a few rules
      await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-1',
          prediction: _createPrediction(probability: 0.9),
        ),
        dryRun: true,
      );

      await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'appointment',
          entityId: 'appt-2',
          prediction: _createPrediction(probability: 0.3),
        ),
        dryRun: true,
      );

      final stats = engine.statistics;
      expect(stats['totalProcessed'], equals(2));
      expect(stats['totalTriggered'], equals(1));
      expect(stats['totalActionsExecuted'], equals(1));
    });
  });

  group('AutomationEngine - Trigger Types', () {
    // Additional test for churn risk trigger
    test('should trigger on high churn risk score', () async {
      final rule = _createTestRule(
        triggerType: AutomationTriggerType.churnRisk,
        threshold: 70, // Using 0-100 scale
      );

      final clientRiskScore = ClientRiskScore(
        id: 'score-1',
        clientId: 'client-123',
        businessId: testContext.businessId,
        calculatedAt: DateTime.now(),
        churnRiskScore: 85,
        satisfactionScore: 30,
        vipScore: 10,
        overallHealthScore: 35,
        churnTrend: ScoreTrend.declining,
        satisfactionTrend: ScoreTrend.declining,
        vipTrend: ScoreTrend.stable,
        riskIndicators: [],
        vipIndicators: [],
        topRiskFactors: ['frequent_cancellations'],
        topVipFactors: [],
        textsAnalyzed: 5,
        analysisStartDate: DateTime.now().subtract(const Duration(days: 30)),
        analysisEndDate: DateTime.now(),
        averageSentiment: -0.3,
        sentimentStdDev: 0.2,
        recommendedActions: [],
        scoringVersion: '1.0.0',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'client',
          entityId: 'client-123',
          clientRiskScore: clientRiskScore,
        ),
        dryRun: true,
      );

      expect(result.triggerResult.shouldFire, isTrue);
      expect(result.triggerResult.evaluatedValue, equals(85.0));
    });

    // Test for sentiment trigger
    test('should trigger on negative sentiment', () async {
      final rule = _createTestRule(
        triggerType: AutomationTriggerType.negativeSentiment,
        threshold: -0.3,
      );

      final sentimentResult = SentimentResult(
        id: 'sentiment-1',
        businessId: testContext.businessId,
        clientId: 'client-123',
        source: SentimentSource.smsReply,
        analyzedText: 'I am very unhappy with the service',
        sentimentScore: -0.6,
        confidence: 0.85,
        riskIndicators: [
          RiskIndicator(
            id: 'risk-1',
            type: IndicatorType.risk,
            severity: IndicatorSeverity.high,
            category: 'dissatisfaction',
            description: 'Client expressed unhappiness',
            confidence: 0.9,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ],
        vipIndicators: [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final result = await engine.processRule(
        context: testContext,
        rule: rule,
        input: AutomationInput(
          entityType: 'client',
          entityId: 'client-123',
          sentimentResult: sentimentResult,
        ),
        dryRun: true,
      );

      expect(result.triggerResult.shouldFire, isTrue);
    });
  });
}
