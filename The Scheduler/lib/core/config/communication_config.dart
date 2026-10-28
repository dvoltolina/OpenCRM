/// Communication templates and automation rules configuration.
/// Clients customize these to match their brand voice and scheduling needs.
class CommunicationConfig {
  const CommunicationConfig({
    required this.emailTemplates,
    required this.smsTemplates,
    required this.automationRules,
    this.senderEmail = 'noreply@scheduler.example.com',
    this.senderName = 'Scheduler HQ',
    this.replyToEmail,
    this.supportPhone = '(555) 123-4567',
    this.emailEnabled = true,
    this.smsEnabled = true,
    this.sendTestMessageUrl,
    this.sendAutomationMessageUrl,
    this.handleReleasedSlotUrl,
    this.notifyWaitlistEntryUrl,
  });

  final Map<MessageType, MessageTemplate> emailTemplates;
  final Map<MessageType, MessageTemplate> smsTemplates;
  final List<AutomationRule> automationRules;
  
  /// Email address used in the "From" field
  final String senderEmail;
  
  /// Display name for email sender
  final String senderName;
  
  /// Optional reply-to address (if different from sender)
  final String? replyToEmail;
  
  /// Support phone number displayed in messages
  final String supportPhone;

  /// Toggle email sending (per-tenant override)
  final bool emailEnabled;

  /// Toggle SMS sending (per-tenant override)
  final bool smsEnabled;

  /// HTTPS function endpoint for sending test messages.
  final String? sendTestMessageUrl;

  /// HTTPS function endpoint for automation events (confirmation/reminder/etc).
  final String? sendAutomationMessageUrl;

  /// HTTPS function endpoint that notifies waitlist entries when slots free up.
  final String? handleReleasedSlotUrl;

  /// HTTPS function endpoint for manually notifying a waitlist entry.
  final String? notifyWaitlistEntryUrl;

