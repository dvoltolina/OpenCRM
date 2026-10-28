// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AutomationTriggerConfig _$AutomationTriggerConfigFromJson(
  Map<String, dynamic> json,
) => _AutomationTriggerConfig(
  type: $enumDecode(_$AutomationTriggerTypeEnumMap, json['type']),
  threshold: (json['threshold'] as num).toDouble(),
  comparison: json['comparison'] as String? ?? 'gte',
  indicatorTypes:
      (json['indicatorTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0.5,
);

Map<String, dynamic> _$AutomationTriggerConfigToJson(
  _AutomationTriggerConfig instance,
) => <String, dynamic>{
  'type': _$AutomationTriggerTypeEnumMap[instance.type]!,
  'threshold': instance.threshold,
  'comparison': instance.comparison,
  'indicatorTypes': instance.indicatorTypes,
  'minConfidence': instance.minConfidence,
};

const _$AutomationTriggerTypeEnumMap = {
  AutomationTriggerType.noShowRisk: 'noShowRisk',
  AutomationTriggerType.negativeSentiment: 'negativeSentiment',
  AutomationTriggerType.churnRisk: 'churnRisk',
  AutomationTriggerType.vipDetected: 'vipDetected',
};

_AutomationActionConfig _$AutomationActionConfigFromJson(
  Map<String, dynamic> json,
) => _AutomationActionConfig(
  type: $enumDecode(_$AutomationActionTypeEnumMap, json['type']),
  templateId: json['templateId'] as String?,
  messageTemplate: json['messageTemplate'] as String?,
  emailSubject: json['emailSubject'] as String?,
  flagName: json['flagName'] as String?,
  taskTitle: json['taskTitle'] as String?,
  taskDescription: json['taskDescription'] as String?,
  taskPriority: json['taskPriority'] as String? ?? 'medium',
  alertRecipients:
      (json['alertRecipients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  delayed: json['delayed'] as bool? ?? false,
  delayMinutes: (json['delayMinutes'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$AutomationActionConfigToJson(
  _AutomationActionConfig instance,
) => <String, dynamic>{
  'type': _$AutomationActionTypeEnumMap[instance.type]!,
  'templateId': instance.templateId,
  'messageTemplate': instance.messageTemplate,
  'emailSubject': instance.emailSubject,
  'flagName': instance.flagName,
  'taskTitle': instance.taskTitle,
  'taskDescription': instance.taskDescription,
  'taskPriority': instance.taskPriority,
  'alertRecipients': instance.alertRecipients,
  'delayed': instance.delayed,
  'delayMinutes': instance.delayMinutes,
  'metadata': instance.metadata,
};

const _$AutomationActionTypeEnumMap = {
  AutomationActionType.sendSms: 'sendSms',
  AutomationActionType.sendEmail: 'sendEmail',
  AutomationActionType.createTask: 'createTask',
  AutomationActionType.flagClient: 'flagClient',
  AutomationActionType.alertStaff: 'alertStaff',
};

_AutomationConditions _$AutomationConditionsFromJson(
  Map<String, dynamic> json,
) => _AutomationConditions(
  daysOfWeek:
      (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  businessHoursOnly: json['businessHoursOnly'] as bool? ?? true,
  businessHoursStart: (json['businessHoursStart'] as num?)?.toInt() ?? 8,
  businessHoursEnd: (json['businessHoursEnd'] as num?)?.toInt() ?? 18,
  minDaysBeforeAppointment:
      (json['minDaysBeforeAppointment'] as num?)?.toInt() ?? 0,
  maxDaysBeforeAppointment:
      (json['maxDaysBeforeAppointment'] as num?)?.toInt() ?? 30,
  excludeClientTags:
      (json['excludeClientTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  includeClientTags:
      (json['includeClientTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  excludeServiceIds:
      (json['excludeServiceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  includeServiceIds:
      (json['includeServiceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  minClientLifetimeValue:
      (json['minClientLifetimeValue'] as num?)?.toInt() ?? 0,
  skipIfHasFlag: json['skipIfHasFlag'] as String?,
  skipIfPaymentCollected: json['skipIfPaymentCollected'] as bool? ?? false,
);

Map<String, dynamic> _$AutomationConditionsToJson(
  _AutomationConditions instance,
) => <String, dynamic>{
  'daysOfWeek': instance.daysOfWeek,
  'businessHoursOnly': instance.businessHoursOnly,
  'businessHoursStart': instance.businessHoursStart,
  'businessHoursEnd': instance.businessHoursEnd,
  'minDaysBeforeAppointment': instance.minDaysBeforeAppointment,
  'maxDaysBeforeAppointment': instance.maxDaysBeforeAppointment,
  'excludeClientTags': instance.excludeClientTags,
  'includeClientTags': instance.includeClientTags,
  'excludeServiceIds': instance.excludeServiceIds,
  'includeServiceIds': instance.includeServiceIds,
  'minClientLifetimeValue': instance.minClientLifetimeValue,
  'skipIfHasFlag': instance.skipIfHasFlag,
  'skipIfPaymentCollected': instance.skipIfPaymentCollected,
};

_AutomationCooldown _$AutomationCooldownFromJson(Map<String, dynamic> json) =>
    _AutomationCooldown(
      perClientMinutes: (json['perClientMinutes'] as num?)?.toInt() ?? 1440,
      perAppointmentMinutes:
          (json['perAppointmentMinutes'] as num?)?.toInt() ?? 60,
      maxTriggersPerClientPerDay:
          (json['maxTriggersPerClientPerDay'] as num?)?.toInt() ?? 3,
      maxTriggersPerRulePerDay:
          (json['maxTriggersPerRulePerDay'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$AutomationCooldownToJson(_AutomationCooldown instance) =>
    <String, dynamic>{
      'perClientMinutes': instance.perClientMinutes,
      'perAppointmentMinutes': instance.perAppointmentMinutes,
      'maxTriggersPerClientPerDay': instance.maxTriggersPerClientPerDay,
      'maxTriggersPerRulePerDay': instance.maxTriggersPerRulePerDay,
    };

_AutomationRule _$AutomationRuleFromJson(
  Map<String, dynamic> json,
) => _AutomationRule(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  isEnabled: json['isEnabled'] as bool? ?? true,
  priority:
      $enumDecodeNullable(_$AutomationPriorityEnumMap, json['priority']) ??
      AutomationPriority.medium,
  trigger: AutomationTriggerConfig.fromJson(
    json['trigger'] as Map<String, dynamic>,
  ),
  actions: (json['actions'] as List<dynamic>)
      .map((e) => AutomationActionConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  conditions: json['conditions'] == null
      ? const AutomationConditions()
      : AutomationConditions.fromJson(
          json['conditions'] as Map<String, dynamic>,
        ),
  cooldown: json['cooldown'] == null
      ? const AutomationCooldown()
      : AutomationCooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
  lastTriggeredAt: json['lastTriggeredAt'] == null
      ? null
      : DateTime.parse(json['lastTriggeredAt'] as String),
  triggerCount: (json['triggerCount'] as num?)?.toInt() ?? 0,
  successCount: (json['successCount'] as num?)?.toInt() ?? 0,
  failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  createdBy: json['createdBy'] as String,
  updatedBy: json['updatedBy'] as String?,
  version: (json['version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$AutomationRuleToJson(_AutomationRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'name': instance.name,
      'description': instance.description,
      'isEnabled': instance.isEnabled,
      'priority': _$AutomationPriorityEnumMap[instance.priority]!,
      'trigger': instance.trigger.toJson(),
      'actions': instance.actions.map((e) => e.toJson()).toList(),
      'conditions': instance.conditions.toJson(),
      'cooldown': instance.cooldown.toJson(),
      'lastTriggeredAt': instance.lastTriggeredAt?.toIso8601String(),
      'triggerCount': instance.triggerCount,
      'successCount': instance.successCount,
      'failureCount': instance.failureCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'version': instance.version,
    };

const _$AutomationPriorityEnumMap = {
  AutomationPriority.critical: 'critical',
  AutomationPriority.high: 'high',
  AutomationPriority.medium: 'medium',
  AutomationPriority.low: 'low',
};

_TriggerEvaluationResult _$TriggerEvaluationResultFromJson(
  Map<String, dynamic> json,
) => _TriggerEvaluationResult(
  shouldFire: json['shouldFire'] as bool,
  evaluatedValue: (json['evaluatedValue'] as num).toDouble(),
  threshold: (json['threshold'] as num).toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  reason: json['reason'] as String,
  context: json['context'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$TriggerEvaluationResultToJson(
  _TriggerEvaluationResult instance,
) => <String, dynamic>{
  'shouldFire': instance.shouldFire,
  'evaluatedValue': instance.evaluatedValue,
  'threshold': instance.threshold,
  'confidence': instance.confidence,
  'reason': instance.reason,
  'context': instance.context,
};

_ActionExecutionResult _$ActionExecutionResultFromJson(
  Map<String, dynamic> json,
) => _ActionExecutionResult(
  success: json['success'] as bool,
  actionType: $enumDecode(_$AutomationActionTypeEnumMap, json['actionType']),
  message: json['message'] as String,
  externalId: json['externalId'] as String?,
  error: json['error'] as String?,
  executedAt: DateTime.parse(json['executedAt'] as String),
  durationMs: (json['durationMs'] as num?)?.toInt(),
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ActionExecutionResultToJson(
  _ActionExecutionResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'actionType': _$AutomationActionTypeEnumMap[instance.actionType]!,
  'message': instance.message,
  'externalId': instance.externalId,
  'error': instance.error,
  'executedAt': instance.executedAt.toIso8601String(),
  'durationMs': instance.durationMs,
  'metadata': instance.metadata,
};

_AutomationExecutionResult _$AutomationExecutionResultFromJson(
  Map<String, dynamic> json,
) => _AutomationExecutionResult(
  ruleId: json['ruleId'] as String,
  ruleName: json['ruleName'] as String,
  triggerResult: TriggerEvaluationResult.fromJson(
    json['triggerResult'] as Map<String, dynamic>,
  ),
  actionResults: (json['actionResults'] as List<dynamic>)
      .map((e) => ActionExecutionResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  dryRun: json['dryRun'] as bool? ?? false,
  skippedReason: json['skippedReason'] as String?,
  entityType: json['entityType'] as String,
  entityId: json['entityId'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  completedAt: DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$AutomationExecutionResultToJson(
  _AutomationExecutionResult instance,
) => <String, dynamic>{
  'ruleId': instance.ruleId,
  'ruleName': instance.ruleName,
  'triggerResult': instance.triggerResult.toJson(),
  'actionResults': instance.actionResults.map((e) => e.toJson()).toList(),
  'dryRun': instance.dryRun,
  'skippedReason': instance.skippedReason,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'startedAt': instance.startedAt.toIso8601String(),
  'completedAt': instance.completedAt.toIso8601String(),
};
