// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/ui/animations.dart';
import '../../../core/ui/loading_skeleton.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/intake_form.dart';
import '../../../data/models/location.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/resource.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/providers_repository.dart';
import '../../../data/repositories/services_repository.dart';
import 'widgets/edit_service_dialog.dart';
import 'widgets/new_service_dialog.dart';
import 'widgets/service_list_item.dart';
import 'widgets/services_empty_state.dart';
import 'widgets/services_filter_chip.dart';
import 'widgets/services_search_bar.dart';

/// ServicesPage with modern card-based layout and gradient header.
/// Updated by Agent (2025-11-30) - Redesigned to match clients/providers page pattern
class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  ServicesRepository get _servicesRepository =>
      ref.read(servicesRepositoryProvider);
  ProvidersRepository get _providersRepository =>
      ref.read(providersRepositoryProvider);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

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

  List<Service> _filterServices(List<Service> services) {
    var filtered = services;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((service) {
        return service.name.toLowerCase().contains(_searchQuery) ||
            (service.description?.toLowerCase().contains(_searchQuery) ??
                false) ||
            (service.category?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((service) => service.category == _selectedCategory)
          .toList();
    }
    return filtered;
  }

  List<String> _getCategories(List<Service> services) {
    final categories = services
        .where((s) => s.category != null)
        .map((s) => s.category!)
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  Map<String, int> _getCategoryCounts(List<Service> services) {
    final counts = <String, int>{'All': services.length};
    for (final service in services) {
      if (service.category != null) {
        counts[service.category!] = (counts[service.category!] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> _showNewServiceDialog({
    required SecurityContext securityContext,
    required List<provider_model.Provider> providers,
    required List<Resource> resources,
    required List<IntakeFormTemplate> templates,
  }) async {
    if (!context.mounted) return;
    final result = await showDialog<Service>(
      context: context,
      builder: (context) => NewServiceDialog(
        securityContext: securityContext,
        servicesRepository: _servicesRepository,
        providers: providers,
        resources: resources,
        intakeForms: templates,
      ),
    );
    if (result != null && context.mounted) {
      await _syncProviderAssignments(
        securityContext: securityContext,
        service: result,
        providers: providers,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service "${result.name}" created successfully'),
        ),
      );
    }
  }

  Future<void> _showEditServiceDialog(
    Service service, {
    required SecurityContext securityContext,
    required List<provider_model.Provider> providers,
    required List<Resource> resources,
    required List<IntakeFormTemplate> templates,
  }) async {
    if (!context.mounted) return;
    final result = await showDialog<Service>(
      context: context,
      builder: (context) => EditServiceDialog(
        service: service,
        securityContext: securityContext,
        servicesRepository: _servicesRepository,
        providers: providers,
        resources: resources,
        intakeForms: templates,
      ),
    );
    if (result != null && context.mounted) {
      await _syncProviderAssignments(
        securityContext: securityContext,
        service: result,
        providers: providers,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service "${result.name}" updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteService(
    Service service,
    SecurityContext securityContext,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
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
      await _servicesRepository.deleteService(
        context: securityContext,
        serviceId: service.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service "${service.name}" deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserMessages.deleteError)));
    }
  }

  Future<void> _syncProviderAssignments({
    required SecurityContext securityContext,
    required Service service,
    required List<provider_model.Provider> providers,
  }) async {
    for (final provider in providers) {
      final hasService = provider.serviceIds.contains(service.id);
      final shouldHave = service.providerIds.contains(provider.id);
      if (shouldHave && !hasService) {
        final updated = provider.copyWith(
          serviceIds: [...provider.serviceIds, service.id],
          updatedAt: DateTime.now(),
        );
        await _providersRepository.upsertProvider(
          context: securityContext,
          provider: updated,
        );
      } else if (!shouldHave && hasService) {
        final updated = provider.copyWith(
          serviceIds: provider.serviceIds
              .where((id) => id != service.id)
              .toList(),
          updatedAt: DateTime.now(),
        );
        await _providersRepository.upsertProvider(
          context: securityContext,
          provider: updated,
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

        // RBAC check: only admin/owner can access services management
        if (!securityContext.role.canManageProviders) {
          return const Center(
            child: Text('Access denied. Admin privileges required.'),
          );
        }

        final providersAsync = ref.watch(
          providersStreamProvider(securityContext),
        );
        final resourcesAsync = ref.watch(
          resourcesStreamProvider(securityContext),
        );
        final locationsAsync = ref.watch(
          locationsStreamProvider(securityContext),
        );
        final templatesAsync = ref.watch(
          intakeFormsStreamProvider(securityContext),
        );
        final servicesAsync = ref.watch(
          servicesStreamProvider(securityContext),
        );

        return Scaffold(
          backgroundColor: branding.backgroundColor,
          body: Column(
            children: [
              _buildSearchBar(
                securityContext: securityContext,
                providersAsync: providersAsync,
                resourcesAsync: resourcesAsync,
                templatesAsync: templatesAsync,
              ),
              Expanded(
                child: _buildServicesBody(
                  securityContext: securityContext,
                  providersAsync: providersAsync,
                  resourcesAsync: resourcesAsync,
                  locationsAsync: locationsAsync,
                  templatesAsync: templatesAsync,
                  servicesAsync: servicesAsync,
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
    required AsyncValue<List<provider_model.Provider>> providersAsync,
    required AsyncValue<List<Resource>> resourcesAsync,
    required AsyncValue<List<IntakeFormTemplate>> templatesAsync,
  }) {
    final providers = providersAsync.valueOrNull ?? <provider_model.Provider>[];
    final resources = resourcesAsync.valueOrNull ?? <Resource>[];
    final templates = templatesAsync.valueOrNull ?? <IntakeFormTemplate>[];

    return ServicesSearchBar(
      controller: _searchController,
      searchQuery: _searchQuery,
      onChanged: _onSearchChanged,
      onClear: _clearSearch,
      onAddService: () => _showNewServiceDialog(
        securityContext: securityContext,
        providers: providers,
        resources: resources,
        templates: templates,
      ),
    );
  }

  Widget _buildCategoryFilters(List<Service> allServices) {
    final theme = Theme.of(context);
    final categories = _getCategories(allServices);
    final categoryCounts = _getCategoryCounts(allServices);

    if (categories.length <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ServicesFilterChip(
                label: category,
                isSelected: isSelected,
                count: categoryCounts[category],
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServicesBody({
    required SecurityContext securityContext,
    required AsyncValue<List<provider_model.Provider>> providersAsync,
    required AsyncValue<List<Resource>> resourcesAsync,
    required AsyncValue<List<Location>> locationsAsync,
    required AsyncValue<List<IntakeFormTemplate>> templatesAsync,
    required AsyncValue<List<Service>> servicesAsync,
  }) {
    final asyncValues = <AsyncValue<dynamic>>[
      providersAsync,
      resourcesAsync,
      locationsAsync,
      templatesAsync,
      servicesAsync,
    ];

    for (final value in asyncValues) {
      if (value.isLoading) {
        return _buildLoadingSkeleton();
      }
      if (value.hasError) {
        return Center(child: ErrorFeedback(message: UserMessages.loadError));
      }
    }

    final providers = providersAsync.value ?? <provider_model.Provider>[];
    final resources = resourcesAsync.value ?? <Resource>[];
    final locations = locationsAsync.value ?? <Location>[];
    final templates = templatesAsync.value ?? <IntakeFormTemplate>[];
    final allServices = servicesAsync.value ?? <Service>[];

    final services = _filterServices(allServices);
    final providerMap = {
      for (final provider in providers) provider.id: provider,
    };
    final resourceMap = {
      for (final resource in resources) resource.id: resource,
    };
    final locationMap = {
      for (final location in locations) location.id: location,
    };
    final templateMap = {for (final form in templates) form.id: form};

    if (allServices.isEmpty) {
      return ServicesEmptyState(
        hasSearchTerm: false,
        onAdd: () => _showNewServiceDialog(
          securityContext: securityContext,
          providers: providers,
          resources: resources,
          templates: templates,
        ),
      );
    }

    return Column(
      children: [
        _buildCategoryFilters(allServices),
        Expanded(
          child: services.isEmpty
              ? ServicesEmptyState(
                  hasSearchTerm: true,
                  searchQuery: _searchQuery,
                  onAdd: () => _showNewServiceDialog(
                    securityContext: securityContext,
                    providers: providers,
                    resources: resources,
                    templates: templates,
                  ),
                )
              : _buildServicesList(
                  services: services,
                  securityContext: securityContext,
                  providers: providers,
                  resources: resources,
                  templates: templates,
                  providerMap: providerMap,
                  resourceMap: resourceMap,
                  locationMap: locationMap,
                  templateMap: templateMap,
                ),
        ),
      ],
    );
  }

  Widget _buildServicesList({
    required List<Service> services,
    required SecurityContext securityContext,
    required List<provider_model.Provider> providers,
    required List<Resource> resources,
    required List<IntakeFormTemplate> templates,
    required Map<String, provider_model.Provider> providerMap,
    required Map<String, Resource> resourceMap,
    required Map<String, Location> locationMap,
    required Map<String, IntakeFormTemplate> templateMap,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderAnnouncements.announceLoaded(
          context,
          '${services.length} ${services.length == 1 ? "service" : "services"}',
        );
      }
    });

    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.xxl * 2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final providerNames = service.providerIds
            .map((id) => providerMap[id]?.fullName)
            .whereType<String>()
            .toList();
        final resourceNames = service.requiredResources
            .map((id) {
              final resource = resourceMap[id];
              if (resource == null) return null;
              final locationLabel =
                  locationMap[resource.locationId]?.name ??
                  locationMap[resource.locationId]?.city;
              return locationLabel == null
                  ? resource.name
                  : '${resource.name} • $locationLabel';
            })
            .whereType<String>()
            .toList();
        final intakeFormName = service.intakeFormTemplateId == null
            ? null
            : templateMap[service.intakeFormTemplateId]?.name;

        return ServiceListItem(
          service: service,
          providerNames: providerNames,
          resourceNames: resourceNames,
          intakeFormName: intakeFormName,
          onTap: () => _showEditServiceDialog(
            service,
            securityContext: securityContext,
            providers: providers,
            resources: resources,
            templates: templates,
          ),
          onEdit: () => _showEditServiceDialog(
            service,
            securityContext: securityContext,
            providers: providers,
            resources: resources,
            templates: templates,
          ),
          onDelete: () => _deleteService(service, securityContext),
        ).slideInFromBottom(delay: Duration(milliseconds: 50 * (index % 10)));
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return SemanticWrapper(
      label: 'Loading services',
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
}
