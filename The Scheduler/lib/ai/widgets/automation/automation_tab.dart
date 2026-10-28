/// Automation tab showing rule management.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../automation/automation_rule.dart';
import '../../providers/automation_providers.dart';
import 'automation_rule_sheets.dart';
import 'automation_widgets.dart';

/// Tab showing automation rules and statistics.
class AutomationTab extends ConsumerStatefulWidget {
  const AutomationTab({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<AutomationTab> createState() => _AutomationTabState();
}

class _AutomationTabState extends ConsumerState<AutomationTab> {
  AutomationTriggerType? _filterType;

  @override
  void initState() {
    super.initState();
    // Initialize the notifier with security context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(automationRulesNotifierProvider.notifier)
          .initialize(widget.securityContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(automationRulesNotifierProvider);

    return rulesAsync.when(
      data: (rules) => _buildContent(context, rules),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildContent(BuildContext context, List<AutomationRule> rules) {
    if (rules.isEmpty) {
      return AutomationEmptyState(
        onCreateRule: _createNewRule,
      );
    }

    // Filter rules if filter is set
    final filteredRules = _filterType == null
        ? rules
        : rules.where((r) => r.trigger.type == _filterType).toList();

    // Calculate stats
    final stats = ref.watch(automationStatsProvider(rules));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(automationRulesNotifierProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // Stats summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AutomationStatsCard(
                totalRules: stats.totalRules,
                enabledRules: stats.enabledRules,
                totalTriggers: stats.totalTriggers,
                successRate: stats.successRate * 100,
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: _FilterChips(
              selectedType: _filterType,
              rulesByType: stats.rulesByType,
              onTypeSelected: (type) {
                setState(() => _filterType = type);
              },
            ),
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    _filterType == null
                        ? 'All Rules (${filteredRules.length})'
                        : '${_filterType!.displayName} Rules (${filteredRules.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create Rule',
                    onPressed: _createNewRule,
                  ),
                ],
              ),
            ),
          ),

          // Rules list
          if (filteredRules.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Text(
                    'No rules match the filter',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rule = filteredRules[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AutomationRuleCard(
                        rule: rule,
                        onTap: () => _showRuleDetails(rule),
                        onToggle: (enabled) => _toggleRule(rule, enabled),
                        onEdit: () => _editRule(rule),
                        onDelete: () => _deleteRule(rule),
                      ),
                    );
                  },
                  childCount: filteredRules.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to Load Rules',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                ref.read(automationRulesNotifierProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewRule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return RuleEditorSheet(
            scrollController: scrollController,
            securityContext: widget.securityContext,
            onSave: (rule) async {
              final result = await ref
                  .read(automationRulesNotifierProvider.notifier)
                  .createRule(rule);
              if (context.mounted && result != null) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rule created successfully')),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _showRuleDetails(AutomationRule rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return RuleDetailsSheet(
            rule: rule,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  void _editRule(AutomationRule rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return RuleEditorSheet(
            rule: rule,
            scrollController: scrollController,
            securityContext: widget.securityContext,
            onSave: (updatedRule) async {
              final result = await ref
                  .read(automationRulesNotifierProvider.notifier)
                  .updateRule(updatedRule);
              if (context.mounted && result != null) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rule updated successfully')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleRule(AutomationRule rule, bool enabled) async {
    await ref
        .read(automationRulesNotifierProvider.notifier)
        .toggleRule(rule.id, enabled: enabled);
  }

  Future<void> _deleteRule(AutomationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(automationRulesNotifierProvider.notifier)
          .deleteRule(rule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rule deleted')),
        );
      }
    }
  }
}

/// Filter chips for trigger types.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedType,
    required this.rulesByType,
    required this.onTypeSelected,
  });

  final AutomationTriggerType? selectedType;
  final Map<AutomationTriggerType, int> rulesByType;
  final ValueChanged<AutomationTriggerType?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          // All filter
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedType == null,
              onSelected: (_) => onTypeSelected(null),
            ),
          ),
          // Type-specific filters
          ...AutomationTriggerType.values.map((type) {
            final count = rulesByType[type] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text('${type.displayName} ($count)'),
                selected: selectedType == type,
                onSelected: (_) => onTypeSelected(
                  selectedType == type ? null : type,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
