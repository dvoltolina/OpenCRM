/// Action executors for the automation engine.
///
/// Each action type implements a specific automated response
/// (SMS, email, task creation, client flagging).
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter/foundation.dart';

import '../../../core/services/email_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/clients_repository.dart';
import '../automation_rule.dart';

/// Context data passed to action executors.
class ActionExecutionContext {
  final SecurityContext securityContext;
  final String entityType;
  final String entityId;
  final Client? client;
  final Map<String, dynamic> triggerContext;
  final bool dryRun;

  ActionExecutionContext({
    required this.securityContext,
    required this.entityType,
    required this.entityId,
    this.client,
    required this.triggerContext,
    this.dryRun = false,
  });

  /// Template variables available for message rendering.
  Map<String, String> get templateVariables {
    final vars = <String, String>{
      'businessId': securityContext.businessId,
      'entityType': entityType,
      'entityId': entityId,
    };

    if (client != null) {
      vars['clientFirstName'] = client!.firstName;
      vars['clientLastName'] = client!.lastName;
      vars['clientName'] = '${client!.firstName} ${client!.lastName}';
      vars['clientEmail'] = client!.email ?? '';
      vars['clientPhone'] = client!.phone ?? '';
    }

    // Add trigger context values (converted to strings)
    triggerContext.forEach((key, value) {
      if (value is String) {
        vars[key] = value;
      } else if (value is num || value is bool) {
        vars[key] = value.toString();
      }
    });

    return vars;
  }
}

/// Base class for all action executors.
abstract class ActionExecutor {
  /// Execute the action.
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  });

  /// Render a message template with variables.
  @protected
  String renderTemplate(String template, Map<String, String> variables) {
    var result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}

/// Sends SMS messages via SmsService.
class SendSmsActionExecutor extends ActionExecutor {
  final SmsService _smsService;

  SendSmsActionExecutor({required SmsService smsService})
      : _smsService = smsService;

  @override
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Validate client has phone number
      final phone = context.client?.phone;
      if (phone == null || phone.isEmpty) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendSms,
          message: 'Cannot send SMS: client has no phone number',
          error: 'missing_phone',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'clientId': context.client?.id,
            'entityId': context.entityId,
          },
        );
      }

      // Validate phone format
      if (!_smsService.isValidPhoneNumber(phone)) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendSms,
          message: 'Cannot send SMS: invalid phone number format',
          error: 'invalid_phone',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'phone': phone},
        );
      }

      // Render message
      final messageTemplate = config.messageTemplate ?? _getDefaultTemplate();
      final message = renderTemplate(messageTemplate, context.templateVariables);

      // Dry run - don't actually send
      if (context.dryRun) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.sendSms,
          message: 'DRY RUN: Would send SMS to $phone',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'phone': phone,
            'message': message,
            'dryRun': true,
          },
        );
      }

      // Send SMS
      final result = await _smsService.sendPlainSms(
        recipientPhone: phone,
        message: message,
      );

      stopwatch.stop();

      if (result.success) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.sendSms,
          message: 'SMS sent successfully',
          externalId: result.messageId,
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'phone': phone,
            'messageLength': message.length,
            'segments': result.segments,
          },
        );
      } else {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendSms,
          message: 'Failed to send SMS',
          error: result.error ?? 'unknown_error',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'phone': phone},
        );
      }
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        actionType: AutomationActionType.sendSms,
        message: 'SMS action failed with exception',
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  String _getDefaultTemplate() {
    return 'Hi {{clientFirstName}}, this is a reminder about your upcoming appointment.';
  }
}

/// Sends emails via EmailService.
class SendEmailActionExecutor extends ActionExecutor {
  final EmailService _emailService;

  SendEmailActionExecutor({required EmailService emailService})
      : _emailService = emailService;

