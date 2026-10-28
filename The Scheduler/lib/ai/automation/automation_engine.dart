/// Core automation engine for AI-triggered actions.
///
/// Evaluates automation rules against predictions and executes actions.
/// Supports batch processing, cooldown enforcement, dry-run mode,
/// and HIPAA-compliant audit logging.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter/foundation.dart';

import '../../core/services/email_service.dart';
import '../../core/services/sms_service.dart';
import '../../data/models/client.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../models/noshow_prediction.dart';
import '../models/sentiment_result.dart';
import '../models/client_risk_score.dart';
import 'actions/automation_actions.dart';
import 'automation_rule.dart';
import 'triggers/automation_triggers.dart';

/// Result of evaluating conditions for a rule.
class ConditionEvaluationResult {
  final bool passed;
  final String reason;
  final Map<String, dynamic> details;

  ConditionEvaluationResult({
    required this.passed,
    required this.reason,
    this.details = const {},
  });

  factory ConditionEvaluationResult.pass() =>
      ConditionEvaluationResult(passed: true, reason: 'All conditions met');

  factory ConditionEvaluationResult.fail(String reason,
          [Map<String, dynamic>? details]) =>
      ConditionEvaluationResult(
        passed: false,
        reason: reason,
        details: details ?? {},
      );
}

/// Input data for processing automation rules.
class AutomationInput {
  /// The entity type being processed (appointment, client).
  final String entityType;

  /// The entity ID being processed.
  final String entityId;

  /// No-show prediction for the entity (if available).
  final NoshowPrediction? prediction;

  /// Sentiment result for the client (if available).
  final SentimentResult? sentimentResult;

  /// Client risk score (if available).
  final ClientRiskScore? clientRiskScore;

  /// Client record (if available).
  final Client? client;

  /// Additional context data.
  final Map<String, dynamic> additionalContext;

  /// Appointment date (for condition checking).
  final DateTime? appointmentDate;

  /// Whether payment has been collected.
  final bool paymentCollected;

  /// Service ID (for condition checking).
  final String? serviceId;

  AutomationInput({
    required this.entityType,
    required this.entityId,
    this.prediction,
    this.sentimentResult,
    this.clientRiskScore,
    this.client,
    this.additionalContext = const {},
    this.appointmentDate,
    this.paymentCollected = false,
    this.serviceId,
  });

  /// Build context map for trigger evaluation.
  Map<String, dynamic> toTriggerContext() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      if (prediction != null) 'prediction': prediction,
      if (sentimentResult != null) 'sentimentResult': sentimentResult,
      if (clientRiskScore != null) 'clientRiskScore': clientRiskScore,
      if (client != null) 'client': client,
      ...additionalContext,
    };
  }
}

/// Core automation engine.
///
/// Processes automation rules against input data and executes actions.
/// Maintains cooldown state and logs all operations for audit.
class AutomationEngine {
  final SmsService? _smsService;
  final EmailService? _emailService;
  final ClientsRepository? _clientsRepository;
  final AuditLogRepository? _auditLogRepository;

  late final ActionExecutorFactory _actionFactory;

  // Cooldown tracking: ruleId -> (clientId -> lastTriggeredAt)
  final Map<String, Map<String, DateTime>> _cooldownState = {};

  // Daily trigger counts: ruleId -> (date -> count)
  final Map<String, Map<String, int>> _dailyTriggerCounts = {};

  // Statistics
  int _totalProcessed = 0;
  int _totalTriggered = 0;
  int _totalActionsExecuted = 0;
  int _totalActionsFailed = 0;

  AutomationEngine({
    SmsService? smsService,
    EmailService? emailService,
    ClientsRepository? clientsRepository,
    AuditLogRepository? auditLogRepository,
  })  : _smsService = smsService,
        _emailService = emailService,
        _clientsRepository = clientsRepository,
        _auditLogRepository = auditLogRepository {
    _actionFactory = ActionExecutorFactory(
      smsService: _smsService,
      emailService: _emailService,
      clientsRepository: _clientsRepository,
    );
  }

