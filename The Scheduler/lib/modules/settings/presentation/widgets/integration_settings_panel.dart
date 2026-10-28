import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/external_calendar_service.dart';
import '../../../../core/services/integration_token_cipher.dart';
import '../../../../core/services/oauth_service.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/integration_models.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/integration_repository.dart';
import 'integration_tile.dart';

class IntegrationSettingsPanel extends ConsumerStatefulWidget {
  const IntegrationSettingsPanel({super.key, required this.config});

  final AppConfig config;

  @override
  ConsumerState<IntegrationSettingsPanel> createState() =>
      _IntegrationSettingsPanelState();
}

class _IntegrationSettingsPanelState extends ConsumerState<IntegrationSettingsPanel> {
  final IntegrationRepository _integrationRepository = IntegrationRepository();
  late final IntegrationTokenCipher _cipher = IntegrationTokenCipher(
    widget.config.integrationConfig.tokenEncryptionKey,
  );
  late final OAuthService _oauthService = OAuthService();
  late final ExternalCalendarService _calendarService =
      ExternalCalendarService(
    integrationRepository: _integrationRepository,
    tokenCipher: _cipher,
    oauthService: _oauthService,
    integrationConfig: widget.config.integrationConfig,
    bookingPolicies: widget.config.bookingPolicies,
  );

  bool _isBusy = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authStateServiceProvider);
    return FutureBuilder<SecurityContext?>(
      future: authService.getCurrentSecurityContext(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final securityContext = snapshot.data;
        if (securityContext == null) {
          return AppCard(
            child: Text(
              'Sign in as an administrator to manage integrations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return StreamBuilder<List<IntegrationAccount>>(
          stream: _integrationRepository.watchIntegrations(securityContext),
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? const [];
            IntegrationAccount? googleAccount;
            IntegrationAccount? outlookAccount;

            if (accounts.isNotEmpty) {
              for (final account in accounts) {
                if (account.provider == IntegrationProvider.googleCalendar) {
                  googleAccount = account;
                } else if (account.provider ==
                    IntegrationProvider.outlookCalendar) {
                  outlookAccount = account;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'External Integrations', padding: EdgeInsets.zero),
                VSpace.xs,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isBusy)
                            const SizedBox(
                              height: AppIconSize.sm,
                              width: AppIconSize.sm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (_statusMessage != null) ...[
                        Text(
                          _statusMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                        VSpace.sm,
                      ],
                      IntegrationTile(
                        title: 'Google Calendar',
                        description: googleAccount?.email ??
                            'Sync appointments to a Google Workspace calendar.',
                        isConnected:
                            googleAccount?.status == IntegrationStatus.connected,
                        onConnect: _isBusy
                            ? null
                            : () => _connectCalendar(
                                  securityContext,
                                  IntegrationProvider.googleCalendar,
                                ),
                        onDisconnect: googleAccount?.status ==
                                IntegrationStatus.connected
                            ? () => _disconnectCalendar(
                                  securityContext,
                                  googleAccount!.id,
                                  IntegrationProvider.googleCalendar,
                                )
                            : null,
                      ),
                      const SpacedDivider(),
                      IntegrationTile(
                        title: 'Microsoft Outlook',
                        description: outlookAccount?.email ??
                            'Connect Microsoft 365 or Exchange calendars.',
                        isConnected:
                            outlookAccount?.status == IntegrationStatus.connected,
                        onConnect: _isBusy
                            ? null
                            : () => _connectCalendar(
                                  securityContext,
                                  IntegrationProvider.outlookCalendar,
                                ),
                        onDisconnect: outlookAccount?.status ==
                                IntegrationStatus.connected
                            ? () => _disconnectCalendar(
                                  securityContext,
                                  outlookAccount!.id,
                                  IntegrationProvider.outlookCalendar,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _connectCalendar(
    SecurityContext context,
    IntegrationProvider provider,
  ) async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      if (provider == IntegrationProvider.googleCalendar) {
        await _calendarService.connectGoogleCalendar(context);
      } else if (provider == IntegrationProvider.outlookCalendar) {
        await _calendarService.connectMicrosoftCalendar(context);
      }
      if (mounted) {
        setState(() {
          _statusMessage = 'Connected ${provider.name} successfully.';
        });
      }
    } catch (error) {
      debugPrint('Calendar connection failed: $error');
      if (mounted) {
        setState(() {
          _statusMessage = 'Integration failed: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _disconnectCalendar(
    SecurityContext context,
    String integrationId,
    IntegrationProvider provider,
  ) async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      await _integrationRepository.deleteIntegration(
        context: context,
        integrationId: integrationId,
      );
      if (mounted) {
        setState(() {
          _statusMessage = '${provider.name} disconnected.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Unable to disconnect: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}