  @override
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Validate client has email
      final email = context.client?.email;
      if (email == null || email.isEmpty) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendEmail,
          message: 'Cannot send email: client has no email address',
          error: 'missing_email',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'clientId': context.client?.id,
            'entityId': context.entityId,
          },
        );
      }

      // Validate email format
      if (!_emailService.isValidEmail(email)) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendEmail,
          message: 'Cannot send email: invalid email format',
          error: 'invalid_email',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'email': email},
        );
      }

      // Render subject and body
      final subject = config.emailSubject ?? 'Appointment Reminder';
      final body = config.messageTemplate ?? _getDefaultTemplate();
      final renderedSubject = renderTemplate(subject, context.templateVariables);
      final renderedBody = renderTemplate(body, context.templateVariables);

      // Dry run - don't actually send
      if (context.dryRun) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.sendEmail,
          message: 'DRY RUN: Would send email to $email',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'email': email,
            'subject': renderedSubject,
            'bodyPreview': renderedBody.substring(0, renderedBody.length.clamp(0, 100)),
            'dryRun': true,
          },
        );
      }

      // Send email
      final clientName = context.client != null
          ? '${context.client!.firstName} ${context.client!.lastName}'
          : 'Client';

      final result = await _emailService.sendPlainEmail(
        recipientEmail: email,
        recipientName: clientName,
        subject: renderedSubject,
        body: renderedBody,
      );

      stopwatch.stop();

      if (result.success) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.sendEmail,
          message: 'Email sent successfully',
          externalId: result.messageId,
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'email': email,
            'subject': renderedSubject,
          },
        );
      } else {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.sendEmail,
          message: 'Failed to send email',
          error: result.error ?? 'unknown_error',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {'email': email},
        );
      }
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        actionType: AutomationActionType.sendEmail,
        message: 'Email action failed with exception',
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  String _getDefaultTemplate() {
    return '''
Dear {{clientFirstName}},

This is a friendly reminder about your upcoming appointment.

We look forward to seeing you!

Best regards,
Your appointment team
''';
  }
}

/// Creates follow-up tasks for staff.
class CreateTaskActionExecutor extends ActionExecutor {
  // Note: In a full implementation, this would integrate with a TasksRepository
  // For now, we log the task creation intent

  @override
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final title = config.taskTitle ?? 'Follow up with client';
      final description = config.taskDescription ?? 'Automated task created by risk automation';
      final priority = config.taskPriority;

      final renderedTitle = renderTemplate(title, context.templateVariables);
      final renderedDescription = renderTemplate(description, context.templateVariables);

