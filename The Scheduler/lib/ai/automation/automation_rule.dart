/// Automation rule model for AI-triggered actions.
///
/// Defines rules that trigger automated actions based on AI predictions,
/// sentiment analysis, or other signals. Supports HIPAA-compliant
/// audit logging and multi-tenant isolation.
///
/// Agent AI-11: Risk Automation Engine
import 'package:freezed_annotation/freezed_annotation.dart';

part 'automation_rule.freezed.dart';
part 'automation_rule.g.dart';

/// Type of trigger that activates an automation rule.
enum AutomationTriggerType {
  /// Triggers when no-show prediction exceeds threshold.
  noShowRisk,

  /// Triggers when sentiment score is below threshold.
  negativeSentiment,

  /// Triggers when churn risk score exceeds threshold.
  churnRisk,

  /// Triggers when VIP indicators are detected.
  vipDetected,
}

/// Type of action to execute when rule triggers.
enum AutomationActionType {
  /// Send an SMS message.
  sendSms,

  /// Send an email.
  sendEmail,

  /// Create a follow-up task for staff.
  createTask,

  /// Add a flag/tag to the client.
  flagClient,

  /// Send an internal alert to staff.
  alertStaff,
}

/// Priority level for automation rules.
enum AutomationPriority {
  /// Critical - execute immediately.
  critical,

  /// High - execute with priority.
  high,

  /// Medium - execute in normal order.
  medium,

  /// Low - execute when convenient.
  low,
}

/// Configuration for when a trigger should fire.
@freezed
abstract class AutomationTriggerConfig with _$AutomationTriggerConfig {
  const factory AutomationTriggerConfig({
    /// Type of trigger.
    required AutomationTriggerType type,

    /// Threshold value for the trigger (e.g., 0.7 for 70% no-show risk).
    required double threshold,

    /// Comparison operator: 'gte' (>=), 'lte' (<=), 'gt' (>), 'lt' (<).
    @Default('gte') String comparison,

    /// Optional: Specific risk/VIP indicators to check.
    @Default([]) List<String> indicatorTypes,

    /// Optional: Minimum confidence required for trigger to fire.
    @Default(0.5) double minConfidence,
  }) = _AutomationTriggerConfig;

  factory AutomationTriggerConfig.fromJson(Map<String, dynamic> json) =>
      _$AutomationTriggerConfigFromJson(json);
}

/// Configuration for an action to execute.
@freezed
abstract class AutomationActionConfig with _$AutomationActionConfig {
  const factory AutomationActionConfig({
    /// Type of action.
    required AutomationActionType type,

    /// Template ID for message content (SMS/email).
    String? templateId,

    /// Custom message template (if not using templateId).
    String? messageTemplate,

    /// Subject line for emails.
    String? emailSubject,

    /// Flag/tag name for flagClient action.
    String? flagName,

    /// Task title for createTask action.
    String? taskTitle,

    /// Task description for createTask action.
    String? taskDescription,

    /// Task priority for createTask action.
    @Default('medium') String taskPriority,

    /// Alert recipients for alertStaff action (role IDs).
    @Default([]) List<String> alertRecipients,

    /// Whether to delay action execution.
    @Default(false) bool delayed,

    /// Delay duration in minutes (if delayed is true).
    @Default(0) int delayMinutes,

    /// Additional metadata for the action.
    @Default({}) Map<String, dynamic> metadata,
  }) = _AutomationActionConfig;

  factory AutomationActionConfig.fromJson(Map<String, dynamic> json) =>
      _$AutomationActionConfigFromJson(json);
}

