import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/business_search_result.dart';
import '../providers/client_portal_providers.dart';
import 'client_auth_choice_page.dart';

/// Business detail page showing information before booking.
///
/// Displays:
/// - Business name, logo, description
/// - Service categories
/// - Hours of operation
/// - Contact information
/// - "Book Appointment" button
///
/// HIPAA Note: No PHI on this page - public business info only
class BusinessDetailPage extends ConsumerWidget {
  const BusinessDetailPage({
    super.key,
    required this.businessId,
  });

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessDetails = ref.watch(businessDetailsProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: businessDetails.when(
        data: (details) {
          if (details == null) {
            return _buildNotFound(context);
          }
          return _buildDetails(context, ref, details);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            VSpace.lg,
            Text(
              'Business Not Found',
              style: theme.textTheme.headlineSmall,
            ),
            VSpace.md,
            Text(
              'This business may no longer be available for booking.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.lg,
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            VSpace.lg,
            Text(
              'Failed to Load Business',
              style: theme.textTheme.headlineSmall,
            ),
            VSpace.md,
            Text(
              'Please try again later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.lg,
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref, details) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                if (details.logoUrl != null && details.logoUrl!.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        details.logoUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderLogo(theme);
                        },
                      ),
                    ),
                  )
                else
                  Center(child: _buildPlaceholderLogo(theme)),
                VSpace.lg,

                // Business name
                Text(
                  details.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.sm,

                // Service categories
                if (details.serviceCategories.isNotEmpty)
                  Text(
                    details.serviceCategories.join(' • '),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                VSpace.sm,

                // Rating
                if (details.rating != null && details.reviewCount != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      HSpace.xs,
                      Text(
                        '${details.rating!.toStringAsFixed(1)} (${details.reviewCount} reviews)',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                VSpace.lg,

                // Description
                if (details.description != null &&
                    details.description!.isNotEmpty) ...[
                  const Divider(),
                  VSpace.md,
                  Text(
                    details.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  VSpace.lg,
                ],

                // Contact info
                const Divider(),
                VSpace.md,
                _buildContactSection(theme, details),
                VSpace.lg,

                // Locations
                if (details.locations.isNotEmpty) ...[
                  const Divider(),
                  VSpace.md,
                  _buildLocationsSection(theme, details),
                  VSpace.lg,
                ],

                // Hours (placeholder - will need full implementation)
                if (details.hours != null) ...[
                  const Divider(),
                  VSpace.md,
                  _buildHoursSection(theme, details),
                ],
              ],
            ),
          ),
        ),

        // Book appointment button (fixed at bottom)
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: () => _handleBookAppointment(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Book Appointment'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderLogo(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.business,
        size: 60,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme, details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.md,
        if (details.phone != null) ...[
          _buildContactItem(
            theme,
            Icons.phone_outlined,
            details.phone!,
          ),
          VSpace.sm,
        ],
        if (details.email != null) ...[
          _buildContactItem(
            theme,
            Icons.email_outlined,
            details.email!,
          ),
          VSpace.sm,
        ],
        if (details.website != null) ...[
          _buildContactItem(
            theme,
            Icons.language,
            details.website!,
          ),
        ],
      ],
    );
  }

  Widget _buildContactItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        HSpace.md,
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsSection(ThemeData theme, details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.md,
        ...details.locations.map((location) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                HSpace.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (location.address != null)
                        Text(
                          _formatAddress(location),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHoursSection(ThemeData theme, details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hours',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.md,
        Text(
          'Hours information coming soon',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatAddress(BusinessLocation location) {
    final parts = <String>[];
    if (location.address != null) parts.add(location.address!);
    if (location.city != null) parts.add(location.city!);
    if (location.state != null) parts.add(location.state!);
    if (location.zipCode != null) parts.add(location.zipCode!);
    return parts.join(', ');
  }

  void _handleBookAppointment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientAuthChoicePage(businessId: businessId),
      ),
    );
  }
}
