import 'package:flutter/material.dart';

import '../config/demo_config.dart';

class DemoModeBlockedException implements Exception {
  const DemoModeBlockedException(this.action, [this.message]);

  final String action;
  final String? message;

  @override
  String toString() => message ?? DemoConfig.demoDisabledMessage;
}

class DemoGuardService {
  DemoGuardService._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool get isDemoMode => DemoConfig.isDemoMode;

  static void showDisabledMessage([
    String message = DemoConfig.demoDisabledMessage,
  ]) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  static Never blockWrite(
    String action, {
    String? message,
    bool showMessage = true,
  }) {
    final resolvedMessage = message ?? DemoConfig.demoDisabledMessage;
    if (showMessage) {
      showDisabledMessage(resolvedMessage);
    }
    throw DemoModeBlockedException(action, resolvedMessage);
  }

  static Future<T> guardWrite<T>(
    String action,
    Future<T> Function() operation, {
    String? message,
  }) async {
    if (!isDemoMode) {
      return operation();
    }
    blockWrite(action, message: message);
  }

  static void assertReadOnly(
    String action, {
    String? message,
    bool showMessage = true,
  }) {
    if (isDemoMode) {
      blockWrite(action, message: message, showMessage: showMessage);
    }
  }
}