/// Conditions that must be met for a rule to execute.
@freezed
abstract class AutomationConditions with _$AutomationConditions {
  const factory AutomationConditions({
    /// Restrict to specific days of week (1=Mon, 7=Sun). Empty = all days.
    @Default([]) List<int> daysOfWeek,

    /// Restrict to business hours only.
    @Default(true) bool businessHoursOnly,

    /// Start hour for business hours (24h format).
    @Default(8) int businessHoursStart,

    /// End hour for business hours (24h format).
    @Default(18) int businessHoursEnd,

    /// Minimum days until appointment for trigger to fire.
    @Default(0) int minDaysBeforeAppointment,

    /// Maximum days until appointment for trigger to fire.
    @Default(30) int maxDaysBeforeAppointment,

    /// Exclude clients with these tags.
    @Default([]) List<String> excludeClientTags,

    /// Only include clients with these tags.
    @Default([]) List<String> includeClientTags,

    /// Exclude specific service IDs.
    @Default([]) List<String> excludeServiceIds,

    /// Only include specific service IDs.
    @Default([]) List<String> includeServiceIds,

    /// Minimum client lifetime value (cents) to trigger.
    @Default(0) int minClientLifetimeValue,

    /// Skip if client already has this flag.
    String? skipIfHasFlag,

    /// Skip if payment is already collected.
    @Default(false) bool skipIfPaymentCollected,
  }) = _AutomationConditions;

  factory AutomationConditions.fromJson(Map<String, dynamic> json) =>
      _$AutomationConditionsFromJson(json);

  const AutomationConditions._();

  /// Check if conditions have any restrictions.
  bool get hasRestrictions =>
      daysOfWeek.isNotEmpty ||
      businessHoursOnly ||
      excludeClientTags.isNotEmpty ||
      includeClientTags.isNotEmpty ||
      excludeServiceIds.isNotEmpty ||
      includeServiceIds.isNotEmpty ||
      minClientLifetimeValue > 0 ||
      skipIfHasFlag != null ||
      skipIfPaymentCollected;
}

/// Cooldown configuration to prevent duplicate actions.
@freezed
abstract class AutomationCooldown with _$AutomationCooldown {
  const factory AutomationCooldown({
    /// Cooldown period in minutes per client.
    @Default(1440) int perClientMinutes, // 24 hours default

    /// Cooldown period in minutes per appointment.
    @Default(60) int perAppointmentMinutes, // 1 hour default

    /// Maximum triggers per client per day.
    @Default(3) int maxTriggersPerClientPerDay,

    /// Maximum triggers per rule per day (across all clients).
    @Default(100) int maxTriggersPerRulePerDay,
  }) = _AutomationCooldown;

  factory AutomationCooldown.fromJson(Map<String, dynamic> json) =>
      _$AutomationCooldownFromJson(json);
}

/// A complete automation rule definition.
@freezed
abstract class AutomationRule with _$AutomationRule {
  const factory AutomationRule({
    /// Unique rule identifier.
    required String id,

    /// Business ID (multi-tenant isolation).
    required String businessId,

    /// Human-readable rule name.
    required String name,

    /// Optional description of what the rule does.
    String? description,

    /// Whether the rule is currently active.
    @Default(true) bool isEnabled,

    /// Priority for rule execution order.
    @Default(AutomationPriority.medium) AutomationPriority priority,

    /// Trigger configuration.
    required AutomationTriggerConfig trigger,

    /// Actions to execute when triggered.
    required List<AutomationActionConfig> actions,

    /// Conditions that must be met.
    @Default(AutomationConditions()) AutomationConditions conditions,

    /// Cooldown settings to prevent spam.
    @Default(AutomationCooldown()) AutomationCooldown cooldown,

    /// When the rule was last triggered.
    DateTime? lastTriggeredAt,

    /// Total number of times the rule has triggered.
    @Default(0) int triggerCount,

    /// Number of successful action executions.
    @Default(0) int successCount,

    /// Number of failed action executions.
    @Default(0) int failureCount,

    /// When the rule was created.
    required DateTime createdAt,

    /// When the rule was last updated.
    DateTime? updatedAt,

    /// User ID who created the rule.
    required String createdBy,

    /// User ID who last updated the rule.
    String? updatedBy,

    /// Version number for optimistic locking.
    @Default(1) int version,
  }) = _AutomationRule;

