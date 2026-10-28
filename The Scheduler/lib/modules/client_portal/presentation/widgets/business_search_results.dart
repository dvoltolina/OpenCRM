import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/business_search_result.dart';

/// Widget displaying business search results.
///
/// Shows:
/// - Business logo/icon
/// - Business name
/// - Service categories
/// - Location (city, state)
/// - Rating (if available)
/// - Tap to select
class BusinessSearchResults extends ConsumerWidget {
  const BusinessSearchResults({
    super.key,
    required this.results,
    required this.onBusinessSelected,
  });

  final List<BusinessSearchResult> results;
  final void Function(BusinessSearchResult) onBusinessSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (context, index) => VSpace.sm,
      itemBuilder: (context, index) {
        final business = results[index];
        return BusinessSearchResultCard(
          business: business,
          onTap: () => onBusinessSelected(business),
        );
      },
    );
  }
}

/// Individual business search result card
class BusinessSearchResultCard extends StatelessWidget {
  const BusinessSearchResultCard({
    super.key,
    required this.business,
    required this.onTap,
  });

  final BusinessSearchResult business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Logo or placeholder
              _buildLogo(theme),
              HSpace.md,

              // Business info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business name
                    Text(
                      business.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    VSpace.xs,

                    // Service categories
                    if (business.serviceCategories.isNotEmpty)
                      Text(
                        business.serviceCategories.join(' • '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Location
                    if (business.city != null || business.state != null) ...[
                      VSpace.xs,
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          HSpace.xs,
                          Expanded(
                            child: Text(
                              _formatLocation(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Rating
                    if (business.rating != null && business.reviewCount != null) ...[
                      VSpace.xs,
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          HSpace.xs,
                          Text(
                            '${business.rating!.toStringAsFixed(1)} (${business.reviewCount} reviews)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    if (business.logoUrl != null && business.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          business.logoUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderLogo(theme);
          },
        ),
      );
    }

    return _buildPlaceholderLogo(theme);
  }

  Widget _buildPlaceholderLogo(ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.business,
        color: theme.colorScheme.onPrimaryContainer,
        size: 30,
      ),
    );
  }

  String _formatLocation() {
    final parts = <String>[];
    if (business.city != null) parts.add(business.city!);
    if (business.state != null) parts.add(business.state!);
    return parts.join(', ');
  }
}
