/// EXAMPLE: How to integrate the communications system with other modules
/// This file demonstrates the integration patterns for other agents to follow.
/// 
/// This is a reference file - not meant to be imported directly into production code.
library;

import '../../data/repositories/communication_repository.dart';
import '../config/app_config.dart';
import '../config/communication_config.dart';
import '../config/integration_config.dart';
import 'automation_service.dart';
import 'email_service.dart';
import 'sms_service.dart';

/// Example: Setting up the communication services
/// Typically done during app initialization in bootstrap.dart or a DI container
class CommunicationServiceSetup {
  static AutomationService createAutomationService(AppConfig config) {
    final integration = config.integrationConfig;
    final gatewayBase = integration.integrationApiBaseUrl;

    final emailService = _buildEmailService(
      integration.emailProvider,
      gatewayBase,
      config.communicationConfig,
    );

    final smsService = _buildSmsService(
      integration.smsProvider,
      gatewayBase,
      senderId: config.branding.productName,
    );

    final communicationRepo = InMemoryCommunicationRepository(
      config.communicationConfig,
    );

    return AutomationService(
      emailService: emailService,
      smsService: smsService,
      communicationRepository: communicationRepo,
      communicationConfig: config.communicationConfig,
      automationFunctionUrl:
          config.communicationConfig.sendAutomationMessageUrl,
    );
  }

  static EmailService _buildEmailService(
    EmailProviderType provider,
    Uri baseUrl,
    CommunicationConfig communicationConfig,
  ) {
    switch (provider) {
      case EmailProviderType.sendGrid:
        return SendGridEmailService(
          gatewayEndpoint: _appendPath(baseUrl, 'sendgridEmail'),
          senderEmail: communicationConfig.senderEmail,
          senderName: communicationConfig.senderName,
        );
      case EmailProviderType.awsSes:
        return AwsSesEmailService(
          gatewayEndpoint: _appendPath(baseUrl, 'sesEmail'),
          senderEmail: communicationConfig.senderEmail,
          senderName: communicationConfig.senderName,
        );
      case EmailProviderType.mock:
        return MockEmailService();
    }
  }

  static SmsService _buildSmsService(
    SmsProviderType provider,
    Uri baseUrl, {
    String? senderId,
  }) {
    switch (provider) {
      case SmsProviderType.twilio:
        return TwilioSmsService(
          gatewayEndpoint: _appendPath(baseUrl, 'twilioSms'),
        );
      case SmsProviderType.awsSns:
        return AwsSnsSmsService(
          gatewayEndpoint: _appendPath(baseUrl, 'snsSms'),
          senderId: senderId,
        );
      case SmsProviderType.mock:
        return MockSmsService();
    }
  }

  static Uri _appendPath(Uri base, String segment) {
    final normalizedPath =
        base.path.endsWith('/') ? '${base.path}$segment' : '${base.path}/$segment';
    return base.replace(path: normalizedPath);
  }
}

/// Example: Booking Agent integration
/// Call these methods when appointment state changes
class BookingAgentExample {
  final AutomationService _automationService;

  BookingAgentExample(this._automationService);

  /// When a new appointment is created
  Future<void> onAppointmentCreated({
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
    required Map<String, dynamic> clientData,
  }) async {
    await _automationService.onAppointmentCreated(
      appointmentId: appointmentId,
      clientId: clientData['id'] as String,
      clientName: clientData['name'] as String,
      clientEmail: clientData['email'] as String,
      clientPhone: clientData['phone'] as String?,
      appointmentDate: appointmentData['date'] as DateTime,
      appointmentTime: appointmentData['time'] as String,
      providerName: appointmentData['providerName'] as String,
      location: appointmentData['location'] as String,
      serviceType: appointmentData['serviceType'] as String,
      additionalVariables: {
        'custom_instructions': 'Please arrive 10 minutes early.',
      },
    );

    // Also schedule future reminders
    await _automationService.scheduleReminders(
      appointmentId: appointmentId,
      clientId: clientData['id'] as String,
      clientName: clientData['name'] as String,
      clientEmail: clientData['email'] as String,
      clientPhone: clientData['phone'] as String?,
      appointmentDate: appointmentData['date'] as DateTime,
      appointmentTime: appointmentData['time'] as String,
      providerName: appointmentData['providerName'] as String,
      location: appointmentData['location'] as String,
      serviceType: appointmentData['serviceType'] as String,
    );
  }

  /// When an appointment is cancelled
  Future<void> onAppointmentCancelled({
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
    required Map<String, dynamic> clientData,
    String? reason,
  }) async {
    await _automationService.onAppointmentCancelled(
      appointmentId: appointmentId,
      clientId: clientData['id'] as String,
      clientName: clientData['name'] as String,
      clientEmail: clientData['email'] as String,
      clientPhone: clientData['phone'] as String?,
      appointmentDate: appointmentData['date'] as DateTime,
      appointmentTime: appointmentData['time'] as String,
      providerName: appointmentData['providerName'] as String,
      cancellationReason: reason,
    );
  }