      // Dry run - don't actually create
      if (context.dryRun) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.createTask,
          message: 'DRY RUN: Would create task "$renderedTitle"',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'title': renderedTitle,
            'description': renderedDescription,
            'priority': priority,
            'dryRun': true,
          },
        );
      }

      // TODO: Integrate with actual TasksRepository when available
      // For now, we simulate task creation
      final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('CreateTaskAction: Creating task "$renderedTitle" '
          'for entity ${context.entityType}/${context.entityId}');

      stopwatch.stop();

      return ActionExecutionResult.success(
        actionType: AutomationActionType.createTask,
        message: 'Task created: $renderedTitle',
        externalId: taskId,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'taskId': taskId,
          'title': renderedTitle,
          'description': renderedDescription,
          'priority': priority,
          'clientId': context.client?.id,
          'entityType': context.entityType,
          'entityId': context.entityId,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        actionType: AutomationActionType.createTask,
        message: 'Task creation failed with exception',
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

/// Adds flags/tags to client records.
class FlagClientActionExecutor extends ActionExecutor {
  final ClientsRepository _clientsRepository;

  FlagClientActionExecutor({required ClientsRepository clientsRepository})
      : _clientsRepository = clientsRepository;

  @override
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final client = context.client;
      if (client == null) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.flagClient,
          message: 'Cannot flag client: client not found',
          error: 'missing_client',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      final flagName = config.flagName;
      if (flagName == null || flagName.isEmpty) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.flagClient,
          message: 'Cannot flag client: no flag name specified',
          error: 'missing_flag_name',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Check if client already has this flag
      final currentTags = client.tags;
      if (currentTags.contains(flagName)) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.flagClient,
          message: 'Client already has flag "$flagName"',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'clientId': client.id,
            'flagName': flagName,
            'alreadyHadFlag': true,
          },
        );
      }

      // Dry run - don't actually update
      if (context.dryRun) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.flagClient,
          message: 'DRY RUN: Would add flag "$flagName" to client',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'clientId': client.id,
            'flagName': flagName,
            'currentTags': currentTags,
            'dryRun': true,
          },
        );
      }

      // Add the flag to client's tags
      final updatedTags = [...currentTags, flagName];
      final updatedClient = client.copyWith(tags: updatedTags);

      await _clientsRepository.updateClient(
        context: context.securityContext,
        client: updatedClient,
      );

      stopwatch.stop();

      return ActionExecutionResult.success(
        actionType: AutomationActionType.flagClient,
        message: 'Added flag "$flagName" to client',
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'clientId': client.id,
          'flagName': flagName,
          'previousTagCount': currentTags.length,
          'newTagCount': updatedTags.length,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        actionType: AutomationActionType.flagClient,
        message: 'Failed to flag client',
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

/// Sends internal alerts to staff members.
class AlertStaffActionExecutor extends ActionExecutor {
  // Note: In a full implementation, this would integrate with NotificationService
  // For now, we log the alert intent

  @override
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final recipients = config.alertRecipients;
      if (recipients.isEmpty) {
        return ActionExecutionResult.failure(
          actionType: AutomationActionType.alertStaff,
          message: 'Cannot send alert: no recipients specified',
          error: 'missing_recipients',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      final message = config.messageTemplate ?? _getDefaultAlertMessage();
      final renderedMessage = renderTemplate(message, context.templateVariables);

      // Dry run - don't actually send
      if (context.dryRun) {
        return ActionExecutionResult.success(
          actionType: AutomationActionType.alertStaff,
          message: 'DRY RUN: Would alert ${recipients.length} staff members',
          durationMs: stopwatch.elapsedMilliseconds,
          metadata: {
            'recipients': recipients,
            'message': renderedMessage,
            'dryRun': true,
          },
        );
      }

      // TODO: Integrate with NotificationService when available
      final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('AlertStaffAction: Sending alert to ${recipients.length} '
          'recipients for entity ${context.entityType}/${context.entityId}');

      stopwatch.stop();

      return ActionExecutionResult.success(
        actionType: AutomationActionType.alertStaff,
        message: 'Alert sent to ${recipients.length} staff members',
        externalId: alertId,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'alertId': alertId,
          'recipientCount': recipients.length,
          'recipients': recipients,
          'entityType': context.entityType,
          'entityId': context.entityId,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        actionType: AutomationActionType.alertStaff,
        message: 'Staff alert failed with exception',
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  String _getDefaultAlertMessage() {
    return 'Action required: Client {{clientName}} requires attention. '
        'Risk automation triggered for {{entityType}} {{entityId}}.';
  }
}

/// Factory for creating action executors.
class ActionExecutorFactory {
  final SmsService? smsService;
  final EmailService? emailService;
  final ClientsRepository? clientsRepository;

  ActionExecutorFactory({
    this.smsService,
    this.emailService,
    this.clientsRepository,
  });

  /// Get executor for an action type.
  ActionExecutor? getExecutor(AutomationActionType type) {
    return switch (type) {
      AutomationActionType.sendSms => smsService != null
          ? SendSmsActionExecutor(smsService: smsService!)
          : null,
      AutomationActionType.sendEmail => emailService != null
          ? SendEmailActionExecutor(emailService: emailService!)
          : null,
      AutomationActionType.createTask => CreateTaskActionExecutor(),
      AutomationActionType.flagClient => clientsRepository != null
          ? FlagClientActionExecutor(clientsRepository: clientsRepository!)
          : null,
      AutomationActionType.alertStaff => AlertStaffActionExecutor(),
    };
  }

  /// Execute an action configuration.
  Future<ActionExecutionResult> execute({
    required AutomationActionConfig config,
    required ActionExecutionContext context,
  }) async {
    final executor = getExecutor(config.type);

    if (executor == null) {
      return ActionExecutionResult.failure(
        actionType: config.type,
        message: 'No executor available for action type ${config.type.name}',
        error: 'missing_executor',
      );
    }

    return executor.execute(config: config, context: context);
  }
}
