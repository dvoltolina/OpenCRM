// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/ui/animations.dart';
import '../../../core/ui/loading_skeleton.dart';
import '../../../core/ui/responsive_helpers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/location.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/providers_repository.dart';
import '../../../data/repositories/services_repository.dart';
import 'widgets/edit_provider_dialog.dart';
import 'widgets/new_provider_dialog.dart';
import 'widgets/provider_list_item.dart';
import 'widgets/providers_empty_state.dart';
import 'widgets/providers_search_bar.dart';

/// ProvidersPage with modern card-based layout and gradient header.
/// Updated by Agent (2025-11-30) - Redesigned to match clients page pattern
class ProvidersPage extends ConsumerStatefulWidget {
  const ProvidersPage({super.key});

  @override
  ConsumerState<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends ConsumerState<ProvidersPage> {
  ProvidersRepository get _providersRepository =>
      ref.read(providersRepositoryProvider);
  ServicesRepository get _servicesRepository =>
      ref.read(servicesRepositoryProvider);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  List<provider_model.Provider> _filterProviders(
    List<provider_model.Provider> providers,
  ) {
    if (_searchQuery.isEmpty) return providers;
    return providers.where((provider) {
      return provider.fullName.toLowerCase().contains(_searchQuery) ||
          (provider.email?.toLowerCase().contains(_searchQuery) ?? false) ||
          (provider.phone?.contains(_searchQuery) ?? false) ||
          provider.specializations.any(
            (s) => s.toLowerCase().contains(_searchQuery),
          );
    }).toList();
  }

  Future<void> _showNewProviderDialog({
    required SecurityContext securityContext,
    required List<Service> services,
    required List<Location> locations,
  }) async {
    if (!context.mounted) return;

    final result = await showDialog<provider_model.Provider>(
      context: context,
      builder: (context) => NewProviderDialog(
        securityContext: securityContext,
        providersRepository: _providersRepository,
        services: services,
        locations: locations,
      ),
    );

    if (result != null && context.mounted) {
      await _syncServiceAssignments(
        securityContext: securityContext,
        provider: result,
        services: services,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Provider "${result.fullName}" created successfully'),
        ),
      );
    }
  }

  Future<void> _showEditProviderDialog({
    required provider_model.Provider provider,
    required SecurityContext securityContext,
    required List<Service> services,
    required List<Location> locations,
  }) async {
    if (!context.mounted) return;

    final result = await showDialog<provider_model.Provider>(
      context: context,
      builder: (context) => EditProviderDialog(
        provider: provider,
        securityContext: securityContext,
        providersRepository: _providersRepository,
        services: services,
        locations: locations,
      ),
    );

    if (result != null && context.mounted) {
      await _syncServiceAssignments(
        securityContext: securityContext,
        provider: result,
        services: services,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Provider "${result.fullName}" updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteProvider(
    provider_model.Provider provider,
    SecurityContext securityContext,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: const Text('Delete Provider'),
        content: Text(
          'Are you sure you want to delete ${provider.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _providersRepository.deleteProvider(
        context: securityContext,
        providerId: provider.id,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provider "${provider.fullName}" deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserMessages.deleteError)));
    }
  }

