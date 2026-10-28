import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/communication_config.dart';

/// Service interface for sending SMS messages.
/// Implementations should integrate with actual providers (Twilio, AWS SNS, etc.)
abstract class SmsService {
  /// Send an SMS using a template
  Future<SmsResult> sendTemplatedSms({
    required String recipientPhone,
    required MessageTemplate template,
    required Map<String, String> variables,
  });

  /// Send a plain SMS (no template)
  Future<SmsResult> sendPlainSms({
    required String recipientPhone,
    required String message,
  });

  /// Verify phone number format
  bool isValidPhoneNumber(String phone);

  /// Format phone number to E.164 format (e.g., +15551234567)
  String? formatPhoneNumber(String phone, {String defaultCountryCode = '+1'});
}

/// Result of SMS sending operation
class SmsResult {
  const SmsResult({
    required this.success,
    this.messageId,
    this.error,
    this.timestamp,
    this.segments,
  });

  final bool success;
  final String? messageId;
  final String? error;
  final DateTime? timestamp;
  final int? segments; // SMS can be split into multiple segments

  factory SmsResult.success({String? messageId, int segments = 1}) {
    return SmsResult(
      success: true,
      messageId: messageId,
      timestamp: DateTime.now(),
      segments: segments,
    );
  }

  factory SmsResult.failure(String error) {
    return SmsResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// Placeholder implementation for development/testing
/// Does NOT send real SMS - only logs the operation
class MockSmsService implements SmsService {
  final List<SmsLog> sentMessages = [];
  final bool simulateFailure;

  MockSmsService({this.simulateFailure = false});

  @override
  Future<SmsResult> sendTemplatedSms({
    required String recipientPhone,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (simulateFailure) {
      return SmsResult.failure('Simulated failure');
    }

    final formattedPhone = formatPhoneNumber(recipientPhone);
    if (formattedPhone == null) {
      return SmsResult.failure('Invalid phone number: $recipientPhone');
    }

    final renderedMessage = template.render(variables);
    final segments = calculateSmsSegments(renderedMessage);

    final log = SmsLog(
      recipientPhone: formattedPhone,
      message: renderedMessage,
      timestamp: DateTime.now(),
      templateType: template.type,
      segments: segments,
    );

    sentMessages.add(log);

    // In development, log to console
    developer.log(
      '📱 [MOCK SMS] To: $formattedPhone',
      name: 'SmsService',
    );
    developer.log(
      '   Message: ${renderedMessage.length > 100 ? '${renderedMessage.substring(0, 100)}...' : renderedMessage}',
      name: 'SmsService',
    );
    developer.log(
      '   Segments: $segments',
      name: 'SmsService',
    );

    return SmsResult.success(
      messageId: 'mock-sms-${DateTime.now().millisecondsSinceEpoch}',
      segments: segments,
    );
  }

  @override
  Future<SmsResult> sendPlainSms({
    required String recipientPhone,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (simulateFailure) {
      return SmsResult.failure('Simulated failure');
    }

    final formattedPhone = formatPhoneNumber(recipientPhone);
    if (formattedPhone == null) {
      return SmsResult.failure('Invalid phone number: $recipientPhone');
    }

    final segments = calculateSmsSegments(message);

    final log = SmsLog(
      recipientPhone: formattedPhone,
      message: message,
      timestamp: DateTime.now(),
      segments: segments,
    );

    sentMessages.add(log);

    developer.log(
      '📱 [MOCK SMS] To: $formattedPhone',
      name: 'SmsService',
    );
    developer.log(
      '   Message: $message',
      name: 'SmsService',
    );

    return SmsResult.success(
      messageId: 'mock-sms-${DateTime.now().millisecondsSinceEpoch}',
      segments: segments,
    );
  }

  @override
  bool isValidPhoneNumber(String phone) {
    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    // Check if it's 10-11 digits (with optional + prefix)
    return RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned);
  }

  @override
  String? formatPhoneNumber(String phone, {String defaultCountryCode = '+1'}) {
    // Remove formatting
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    if (!isValidPhoneNumber(cleaned)) {
      return null;
    }

    // Add country code if missing
    if (!cleaned.startsWith('+')) {
      return '$defaultCountryCode$cleaned';
    }

    return cleaned;
  }

  /// Clear sent SMS logs (for testing)
  void clearLogs() {
    sentMessages.clear();
  }
}

/// Log entry for a sent SMS
class SmsLog {
  const SmsLog({
    required this.recipientPhone,
    required this.message,
    required this.timestamp,
    this.templateType,
    this.segments = 1,
  });

  final String recipientPhone;
  final String message;
  final DateTime timestamp;
  final MessageType? templateType;
  final int segments;
}

/// Helper that calculates how many SMS segments are needed.
int calculateSmsSegments(String message) {
  final hasUnicode = message.runes.any((rune) => rune > 127);
  final charsPerSegment = hasUnicode ? 70 : 160;
  return (message.length / charsPerSegment).ceil();
}

/// Twilio implementation routed through the secure integration gateway.
class TwilioSmsService implements SmsService {
  TwilioSmsService({
    required Uri gatewayEndpoint,
    http.Client? httpClient,
  })  : _gatewayEndpoint = gatewayEndpoint,
        _httpClient = httpClient ?? http.Client();

  final Uri _gatewayEndpoint;
  final http.Client _httpClient;

  @override
  Future<SmsResult> sendTemplatedSms({
    required String recipientPhone,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) {
    return _dispatch(
      phone: recipientPhone,
      message: template.render(variables),
    );
  }

  @override
  Future<SmsResult> sendPlainSms({
    required String recipientPhone,
    required String message,
  }) {
    return _dispatch(phone: recipientPhone, message: message);
  }

  Future<SmsResult> _dispatch({
    required String phone,
    required String message,
  }) async {
    final response = await _httpClient.post(
      _gatewayEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': 'twilio',
        'to': phone,
        'message': message,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>?;
      return SmsResult.success(
        messageId: data?['messageId'] as String?,
        segments: calculateSmsSegments(message),
      );
    }

    return SmsResult.failure(
      'Twilio gateway error (${response.statusCode})',
    );
  }

  @override
  bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    return RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned);
  }

  @override
  String? formatPhoneNumber(String phone, {String defaultCountryCode = '+1'}) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    if (!isValidPhoneNumber(cleaned)) {
      return null;
    }

    if (!cleaned.startsWith('+')) {
      return '$defaultCountryCode$cleaned';
    }

    return cleaned;
  }
}

/// AWS SNS SMS implementation using the Cloud Function gateway.
class AwsSnsSmsService implements SmsService {
  AwsSnsSmsService({
    required Uri gatewayEndpoint,
    this.senderId,
    http.Client? httpClient,
  })  : _gatewayEndpoint = gatewayEndpoint,
        _httpClient = httpClient ?? http.Client();