  /// Provides sensible defaults for a clinic/therapy practice
  factory CommunicationConfig.defaultClinic() {
    return CommunicationConfig(
      senderEmail: 'appointments@scheduler.example.com',
      senderName: 'Scheduler HQ',
      replyToEmail: 'support@scheduler.example.com',
      supportPhone: '(555) 123-4567',
      emailEnabled: true,
      smsEnabled: true,
      emailTemplates: {
        MessageType.bookingConfirmation: MessageTemplate(
          type: MessageType.bookingConfirmation,
          channel: MessageChannel.email,
          subject: 'Appointment Confirmed - {{date}} at {{time}}',
          body: '''
Hello {{client_name}},

Your appointment has been confirmed:

📅 Date: {{date}}
⏰ Time: {{time}}
📍 Location: {{location}}
👤 Provider: {{provider_name}}
🏥 Service: {{service_type}}

If you need to reschedule or cancel, please contact us at {{support_phone}} 
at least {{cancellation_hours}} hours in advance.

{{custom_instructions}}

We look forward to seeing you!

Best regards,
{{business_name}}
''',
          variables: _bookingVariables,
        ),
        MessageType.reminder24h: MessageTemplate(
          type: MessageType.reminder24h,
          channel: MessageChannel.email,
          subject: 'Reminder: Tomorrow at {{time}} - {{business_name}}',
          body: '''
Hello {{client_name}},

This is a friendly reminder of your appointment tomorrow:

⏰ {{date}} at {{time}}
📍 {{location}}
👤 With {{provider_name}}

{{preparation_instructions}}

Reply YES to confirm or call us at {{support_phone}} to reschedule.

See you soon,
{{business_name}}
''',
          variables: _bookingVariables,
        ),
        MessageType.reminder1h: MessageTemplate(
          type: MessageType.reminder1h,
          channel: MessageChannel.email,
          subject: 'Starting Soon: Your appointment in 1 hour',
          body: '''
Hello {{client_name}},

Your appointment with {{provider_name}} starts in approximately 1 hour.

Time: {{time}}
Location: {{location}}

We look forward to seeing you!
''',
          variables: _bookingVariables,
        ),
        MessageType.cancellationNotice: MessageTemplate(
          type: MessageType.cancellationNotice,
          channel: MessageChannel.email,
          subject: 'Appointment Cancelled',
          body: '''
Hello {{client_name}},

Your appointment scheduled for {{date}} at {{time}} has been cancelled.

{{cancellation_reason}}

To reschedule, please contact us at {{support_phone}} or visit our booking portal.

Best regards,
{{business_name}}
''',
          variables: _bookingVariables,
        ),
        MessageType.followUp: MessageTemplate(
          type: MessageType.followUp,
          channel: MessageChannel.email,
          subject: 'How was your visit?',
          body: '''
Hello {{client_name}},

Thank you for visiting us on {{date}}. We hope everything went well!

We'd love to hear your feedback. Please take a moment to let us know how we did.

{{feedback_link}}

If you have any questions or concerns, don't hesitate to reach out at {{support_phone}}.

Best regards,
{{business_name}}
''',
          variables: _bookingVariables,
        ),
        MessageType.waitlistNotification: MessageTemplate(
          type: MessageType.waitlistNotification,
          channel: MessageChannel.email,
          subject: 'Spot Available - {{date}} at {{time}}',
          body: '''
Hello {{client_name}},

Good news! A spot has opened up on your preferred date:

📅 {{date}} at {{time}}
👤 {{provider_name}}

This spot is available on a first-come, first-served basis. 
Click the link below to book now or call {{support_phone}}.

{{booking_link}}

Best regards,
{{business_name}}
''',
          variables: _bookingVariables,
        ),
      },
      smsTemplates: {
        MessageType.bookingConfirmation: MessageTemplate(
          type: MessageType.bookingConfirmation,
          channel: MessageChannel.sms,
          subject: '', // SMS doesn't use subject
          body: '''
{{business_name}}: Appointment confirmed for {{date}} at {{time}} with {{provider_name}}. Call {{support_phone}} to change. See you soon!
''',
          variables: _bookingVariables,
        ),
        MessageType.reminder24h: MessageTemplate(
          type: MessageType.reminder24h,
          channel: MessageChannel.sms,
          subject: '',
          body: '''
Hi {{client_name}}, reminder of your appointment tomorrow at {{time}} with {{provider_name}}. Reply YES to confirm or call {{support_phone}} to reschedule.
''',
          variables: _bookingVariables,
        ),
        MessageType.reminder1h: MessageTemplate(
          type: MessageType.reminder1h,
          channel: MessageChannel.sms,
          subject: '',
          body: '''
{{business_name}}: Your appointment with {{provider_name}} starts in 1 hour at {{location}}. See you soon!
''',
          variables: _bookingVariables,
        ),
        MessageType.cancellationNotice: MessageTemplate(
          type: MessageType.cancellationNotice,
          channel: MessageChannel.sms,
          subject: '',
          body: '''
{{business_name}}: Your appointment on {{date}} at {{time}} has been cancelled. Call {{support_phone}} to reschedule.
''',
          variables: _bookingVariables,
        ),
        MessageType.followUp: MessageTemplate(
          type: MessageType.followUp,
          channel: MessageChannel.sms,
          subject: '',
          body: '''
Thanks for visiting {{business_name}}! We'd love your feedback: {{feedback_link}}
''',
          variables: _bookingVariables,
        ),
        MessageType.waitlistNotification: MessageTemplate(
          type: MessageType.waitlistNotification,
          channel: MessageChannel.sms,
          subject: '',
          body: '''
{{business_name}}: Spot available {{date}} at {{time}} with {{provider_name}}! Book now: {{booking_link}} or call {{support_phone}}
''',
          variables: _bookingVariables,
        ),
      },
      automationRules: [
        AutomationRule(
          id: 'confirmation_on_booking',
          name: 'Booking Confirmation',
          trigger: AutomationTrigger.onBookingCreated,
          messageType: MessageType.bookingConfirmation,
          channels: {MessageChannel.email, MessageChannel.sms},
          delayDuration: Duration.zero,
          enabled: true,
        ),
        AutomationRule(
          id: 'reminder_24h',
          name: '24-Hour Reminder',
          trigger: AutomationTrigger.beforeAppointment,
          messageType: MessageType.reminder24h,
          channels: {MessageChannel.email, MessageChannel.sms},
          delayDuration: const Duration(hours: 24),
          enabled: true,
        ),
        AutomationRule(
          id: 'reminder_1h',
          name: '1-Hour Reminder',
          trigger: AutomationTrigger.beforeAppointment,
          messageType: MessageType.reminder1h,
          channels: {MessageChannel.sms},
          delayDuration: const Duration(hours: 1),
          enabled: false, // disabled by default, opt-in
        ),
        AutomationRule(
          id: 'cancellation_notice',
          name: 'Cancellation Notice',
          trigger: AutomationTrigger.onBookingCancelled,
          messageType: MessageType.cancellationNotice,
          channels: {MessageChannel.email, MessageChannel.sms},
          delayDuration: Duration.zero,
          enabled: true,
        ),
        AutomationRule(
          id: 'followup_24h',
          name: 'Post-Visit Follow-up',
          trigger: AutomationTrigger.afterAppointment,
          messageType: MessageType.followUp,
          channels: {MessageChannel.email},
          delayDuration: const Duration(hours: 24),
          enabled: true,
        ),
        AutomationRule(
          id: 'waitlist_notify',
          name: 'Waitlist Notification',
          trigger: AutomationTrigger.onWaitlistSpot,
          messageType: MessageType.waitlistNotification,
          channels: {MessageChannel.email, MessageChannel.sms},
          delayDuration: Duration.zero,
          enabled: true,
        ),
      ],
      sendTestMessageUrl:
          'https://your-function-url.example.com',
      sendAutomationMessageUrl:
          'https://your-function-url.example.com',
      handleReleasedSlotUrl:
          'https://your-function-url.example.com',
      notifyWaitlistEntryUrl:
          'https://your-function-url.example.com',
    );
  }

