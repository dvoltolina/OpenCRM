import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/reference_data_cache.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../data/models/location.dart';
import '../../../data/models/resource.dart';
import '../../../data/models/security_context.dart';
import 'widgets/new_location_dialog.dart';
import 'widgets/edit_location_dialog.dart';
import 'widgets/new_resource_dialog.dart';
import 'widgets/edit_resource_dialog.dart';

/// LocationsPage displays and manages business locations and their resources.
/// Admin-only access - allows viewing, creating, editing, and deleting locations and resources.
class LocationsPage extends ConsumerStatefulWidget {
  const LocationsPage({super.key});

  @override
  ConsumerState<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends ConsumerState<LocationsPage> {
  String? _selectedLocationId;

  Future<void> _showNewLocationDialog() async {
    final authService = ref.read(authStateServiceProvider);
    final locationsRepository = ref.read(locationsRepositoryProvider);
    final securityContext = await authService.getCurrentSecurityContext();
    if (securityContext == null || !mounted) return;

    if (!context.mounted) return;
    final result = await showDialog<Location>(
      context: context,
      builder: (context) => NewLocationDialog(
        securityContext: securityContext,
        locationsRepository: locationsRepository,
      ),
    );

    if (result != null && mounted) {
      ScreenReaderAnnouncements.announceSuccess(
        context,
        'Location created successfully',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location "${result.name ?? result.city}" created successfully')),
      );
    }
  }

  Future<void> _showEditLocationDialog(Location location) async {
    final authService = ref.read(authStateServiceProvider);
    final locationsRepository = ref.read(locationsRepositoryProvider);
    final securityContext = await authService.getCurrentSecurityContext();
    if (securityContext == null || !mounted) return;

    if (!context.mounted) return;
    final result = await showDialog<Location>(
      context: context,
      builder: (context) => EditLocationDialog(
        location: location,
        securityContext: securityContext,
        locationsRepository: locationsRepository,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location "${result.name ?? result.city}" updated successfully')),
      );
    }
  }

  Future<void> _deleteLocation(Location location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete this location? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authService = ref.read(authStateServiceProvider);
      final locationsRepository = ref.read(locationsRepositoryProvider);
      final securityContext = await authService.getCurrentSecurityContext();
      if (securityContext == null) return;

      await locationsRepository.deleteLocation(
        context: securityContext,
        locationId: location.id,
      );

      if (mounted) {
        setState(() {
          if (_selectedLocationId == location.id) {
            _selectedLocationId = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserMessages.deleteError)),
        );
      }
    }
  }

  Future<void> _showNewResourceDialog(String locationId) async {
    final authService = ref.read(authStateServiceProvider);
    final resourcesRepository = ref.read(resourcesRepositoryProvider);
    final securityContext = await authService.getCurrentSecurityContext();
    if (securityContext == null || !mounted) return;

    if (!context.mounted) return;
    final result = await showDialog<Resource>(
      context: context,
      builder: (context) => NewResourceDialog(
        locationId: locationId,
        securityContext: securityContext,
        resourcesRepository: resourcesRepository,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resource "${result.name}" created successfully')),
      );
    }
  }

  Future<void> _showEditResourceDialog(Resource resource) async {
    final authService = ref.read(authStateServiceProvider);
    final resourcesRepository = ref.read(resourcesRepositoryProvider);
    final securityContext = await authService.getCurrentSecurityContext();
    if (securityContext == null || !mounted) return;

    if (!context.mounted) return;
    final result = await showDialog<Resource>(
      context: context,
      builder: (context) => EditResourceDialog(
        resource: resource,
        securityContext: securityContext,
        resourcesRepository: resourcesRepository,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resource "${result.name}" updated successfully')),
      );
    }
  }

  Future<void> _deleteResource(Resource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authService = ref.read(authStateServiceProvider);
      final resourcesRepository = ref.read(resourcesRepositoryProvider);
      final securityContext = await authService.getCurrentSecurityContext();
      if (securityContext == null) return;

      await resourcesRepository.deleteResource(
        context: securityContext,
        resourceId: resource.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resource "${resource.name}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserMessages.deleteError)),
        );
      }
    }
  }

  Widget _buildLocationCard(Location location, SecurityContext securityContext) {
    final theme = Theme.of(context);
    final isSelected = _selectedLocationId == location.id;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          // Location header
          InkWell(
            onTap: () {
              setState(() {
                _selectedLocationId = isSelected ? null : location.id;
              });
            },
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  HSpace.md,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name ?? 'Unnamed Location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        VSpace.xxs,
                        Text(
                          '${location.address}, ${location.city}, ${location.state} ${location.zipCode}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (location.phone != null) ...[
                          VSpace.xxs,
                          Text(
                            location.phone!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(isSelected ? Icons.expand_less : Icons.expand_more),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            HSpace.sm,
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            HSpace.sm,
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditLocationDialog(location);
                      } else if (value == 'delete') {
                        _deleteLocation(location);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Resources section (expanded)
          if (isSelected) ...[
            const Divider(height: 1),
            StreamBuilder<List<Resource>>(
              stream: ref.read(resourcesRepositoryProvider).watchResourcesByLocation(
                context: securityContext,
                locationId: location.id,
              ),
              builder: (context, snapshot) {
                final resources = snapshot.data ?? [];

                return Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Resources',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showNewResourceDialog(location.id),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Resource'),
                          ),
                        ],
                      ),
                      VSpace.sm,
                      if (resources.isEmpty)
                        Center(
                          child: Padding(
                            padding: AppSpacing.pagePadding,
                            child: Text(
                              'No resources added yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      else
                        ...resources.map((resource) => _buildResourceItem(resource, theme)),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceItem(Resource resource, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(_getResourceIcon(resource.type)),
        title: Text(resource.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (!resource.isActive) 'Inactive',
                resource.type.displayName,
                resource.capacityDisplay,
              ].join(' • '),
            ),
            if (resource.maintenanceSchedule.isNotEmpty)
              Text(
                'Maintenance: ${resource.maintenanceSchedule.first}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  HSpace.sm,
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  HSpace.sm,
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditResourceDialog(resource);
            } else if (value == 'delete') {
              _deleteResource(resource);
            }
          },
        ),
      ),
    );
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.room:
        return Icons.meeting_room;
      case ResourceType.equipment:
        return Icons.medical_services;
      case ResourceType.vehicle:
        return Icons.directions_car;
      case ResourceType.other:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: StreamBuilder<SecurityContext?>(
        stream: ref.read(authStateServiceProvider).watchSecurityContext(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: buildSkeletonList(count: 5));
          }

          final securityContext = snapshot.data!;

          return StreamBuilder<List<Location>>(
            stream: ReferenceDataCache.instance.watchLocations(securityContext),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: buildSkeletonList(count: 5));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                      VSpace.md,
                      Text(UserMessages.loadError),
                    ],
                  ),
                );
              }

              final locations = snapshot.data ?? [];

              if (locations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      VSpace.lg,
                      Text(
                        'No Locations Yet',
                        style: theme.textTheme.headlineSmall,
                      ),
                      VSpace.xs,
                      Text(
                        'Add your first location to get started',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      VSpace.lg,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showNewLocationDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Location'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  ListView.builder(
                    padding: AppSpacing.cardPadding.copyWith(bottom: 80),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return _buildLocationCard(location, securityContext);
                    },
                  ),
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: FloatingActionButton.extended(
                      onPressed: _showNewLocationDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Location'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      ),
    );
  }
}
