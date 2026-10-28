import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// Secure error handler that prevents PHI/sensitive data exposure in user-facing messages.
///
/// HIPAA Compliance: Never display raw exception details to users as they may contain
/// PHI, Firestore document IDs, stack traces, or database structure information.
class SecureErrorHandler {
  /// Shows a generic error message to the user while logging the actual error securely.
  static void showError(
    BuildContext context, {
    required Exception error,
    String? userMessage,
    StackTrace? stackTrace,
  }) {
    // Log actual error to secure logging (never shown to user)
    developer.log(
      'Operation failed',
      name: 'SecureErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // Show generic message to user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage ?? operationFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Common generic error messages
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String loadingFailed = 'Failed to load data. Please try again.';
  static const String saveFailed = 'Failed to save changes. Please try again.';
  static const String deleteFailed = 'Failed to delete. Please try again.';
  static const String uploadFailed = 'Upload failed. Please try again.';
  static const String exportFailed = 'Export failed. Please try again.';
  static const String updateFailed = 'Failed to update. Please try again.';
}
