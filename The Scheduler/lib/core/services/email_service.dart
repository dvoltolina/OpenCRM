import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/communication_config.dart';

/// Service interface for sending emails.
/// Implementations should integrate with actual providers (SendGrid, AWS SES, etc.)
abstract class EmailService {
  /// Send an email using a template
  Future<EmailResult> sendTemplatedEmail({
    required String recipientEmail,
    required String recipientName,
    required MessageTemplate template,
    required Map<String, String> variables,
  });

  /// Send a plain email (no template)
  Future<EmailResult> sendPlainEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  });

  /// Verify email address format
  bool isValidEmail(String email);
}

/// Result of email sending operation
class EmailResult {
  const EmailResult({
    required this.success,
    this.messageId,
    this.error,
    this.timestamp,
  });

  final bool success;
  final String? messageId;
  final String? error;
  final DateTime? timestamp;

  factory EmailResult.success({String? messageId}) {
    return EmailResult(
      success: true,
      messageId: messageId,
      timestamp: DateTime.now(),
    );
  }

  factory EmailResult.failure(String error) {
    return EmailResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// Placeholder implementation for development/testing
/// Does NOT send real emails - only logs the operation
class MockEmailService implements EmailService {
  final List<EmailLog> sentEmails = [];
  final bool simulateFailure;

  MockEmailService({this.simulateFailure = false});

  @override
  Future<EmailResult> sendTemplatedEmail({
    required String recipientEmail,
    required String recipientName,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (simulateFailure) {
      return EmailResult.failure('Simulated failure');
    }

    if (!isValidEmail(recipientEmail)) {
      return EmailResult.failure('Invalid email address: $recipientEmail');
    }

    final renderedSubject = template.renderSubject(variables);
    final renderedBody = template.render(variables);

    final log = EmailLog(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: renderedSubject,
      body: renderedBody,
      timestamp: DateTime.now(),
      templateType: template.type,
    );

    sentEmails.add(log);

    // In development, log to console
    developer.log(
      '📧 [MOCK EMAIL] To: $recipientEmail',
      name: 'EmailService',
    );
    developer.log(
      '   Subject: $renderedSubject',
      name: 'EmailService',
    );
    developer.log(
      '   Body preview omitted in mock to avoid logging content',
      name: 'EmailService',
    );

    return EmailResult.success(
      messageId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<EmailResult> sendPlainEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (simulateFailure) {
      return EmailResult.failure('Simulated failure');
    }

    if (!isValidEmail(recipientEmail)) {
      return EmailResult.failure('Invalid email address: $recipientEmail');
    }

    final log = EmailLog(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      timestamp: DateTime.now(),
    );

    sentEmails.add(log);

    developer.log(
      '📧 [MOCK EMAIL] To: $recipientEmail',
      name: 'EmailService',
    );
    developer.log(
      '   Subject: $subject',
      name: 'EmailService',
    );

    return EmailResult.success(
      messageId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Clear sent email logs (for testing)
  void clearLogs() {
    sentEmails.clear();
  }
}

/// Log entry for a sent email
class EmailLog {
  const EmailLog({
    required this.recipientEmail,
    required this.recipientName,
    required this.subject,
    required this.body,
    required this.timestamp,
    this.templateType,
  });

  final String recipientEmail;
  final String recipientName;
  final String subject;
  final String body;
  final DateTime timestamp;
  final MessageType? templateType;
}

/// Production-ready SendGrid implementation that proxies through the
/// Integration Cloud Function gateway so API keys remain server-side.
class SendGridEmailService implements EmailService {
  SendGridEmailService({
    required Uri gatewayEndpoint,
    required this.senderEmail,
    required this.senderName,
    http.Client? httpClient,
  })  : _gatewayEndpoint = gatewayEndpoint,
        _httpClient = httpClient ?? http.Client();

  final Uri _gatewayEndpoint;
  final http.Client _httpClient;
  final String senderEmail;
  final String senderName;

  @override
  Future<EmailResult> sendTemplatedEmail({
    required String recipientEmail,
    required String recipientName,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) {
    return _dispatchEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: template.renderSubject(variables),
      body: template.render(variables),
    );
  }

  @override
  Future<EmailResult> sendPlainEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) {
    return _dispatchEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      replyTo: replyTo,
    );
  }

  Future<EmailResult> _dispatchEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    final payload = {
      'provider': 'sendgrid',
      'fromEmail': senderEmail,
      'fromName': senderName,
      'toEmail': recipientEmail,
      'toName': recipientName,
      'subject': subject,
      'body': body,
      if (replyTo != null) 'replyTo': replyTo,
    };

    final response = await _httpClient.post(
      _gatewayEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>?;
      return EmailResult.success(
        messageId: data?['messageId'] as String?,
      );
    }

    return EmailResult.failure(
      'SendGrid gateway error (${response.statusCode}): ${response.body}',
    );
  }

  @override
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// AWS SES implementation that uses the Cloud Function gateway.
class AwsSesEmailService implements EmailService {
  AwsSesEmailService({
    required Uri gatewayEndpoint,
    required this.senderEmail,
    required this.senderName,
    http.Client? httpClient,
  })  : _gatewayEndpoint = gatewayEndpoint,
        _httpClient = httpClient ?? http.Client();

  final Uri _gatewayEndpoint;
  final http.Client _httpClient;
  final String senderEmail;
  final String senderName;

  @override
  Future<EmailResult> sendTemplatedEmail({
    required String recipientEmail,
    required String recipientName,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) {
    return _dispatchSes(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: template.renderSubject(variables),
      body: template.render(variables),
    );
  }

  @override
  Future<EmailResult> sendPlainEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) {
    return _dispatchSes(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      replyTo: replyTo,
    );
  }

  Future<EmailResult> _dispatchSes({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    final payload = {
      'provider': 'ses',
      'fromEmail': senderEmail,
      'fromName': senderName,
      'toEmail': recipientEmail,
      'toName': recipientName,
      'subject': subject,
      'body': body,
      if (replyTo != null) 'replyTo': replyTo,
    };

    final response = await _httpClient.post(
      _gatewayEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>?;
      return EmailResult.success(messageId: data?['messageId'] as String?);
    }

    return EmailResult.failure(
      'AWS SES gateway error (${response.statusCode}): ${response.body}',
    );
  }

  @override
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
