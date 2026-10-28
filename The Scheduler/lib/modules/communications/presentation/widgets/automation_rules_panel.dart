import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/communication_config.dart';
import '../../../../core/providers/providers.dart';

/// Panel showing automation rules with toggle switches.
/// Modern design with professional clean styling and sophisticated blue colors.
class AutomationRulesPanel extends ConsumerWidget {
  const AutomationRulesPanel({
    super.key,
    required this.rules,
    this.onRuleToggled,
    this.readOnly = false,
  });

  final List<AutomationRule> rules;
  final Function(AutomationRule)? onRuleToggled;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final branding = ref.watch(appConfigProvider).branding;

    return Container(
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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: branding.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Automation Rules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: branding.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Control when automated messages are sent',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Divider(height: 24),
            ...rules.map((rule) => _buildRuleItem(context, rule)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildRuleItem(BuildContext context, AutomationRule rule) {
    final theme = Theme.of(context);
    final channels = rule.channels.map(_getChannelIcon).join(' ');
    final timing = _getTimingDescription(rule);
    final disabled = readOnly || onRuleToggled == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Switch(
            value: rule.enabled,
            onChanged: disabled ? null : (_) => onRuleToggled?.call(rule),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: rule.enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(channels, style: theme.textTheme.bodySmall),
                    Text(' • ', style: theme.textTheme.bodySmall),
                    Flexible(
                      child: Text(
                        timing,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChannelIcon(MessageChannel channel) {
    switch (channel) {
      case MessageChannel.email:
        return '📧';
      case MessageChannel.sms:
        return '📱';
      case MessageChannel.push:
        return '🔔';
    }
  }

  String _getTimingDescription(AutomationRule rule) {
    switch (rule.trigger) {
      case AutomationTrigger.onBookingCreated:
        return 'Sent immediately when booking is created';
      case AutomationTrigger.onBookingCancelled:
        return 'Sent when booking is cancelled';
      case AutomationTrigger.onBookingRescheduled:
        return 'Sent when booking is rescheduled';
      case AutomationTrigger.beforeAppointment:
        return 'Sent ${_formatDuration(rule.delayDuration)} before appointment';
      case AutomationTrigger.afterAppointment:
        return 'Sent ${_formatDuration(rule.delayDuration)} after appointment';
      case AutomationTrigger.onWaitlistSpot:
        return 'Sent when waitlist spot becomes available';
      case AutomationTrigger.onPaymentDue:
        return 'Sent when payment is due';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}
