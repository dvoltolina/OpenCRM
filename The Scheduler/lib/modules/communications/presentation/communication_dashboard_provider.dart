import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/communication_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/security_context.dart' show SecurityException;

/// Aggregated state for the communications dashboard.
class CommunicationDashboardState {
  const CommunicationDashboardState({
    required this.config,
    required this.emailTemplates,
    required this.smsTemplates,
    required this.automationRules,
  });

  final CommunicationConfig config;
  final Map<MessageType, MessageTemplate> emailTemplates;
  final Map<MessageType, MessageTemplate> smsTemplates;
  final List<AutomationRule> automationRules;
}

/// Loads templates, automation rules, and configuration in parallel so the UI
/// can render a consistent snapshot and revalidate via ref.invalidate().
final communicationDashboardProvider =
    FutureProvider<CommunicationDashboardState>((ref) async {
      final repository = ref.watch(communicationRepositoryProvider);
      final defaultConfig = ref.watch(appConfigProvider).communicationConfig;

      Future<T> loadOrFallback<T>(Future<T> future, T fallback) async {
        try {
          return await future;
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            return fallback;
          }
          rethrow;
        } on SecurityException {
          return fallback;
        }
      }

      final results = await Future.wait([
        loadOrFallback(repository.getCommunicationConfig(), defaultConfig),
        loadOrFallback(
          repository.getEmailTemplates(),
          Map<MessageType, MessageTemplate>.from(defaultConfig.emailTemplates),
        ),
        loadOrFallback(
          repository.getSmsTemplates(),
          Map<MessageType, MessageTemplate>.from(defaultConfig.smsTemplates),
        ),
        loadOrFallback(
          repository.getAutomationRules(),
          List<AutomationRule>.from(defaultConfig.automationRules),
        ),
      ]);

      final config = results[0] as CommunicationConfig;
      final emailTemplates = results[1] as Map<MessageType, MessageTemplate>;
      final smsTemplates = results[2] as Map<MessageType, MessageTemplate>;
      final automationRules = results[3] as List<AutomationRule>;

      return CommunicationDashboardState(
        config: config,
        emailTemplates: emailTemplates,
        smsTemplates: smsTemplates,
        automationRules: automationRules,
      );
    });