  factory AutomationRule.fromJson(Map<String, dynamic> json) =>
      _$AutomationRuleFromJson(json);

  const AutomationRule._();

  /// Success rate as percentage (0-100).
  double get successRate {
    final total = successCount + failureCount;
    if (total == 0) return 0;
    return (successCount / total) * 100;
  }

  /// Whether the rule has been triggered before.
  bool get hasBeenTriggered => triggerCount > 0;

  /// Whether the rule is in cooldown period.
  bool isInCooldown(DateTime now) {
    if (lastTriggeredAt == null) return false;
    final cooldownDuration = Duration(minutes: cooldown.perClientMinutes);
    return now.difference(lastTriggeredAt!) < cooldownDuration;
  }
}

/// Result of evaluating a trigger.
@freezed
abstract class TriggerEvaluationResult with _$TriggerEvaluationResult {
  const factory TriggerEvaluationResult({
    /// Whether the trigger should fire.
    required bool shouldFire,

    /// The value that was evaluated.
    required double evaluatedValue,

    /// The threshold that was compared against.
    required double threshold,

    /// Confidence level of the evaluation.
    required double confidence,

    /// Reason for the result (useful for logging).
    required String reason,

    /// Additional context data.
    @Default({}) Map<String, dynamic> context,
  }) = _TriggerEvaluationResult;

  factory TriggerEvaluationResult.fromJson(Map<String, dynamic> json) =>
      _$TriggerEvaluationResultFromJson(json);

  /// Create a result indicating trigger should fire.
  factory TriggerEvaluationResult.fire({
    required double value,
    required double threshold,
    required double confidence,
    required String reason,
    Map<String, dynamic>? context,
  }) =>
      TriggerEvaluationResult(
        shouldFire: true,
        evaluatedValue: value,
        threshold: threshold,
        confidence: confidence,
        reason: reason,
        context: context ?? {},
      );

  /// Create a result indicating trigger should not fire.
  factory TriggerEvaluationResult.skip({
    required double value,
    required double threshold,
    required String reason,
    Map<String, dynamic>? context,
  }) =>
      TriggerEvaluationResult(
        shouldFire: false,
        evaluatedValue: value,
        threshold: threshold,
        confidence: 0,
        reason: reason,
        context: context ?? {},
      );
}

/// Result of executing an automation action.
@freezed
abstract class ActionExecutionResult with _$ActionExecutionResult {
  const factory ActionExecutionResult({
    /// Whether the action executed successfully.
    required bool success,

    /// Action type that was executed.
    required AutomationActionType actionType,

    /// Message describing the result.
    required String message,

    /// External reference ID (e.g., SMS message ID).
    String? externalId,

    /// Error details if failed.
    String? error,

    /// Execution timestamp.
    required DateTime executedAt,

    /// Execution duration in milliseconds.
    int? durationMs,

    /// Additional result data.
    @Default({}) Map<String, dynamic> metadata,
  }) = _ActionExecutionResult;

  factory ActionExecutionResult.fromJson(Map<String, dynamic> json) =>
      _$ActionExecutionResultFromJson(json);

