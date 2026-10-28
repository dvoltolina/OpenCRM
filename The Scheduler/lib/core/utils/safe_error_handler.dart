import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import '../constants/user_messages.dart';

/// Centralized error handler that prevents PHI exposure in error messages.
///
/// This utility ensures HIPAA compliance by:
/// 1. Logging full error details securely (only in debug logs, not exposed to users)
/// 2. Returning generic, user-safe messages that contain no PHI or sensitive data
/// 3. Providing specific handlers for common error types
///
/// Usage:
/// ```dart
/// try {
///   await someRiskyOperation();
/// } catch (e) {
///   final userMessage = SafeErrorHandler.handle(e, context: 'Booking appointment');
///   showErrorDialog(userMessage);
/// }
/// ```
class SafeErrorHandler {
  // Private constructor to prevent instantiation
  SafeErrorHandler._();

  /// Logs error securely and returns user-safe message.
  ///
  /// [error] - The error or exception that occurred
  /// [context] - Optional context description (e.g., 'Loading appointments', 'Saving note')
  /// [stackTrace] - Optional stack trace for debugging
  ///
  /// Returns a user-safe error message that contains no PHI or technical details.
  static String handle(
    Object error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    // Log full error for debugging (not visible to users)
    // Using developer.log instead of print for security
    final logMessage = context != null ? 'Error in $context: $error' : 'Error: $error';

    developer.log(
      logMessage,
      error: error,
      stackTrace: stackTrace,
      name: 'SafeErrorHandler',
      level: 1000, // SEVERE level
    );

    // Return generic user-safe message
    return getUserMessage(error);
  }

  /// Handles async errors and returns user-safe message.
  ///
  /// Useful for wrapping async operations:
  /// ```dart
  /// await SafeErrorHandler.handleAsync(
  ///   () => loadAppointments(),
  ///   context: 'Loading appointments',
  ///   onError: (message) => showError(message),
  /// );
  /// ```
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    void Function(String message)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final userMessage = handle(e, context: context, stackTrace: stackTrace);
      onError?.call(userMessage);
      return null;
    }
  }

  /// Determines appropriate user-safe message based on error type.
  static String getUserMessage(Object error) {
    // Firebase errors
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // Network errors
    if (error is SocketException) {
      return UserMessages.networkError;
    }

    if (error is TimeoutException) {
      return UserMessages.timeoutError;
    }

    if (error is HttpException) {
      return _handleHttpError(error);
    }

    // File system errors
    if (error is FileSystemException) {
      return _handleFileSystemError(error);
    }

    // Format errors
    if (error is FormatException) {
      return UserMessages.invalidInput;
    }

    // State errors
    if (error is StateError) {
      return UserMessages.unexpectedError;
    }

    // Argument errors
    if (error is ArgumentError) {
      return UserMessages.validationError;
    }

    // Default generic error
    return UserMessages.genericError;
  }

  /// Handles Firebase-specific errors with appropriate user messages.
  static String _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      // Authentication errors
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return UserMessages.invalidCredentials;

      case 'user-disabled':
        return UserMessages.accountLocked;

      case 'too-many-requests':
        return UserMessages.serviceUnavailable;

      case 'operation-not-allowed':
        return UserMessages.permissionDenied;

      // Firestore errors
      case 'permission-denied':
        return UserMessages.permissionDenied;

      case 'not-found':
        return UserMessages.notFound;

      case 'unavailable':
      case 'deadline-exceeded':
        return UserMessages.serviceUnavailable;

      case 'already-exists':
        return UserMessages.validationError;

      case 'resource-exhausted':
        return UserMessages.serviceUnavailable;

      case 'failed-precondition':
      case 'aborted':
        return UserMessages.unexpectedError;

      case 'out-of-range':
      case 'invalid-argument':
        return UserMessages.invalidInput;

      case 'unauthenticated':
        return UserMessages.authError;

      // Storage errors
      case 'storage/unauthorized':
        return UserMessages.permissionDenied;

      case 'storage/canceled':
        return UserMessages.genericError;

      case 'storage/unknown':
        return UserMessages.uploadError;

      case 'storage/object-not-found':
        return UserMessages.notFound;

      case 'storage/quota-exceeded':
        return UserMessages.fileSizeError;

      case 'storage/invalid-format':
        return UserMessages.fileTypeError;

      // Network errors
      case 'network-request-failed':
        return UserMessages.networkError;

      default:
        return UserMessages.genericError;
    }
  }

  /// Handles HTTP-specific errors.
  static String _handleHttpError(HttpException e) {
    final message = e.message.toLowerCase();

    if (message.contains('connection')) {
      return UserMessages.networkError;
    }

    if (message.contains('timeout')) {
      return UserMessages.timeoutError;
    }

    if (message.contains('unauthorized') || message.contains('403')) {
      return UserMessages.permissionDenied;
    }

    if (message.contains('not found') || message.contains('404')) {
      return UserMessages.notFound;
    }

    if (message.contains('500') || message.contains('503')) {
      return UserMessages.serviceUnavailable;
    }

    return UserMessages.networkError;
  }

  /// Handles file system errors.
  static String _handleFileSystemError(FileSystemException e) {
    final osError = e.osError;

    // Check if it's a permission error
    if (osError != null) {
      final errorCode = osError.errorCode;
      // EACCES = 13, EPERM = 1
      if (errorCode == 13 || errorCode == 1) {
        return UserMessages.permissionDenied;
      }
      // ENOENT = 2
      if (errorCode == 2) {
        return UserMessages.notFound;
      }
      // ENOSPC = 28
      if (errorCode == 28) {
        return UserMessages.fileSizeError;
      }
    }

    // Check operation type
    final path = e.path;
    if (path != null) {
      if (e.message.contains('read')) {
        return UserMessages.fileReadError;
      }
      if (e.message.contains('write')) {
        return UserMessages.fileWriteError;
      }
    }

    return UserMessages.genericError;
  }

  /// Logs a warning (less severe than error) with context.
  ///
  /// Use for non-critical issues that don't require user notification.
  static void logWarning(
    String message, {
    String? context,
    Object? error,
  }) {
    final logMessage = context != null ? '[$context] $message' : message;

    developer.log(
      logMessage,
      error: error,
      name: 'SafeErrorHandler',
      level: 900, // WARNING level
    );
  }

  /// Logs informational message with context.
  ///
  /// Use for debugging and tracking application flow.
  static void logInfo(
    String message, {
    String? context,
  }) {
    final logMessage = context != null ? '[$context] $message' : message;

    developer.log(
      logMessage,
      name: 'SafeErrorHandler',
      level: 800, // INFO level
    );
  }

  /// Sanitizes any string to remove potential PHI before logging.
  ///
  /// Use this when you need to log user input or data that might contain PHI.
  ///
  /// Example:
  /// ```dart
  /// developer.log('Search query: ${SafeErrorHandler.sanitize(userInput)}');
  /// ```
  static String sanitize(String input) {
    // Remove common PHI patterns
    String sanitized = input;

    // Remove email addresses
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL]',
    );

    // Remove phone numbers (various formats)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE]',
    );

    // Remove SSN patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
      '[SSN]',
    );

    // Remove potential medical record numbers (various formats)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(MRN|mrn|medical record|patient id)[:\s]*\w+\b', caseSensitive: false),
      '[MEDICAL_ID]',
    );

    return sanitized;
  }
}