  CommunicationConfig copyWith({
    Map<MessageType, MessageTemplate>? emailTemplates,
    Map<MessageType, MessageTemplate>? smsTemplates,
    List<AutomationRule>? automationRules,
    String? senderEmail,
    String? senderName,
    String? replyToEmail,
    String? supportPhone,
    bool? emailEnabled,
    bool? smsEnabled,
    String? sendTestMessageUrl,
    String? sendAutomationMessageUrl,
    String? handleReleasedSlotUrl,
    String? notifyWaitlistEntryUrl,
  }) {
    return CommunicationConfig(
      emailTemplates: emailTemplates ?? this.emailTemplates,
      smsTemplates: smsTemplates ?? this.smsTemplates,
      automationRules: automationRules ?? this.automationRules,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      replyToEmail: replyToEmail ?? this.replyToEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      sendTestMessageUrl: sendTestMessageUrl ?? this.sendTestMessageUrl,
      sendAutomationMessageUrl:
          sendAutomationMessageUrl ?? this.sendAutomationMessageUrl,
      handleReleasedSlotUrl:
          handleReleasedSlotUrl ?? this.handleReleasedSlotUrl,
      notifyWaitlistEntryUrl:
          notifyWaitlistEntryUrl ?? this.notifyWaitlistEntryUrl,
    );
  }
}

/// Standard variables available in booking-related templates
const _bookingVariables = [
  'client_name',
  'date',
  'time',
  'location',
  'provider_name',
  'service_type',
  'business_name',
  'support_phone',
  'cancellation_hours',
  'custom_instructions',
  'preparation_instructions',
  'booking_link',
  'feedback_link',
  'cancellation_reason',
];

/// Types of automated messages
enum MessageType {
  bookingConfirmation,
  reminder24h,
  reminder1h,
  cancellationNotice,
  followUp,
  waitlistNotification,
  rescheduleNotice,
  paymentReminder,
}

/// Communication channels
enum MessageChannel {
  email,
  sms,
  push, // future: push notifications
}

/// Template for a message
class MessageTemplate {
  const MessageTemplate({
    required this.type,
    required this.channel,
    required this.subject,
    required this.body,
    required this.variables,
  });

  final MessageType type;
  final MessageChannel channel;
  final String subject; // empty for SMS
  final String body;
  final List<String> variables;

  /// Replace template variables with actual values
  String render(Map<String, String> values) {
    var result = body;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  String renderSubject(Map<String, String> values) {
    var result = subject;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  MessageTemplate copyWith({
    MessageType? type,
    MessageChannel? channel,
    String? subject,
    String? body,
    List<String>? variables,
  }) {
    return MessageTemplate(
      type: type ?? this.type,
      channel: channel ?? this.channel,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      variables: variables ?? this.variables,
    );
  }
}

/// Triggers for automation rules
enum AutomationTrigger {
  onBookingCreated,
  onBookingCancelled,
  onBookingRescheduled,
  beforeAppointment, // X hours/days before
  afterAppointment, // X hours/days after
  onWaitlistSpot,
  onPaymentDue,
}

/// Automation rule defining when and how to send messages
class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.messageType,
    required this.channels,
    required this.delayDuration,
    this.enabled = true,
    this.conditions,
  });

  final String id;
  final String name;
  final AutomationTrigger trigger;
  final MessageType messageType;
  final Set<MessageChannel> channels;
  
  /// Delay from trigger (e.g., 24h before appointment)
  /// For beforeAppointment: Duration(hours: 24) means "24h before"
  /// For afterAppointment: Duration(hours: 24) means "24h after"
  final Duration delayDuration;
  
  final bool enabled;
  
  /// Optional conditions (e.g., only if client has email)
  final Map<String, dynamic>? conditions;

  AutomationRule copyWith({
    String? id,
    String? name,
    AutomationTrigger? trigger,
    MessageType? messageType,
    Set<MessageChannel>? channels,
    Duration? delayDuration,
    bool? enabled,
    Map<String, dynamic>? conditions,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      trigger: trigger ?? this.trigger,
      messageType: messageType ?? this.messageType,
      channels: channels ?? this.channels,
      delayDuration: delayDuration ?? this.delayDuration,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
    );
  }
}