  /// Create a successful result.
  factory ActionExecutionResult.success({
    required AutomationActionType actionType,
    required String message,
    String? externalId,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) =>
      ActionExecutionResult(
        success: true,
        actionType: actionType,
        message: message,
        externalId: externalId,
        executedAt: DateTime.now(),
        durationMs: durationMs,
        metadata: metadata ?? {},
      );

  /// Create a failed result.
  factory ActionExecutionResult.failure({
    required AutomationActionType actionType,
    required String message,
    required String error,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) =>
      ActionExecutionResult(
        success: false,
        actionType: actionType,
        message: message,
        error: error,
        executedAt: DateTime.now(),
        durationMs: durationMs,
        metadata: metadata ?? {},
      );
}

/// Complete result of processing an automation rule.
@freezed
abstract class AutomationExecutionResult with _$AutomationExecutionResult {
  const factory AutomationExecutionResult({
    /// Rule that was processed.
    required String ruleId,

    /// Rule name for display.
    required String ruleName,

    /// Trigger evaluation result.
    required TriggerEvaluationResult triggerResult,

    /// Results of each action executed.
    required List<ActionExecutionResult> actionResults,

    /// Whether dry run mode was enabled.
    @Default(false) bool dryRun,

    /// Skipped reason if rule was skipped.
    String? skippedReason,

    /// Target entity type (appointment, client).
    required String entityType,

    /// Target entity ID.
    required String entityId,

    /// When execution started.
    required DateTime startedAt,

    /// When execution completed.
    required DateTime completedAt,
  }) = _AutomationExecutionResult;

  factory AutomationExecutionResult.fromJson(Map<String, dynamic> json) =>
      _$AutomationExecutionResultFromJson(json);

  const AutomationExecutionResult._();

  /// Total execution duration in milliseconds.
  int get durationMs => completedAt.difference(startedAt).inMilliseconds;

  /// Whether all actions succeeded.
  bool get allActionsSucceeded =>
      actionResults.isNotEmpty && actionResults.every((r) => r.success);

  /// Whether the rule was skipped.
  bool get wasSkipped => skippedReason != null;

  /// Count of successful actions.
  int get successfulActionCount =>
      actionResults.where((r) => r.success).length;

  /// Count of failed actions.
  int get failedActionCount => actionResults.where((r) => !r.success).length;
}

/// Extension methods for AutomationTriggerType.
extension AutomationTriggerTypeExtension on AutomationTriggerType {
  /// Display name for UI.
  String get displayName => switch (this) {
        AutomationTriggerType.noShowRisk => 'No-Show Risk',
        AutomationTriggerType.negativeSentiment => 'Negative Sentiment',
        AutomationTriggerType.churnRisk => 'Churn Risk',
        AutomationTriggerType.vipDetected => 'VIP Detected',
      };

  /// Icon name for UI.
  String get iconName => switch (this) {
        AutomationTriggerType.noShowRisk => 'event_busy',
        AutomationTriggerType.negativeSentiment => 'sentiment_dissatisfied',
        AutomationTriggerType.churnRisk => 'trending_down',
        AutomationTriggerType.vipDetected => 'star',
      };

  /// Description of what the trigger does.
  String get description => switch (this) {
        AutomationTriggerType.noShowRisk =>
          'Triggers when predicted no-show probability exceeds threshold',
        AutomationTriggerType.negativeSentiment =>
          'Triggers when sentiment score falls below threshold',
        AutomationTriggerType.churnRisk =>
          'Triggers when client churn risk score exceeds threshold',
        AutomationTriggerType.vipDetected =>
          'Triggers when VIP indicators are detected for a client',
      };
}

/// Extension methods for AutomationActionType.
extension AutomationActionTypeExtension on AutomationActionType {
  /// Display name for UI.
  String get displayName => switch (this) {
        AutomationActionType.sendSms => 'Send SMS',
        AutomationActionType.sendEmail => 'Send Email',
        AutomationActionType.createTask => 'Create Task',
        AutomationActionType.flagClient => 'Flag Client',
        AutomationActionType.alertStaff => 'Alert Staff',
      };

  /// Icon name for UI.
  String get iconName => switch (this) {
        AutomationActionType.sendSms => 'sms',
        AutomationActionType.sendEmail => 'email',
        AutomationActionType.createTask => 'task_alt',
        AutomationActionType.flagClient => 'flag',
        AutomationActionType.alertStaff => 'notification_important',
      };

  /// Whether this action is automatable (can run without user input).
  bool get isAutomatable => switch (this) {
        AutomationActionType.sendSms => true,
        AutomationActionType.sendEmail => true,
        AutomationActionType.createTask => true,
        AutomationActionType.flagClient => true,
        AutomationActionType.alertStaff => true,
      };
}