  /// When an appointment is rescheduled
  Future<void> onAppointmentRescheduled({
    required String appointmentId,
    required DateTime oldDate,
    required DateTime newDate,
    required Map<String, dynamic> appointmentData,
    required Map<String, dynamic> clientData,
  }) async {
    await _automationService.onAppointmentRescheduled(
      appointmentId: appointmentId,
      clientId: clientData['id'] as String,
      clientName: clientData['name'] as String,
      clientEmail: clientData['email'] as String,
      clientPhone: clientData['phone'] as String?,
      oldDate: oldDate,
      newDate: newDate,
      newTime: appointmentData['time'] as String,
      providerName: appointmentData['providerName'] as String,
      location: appointmentData['location'] as String,
    );
  }
}

/// Example: Calendar Agent integration
/// Implement background jobs for time-based reminders
class CalendarAgentExample {
  final AutomationService _automationService;

  CalendarAgentExample(this._automationService);

  /// Background job that runs periodically (e.g., every hour)
  /// to check for upcoming appointments and send reminders
  Future<void> processScheduledReminders() async {
    // TODO: Query upcoming appointments from database
    // For each appointment in the next 24-48 hours:
    
    // Example appointment
    final appointment = {
      'id': 'appt_123',
      'date': DateTime.now().add(const Duration(hours: 23)),
      'time': '2:00 PM',
      'providerName': 'Dr. Smith',
      'location': 'Main Office',
      'serviceType': 'Consultation',
    };

    final client = {
      'id': 'client_456',
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '+15551234567',
    };

    await _automationService.scheduleReminders(
      appointmentId: appointment['id'] as String,
      clientId: client['id'] as String,
      clientName: client['name'] as String,
      clientEmail: client['email'] as String,
      clientPhone: client['phone'],
      appointmentDate: appointment['date'] as DateTime,
      appointmentTime: appointment['time'] as String,
      providerName: appointment['providerName'] as String,
      location: appointment['location'] as String,
      serviceType: appointment['serviceType'] as String,
    );
  }

  /// Background job for follow-up messages
  /// Run this for completed appointments
  Future<void> processFollowUps() async {
    // TODO: Query appointments completed in last 24 hours
    // For each completed appointment:
    
    final appointment = {
      'id': 'appt_789',
      'date': DateTime.now().subtract(const Duration(hours: 24)),
      'providerName': 'Dr. Smith',
    };

    final client = {
      'id': 'client_456',
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '+15551234567',
    };

    await _automationService.sendFollowUp(
      appointmentId: appointment['id'] as String,
      clientId: client['id'] as String,
      clientName: client['name'] as String,
      clientEmail: client['email'] as String,
      clientPhone: client['phone'],
      appointmentDate: appointment['date'] as DateTime,
      providerName: appointment['providerName'] as String,
      feedbackLink: 'https://scheduler.example.com/feedback/appt_789',
    );
  }
}

/// Example: Clients Agent integration
/// Show communication history in client profiles
class ClientsAgentExample {
  final CommunicationRepository _communicationRepo;

  ClientsAgentExample(this._communicationRepo);

  /// Get message history for a client
  Future<List<MessageHistory>> getClientCommunications(String clientId) async {
    return await _communicationRepo.getMessageHistory(
      clientId: clientId,
      limit: 50,
    );
  }

  /// Get recent SMS messages for a client
  Future<List<MessageHistory>> getClientSmsHistory(String clientId) async {
    return await _communicationRepo.getMessageHistory(
      clientId: clientId,
      channel: MessageChannel.sms,
      limit: 20,
    );
  }

  /// Get communication stats for reporting
  Future<Map<String, int>> getCommunicationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final history = await _communicationRepo.getMessageHistory(
      startDate: startDate,
      endDate: endDate,
      limit: 10000, // Get all for stats
    );

    return {
      'total': history.length,
      'emails': history.where((h) => h.channel == MessageChannel.email).length,
      'sms': history.where((h) => h.channel == MessageChannel.sms).length,
      'failed': history.where((h) => h.status == MessageStatus.failed).length,
    };
  }
}

/// Example: Waitlist feature integration
class WaitlistAgentExample {
  final AutomationService _automationService;

  WaitlistAgentExample(this._automationService);

  /// Notify waitlisted clients when a spot opens
  Future<void> notifyWaitlistedClient({
    required Map<String, dynamic> clientData,
    required DateTime availableDate,
    required String availableTime,
    required String providerName,
  }) async {
    await _automationService.notifyWaitlistSpot(
      clientId: clientData['id'] as String,
      clientName: clientData['name'] as String,
      clientEmail: clientData['email'] as String,
      clientPhone: clientData['phone'] as String?,
      availableDate: availableDate,
      availableTime: availableTime,
      providerName: providerName,
      bookingLink: 'https://scheduler.example.com/book?slot=${availableDate.toIso8601String()}',
    );
  }
}
