import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart' as models;
import '../../../../data/models/service.dart';

/// Service selection dropdown with premium styling.
class ServiceDropdown extends ConsumerWidget {
  const ServiceDropdown({
    super.key,
    required this.services,
    required this.selectedServiceId,
    required this.onChanged,
  });

  final List<Service> services;
  final String? selectedServiceId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedServiceId ?? 'service_null'),
        initialValue: selectedServiceId,
        decoration: InputDecoration(
          labelText: 'Service',
          labelStyle: TextStyle(color: branding.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: services
            .map(
              (service) => DropdownMenuItem(
                value: service.id,
                child: Text('${service.name} • ${service.durationDisplay}'),
              ),
            )
            .toList(),
        validator: (value) =>
            value == null ? 'Select a service to continue' : null,
        onChanged: onChanged,
      ),
    );
  }
}

/// Provider selection dropdown with premium styling.
class ProviderDropdown extends ConsumerWidget {
  const ProviderDropdown({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.onChanged,
  });

  final List<models.Provider> providers;
  final String? selectedProviderId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedProviderId ?? 'provider_null'),
        initialValue: selectedProviderId,
        decoration: InputDecoration(
          labelText: 'Provider',
          labelStyle: TextStyle(color: branding.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: providers
            .map(
              (provider) => DropdownMenuItem<String>(
                value: provider.id,
                child: Text(provider.fullName),
              ),
            )
            .toList(),
        validator: (value) =>
            value == null ? 'Select a provider to continue' : null,
        onChanged: onChanged,
      ),
    );
  }
}

/// Location selection dropdown with premium styling.
class LocationDropdown extends ConsumerWidget {
  const LocationDropdown({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onChanged,
  });

  final List<Location> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    if (locations.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: AppIconSize.lg,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            HSpace.md,
            Expanded(
              child: Text(
                'No locations configured. Contact your administrator.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (locations.length == 1) {
      final location = locations.first;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Location',
            labelStyle: TextStyle(color: branding.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(location.name ?? location.address),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedLocationId ?? 'location_null'),
        initialValue: selectedLocationId ?? locations.first.id,
        decoration: InputDecoration(
          labelText: 'Location',
          labelStyle: TextStyle(color: branding.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: branding.accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: locations
            .map(
              (location) => DropdownMenuItem(
                value: location.id,
                child: Text(location.name ?? location.address),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// Client selection section with premium styling.
class ClientSection extends ConsumerWidget {
  const ClientSection({
    super.key,
    required this.canManageClients,
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.onQuickAddClient,
  });

  final bool canManageClients;
  final List<Client> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onQuickAddClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!canManageClients) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: AppIconSize.lg,
              color: colorScheme.error,
            ),
            HSpace.md,
            Expanded(
              child: Text(
                'You do not have permission to view clients. Ask an administrator to schedule on your behalf.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: branding.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedClientId,
            decoration: InputDecoration(
              labelText: 'Client',
              labelStyle: TextStyle(color: branding.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: branding.accentColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: branding.accentColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: clients
                .map(
                  (client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.fullName),
                  ),
                )
                .toList(),
            validator: (value) =>
                value == null ? 'Select a client to continue' : null,
            onChanged: onClientChanged,
          ),
        ),
        VSpace.xs,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onQuickAddClient,
            icon: Icon(Icons.person_add, color: branding.accentColor),
            label: Text(
              'Quick add client',
              style: TextStyle(color: branding.accentColor),
            ),
          ),
        ),
      ],
    );
  }
}
