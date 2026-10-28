import '../../data/repositories/communication_repository.dart';
import '../config/app_config.dart';
import 'automation_service.dart';
import 'email_service.dart';
import 'sms_service.dart';

export 'automation_service.dart';

/// Centralized helpers for common service wiring to avoid copy/paste.
AutomationService buildAutomationService(
  AppConfig config, {
  CommunicationRepository? communicationRepository,
  EmailService? emailService,
  SmsService? smsService,
  String? automationFunctionUrl,
}) {
  return AutomationService(
    emailService: emailService ?? MockEmailService(),
    smsService: smsService ?? MockSmsService(),
    communicationRepository: communicationRepository ??
        InMemoryCommunicationRepository(config.communicationConfig),
    communicationConfig: config.communicationConfig,
    automationFunctionUrl:
        automationFunctionUrl ?? config.communicationConfig.sendAutomationMessageUrl,
  );
}