  /// Process a single rule against input data.
  ///
  /// Returns execution result with trigger evaluation and action results.
  Future<AutomationExecutionResult> processRule({
    required SecurityContext context,
    required AutomationRule rule,
    required AutomationInput input,
    bool dryRun = false,
  }) async {
    final startedAt = DateTime.now();
    _totalProcessed++;

    // Check if rule is enabled
    if (!rule.isEnabled) {
      return _buildSkippedResult(
        rule: rule,
        input: input,
        reason: 'Rule is disabled',
        startedAt: startedAt,
        dryRun: dryRun,
      );
    }

    // Check cooldown
    final cooldownResult = _checkCooldown(rule, input.client?.id);
    if (!cooldownResult.passed) {
      return _buildSkippedResult(
        rule: rule,
        input: input,
        reason: cooldownResult.reason,
        startedAt: startedAt,
        dryRun: dryRun,
      );
    }

    // Check daily limits
    final limitsResult = _checkDailyLimits(rule, input.client?.id);
    if (!limitsResult.passed) {
      return _buildSkippedResult(
        rule: rule,
        input: input,
        reason: limitsResult.reason,
        startedAt: startedAt,
        dryRun: dryRun,
      );
    }

    // Check conditions
    final conditionsResult = _evaluateConditions(rule.conditions, input);
    if (!conditionsResult.passed) {
      return _buildSkippedResult(
        rule: rule,
        input: input,
        reason: conditionsResult.reason,
        startedAt: startedAt,
        dryRun: dryRun,
      );
    }

    // Evaluate trigger
    final triggerResult = TriggerEvaluatorFactory.evaluate(
      config: rule.trigger,
      context: input.toTriggerContext(),
    );

    if (!triggerResult.shouldFire) {
      return AutomationExecutionResult(
        ruleId: rule.id,
        ruleName: rule.name,
        triggerResult: triggerResult,
        actionResults: [],
        dryRun: dryRun,
        entityType: input.entityType,
        entityId: input.entityId,
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );
    }

    // Trigger fired - execute actions
    _totalTriggered++;

    // Update cooldown state
    if (!dryRun) {
      _updateCooldownState(rule.id, input.client?.id);
      _updateDailyCount(rule.id, input.client?.id);
    }

    // Execute actions
    final actionContext = ActionExecutionContext(
      securityContext: context,
      entityType: input.entityType,
      entityId: input.entityId,
      client: input.client,
      triggerContext: triggerResult.context,
      dryRun: dryRun,
    );

    final actionResults = <ActionExecutionResult>[];
    for (final actionConfig in rule.actions) {
      try {
        final result = await _actionFactory.execute(
          config: actionConfig,
          context: actionContext,
        );
        actionResults.add(result);

        if (result.success) {
          _totalActionsExecuted++;
        } else {
          _totalActionsFailed++;
        }
      } catch (e) {
        _totalActionsFailed++;
        actionResults.add(ActionExecutionResult.failure(
          actionType: actionConfig.type,
          message: 'Action execution failed with exception',
          error: e.toString(),
        ));
      }
    }

    // Log to audit trail (non-blocking)
    if (!dryRun) {
      _logAutomationExecution(context, rule, input, triggerResult, actionResults);
    }

    return AutomationExecutionResult(
      ruleId: rule.id,
      ruleName: rule.name,
      triggerResult: triggerResult,
      actionResults: actionResults,
      dryRun: dryRun,
      entityType: input.entityType,
      entityId: input.entityId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }

  /// Process multiple rules against input data.
  ///
  /// Rules are processed in priority order.
  Future<List<AutomationExecutionResult>> processRules({
    required SecurityContext context,
    required List<AutomationRule> rules,
    required AutomationInput input,
    bool dryRun = false,
    bool stopOnFirstTrigger = false,
  }) async {
    // Sort rules by priority
    final sortedRules = [...rules]..sort((a, b) =>
        a.priority.index.compareTo(b.priority.index));

    final results = <AutomationExecutionResult>[];

    for (final rule in sortedRules) {
      final result = await processRule(
        context: context,
        rule: rule,
        input: input,
        dryRun: dryRun,
      );

      results.add(result);

      // Stop if configured and trigger fired
      if (stopOnFirstTrigger &&
          result.triggerResult.shouldFire &&
          !result.wasSkipped) {
        break;
      }
    }

    return results;
  }

  /// Process a batch of inputs against rules.
  ///
  /// More efficient for processing multiple appointments/clients.
  Future<Map<String, List<AutomationExecutionResult>>> processBatch({
    required SecurityContext context,
    required List<AutomationRule> rules,
    required List<AutomationInput> inputs,
    bool dryRun = false,
  }) async {
    final results = <String, List<AutomationExecutionResult>>{};

    for (final input in inputs) {
      final inputResults = await processRules(
        context: context,
        rules: rules,
        input: input,
        dryRun: dryRun,
      );
      results[input.entityId] = inputResults;
    }

    return results;
  }

  /// Get engine statistics.
  Map<String, dynamic> get statistics => {
        'totalProcessed': _totalProcessed,
        'totalTriggered': _totalTriggered,
        'totalActionsExecuted': _totalActionsExecuted,
        'totalActionsFailed': _totalActionsFailed,
        'triggerRate': _totalProcessed > 0
            ? '${(_totalTriggered / _totalProcessed * 100).toStringAsFixed(1)}%'
            : '0%',
        'actionSuccessRate': _totalActionsExecuted + _totalActionsFailed > 0
            ? '${(_totalActionsExecuted / (_totalActionsExecuted + _totalActionsFailed) * 100).toStringAsFixed(1)}%'
            : '0%',
        'cooldownEntriesCount': _cooldownState.values
            .fold(0, (sum, map) => sum + map.length),
      };

  /// Clear cooldown state (for testing).
  void clearCooldownState() {
    _cooldownState.clear();
    _dailyTriggerCounts.clear();
  }

  /// Reset statistics (for testing).
  void resetStatistics() {
    _totalProcessed = 0;
    _totalTriggered = 0;
    _totalActionsExecuted = 0;
    _totalActionsFailed = 0;
  }

  // ============ Private Methods ============

  ConditionEvaluationResult _checkCooldown(
    AutomationRule rule,
    String? clientId,
  ) {
    if (clientId == null) {
      return ConditionEvaluationResult.pass();
    }

    final ruleState = _cooldownState[rule.id];
    if (ruleState == null) {
      return ConditionEvaluationResult.pass();
    }

    final lastTriggered = ruleState[clientId];
    if (lastTriggered == null) {
      return ConditionEvaluationResult.pass();
    }

    final cooldownDuration = Duration(minutes: rule.cooldown.perClientMinutes);
    final timeSinceLastTrigger = DateTime.now().difference(lastTriggered);

    if (timeSinceLastTrigger < cooldownDuration) {
      final remainingMinutes =
          (cooldownDuration - timeSinceLastTrigger).inMinutes;
      return ConditionEvaluationResult.fail(
        'Client in cooldown period ($remainingMinutes min remaining)',
        {
          'lastTriggered': lastTriggered.toIso8601String(),
          'cooldownMinutes': rule.cooldown.perClientMinutes,
          'remainingMinutes': remainingMinutes,
        },
      );
    }

    return ConditionEvaluationResult.pass();
  }

  ConditionEvaluationResult _checkDailyLimits(
    AutomationRule rule,
    String? clientId,
  ) {
    final today = _todayKey();

    // Check per-rule daily limit
    final ruleCounts = _dailyTriggerCounts[rule.id]?[today] ?? 0;
    if (ruleCounts >= rule.cooldown.maxTriggersPerRulePerDay) {
      return ConditionEvaluationResult.fail(
        'Rule daily limit reached ($ruleCounts/${rule.cooldown.maxTriggersPerRulePerDay})',
        {'currentCount': ruleCounts},
      );
    }

    // Check per-client daily limit
    if (clientId != null) {
      final clientKey = '${rule.id}_$clientId';
      final clientCounts = _dailyTriggerCounts[clientKey]?[today] ?? 0;
      if (clientCounts >= rule.cooldown.maxTriggersPerClientPerDay) {
        return ConditionEvaluationResult.fail(
          'Client daily limit reached ($clientCounts/${rule.cooldown.maxTriggersPerClientPerDay})',
          {'currentCount': clientCounts},
        );
      }
    }

    return ConditionEvaluationResult.pass();
  }

  ConditionEvaluationResult _evaluateConditions(
    AutomationConditions conditions,
    AutomationInput input,
  ) {
    final now = DateTime.now();

    // Check day of week
    if (conditions.daysOfWeek.isNotEmpty &&
        !conditions.daysOfWeek.contains(now.weekday)) {
      return ConditionEvaluationResult.fail(
        'Current day not in allowed days',
        {'currentDay': now.weekday, 'allowedDays': conditions.daysOfWeek},
      );
    }

    // Check business hours
    if (conditions.businessHoursOnly) {
      final hour = now.hour;
      if (hour < conditions.businessHoursStart ||
          hour >= conditions.businessHoursEnd) {
        return ConditionEvaluationResult.fail(
          'Outside business hours',
          {
            'currentHour': hour,
            'businessHoursStart': conditions.businessHoursStart,
            'businessHoursEnd': conditions.businessHoursEnd,
          },
        );
      }
    }

    // Check appointment timing
    if (input.appointmentDate != null) {
      final daysUntil = input.appointmentDate!.difference(now).inDays;

      if (daysUntil < conditions.minDaysBeforeAppointment) {
        return ConditionEvaluationResult.fail(
          'Appointment too soon ($daysUntil days)',
          {
            'daysUntil': daysUntil,
            'minDays': conditions.minDaysBeforeAppointment,
          },
        );
      }

      if (daysUntil > conditions.maxDaysBeforeAppointment) {
        return ConditionEvaluationResult.fail(
          'Appointment too far ($daysUntil days)',
          {
            'daysUntil': daysUntil,
            'maxDays': conditions.maxDaysBeforeAppointment,
          },
        );
      }
    }

    // Check client tags
    if (input.client != null) {
      final clientTags = input.client!.tags;

      // Exclude tags
      for (final excludeTag in conditions.excludeClientTags) {
        if (clientTags.contains(excludeTag)) {
          return ConditionEvaluationResult.fail(
            'Client has excluded tag: $excludeTag',
            {'excludedTag': excludeTag},
          );
        }
      }

      // Include tags (must have at least one)
      if (conditions.includeClientTags.isNotEmpty) {
        final hasIncludeTag =
            conditions.includeClientTags.any((t) => clientTags.contains(t));
        if (!hasIncludeTag) {
          return ConditionEvaluationResult.fail(
            'Client missing required tags',
            {'requiredTags': conditions.includeClientTags},
          );
        }
      }

      // Skip if has flag
      if (conditions.skipIfHasFlag != null &&
          clientTags.contains(conditions.skipIfHasFlag)) {
        return ConditionEvaluationResult.fail(
          'Client already has flag: ${conditions.skipIfHasFlag}',
        );
      }
    }

    // Check service ID
    if (input.serviceId != null) {
      if (conditions.excludeServiceIds.contains(input.serviceId)) {
        return ConditionEvaluationResult.fail(
          'Service excluded: ${input.serviceId}',
        );
      }

      if (conditions.includeServiceIds.isNotEmpty &&
          !conditions.includeServiceIds.contains(input.serviceId)) {
        return ConditionEvaluationResult.fail(
          'Service not in allowed list',
          {'allowedServices': conditions.includeServiceIds},
        );
      }
    }

    // Check payment status
    if (conditions.skipIfPaymentCollected && input.paymentCollected) {
      return ConditionEvaluationResult.fail(
        'Payment already collected',
      );
    }

    return ConditionEvaluationResult.pass();
  }

  void _updateCooldownState(String ruleId, String? clientId) {
    if (clientId == null) return;

    _cooldownState.putIfAbsent(ruleId, () => {});
    _cooldownState[ruleId]![clientId] = DateTime.now();
  }

  void _updateDailyCount(String ruleId, String? clientId) {
    final today = _todayKey();

    // Update rule count
    _dailyTriggerCounts.putIfAbsent(ruleId, () => {});
    _dailyTriggerCounts[ruleId]![today] =
        (_dailyTriggerCounts[ruleId]![today] ?? 0) + 1;

    // Update client-specific count
    if (clientId != null) {
      final clientKey = '${ruleId}_$clientId';
      _dailyTriggerCounts.putIfAbsent(clientKey, () => {});
      _dailyTriggerCounts[clientKey]![today] =
          (_dailyTriggerCounts[clientKey]![today] ?? 0) + 1;
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  AutomationExecutionResult _buildSkippedResult({
    required AutomationRule rule,
    required AutomationInput input,
    required String reason,
    required DateTime startedAt,
    required bool dryRun,
  }) {
    return AutomationExecutionResult(
      ruleId: rule.id,
      ruleName: rule.name,
      triggerResult: TriggerEvaluationResult.skip(
        value: 0,
        threshold: rule.trigger.threshold,
        reason: reason,
      ),
      actionResults: [],
      dryRun: dryRun,
      skippedReason: reason,
      entityType: input.entityType,
      entityId: input.entityId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }

  Future<void> _logAutomationExecution(
    SecurityContext context,
    AutomationRule rule,
    AutomationInput input,
    TriggerEvaluationResult triggerResult,
    List<ActionExecutionResult> actionResults,
  ) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository.log(
        context: context,
        action: 'automation_rule_triggered',
        entityType: input.entityType,
        entityId: input.entityId,
        source: 'AutomationEngine',
        details: {
          'rule_id': rule.id,
          'rule_name': rule.name,
          'trigger_type': rule.trigger.type.name,
          'trigger_value': triggerResult.evaluatedValue,
          'trigger_threshold': triggerResult.threshold,
          'actions_executed': actionResults.length,
          'actions_succeeded': actionResults.where((r) => r.success).length,
          'client_id': input.client?.id,
        },
      );
    } catch (e) {
      // Audit logging should never block the primary operation
      debugPrint('AutomationEngine: Audit log failed (non-blocking): $e');
    }
  }
}
