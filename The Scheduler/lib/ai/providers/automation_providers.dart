/// Riverpod providers for automation rules.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/automation_rules_repository.dart';
import '../automation/automation_rule.dart';

/// Provider for AutomationRulesRepository.
final automationRulesRepositoryProvider = Provider<AutomationRulesRepository>((ref) {
  return AutomationRulesRepository(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  );
});

/// Parameters for fetching automation rules.
typedef AutomationRulesParams = ({
  SecurityContext context,
});

/// Provider for all automation rules.
final automationRulesProvider = FutureProvider.family<
    List<AutomationRule>,
    AutomationRulesParams>((ref, params) async {
  final repo = ref.watch(automationRulesRepositoryProvider);
  return repo.getRules(params.context);
});

/// Provider for enabled automation rules only.
final enabledAutomationRulesProvider = FutureProvider.family<
    List<AutomationRule>,
    AutomationRulesParams>((ref, params) async {
  final repo = ref.watch(automationRulesRepositoryProvider);
  return repo.getEnabledRules(params.context);
});

/// Stream provider for real-time rule updates.
final automationRulesStreamProvider = StreamProvider.family<
    List<AutomationRule>,
    AutomationRulesParams>((ref, params) {
  final repo = ref.watch(automationRulesRepositoryProvider);
  return repo.watchRules(params.context);
});

/// Parameters for fetching rules by trigger type.
typedef RulesByTriggerParams = ({
  SecurityContext context,
  AutomationTriggerType triggerType,
});

/// Provider for rules filtered by trigger type.
final rulesByTriggerTypeProvider = FutureProvider.family<
    List<AutomationRule>,
    RulesByTriggerParams>((ref, params) async {
  final repo = ref.watch(automationRulesRepositoryProvider);
  return repo.getRulesByTriggerType(params.context, params.triggerType);
});

/// State notifier for managing automation rules.
class AutomationRulesNotifier extends StateNotifier<AsyncValue<List<AutomationRule>>> {
  AutomationRulesNotifier(this._repository) : super(const AsyncValue.loading());

  final AutomationRulesRepository _repository;
  SecurityContext? _context;

  /// Initialize with security context.
  Future<void> initialize(SecurityContext context) async {
    _context = context;
    await refresh();
  }

  /// Refresh rules from repository.
  Future<void> refresh() async {
    if (_context == null) return;

    state = const AsyncValue.loading();
    try {
      final rules = await _repository.getRules(_context!);
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new rule.
  Future<AutomationRule?> createRule(AutomationRule rule) async {
    if (_context == null) return null;

    try {
      final created = await _repository.createRule(_context!, rule);
      await refresh();
      return created;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing rule.
  Future<AutomationRule?> updateRule(AutomationRule rule) async {
    if (_context == null) return null;

    try {
      final updated = await _repository.updateRule(_context!, rule);
      await refresh();
      return updated;
    } catch (e) {
      return null;
    }
  }

  /// Delete a rule.
  Future<bool> deleteRule(String ruleId) async {
    if (_context == null) return false;

    try {
      await _repository.deleteRule(_context!, ruleId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle rule enabled state.
  Future<bool> toggleRule(String ruleId, {required bool enabled}) async {
    if (_context == null) return false;

    try {
      if (enabled) {
        await _repository.enableRule(_context!, ruleId);
      } else {
        await _repository.disableRule(_context!, ruleId);
      }
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for automation rules state notifier.
final automationRulesNotifierProvider = StateNotifierProvider<
    AutomationRulesNotifier,
    AsyncValue<List<AutomationRule>>>((ref) {
  final repo = ref.watch(automationRulesRepositoryProvider);
  return AutomationRulesNotifier(repo);
});

/// Provider for automation statistics summary.
final automationStatsProvider = Provider.family<
    AutomationStats,
    List<AutomationRule>>((ref, rules) {
  return AutomationStats.fromRules(rules);
});

/// Summary statistics for automation rules.
class AutomationStats {
  final int totalRules;
  final int enabledRules;
  final int disabledRules;
  final int totalTriggers;
  final int totalSuccesses;
  final int totalFailures;
  final Map<AutomationTriggerType, int> rulesByType;

  const AutomationStats({
    required this.totalRules,
    required this.enabledRules,
    required this.disabledRules,
    required this.totalTriggers,
    required this.totalSuccesses,
    required this.totalFailures,
    required this.rulesByType,
  });

  factory AutomationStats.fromRules(List<AutomationRule> rules) {
    final rulesByType = <AutomationTriggerType, int>{};
    int triggers = 0;
    int successes = 0;
    int failures = 0;
    int enabled = 0;

    for (final rule in rules) {
      rulesByType[rule.trigger.type] =
          (rulesByType[rule.trigger.type] ?? 0) + 1;
      triggers += rule.triggerCount;
      successes += rule.successCount;
      failures += rule.failureCount;
      if (rule.isEnabled) enabled++;
    }

    return AutomationStats(
      totalRules: rules.length,
      enabledRules: enabled,
      disabledRules: rules.length - enabled,
      totalTriggers: triggers,
      totalSuccesses: successes,
      totalFailures: failures,
      rulesByType: rulesByType,
    );
  }

  double get successRate {
    final total = totalSuccesses + totalFailures;
    if (total == 0) return 0;
    return totalSuccesses / total;
  }
}