  Future<void> _syncServiceAssignments({
    required SecurityContext securityContext,
    required provider_model.Provider provider,
    required List<Service> services,
  }) async {
    for (final service in services) {
      final hasProvider = service.providerIds.contains(provider.id);
      final shouldHave = provider.serviceIds.contains(service.id);

      if (shouldHave && !hasProvider) {
        final updated = service.copyWith(
          providerIds: [...service.providerIds, provider.id],
          updatedAt: DateTime.now(),
        );
        await _servicesRepository.upsertService(
          context: securityContext,
          service: updated,
        );
      } else if (!shouldHave && hasProvider) {
        final updated = service.copyWith(
          providerIds: service.providerIds
              .where((id) => id != provider.id)
              .toList(),
          updatedAt: DateTime.now(),
        );
        await _servicesRepository.upsertService(
          context: securityContext,
          service: updated,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appConfigProvider).branding;
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: ErrorFeedback(message: UserMessages.loadError)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // RBAC check: only admin/owner can access providers management
        if (!securityContext.role.canManageProviders) {
          return const Center(
            child: Text('Access denied. Admin privileges required.'),
          );
        }

        final servicesAsync = ref.watch(
          servicesStreamProvider(securityContext),
        );
        final locationsAsync = ref.watch(
          locationsStreamProvider(securityContext),
        );
        final providersAsync = ref.watch(
          providersStreamProvider(securityContext),
        );

        return Scaffold(
          backgroundColor: branding.backgroundColor,
          body: Column(
            children: [
              _buildSearchBar(
                securityContext: securityContext,
                servicesAsync: servicesAsync,
                locationsAsync: locationsAsync,
              ),
              Expanded(
                child: _buildProvidersBody(
                  securityContext: securityContext,
                  servicesAsync: servicesAsync,
                  locationsAsync: locationsAsync,
                  providersAsync: providersAsync,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar({
    required SecurityContext securityContext,
    required AsyncValue<List<Service>> servicesAsync,
    required AsyncValue<List<Location>> locationsAsync,
  }) {
    final services = servicesAsync.valueOrNull ?? <Service>[];
    final locations = locationsAsync.valueOrNull ?? <Location>[];

    return ProvidersSearchBar(
      controller: _searchController,
      searchQuery: _searchQuery,
      onChanged: _onSearchChanged,
      onClear: _clearSearch,
      onAddProvider: () => _showNewProviderDialog(
        securityContext: securityContext,
        services: services,
        locations: locations,
      ),
    );
  }

  Widget _buildProvidersBody({
    required SecurityContext securityContext,
    required AsyncValue<List<Service>> servicesAsync,
    required AsyncValue<List<Location>> locationsAsync,
    required AsyncValue<List<provider_model.Provider>> providersAsync,
  }) {
    final asyncValues = <AsyncValue<dynamic>>[
      servicesAsync,
      locationsAsync,
      providersAsync,
    ];

    for (final value in asyncValues) {
      if (value.isLoading) {
        return _buildLoadingSkeleton();
      }
      if (value.hasError) {
        return Center(child: ErrorFeedback(message: UserMessages.loadError));
      }
    }

    final services = servicesAsync.value ?? <Service>[];
    final locations = locationsAsync.value ?? <Location>[];
    final allProviders = providersAsync.value ?? <provider_model.Provider>[];
    final providers = _filterProviders(allProviders);

    final serviceMap = {for (final service in services) service.id: service};
    final locationMap = {
      for (final location in locations) location.id: location,
    };

    if (allProviders.isEmpty) {
      return ProvidersEmptyState(
        hasSearchTerm: false,
        onAdd: () => _showNewProviderDialog(
          securityContext: securityContext,
          services: services,
          locations: locations,
        ),
      );
    }

    if (providers.isEmpty) {
      return ProvidersEmptyState(
        hasSearchTerm: true,
        searchQuery: _searchQuery,
        onAdd: () => _showNewProviderDialog(
          securityContext: securityContext,
          services: services,
          locations: locations,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderAnnouncements.announceLoaded(
          context,
          '${providers.length} ${providers.length == 1 ? "provider" : "providers"}',
        );
      }
    });

    return PullToRefreshWrapper(
      onRefresh: _refreshProviders,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.xxl * 2,
        ),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          final serviceNames = provider.serviceIds
              .map((id) => serviceMap[id]?.name)
              .whereType<String>()
              .toList();
          final locationNames = provider.locationIds
              .map((id) => locationMap[id]?.name ?? locationMap[id]?.city)
              .whereType<String>()
              .toList();

          return ProviderListItem(
            provider: provider,
            serviceNames: serviceNames,
            locationNames: locationNames,
            onTap: () => _showEditProviderDialog(
              provider: provider,
              securityContext: securityContext,
              services: services,
              locations: locations,
            ),
            onEdit: () => _showEditProviderDialog(
              provider: provider,
              securityContext: securityContext,
              services: services,
              locations: locations,
            ),
            onDelete: () => _deleteProvider(provider, securityContext),
          ).slideInFromBottom(delay: Duration(milliseconds: 50 * (index % 10)));
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SemanticWrapper(
      label: 'Loading providers',
      child: ListView.separated(
        padding: AppSpacing.pagePadding,
        itemCount: 5,
        separatorBuilder: (context, index) => VSpace.sm,
        itemBuilder: (context, index) => const SkeletonListItem(
          hasAvatar: true,
          hasSubtitle: true,
          lineCount: 2,
        ),
      ),
    );
  }

  Future<void> _refreshProviders() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScreenReaderAnnouncements.announceAction(context, 'Providers refreshed');
    }
  }
}
