import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/communication_config.dart';
import '../../data/repositories/communication_repository.dart';
import 'email_service.dart';
import 'sms_service.dart';

/// Service that orchestrates automated communications based on appointment events.
/// Checks automation rules and schedules/sends messages accordingly.
class AutomationService {
  AutomationService({
    required this.emailService,
    required this.smsService,
    required this.communicationRepository,
    required this.communicationConfig,
    this.automationFunctionUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final EmailService emailService;
  final SmsService smsService;
  final CommunicationRepository communicationRepository;
  final CommunicationConfig communicationConfig;
  final String? automationFunctionUrl;
  final http.Client _httpClient;

  /// Handle appointment created event
  Future<void> onAppointmentCreated({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String providerName,
    required String location,
    required String serviceType,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final variables = _buildVariables(
      clientName: clientName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      providerName: providerName,
      location: location,
      serviceType: serviceType,
      additionalVariables: additionalVariables,
    );

    final triggered = await _triggerCloudAutomation(
      trigger: AutomationTrigger.onBookingCreated,
      businessId: businessId,
      userId: userId,
      appointmentId: appointmentId,
      clientId: clientId,
      variables: variables,
      appointmentDate: appointmentDate,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
    );

    if (triggered) return;

    final rules = await _getActiveRules(AutomationTrigger.onBookingCreated);

    for (final rule in rules) {
      await _executeRule(
        rule: rule,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        appointmentId: appointmentId,
        variables: variables,
      );
    }
  }

  /// Handle appointment cancelled event
  Future<void> onAppointmentCancelled({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String providerName,
    String? cancellationReason,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final variables = _buildVariables(
      clientName: clientName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      providerName: providerName,
      location: 'N/A',
      serviceType: 'N/A',
      additionalVariables: {
        'cancellation_reason': cancellationReason ?? 'No reason provided',
        ...?additionalVariables,
      },
    );

    final triggered = await _triggerCloudAutomation(
      trigger: AutomationTrigger.onBookingCancelled,
      businessId: businessId,
      userId: userId,
      appointmentId: appointmentId,
      clientId: clientId,
      variables: variables,
      appointmentDate: appointmentDate,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
    );

    if (triggered) return;

    final rules = await _getActiveRules(AutomationTrigger.onBookingCancelled);

    for (final rule in rules) {
      await _executeRule(
        rule: rule,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        appointmentId: appointmentId,
        variables: variables,
      );
    }
  }

  /// Handle appointment rescheduled event
  Future<void> onAppointmentRescheduled({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime oldDate,
    required DateTime newDate,
    required String newTime,
    required String providerName,
    required String location,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final variables = _buildVariables(
      clientName: clientName,
      appointmentDate: newDate,
      appointmentTime: newTime,
      providerName: providerName,
      location: location,
      serviceType: 'N/A',
      additionalVariables: {
        'old_date': _formatDate(oldDate),
        'new_date': _formatDate(newDate),
        ...?additionalVariables,
      },
    );

    final triggered = await _triggerCloudAutomation(
      trigger: AutomationTrigger.onBookingRescheduled,
      businessId: businessId,
      userId: userId,
      appointmentId: appointmentId,
      clientId: clientId,
      variables: variables,
      appointmentDate: newDate,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
    );

    if (triggered) return;

    final rules = await _getActiveRules(AutomationTrigger.onBookingRescheduled);

    for (final rule in rules) {
      await _executeRule(
        rule: rule,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        appointmentId: appointmentId,
        variables: variables,
      );
    }
  }

  /// Schedule reminder messages for an appointment
  /// This would typically be called by a background job/scheduler
  Future<void> scheduleReminders({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String providerName,
    required String location,
    required String serviceType,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final rules = await _getActiveRules(AutomationTrigger.beforeAppointment);
    final now = DateTime.now();

    for (final rule in rules) {
      // Calculate when to send this reminder
      final sendAt = appointmentDate.subtract(rule.delayDuration);

      if (sendAt.isAfter(now)) {
        developer.log(
          '⏰ Reminder scheduled for $sendAt (${rule.name})',
          name: 'AutomationService',
        );
        // In production, this would create a scheduled task
        // For now, just log it
        // TODO: Integrate with Cloud Scheduler, AWS EventBridge, or similar
      } else if (sendAt.isBefore(now) && 
                 appointmentDate.isAfter(now) && 
                 now.difference(sendAt).inHours < 1) {
        // If we're within the reminder window, send immediately
        await _executeRule(
          rule: rule,
          clientId: clientId,
          clientName: clientName,
          clientEmail: clientEmail,
          clientPhone: clientPhone,
          appointmentId: appointmentId,
          variables: _buildVariables(
            clientName: clientName,
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            providerName: providerName,
            location: location,
            serviceType: serviceType,
            additionalVariables: additionalVariables,
          ),
          businessId: businessId,
          userId: userId,
        );
      }
    }
  }

  /// Send follow-up messages after appointment
  /// Called by background scheduler after appointment completes
  Future<void> sendFollowUp({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime appointmentDate,
    required String providerName,
    String? feedbackLink,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final variables = _buildVariables(
      clientName: clientName,
      appointmentDate: appointmentDate,
      appointmentTime: 'N/A',
      providerName: providerName,
      location: 'N/A',
      serviceType: 'N/A',
      additionalVariables: {
        'feedback_link': feedbackLink ?? 'https://example.com/feedback',
        ...?additionalVariables,
      },
    );

    final triggered = await _triggerCloudAutomation(
      trigger: AutomationTrigger.afterAppointment,
      businessId: businessId,
      userId: userId,
      appointmentId: appointmentId,
      clientId: clientId,
      variables: variables,
      appointmentDate: appointmentDate,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
    );

    if (triggered) return;

    final rules = await _getActiveRules(AutomationTrigger.afterAppointment);

    for (final rule in rules) {
      await _executeRule(
        rule: rule,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        appointmentId: appointmentId,
        variables: variables,
      );
    }
  }

  /// Notify waitlisted client when spot opens
  Future<void> notifyWaitlistSpot({
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime availableDate,
    required String availableTime,
    required String providerName,
    required String bookingLink,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    final rules = await _getActiveRules(AutomationTrigger.onWaitlistSpot);

    for (final rule in rules) {
      await _executeRule(
        rule: rule,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        appointmentId: null,
        variables: _buildVariables(
          clientName: clientName,
          appointmentDate: availableDate,
          appointmentTime: availableTime,
          providerName: providerName,
          location: 'N/A',
          serviceType: 'N/A',
          additionalVariables: {
            'booking_link': bookingLink,
            ...?additionalVariables,
          },
        ),
      );
    }
  }

  /// Get active automation rules for a trigger
  Future<List<AutomationRule>> _getActiveRules(AutomationTrigger trigger) async {
    final allRules = await communicationRepository.getAutomationRules();
    return allRules
        .where((rule) => rule.enabled && rule.trigger == trigger)
        .toList();
  }

  /// Dispatch automation to Cloud Functions when configured.
  Future<bool> _triggerCloudAutomation({
    required AutomationTrigger trigger,
    required String? businessId,
    required String? userId,
    required String appointmentId,
    required String clientId,
    required Map<String, String> variables,
    required DateTime appointmentDate,
    required String clientEmail,
    required String? clientPhone,
  }) async {
    if (automationFunctionUrl == null || businessId == null || userId == null) {
      return false;
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(automationFunctionUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': businessId,
          'userId': userId,
          'trigger': trigger.name,
          'appointmentId': appointmentId,
          'clientId': clientId,
          'customData': {
            ...variables,
            'appointmentDate': appointmentDate.toIso8601String(),
            'clientEmail': clientEmail,
            'clientPhone': clientPhone,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      developer.log(
        'Automation function returned ${response.statusCode}',
        name: 'AutomationService',
      );
    } catch (error) {
      developer.log(
        'Automation function error',
        name: 'AutomationService',
        error: error,
      );
    }

    return false;
  }

  /// Execute a rule by sending messages on configured channels
  Future<void> _executeRule({
    required AutomationRule rule,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required String? appointmentId,
    required Map<String, String> variables,
    String? businessId,
    String? userId,
  }) async {
    for (final channel in rule.channels) {
      if (channel == MessageChannel.email) {
        if (!communicationConfig.emailEnabled) continue;
        await _sendEmail(
          rule: rule,
          clientId: clientId,
          clientName: clientName,
          clientEmail: clientEmail,
          appointmentId: appointmentId,
          variables: variables,
        );
      } else if (channel == MessageChannel.sms) {
        if (!communicationConfig.smsEnabled) continue;
        if (clientPhone != null && clientPhone.isNotEmpty) {
          await _sendSms(
            rule: rule,
            clientId: clientId,
            clientName: clientName,
            clientPhone: clientPhone,
            appointmentId: appointmentId,
            variables: variables,
          );
        } else {
          developer.log(
            '⚠️  Skipping SMS - no phone number for client $clientName',
            name: 'AutomationService',
          );
        }
      }
    }
  }

  /// Send email for a rule
  Future<void> _sendEmail({
    required AutomationRule rule,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? appointmentId,
    required Map<String, String> variables,
  }) async {
    final template = communicationConfig.emailTemplates[rule.messageType];
    if (template == null) {
      developer.log(
        '❌ No email template found for ${rule.messageType.name}',
        name: 'AutomationService',
      );
      return;
    }

    final result = await emailService.sendTemplatedEmail(
      recipientEmail: clientEmail,
      recipientName: clientName,
      template: template,
      variables: variables,
    );

    // Log the message
    await communicationRepository.logMessage(
      MessageHistory.fromEmailLog(
        clientId: clientId,
        clientName: clientName,
        recipientEmail: clientEmail,
        subject: template.renderSubject(variables),
        body: template.render(variables),
        messageType: rule.messageType,
        success: result.success,
        errorMessage: result.error,
        appointmentId: appointmentId,
      ),
    );

    if (result.success) {
      developer.log(
        'Email sent (${rule.messageType.name})',
        name: 'AutomationService',
      );
    } else {
      developer.log(
        'Email failed',
        name: 'AutomationService',
      );
    }
  }

  /// Send SMS for a rule
  Future<void> _sendSms({
    required AutomationRule rule,
    required String clientId,
    required String clientName,
    required String clientPhone,
    required String? appointmentId,
    required Map<String, String> variables,
  }) async {
    final template = communicationConfig.smsTemplates[rule.messageType];
    if (template == null) {
      developer.log(
        'No SMS template found for ${rule.messageType.name}',
        name: 'AutomationService',
      );
      return;
    }

    final result = await smsService.sendTemplatedSms(
      recipientPhone: clientPhone,
      template: template,
      variables: variables,
    );

    // Log the message
    await communicationRepository.logMessage(
      MessageHistory.fromSmsLog(
        clientId: clientId,
        clientName: clientName,
        recipientPhone: clientPhone,
        message: template.render(variables),
        messageType: rule.messageType,
        success: result.success,
        errorMessage: result.error,
        appointmentId: appointmentId,
      ),
    );

    if (result.success) {
      developer.log(
        'SMS sent (${rule.messageType.name})',
        name: 'AutomationService',
      );
    } else {
      developer.log(
        'SMS failed',
        name: 'AutomationService',
      );
    }
  }

  /// Build standard template variables
  Map<String, String> _buildVariables({
    required String clientName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String providerName,
    required String location,
    required String serviceType,
    Map<String, String>? additionalVariables,
  }) {
    return {
      'client_name': clientName,
      'date': _formatDate(appointmentDate),
      'time': appointmentTime,
      'location': location,
      'provider_name': providerName,
      'service_type': serviceType,
      'business_name': communicationConfig.senderName,
      'support_phone': communicationConfig.supportPhone,
      'cancellation_hours': '24', // Could be dynamic from config
      'custom_instructions': '',
      'preparation_instructions': '',
      'booking_link': 'https://scheduler.example.com/book',
      'feedback_link': 'https://scheduler.example.com/feedback',
      'meeting_link': '',
      'telehealth_passcode': '',
      ...?additionalVariables,
    };
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
