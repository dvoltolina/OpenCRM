import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../data/models/guest_session.dart';

/// Service for guest verification via SMS or email.
///
/// Security Requirements:
/// - Never store plaintext verification codes
/// - Codes are hashed (SHA-256) server-side
/// - Max 3 verification attempts per code
/// - Codes expire after 10 minutes
/// - Rate limit: 1 code per email/phone per 2 minutes
/// - Guest sessions expire after 24 hours
///
/// HIPAA Notes:
/// - Guest contact info becomes PHI when linked to appointments
/// - Do not log contact info or codes
/// - Clear codes from memory after use
class GuestVerificationService {
  GuestVerificationService({
    required String sendVerificationUrl,
    required String verifyCodeUrl,
    required String resendCodeUrl,
  })  : _sendVerificationUrl = sendVerificationUrl,
        _verifyCodeUrl = verifyCodeUrl,
        _resendCodeUrl = resendCodeUrl;

  final String _sendVerificationUrl;
  final String _verifyCodeUrl;
  final String _resendCodeUrl;

  /// Send verification code via SMS.
  ///
  /// Server-side implementation:
  /// 1. Generate 6-digit random code
  /// 2. Hash code with SHA-256
  /// 3. Store hash with expiry (10 min)
  /// 4. Send code via Twilio
  /// 5. Return session ID (not the code!)
  Future<VerificationResult> sendSmsCode({
    required String businessId,
    required String phone,
    required String name,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_sendVerificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'businessId': businessId,
          'phone': phone,
          'name': name,
          'email': email,
          'method': 'sms',
        }),
      );

      if (response.statusCode == 429) {
        throw RateLimitException(
          'Too many requests. Please wait before requesting another code.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to send verification code');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return VerificationResult.fromJson(data);
    } catch (e) {
      if (e is RateLimitException) rethrow;
      throw Exception('Failed to send SMS verification code');
    }
  }

  /// Send verification code via email.
  ///
  /// Server-side implementation:
  /// 1. Generate 6-digit random code
  /// 2. Hash code with SHA-256
  /// 3. Store hash with expiry (10 min)
  /// 4. Send code via SendGrid/similar
  /// 5. Return session ID (not the code!)
  Future<VerificationResult> sendEmailCode({
    required String businessId,
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_sendVerificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'businessId': businessId,
          'email': email,
          'name': name,
          'phone': phone,
          'method': 'email',
        }),
      );

      if (response.statusCode == 429) {
        throw RateLimitException(
          'Too many requests. Please wait before requesting another code.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to send verification code');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return VerificationResult.fromJson(data);
    } catch (e) {
      if (e is RateLimitException) rethrow;
      throw Exception('Failed to send email verification code');
    }
  }

  /// Verify the code entered by the user.
  ///
  /// Server-side implementation:
  /// 1. Lookup session by ID
  /// 2. Hash provided code
  /// 3. Compare with stored hash
  /// 4. Check expiry and attempt count
  /// 5. On success: create guest session (24h)
  /// 6. Return guest session
  Future<GuestSession> verifyCode({
    required String sessionId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sessionId': sessionId,
          'code': code,
        }),
      );

      if (response.statusCode == 400) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final errorType = data['error'] as String?;

        if (errorType == 'invalid_code') {
          throw InvalidCodeException('Invalid verification code');
        } else if (errorType == 'expired') {
          throw CodeExpiredException('Verification code has expired');
        } else if (errorType == 'max_attempts') {
          throw MaxAttemptsException('Too many attempts. Please request a new code.');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Verification failed');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return GuestSession.fromJson(data);
    } catch (e) {
      if (e is VerificationException) rethrow;
      throw Exception('Failed to verify code');
    }
  }

  /// Resend verification code to the same contact method.
  ///
  /// Rate limited to prevent abuse.
  Future<VerificationResult> resendCode({
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_resendCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 429) {
        throw RateLimitException(
          'Please wait before requesting another code.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to resend code');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return VerificationResult.fromJson(data);
    } catch (e) {
      if (e is RateLimitException) rethrow;
      throw Exception('Failed to resend verification code');
    }
  }

  /// Validate phone number format (US only for now).
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 10 || cleaned.length == 11;
  }

  /// Validate email format.
  static bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }
}

/// Base class for verification exceptions
abstract class VerificationException implements Exception {
  VerificationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Rate limit exceeded
class RateLimitException extends VerificationException {
  RateLimitException(super.message);
}

/// Invalid verification code
class InvalidCodeException extends VerificationException {
  InvalidCodeException(super.message);
}

/// Code has expired
class CodeExpiredException extends VerificationException {
  CodeExpiredException(super.message);
}

/// Max verification attempts exceeded
class MaxAttemptsException extends VerificationException {
  MaxAttemptsException(super.message);
}
