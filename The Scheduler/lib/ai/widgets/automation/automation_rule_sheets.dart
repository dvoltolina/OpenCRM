/// Bottom sheet widgets for automation rule editing and viewing.
///
/// Agent AI-12: AI Dashboard & UI Components
/// Extracted from automation_tab.dart for HIPAA 600-line compliance.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../automation/automation_rule.dart';

/// Rule details bottom sheet.
class RuleDetailsSheet extends StatelessWidget {
  const RuleDetailsSheet({
    super.key,
    required this.rule,
    required this.scrollController,
  });

  final AutomationRule rule;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: rule.isEnabled
                      ? AppColors.success.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  rule.isEnabled ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: rule.isEnabled
                        ? AppColors.success
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (rule.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              rule.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Trigger section
          _DetailSection(
            title: 'Trigger',
            icon: Icons.bolt_outlined,
            children: [
              _DetailRow(
                label: 'Type',
                value: rule.trigger.type.displayName,
              ),
              _DetailRow(
                label: 'Threshold',
                value: '${(rule.trigger.threshold * 100).round()}%',
              ),
              _DetailRow(
                label: 'Min Confidence',
                value: '${(rule.trigger.minConfidence * 100).round()}%',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Actions section
          _DetailSection(
            title: 'Actions',
            icon: Icons.play_arrow_outlined,
            children: rule.actions.map((action) {
              return _DetailRow(
                label: action.type.displayName,
                value: action.messageTemplate ?? action.flagName ?? '—',
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Statistics section
          _DetailSection(
            title: 'Statistics',
            icon: Icons.analytics_outlined,
            children: [
              _DetailRow(
                label: 'Total Triggers',
                value: rule.triggerCount.toString(),
              ),
              _DetailRow(
                label: 'Successes',
                value: rule.successCount.toString(),
              ),
              _DetailRow(
                label: 'Failures',
                value: rule.failureCount.toString(),
              ),
              _DetailRow(
                label: 'Success Rate',
                value: '${rule.successRate.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Rule editor bottom sheet.
class RuleEditorSheet extends StatefulWidget {
  const RuleEditorSheet({
    super.key,
    this.rule,
    required this.scrollController,
    required this.securityContext,
    required this.onSave,
  });

  final AutomationRule? rule;
  final ScrollController scrollController;
  final SecurityContext securityContext;
  final Future<void> Function(AutomationRule rule) onSave;

  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late AutomationTriggerType _triggerType;
  late double _threshold;
  late AutomationActionType _actionType;
  bool _isEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _descriptionController =
        TextEditingController(text: rule?.description ?? '');
    _triggerType = rule?.trigger.type ?? AutomationTriggerType.noShowRisk;
    _threshold = rule?.trigger.threshold ?? 0.7;
    _actionType =
        rule?.actions.firstOrNull?.type ?? AutomationActionType.createTask;
    _isEnabled = rule?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.rule != null;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            isEditing ? 'Edit Rule' : 'Create Rule',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Rule Name',
              hintText: 'e.g., High Risk SMS Reminder',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What does this rule do?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Trigger type
          Text(
            'Trigger Type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AutomationTriggerType.values.map((type) {
              return ChoiceChip(
                label: Text(type.displayName),
                selected: _triggerType == type,
                onSelected: (_) {
                  setState(() => _triggerType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Threshold slider
          Text(
            'Threshold: ${(_threshold * 100).round()}%',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _threshold,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(_threshold * 100).round()}%',
            onChanged: (value) {
              setState(() => _threshold = value);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Action type
          Text(
            'Action Type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AutomationActionType.values.map((type) {
              return ChoiceChip(
                label: Text(type.displayName),
                selected: _actionType == type,
                onSelected: (_) {
                  setState(() => _actionType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Enabled switch
          SwitchListTile(
            title: const Text('Enable Rule'),
            subtitle: const Text('Rule will run automatically when enabled'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() => _isEnabled = value);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Rule' : 'Create Rule'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rule name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final rule = AutomationRule(
      id: widget.rule?.id ?? '',
      businessId: widget.securityContext.businessId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isEnabled: _isEnabled,
      trigger: AutomationTriggerConfig(
        type: _triggerType,
        threshold: _threshold,
      ),
      actions: [
        AutomationActionConfig(type: _actionType),
      ],
      createdAt: widget.rule?.createdAt ?? DateTime.now(),
      createdBy: widget.rule?.createdBy ?? widget.securityContext.userId,
    );

    await widget.onSave(rule);

    setState(() => _isSaving = false);
  }
}
