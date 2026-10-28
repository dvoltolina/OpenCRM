/// Automation rule display and editing widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../automation/automation_rule.dart';

/// Card displaying an automation rule summary.
class AutomationRuleCard extends StatelessWidget {
  const AutomationRuleCard({
    super.key,
    required this.rule,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final AutomationRule rule;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: rule.isEnabled ? null : colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Trigger type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTriggerColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      _getTriggerIcon(),
                      color: _getTriggerColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: rule.isEnabled
                                    ? null
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          rule.trigger.type.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onToggle != null)
                    Switch(
                      value: rule.isEnabled,
                      onChanged: onToggle,
                    ),
                ],
              ),

              if (!compact) ...[
                // Description
                if (rule.description != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    rule.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Stats row
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.bolt_outlined,
                      label: '${rule.triggerCount} triggers',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(
                      icon: Icons.check_circle_outline,
                      label: '${rule.successRate.toStringAsFixed(0)}% success',
                      color: rule.successRate >= 80
                          ? AppColors.success
                          : rule.successRate >= 50
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _PriorityBadge(priority: rule.priority),
                  ],
                ),

                // Actions
                if (rule.actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: rule.actions.take(3).map((action) {
                      return _ActionChip(actionType: action.type);
                    }).toList(),
                  ),
                ],

                // Last triggered
                if (rule.lastTriggeredAt != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Last triggered ${_formatRelativeTime(rule.lastTriggeredAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ],

              // Action buttons
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        tooltip: 'Delete Rule',
                        iconSize: 20,
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTriggerIcon() {
    return switch (rule.trigger.type) {
      AutomationTriggerType.noShowRisk => Icons.event_busy_outlined,
      AutomationTriggerType.negativeSentiment => Icons.sentiment_dissatisfied_outlined,
      AutomationTriggerType.churnRisk => Icons.trending_down_outlined,
      AutomationTriggerType.vipDetected => Icons.star_outline,
    };
  }

  Color _getTriggerColor() {
    return switch (rule.trigger.type) {
      AutomationTriggerType.noShowRisk => AppColors.error,
      AutomationTriggerType.negativeSentiment => AppColors.warning,
      AutomationTriggerType.churnRisk => AppColors.accentPurple,
      AutomationTriggerType.vipDetected => AppColors.warning,
    };
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final AutomationPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      AutomationPriority.critical => ('Critical', AppColors.error),
      AutomationPriority.high => ('High', AppColors.error),
      AutomationPriority.medium => ('Medium', AppColors.warning),
      AutomationPriority.low => ('Low', Theme.of(context).colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.actionType});

  final AutomationActionType actionType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getActionIcon(),
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            actionType.displayName,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    return switch (actionType) {
      AutomationActionType.sendSms => Icons.sms_outlined,
      AutomationActionType.sendEmail => Icons.email_outlined,
      AutomationActionType.createTask => Icons.task_alt_outlined,
      AutomationActionType.flagClient => Icons.flag_outlined,
      AutomationActionType.alertStaff => Icons.notification_important_outlined,
    };
  }
}

/// Automation statistics summary card.
class AutomationStatsCard extends StatelessWidget {
  const AutomationStatsCard({
    super.key,
    required this.totalRules,
    required this.enabledRules,
    required this.totalTriggers,
    required this.successRate,
  });

  final int totalRules;
  final int enabledRules;
  final int totalTriggers;
  final double successRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Automation Overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _AutomationStatItem(
                    icon: Icons.rule_outlined,
                    value: totalRules.toString(),
                    label: 'Total Rules',
                  ),
                ),
                Expanded(
                  child: _AutomationStatItem(
                    icon: Icons.toggle_on_outlined,
                    value: enabledRules.toString(),
                    label: 'Active',
                    valueColor: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _AutomationStatItem(
                    icon: Icons.bolt_outlined,
                    value: totalTriggers.toString(),
                    label: 'Triggers',
                  ),
                ),
                Expanded(
                  child: _AutomationStatItem(
                    icon: Icons.check_circle_outline,
                    value: '${successRate.toStringAsFixed(0)}%',
                    label: 'Success',
                    valueColor: successRate >= 80
                        ? AppColors.success
                        : successRate >= 50
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationStatItem extends StatelessWidget {
  const _AutomationStatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Empty state for automation tab.
class AutomationEmptyState extends StatelessWidget {
  const AutomationEmptyState({
    super.key,
    required this.onCreateRule,
  });

  final VoidCallback onCreateRule;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Automation Rules',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create automation rules to automatically respond\nto AI predictions and sentiment changes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onCreateRule,
              icon: const Icon(Icons.add),
              label: const Text('Create Rule'),
            ),
          ],
        ),
      ),
    );
  }
}
