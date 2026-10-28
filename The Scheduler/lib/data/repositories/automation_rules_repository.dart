// Repository for automation rules with CRUD operations.
// Provides multi-tenant isolation and HIPAA-compliant audit logging.
// Agent AI-11: Risk Automation Engine
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../ai/automation/automation_rule.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing automation rules.
///
/// All operations are scoped to a business (multi-tenant isolation).
class AutomationRulesRepository {
  AutomationRulesRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository;

  final FirebaseFirestore _firestore;
  final AuditLogRepository? _auditLogRepository;

  /// Get the automation rules collection for a business.
  CollectionReference<Map<String, dynamic>> _rulesCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('automation_rules');
  }

  /// Get all automation rules for a business.
  Future<List<AutomationRule>> getRules(SecurityContext context) async {
    final snapshot = await _rulesCollection(context.businessId).get();

    return snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get enabled automation rules for a business.
  Future<List<AutomationRule>> getEnabledRules(SecurityContext context) async {
    final snapshot = await _rulesCollection(
      context.businessId,
    ).where('isEnabled', isEqualTo: true).get();

    return snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get rules by trigger type.
  Future<List<AutomationRule>> getRulesByTriggerType(
    SecurityContext context,
    AutomationTriggerType triggerType,
  ) async {
    final snapshot = await _rulesCollection(context.businessId)
        .where('trigger.type', isEqualTo: triggerType.name)
        .where('isEnabled', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get a single rule by ID.
  Future<AutomationRule?> getRule(
    SecurityContext context,
    String ruleId,
  ) async {
    final doc = await _rulesCollection(context.businessId).doc(ruleId).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    return _fromFirestore(doc.id, data);
  }

  /// Create a new automation rule.
  Future<AutomationRule> createRule(
    SecurityContext context,
    AutomationRule rule,
  ) async {
    DemoGuardService.assertReadOnly('create automation rule');
    final docRef = _rulesCollection(context.businessId).doc();
    final now = DateTime.now();

    final newRule = rule.copyWith(
      id: docRef.id,
      businessId: context.businessId,
      createdAt: now,
      createdBy: context.userId,
      version: 1,
    );

    await docRef.set(_toFirestore(newRule));

    // Audit log
    await _logAction(context, 'automation_rule_created', docRef.id, {
      'ruleName': newRule.name,
      'triggerType': newRule.trigger.type.name,
    });

    return newRule;
  }

  /// Update an existing automation rule.
  Future<AutomationRule> updateRule(
    SecurityContext context,
    AutomationRule rule,
  ) async {
    DemoGuardService.assertReadOnly('update automation rule');
    final docRef = _rulesCollection(context.businessId).doc(rule.id);
    final now = DateTime.now();

    final updatedRule = rule.copyWith(
      updatedAt: now,
      updatedBy: context.userId,
      version: rule.version + 1,
    );

    await docRef.update(_toFirestore(updatedRule));

    // Audit log
    await _logAction(context, 'automation_rule_updated', rule.id, {
      'ruleName': updatedRule.name,
      'version': updatedRule.version,
    });

    return updatedRule;
  }

  /// Delete an automation rule.
  Future<void> deleteRule(SecurityContext context, String ruleId) async {
    DemoGuardService.assertReadOnly('delete automation rule');
    final rule = await getRule(context, ruleId);
    if (rule == null) return;

    await _rulesCollection(context.businessId).doc(ruleId).delete();

    // Audit log
    await _logAction(context, 'automation_rule_deleted', ruleId, {
      'ruleName': rule.name,
    });
  }

  /// Enable a rule.
  Future<void> enableRule(SecurityContext context, String ruleId) async {
    DemoGuardService.assertReadOnly('enable automation rule');
    await _rulesCollection(context.businessId).doc(ruleId).update({
      'isEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': context.userId,
    });

    await _logAction(context, 'automation_rule_enabled', ruleId, {});
  }

  /// Disable a rule.
  Future<void> disableRule(SecurityContext context, String ruleId) async {
    DemoGuardService.assertReadOnly('disable automation rule');
    await _rulesCollection(context.businessId).doc(ruleId).update({
      'isEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': context.userId,
    });

    await _logAction(context, 'automation_rule_disabled', ruleId, {});
  }

  /// Update rule trigger statistics.
  Future<void> updateRuleStats(
    SecurityContext context,
    String ruleId, {
    required int successCount,
    required int failureCount,
  }) async {
    DemoGuardService.assertReadOnly(
      'update automation rule stats',
      showMessage: false,
    );
    await _rulesCollection(context.businessId).doc(ruleId).update({
      'lastTriggeredAt': FieldValue.serverTimestamp(),
      'triggerCount': FieldValue.increment(1),
      'successCount': FieldValue.increment(successCount),
      'failureCount': FieldValue.increment(failureCount),
    });
  }

  /// Stream rules for real-time updates.
  Stream<List<AutomationRule>> watchRules(SecurityContext context) {
    return _rulesCollection(context.businessId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Stream enabled rules for real-time updates.
  Stream<List<AutomationRule>> watchEnabledRules(SecurityContext context) {
    return _rulesCollection(
      context.businessId,
    ).where('isEnabled', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // ============ Private Methods ============

  AutomationRule _fromFirestore(String id, Map<String, dynamic> data) {
    // Parse trigger config
    final triggerData = data['trigger'] as Map<String, dynamic>? ?? {};
    final triggerConfig = AutomationTriggerConfig(
      type: AutomationTriggerType.values.firstWhere(
        (t) => t.name == triggerData['type'],
        orElse: () => AutomationTriggerType.noShowRisk,
      ),
      threshold: (triggerData['threshold'] as num?)?.toDouble() ?? 0.7,
      comparison: triggerData['comparison'] as String? ?? 'gte',
      indicatorTypes: List<String>.from(triggerData['indicatorTypes'] ?? []),
      minConfidence: (triggerData['minConfidence'] as num?)?.toDouble() ?? 0.5,
    );

    // Parse actions
    final actionsData = data['actions'] as List<dynamic>? ?? [];
    final actions = actionsData.map((a) {
      final actionData = a as Map<String, dynamic>;
      return AutomationActionConfig(
        type: AutomationActionType.values.firstWhere(
          (t) => t.name == actionData['type'],
          orElse: () => AutomationActionType.sendSms,
        ),
        templateId: actionData['templateId'] as String?,
        messageTemplate: actionData['messageTemplate'] as String?,
        emailSubject: actionData['emailSubject'] as String?,
        flagName: actionData['flagName'] as String?,
        taskTitle: actionData['taskTitle'] as String?,
        taskDescription: actionData['taskDescription'] as String?,
        taskPriority: actionData['taskPriority'] as String? ?? 'medium',
        alertRecipients: List<String>.from(actionData['alertRecipients'] ?? []),
        delayed: actionData['delayed'] as bool? ?? false,
        delayMinutes: actionData['delayMinutes'] as int? ?? 0,
        metadata: Map<String, dynamic>.from(actionData['metadata'] ?? {}),
      );
    }).toList();

    // Parse conditions
    final conditionsData = data['conditions'] as Map<String, dynamic>? ?? {};
    final conditions = AutomationConditions(
      daysOfWeek: List<int>.from(conditionsData['daysOfWeek'] ?? []),
      businessHoursOnly: conditionsData['businessHoursOnly'] as bool? ?? true,
      businessHoursStart: conditionsData['businessHoursStart'] as int? ?? 8,
      businessHoursEnd: conditionsData['businessHoursEnd'] as int? ?? 18,
      minDaysBeforeAppointment:
          conditionsData['minDaysBeforeAppointment'] as int? ?? 0,
      maxDaysBeforeAppointment:
          conditionsData['maxDaysBeforeAppointment'] as int? ?? 30,
      excludeClientTags: List<String>.from(
        conditionsData['excludeClientTags'] ?? [],
      ),
      includeClientTags: List<String>.from(
        conditionsData['includeClientTags'] ?? [],
      ),
      excludeServiceIds: List<String>.from(
        conditionsData['excludeServiceIds'] ?? [],
      ),
      includeServiceIds: List<String>.from(
        conditionsData['includeServiceIds'] ?? [],
      ),
      minClientLifetimeValue:
          conditionsData['minClientLifetimeValue'] as int? ?? 0,
      skipIfHasFlag: conditionsData['skipIfHasFlag'] as String?,
      skipIfPaymentCollected:
          conditionsData['skipIfPaymentCollected'] as bool? ?? false,
    );

    // Parse cooldown
    final cooldownData = data['cooldown'] as Map<String, dynamic>? ?? {};
    final cooldown = AutomationCooldown(
      perClientMinutes: cooldownData['perClientMinutes'] as int? ?? 1440,
      perAppointmentMinutes:
          cooldownData['perAppointmentMinutes'] as int? ?? 60,
      maxTriggersPerClientPerDay:
          cooldownData['maxTriggersPerClientPerDay'] as int? ?? 3,
      maxTriggersPerRulePerDay:
          cooldownData['maxTriggersPerRulePerDay'] as int? ?? 100,
    );

    return AutomationRule(
      id: id,
      businessId: data['businessId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Rule',
      description: data['description'] as String?,
      isEnabled: data['isEnabled'] as bool? ?? true,
      priority: AutomationPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => AutomationPriority.medium,
      ),
      trigger: triggerConfig,
      actions: actions,
      conditions: conditions,
      cooldown: cooldown,
      lastTriggeredAt: _parseTimestamp(data['lastTriggeredAt']),
      triggerCount: data['triggerCount'] as int? ?? 0,
      successCount: data['successCount'] as int? ?? 0,
      failureCount: data['failureCount'] as int? ?? 0,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String?,
      version: data['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> _toFirestore(AutomationRule rule) {
    return {
      'businessId': rule.businessId,
      'name': rule.name,
      'description': rule.description,
      'isEnabled': rule.isEnabled,
      'priority': rule.priority.name,
      'trigger': {
        'type': rule.trigger.type.name,
        'threshold': rule.trigger.threshold,
        'comparison': rule.trigger.comparison,
        'indicatorTypes': rule.trigger.indicatorTypes,
        'minConfidence': rule.trigger.minConfidence,
      },
      'actions': rule.actions
          .map(
            (a) => {
              'type': a.type.name,
              'templateId': a.templateId,
              'messageTemplate': a.messageTemplate,
              'emailSubject': a.emailSubject,
              'flagName': a.flagName,
              'taskTitle': a.taskTitle,
              'taskDescription': a.taskDescription,
              'taskPriority': a.taskPriority,
              'alertRecipients': a.alertRecipients,
              'delayed': a.delayed,
              'delayMinutes': a.delayMinutes,
              'metadata': a.metadata,
            },
          )
          .toList(),
      'conditions': {
        'daysOfWeek': rule.conditions.daysOfWeek,
        'businessHoursOnly': rule.conditions.businessHoursOnly,
        'businessHoursStart': rule.conditions.businessHoursStart,
        'businessHoursEnd': rule.conditions.businessHoursEnd,
        'minDaysBeforeAppointment': rule.conditions.minDaysBeforeAppointment,
        'maxDaysBeforeAppointment': rule.conditions.maxDaysBeforeAppointment,
        'excludeClientTags': rule.conditions.excludeClientTags,
        'includeClientTags': rule.conditions.includeClientTags,
        'excludeServiceIds': rule.conditions.excludeServiceIds,
        'includeServiceIds': rule.conditions.includeServiceIds,
        'minClientLifetimeValue': rule.conditions.minClientLifetimeValue,
        'skipIfHasFlag': rule.conditions.skipIfHasFlag,
        'skipIfPaymentCollected': rule.conditions.skipIfPaymentCollected,
      },
      'cooldown': {
        'perClientMinutes': rule.cooldown.perClientMinutes,
        'perAppointmentMinutes': rule.cooldown.perAppointmentMinutes,
        'maxTriggersPerClientPerDay': rule.cooldown.maxTriggersPerClientPerDay,
        'maxTriggersPerRulePerDay': rule.cooldown.maxTriggersPerRulePerDay,
      },
      'lastTriggeredAt': rule.lastTriggeredAt != null
          ? Timestamp.fromDate(rule.lastTriggeredAt!)
          : null,
      'triggerCount': rule.triggerCount,
      'successCount': rule.successCount,
      'failureCount': rule.failureCount,
      'createdAt': Timestamp.fromDate(rule.createdAt),
      'updatedAt': rule.updatedAt != null
          ? Timestamp.fromDate(rule.updatedAt!)
          : null,
      'createdBy': rule.createdBy,
      'updatedBy': rule.updatedBy,
      'version': rule.version,
    };
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _logAction(
    SecurityContext context,
    String action,
    String entityId,
    Map<String, dynamic> details,
  ) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository.log(
        context: context,
        action: action,
        entityType: 'automation_rule',
        entityId: entityId,
        source: 'AutomationRulesRepository',
        details: details,
      );
    } catch (e) {
      debugPrint('AutomationRulesRepository: Audit log failed: $e');
    }
  }
}