  final Uri _gatewayEndpoint;
  final http.Client _httpClient;
  final String? senderId;

  @override
  Future<SmsResult> sendTemplatedSms({
    required String recipientPhone,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) {
    return _dispatch(
      phone: recipientPhone,
      message: template.render(variables),
    );
  }

  @override
  Future<SmsResult> sendPlainSms({
    required String recipientPhone,
    required String message,
  }) {
    return _dispatch(phone: recipientPhone, message: message);
  }

  Future<SmsResult> _dispatch({
    required String phone,
    required String message,
  }) async {
    final response = await _httpClient.post(
      _gatewayEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': 'sns',
        'to': phone,
        'message': message,
        if (senderId != null) 'senderId': senderId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>?;
      return SmsResult.success(
        messageId: data?['messageId'] as String?,
        segments: calculateSmsSegments(message),
      );
    }

    return SmsResult.failure(
      'AWS SNS gateway error (${response.statusCode})',
    );
  }

  @override
  bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    return RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned);
  }

  @override
  String? formatPhoneNumber(String phone, {String defaultCountryCode = '+1'}) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    if (!isValidPhoneNumber(cleaned)) {
      return null;
    }

    if (!cleaned.startsWith('+')) {
      return '$defaultCountryCode$cleaned';
    }

    return cleaned;
  }
}
