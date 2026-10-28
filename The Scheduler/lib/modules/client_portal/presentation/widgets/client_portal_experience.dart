import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/security_context.dart';
import '../providers.dart';
import '../gift_card_purchase_page.dart';
import '../group_sessions_page.dart';
import '../join_waitlist_page.dart';
import 'portal_booking_stepper.dart';
import 'portal_hero.dart';

class ClientPortalExperience extends ConsumerWidget {
  const ClientPortalExperience({
    this.debugSecurityContext,
    super.key,
  });

  final SecurityContext? debugSecurityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final availabilityService = ref.watch(availabilityServiceProvider);
    final rulesEngine = ref.watch(bookingRulesEngineProvider);
    final clientsRepository = ref.watch(clientsRepositoryProvider);
    final securityContextAsync = debugSecurityContext != null
        ? AsyncValue.data(debugSecurityContext)
        : ref.watch(securityContextProvider);

    if (!config.featureFlags.enableClientPortal) {
      return const Center(
        child: Text(
          'Client portal is disabled. Enable it in Settings → Features.',
        ),
      );
    }

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(SafeErrorHandler.handle(error)),
      ),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(
            child: Text(
              'Client portal preview requires authentication for now.',
            ),
          );
        }

        final servicesAsync = ref.watch(portalServicesProvider(securityContext));
        final providersAsync =
            ref.watch(portalProvidersProvider(securityContext));
        final locationsAsync =
            ref.watch(portalLocationsProvider(securityContext));

        return servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(SafeErrorHandler.handle(error))),
          data: (services) {
            if (services.isEmpty) {
              return const Center(
                child: Text(
                  'Add services to enable the client portal experience.',
                ),
              );
            }

            return providersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(SafeErrorHandler.handle(error))),
              data: (providers) {
                return locationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(SafeErrorHandler.handle(error))),
                  data: (locations) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PortalHero(config: config, shareUrl: _shareUrl(config)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.card_giftcard),
                                label: const Text('Buy Gift Card'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => GiftCardPurchasePage(
                                        config: config,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.groups),
                                label: const Text('Browse group sessions'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => GroupSessionsPage(
                                        config: config,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: PortalBookingStepper(
                                  config: config,
                                  securityContext: securityContext,
                                  services: services,
                                  providers: providers,
                                  locations: locations,
                                  availabilityService: availabilityService,
                                  rulesEngine: rulesEngine,
                                  clientsRepository: clientsRepository,
                                  onWaitlistPressed: () => _openWaitlist(
                                    context,
                                    config,
                                    securityContext,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _shareUrl(AppConfig config) {
    final slug = config.branding.productName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'https://book.example.com/$slug';
  }

  Future<void> _openWaitlist(
    BuildContext context,
    AppConfig config,
    SecurityContext securityContext,
  ) async {
    // Navigate to waitlist page
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JoinWaitlistPage(
          config: config,
          securityContext: securityContext,
        ),
      ),
    );
  }
}
