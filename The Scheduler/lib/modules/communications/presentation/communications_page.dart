import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/communication_config.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/security_context.dart';
import 'widgets/template_editor_dialog.dart';
import 'widgets/automation_rules_panel.dart';
import 'communication_dashboard_provider.dart';
import 'widgets/messaging_portal.dart';

/// Communications & Automation management page.
/// Modern design with professional clean styling and sophisticated blue colors.
/// Allows configuration of templates, automation rules, and preview of messages
class CommunicationsPage extends ConsumerStatefulWidget {
  const CommunicationsPage({super.key});

  @override
  ConsumerState<CommunicationsPage> createState() => _CommunicationsPageState();
}

class _CommunicationsPageState extends ConsumerState<CommunicationsPage> {
  MessageChannel _selectedChannel = MessageChannel.email;
  MessageType? _selectedTemplateType;

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Authentication error: $error'))),
      data: (securityContext) {
        if (securityContext == null) {
          return const Scaffold(
            body: Center(
              child: Text('You must be signed in to view communications.'),
            ),
          );
        }

        final dashboardAsync = ref.watch(communicationDashboardProvider);

        return dashboardAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(child: Text('Unable to load communications: $error')),
          ),
          data: (dashboard) => _buildContent(
            context: context,
            appConfig: appConfig,
            securityContext: securityContext,
            dashboard: dashboard,
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AppConfig appConfig,
    required SecurityContext securityContext,
    required CommunicationDashboardState dashboard,
  }) {
    final theme = Theme.of(context);
    final branding = appConfig.branding;
    final commConfig = dashboard.config;
    final templates = _selectedChannel == MessageChannel.email
        ? dashboard.emailTemplates
        : dashboard.smsTemplates;
    final canManageCommunications = securityContext.role.canManageClients;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Semantics(
          label: 'Communications page',
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage in-app messaging, automated reminders, and notification templates.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                VSpace.lg,
                MessagingPortalCard(securityContext: securityContext),
                VSpace.lg,
                if (appConfig.featureFlags.enableAutomatedReminders)
                  AutomationRulesPanel(
                    rules: dashboard.automationRules,
                    onRuleToggled: canManageCommunications
                        ? (rule) => _toggleAutomationRule(rule)
                        : null,
                    readOnly: !canManageCommunications,
                  ),
                if (appConfig.featureFlags.enableAutomatedReminders) VSpace.lg,
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: branding.primaryColor,
                              size: AppIconSize.md,
                            ),
                            HSpace.xs,
                            Text(
                              'Message Templates',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: branding.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      VSpace.xxs,
                      Text(
                        'Customize automated emails and SMS content',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SpacedDivider(spacing: AppSpacing.sm),
                      SegmentedButton<MessageChannel>(
                        segments: const [
                          ButtonSegment(
                            value: MessageChannel.email,
                            label: Text('Email'),
                            icon: Icon(Icons.email_outlined),
                          ),
                          ButtonSegment(
                            value: MessageChannel.sms,
                            label: Text('SMS'),
                            icon: Icon(Icons.sms_outlined),
                          ),
                        ],
                        selected: {_selectedChannel},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _selectedChannel = selected.first;
                            _selectedTemplateType = null;
                          });
                        },
                      ),
                      VSpace.md,
                      ...templates.entries.map((entry) {
                        final type = entry.key;
                        final template = entry.value;
                        final isSelected = _selectedTemplateType == type;
                        final previewText =
                            _selectedChannel == MessageChannel.email
                            ? template.subject
                            : template.body.length > 50
                            ? '${template.body.substring(0, 50)}...'
                            : template.body;

                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                _getTemplateIcon(type),
                                color: theme.colorScheme.primary,
                                size: AppIconSize.md,
                              ),
                              title: Text(_getTemplateTypeName(type)),
                              subtitle: Text(
                                previewText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined),
                                    tooltip: 'Preview',
                                    onPressed: () {
                                      setState(() {
                                        _selectedTemplateType = isSelected
                                            ? null
                                            : type;
                                      });
                                    },
                                  ),
                                  Tooltip(
                                    message: canManageCommunications
                                        ? 'Edit template'
                                        : 'Only admins/staff can edit templates',
                                    child: AppButton(
                                      label: 'Edit',
                                      onPressed: canManageCommunications
                                          ? () => _editTemplate(template)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) _buildTemplatePreview(template),
                            const Divider(height: 1),
                          ],
                        );
                      }),
                      ],
                    ),
                  ),
                ),
                VSpace.lg,
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: branding.primaryColor,
                              size: AppIconSize.md,
                            ),
                            HSpace.xs,
                            Text(
                              'Communication Settings',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: branding.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SpacedDivider(spacing: AppSpacing.sm),
                      _buildSettingItem(
                        'Sender Email',
                        commConfig.senderEmail,
                        Icons.email,
                      ),
                      _buildSettingItem(
                        'Sender Name',
                        commConfig.senderName,
                        Icons.person,
                      ),
                      _buildSettingItem(
                        'Support Phone',
                        commConfig.supportPhone,
                        Icons.phone,
                      ),
                      if (commConfig.replyToEmail != null)
                        _buildSettingItem(
                          'Reply-To Email',
                          commConfig.replyToEmail!,
                          Icons.reply,
                        ),
                      ],
                    ),
                  ),
                ),
                VSpace.lg,
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.integration_instructions,
                              color: branding.primaryColor,
                              size: AppIconSize.md,
                            ),
                            HSpace.xs,
                            Text(
                              'Integration Status',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: branding.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SpacedDivider(spacing: AppSpacing.sm),
                      _buildIntegrationStatus(
                        'Email Service',
                        'Mock (Development)',
                        false,
                        'Configure SendGrid or AWS SES for production',
                      ),
                      VSpace.sm,
                      _buildIntegrationStatus(
                        'SMS Service',
                        'Mock (Development)',
                        false,
                        'Configure Twilio or AWS SNS for production',
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(MessageTemplate template) {
    final theme = Theme.of(context);
    final sampleVariables = {
      'client_name': 'Maya Johnson',
      'date': 'Mon, Nov 25, 2025',
      'time': '9:00 AM',
      'location': 'Main Office - Suite 200',
      'provider_name': 'Dr. Sarah Smith',
      'service_type': 'Initial Consultation',
      'business_name': 'Scheduler HQ',
      'support_phone': '(555) 123-4567',
      'cancellation_hours': '24',
      'custom_instructions':
          'Please arrive 10 minutes early to complete paperwork.',
      'preparation_instructions': 'No special preparation needed.',
      'booking_link': 'https://scheduler.example.com/book',
      'feedback_link': 'https://scheduler.example.com/feedback',
      'cancellation_reason': '',
    };

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: AppIconSize.xs,
                color: theme.colorScheme.primary,
              ),
              HSpace.xs,
              Text(
                'Preview with Sample Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          VSpace.sm,
          if (template.channel == MessageChannel.email) ...[
            Text(
              'Subject: ${template.renderSubject(sampleVariables)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            const Divider(),
            VSpace.md,
          ],
          Text(
            template.render(sampleVariables),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.sm, color: theme.colorScheme.primary),
          HSpace.sm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStatus(
    String name,
    String status,
    bool isProduction,
    String description,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: theme.textTheme.titleSmall),
                  HSpace.xs,
                  isProduction
                      ? StatusPill.success(label: status)
                      : StatusPill.warning(label: status),
                ],
              ),
              VSpace.xxs,
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editTemplate(MessageTemplate template) {
    showDialog(
      context: context,
      builder: (context) =>
          TemplateEditorDialog(template: template, onSave: _handleTemplateSave),
    );
  }

  Future<void> _handleTemplateSave(MessageTemplate template) async {
    try {
      await ref.read(communicationRepositoryProvider).updateTemplate(template);
      ref.invalidate(communicationDashboardProvider);
      _showSnack('Template saved');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showSnack('You do not have permission to edit templates.');
      } else {
        _showSnack('Failed to save template: ${e.message ?? e.code}');
      }
    } on SecurityException {
      _showSnack('You do not have permission to edit templates.');
    }
  }

  Future<void> _toggleAutomationRule(AutomationRule rule) async {
    final updatedRule = rule.copyWith(enabled: !rule.enabled);
    try {
      await ref
          .read(communicationRepositoryProvider)
          .updateAutomationRule(updatedRule);
      ref.invalidate(communicationDashboardProvider);
      _showSnack(
        updatedRule.enabled
            ? 'Enabled: ${updatedRule.name}'
            : 'Disabled: ${updatedRule.name}',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showSnack('You do not have permission to manage automations.');
      } else {
        _showSnack('Unable to update rule: ${e.message ?? e.code}');
      }
    } on SecurityException {
      _showSnack('You do not have permission to manage automations.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _getTemplateIcon(MessageType type) {
    switch (type) {
      case MessageType.bookingConfirmation:
        return Icons.check_circle_outline;
      case MessageType.reminder24h:
      case MessageType.reminder1h:
        return Icons.alarm;
      case MessageType.cancellationNotice:
        return Icons.cancel_outlined;
      case MessageType.followUp:
        return Icons.feedback_outlined;
      case MessageType.waitlistNotification:
        return Icons.notification_important;
      case MessageType.rescheduleNotice:
        return Icons.update;
      case MessageType.paymentReminder:
        return Icons.payment;
    }
  }

  String _getTemplateTypeName(MessageType type) {
    switch (type) {
      case MessageType.bookingConfirmation:
        return 'Booking Confirmation';
      case MessageType.reminder24h:
        return '24-Hour Reminder';
      case MessageType.reminder1h:
        return '1-Hour Reminder';
      case MessageType.cancellationNotice:
        return 'Cancellation Notice';
      case MessageType.followUp:
        return 'Follow-up';
      case MessageType.waitlistNotification:
        return 'Waitlist Notification';
      case MessageType.rescheduleNotice:
        return 'Reschedule Notice';
      case MessageType.paymentReminder:
        return 'Payment Reminder';
    }
  }
}
