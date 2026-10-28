import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/core/ui/components/components.dart' hide EmptyStateWidget;
import 'package:the_scheduler/core/ui/ui_exports.dart';
import 'package:the_scheduler/core/utils/secure_error_handler.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;
import 'package:the_scheduler/data/models/security_context.dart';
import 'widgets/weekly_schedule_list.dart';

/// Page for managing provider availability and weekly schedules
/// Updated by Agent S1 (2025-11-30) - Split for readability and HIPAA-safe errors
class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  String? _selectedProviderId;
  String? _selectedLocationId;

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Managing Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Set your weekly working hours by location.'),
            VSpace.sm,
            Text('• Tap a day to add or edit time blocks'),
            Text('• You can add multiple time blocks per day'),
            Text('• Time blocks define when you\'re available for bookings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => _buildLoadingScaffold(theme),
      error: (error, stackTrace) => _buildErrorScaffold(),
      data: (securityContext) {
        if (securityContext == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to manage availability.')),
          );
        }

        final canManageOthers = securityContext.role.canManageProviders;
        final providersAsync = ref.watch(providersStreamProvider(securityContext));
        final locationsAsync = ref.watch(locationsStreamProvider(securityContext));

        return providersAsync.when(
          loading: () => _buildLoadingScaffold(theme),
          error: (error, stackTrace) => _buildErrorScaffold(),
          data: (providers) {
            final effectiveProviderId = canManageOthers
                ? _selectedProviderId ?? (providers.isNotEmpty ? providers.first.id : null)
                : securityContext.providerId;

            return locationsAsync.when(
              loading: () => _buildLoadingScaffold(theme),
              error: (error, stackTrace) => _buildErrorScaffold(),
              data: (locations) {
                if (locations.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Availability'),
                      centerTitle: false,
                    ),
                    body: const EmptyStateWidget(
                      icon: Icons.location_on_outlined,
                      title: 'No locations',
                      subtitle: 'Add a location to manage working hours',
                    ),
                  );
                }

                _selectedLocationId ??= locations.first.id;
                final activeLocationId = _selectedLocationId;

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Availability'),
                    centerTitle: false,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => _showHelpDialog(context),
                        tooltip: 'Help',
                      ),
                    ],
                  ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canManageOthers)
                        _ProviderSelector(
                          providers: providers,
                          selectedProviderId: effectiveProviderId,
                          onChanged: (value) => setState(() => _selectedProviderId = value),
                        )
                      else
                        _buildStaffHeader(securityContext),
                      _LocationSelector(
                        locations: locations,
                        selectedLocationId: activeLocationId,
                        onChanged: (value) => setState(() => _selectedLocationId = value),
                      ),
                      VSpace.sm,
                      Expanded(
                        child: effectiveProviderId == null || activeLocationId == null
                            ? const EmptyStateWidget(
                                icon: Icons.person_outline,
                                title: 'Select a provider',
                                subtitle: 'Choose a provider to manage their availability',
                              )
                            : WeeklyScheduleList(
                                securityContext: securityContext,
                                providerId: effectiveProviderId,
                                locationId: activeLocationId,
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
  }

  Scaffold _buildLoadingScaffold(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: buildSkeletonList(count: 7, hasSubtitle: true),
        ),
      ),
    );
  }

  Scaffold _buildErrorScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        centerTitle: false,
      ),
      body: Center(
        child: const ErrorFeedback(message: SecureErrorHandler.loadingFailed),
      ),
    );
  }

  Widget _buildStaffHeader(SecurityContext securityContext) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  config.branding.primaryColor.withValues(alpha: 0.3),
                  config.branding.accentColor.withValues(alpha: 0.2),
                ]
              : [
                  config.branding.primaryColor.withValues(alpha: 0.08),
                  config.branding.accentColor.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: config.branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: config.branding.primaryColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? config.branding.primaryColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: config.branding.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.schedule,
              color: config.branding.primaryColor,
              size: AppIconSize.md,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'My Availability',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : config.branding.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSelector extends StatelessWidget {
  const _ProviderSelector({
    required this.providers,
    required this.selectedProviderId,
    required this.onChanged,
  });

  final List<provider_model.Provider> providers;
  final String? selectedProviderId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (providers.isEmpty) {
      return const SizedBox(
        height: 4,
        child: LinearProgressIndicator(),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Text(
            'Manage Availability for:',
            style: theme.textTheme.titleMedium,
          ),
          HSpace.md,
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedProviderId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select Provider'),
              items: providers
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider.id,
                      child: Text(provider.fullName),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.locations,
    required this.selectedLocationId,
    required this.onChanged,
  });

  final List<Location> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = selectedLocationId ?? locations.first.id;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Location',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        items: locations
            .map(
              (location) => DropdownMenuItem(
                value: location.id,
                child: Text(location.name ?? location.city),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
