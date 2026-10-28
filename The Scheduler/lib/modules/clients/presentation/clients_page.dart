import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/ui/animations.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/loading_skeleton.dart';
import '../../../core/ui/responsive_helpers.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import 'client_detail_page.dart';
import 'widgets/client_card.dart';
import 'widgets/clients_empty_state.dart';
import 'widgets/clients_filters.dart';
import 'widgets/clients_load_more_button.dart';
import 'widgets/clients_quick_actions_sheet.dart';
import 'widgets/clients_search_bar.dart';
import 'widgets/new_client_dialog.dart';

/// Clients page with card-based layout and improved UI.
/// Updated by Agent (2025-11-30) - Redesigned with cards, gradient header, enhanced filters
class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _debouncedSearchQuery = '';
  Timer? _searchDebounce;
  ClientLifecycle? _lifecycleFilter;
  String? _tagFilter;
  ClientSortOption _sortOption = ClientSortOption.nameAsc;
  Map<String, DateTime> _nextAppointments = {};
  Set<String> _availableTags = {};

  // Count trackers
  int _totalCount = 0;
  int _newCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;

  static const int _pageSize = 50;
  List<Client> _loadedClients = [];
  bool _hasMoreClients = true;
  bool _isLoadingMore = false;
  DateTime? _lastClientCreatedAt;

  static const _searchDebounceMs = Duration(milliseconds: 400);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);
    final branding = ref.watch(appConfigProvider).branding;

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text(SecureErrorHandler.loadingFailed)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: branding.backgroundColor,
          body: SemanticWrapper(
            label: 'Clients management page',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildFilters(),
                Expanded(child: _buildClientsContent(securityContext)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceMs, () {
      if (mounted && _debouncedSearchQuery != value) {
        setState(() => _debouncedSearchQuery = value);
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _debouncedSearchQuery = '';
      _resetPagination();
    });
  }

  void _resetPagination() {
    _loadedClients = [];
    _hasMoreClients = true;
    _isLoadingMore = false;
    _lastClientCreatedAt = null;
  }

  void _onStreamData(List<Client> clients) {
    if (_loadedClients.isEmpty || _lastClientCreatedAt == null) {
      _loadedClients = clients;
      _hasMoreClients = clients.length >= _pageSize;
      if (clients.isNotEmpty) {
        _lastClientCreatedAt = clients.last.createdAt;
      }
    }
  }

  void _updateCounts(List<Client> allClients) {
    int newC = 0, activeC = 0, inactiveC = 0;
    for (final client in allClients) {
      switch (client.lifecycle) {
        case ClientLifecycle.newClient:
          newC++;
          break;
        case ClientLifecycle.active:
          activeC++;
          break;
        case ClientLifecycle.inactive:
          inactiveC++;
          break;
        case ClientLifecycle.churned:
          break;
      }
    }
    // Defer setState to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          (_totalCount != allClients.length ||
              _newCount != newC ||
              _activeCount != activeC ||
              _inactiveCount != inactiveC)) {
        setState(() {
          _totalCount = allClients.length;
          _newCount = newC;
          _activeCount = activeC;
          _inactiveCount = inactiveC;
        });
      }
    });
  }

  Future<void> _loadMoreClients(SecurityContext securityContext) async {
    if (_isLoadingMore || !_hasMoreClients || _debouncedSearchQuery.isNotEmpty) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final clientsRepository = ref.read(clientsRepositoryProvider);
      final moreClients = await clientsRepository.getClients(
        securityContext,
        limit: _pageSize,
        startAfterId: _loadedClients.isNotEmpty ? _loadedClients.last.id : null,
      );

      setState(() {
        _loadedClients = [..._loadedClients, ...moreClients];
        _hasMoreClients = moreClients.length >= _pageSize;
        if (moreClients.isNotEmpty) {
          _lastClientCreatedAt = moreClients.last.createdAt;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SecureErrorHandler.loadingFailed)),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return ClientsSearchBar(
      controller: _searchController,
      searchQuery: _searchQuery,
      onChanged: _onSearchChanged,
      onClear: _clearSearch,
      onAddClient: () => _showNewClientDialog(context),
    );
  }

  Widget _buildFilters() {
    return ClientsFilters(
      lifecycleFilter: _lifecycleFilter,
      onLifecycleChanged: (value) => setState(() => _lifecycleFilter = value),
      sortOption: _sortOption,
      onSortChanged: (value) => setState(() => _sortOption = value),
      availableTags: _availableTags,
      tagFilter: _tagFilter,
      onTagChanged: (value) => setState(() => _tagFilter = value),
      totalCount: _totalCount,
      newCount: _newCount,
      activeCount: _activeCount,
      inactiveCount: _inactiveCount,
    );
  }

  Widget _buildClientsContent(SecurityContext securityContext) {
    final clientsRepository = ref.read(clientsRepositoryProvider);
    final appointmentsRepository = ref.read(appointmentsRepositoryProvider);
    final authService = ref.read(authStateServiceProvider);

    return StreamBuilder<List<Appointment>>(
      stream: appointmentsRepository.watchUpcoming(securityContext),
      builder: (context, appointmentsSnapshot) {
        final upcoming = appointmentsSnapshot.data ?? [];
        _nextAppointments = _computeNextAppointments(upcoming);

        return StreamBuilder<List<Client>>(
          stream: _debouncedSearchQuery.isEmpty
              ? clientsRepository.watchClients(securityContext, limit: _pageSize)
              : clientsRepository.searchClients(
                  context: securityContext,
                  query: _debouncedSearchQuery,
                ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: ErrorFeedback(
                  message: SecureErrorHandler.loadingFailed,
                ),
              );
            }

            if (!snapshot.hasData) {
              return _buildLoadingSkeleton();
            }

            final streamClients = snapshot.data!;
            if (_debouncedSearchQuery.isEmpty) {
              _onStreamData(streamClients);
            }

            var clients =
                _debouncedSearchQuery.isEmpty ? _loadedClients : streamClients;

            // Update counts before filtering
            _updateCounts(clients);

            if (_lifecycleFilter != null) {
              clients = clients
                  .where((client) => client.lifecycle == _lifecycleFilter)
                  .toList();
            }

            if (_tagFilter != null) {
              clients = clients
                  .where((client) => client.tags.contains(_tagFilter))
                  .toList();
            }

            _captureAvailableTags(clients);
            clients = _sortClients(clients);

            if (clients.isEmpty) {
              return ClientsEmptyState(
                hasSearchTerm: _searchQuery.isNotEmpty,
                onAdd: () => _showNewClientDialog(context),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScreenReaderAnnouncements.announceLoaded(
                  context,
                  '${clients.length} ${clients.length == 1 ? "client" : "clients"}',
                );
              }
            });

            final showLoadMore =
                _debouncedSearchQuery.isEmpty && _hasMoreClients;

            return PullToRefreshWrapper(
              onRefresh: () async {
                _resetPagination();
                await _refreshClients(securityContext);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xxl * 2,
                ),
                itemCount: clients.length + (showLoadMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == clients.length) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildLoadMoreButton(securityContext),
                    );
                  }

                  final client = clients[index];
                  final nextAppt = _nextAppointments[client.id];

                  return ClientCard(
                    client: client,
                    nextAppointment: nextAppt,
                    onTap: () => _navigateToClientDetail(client),
                    onQuickActions: () => _showQuickActions(
                      context,
                      client,
                      authService,
                      clientsRepository,
                    ),
                  ).slideInFromBottom(
                    delay: Duration(milliseconds: 50 * (index % 10)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return SemanticWrapper(
      label: 'Loading clients',
      child: ListView.separated(
        padding: AppSpacing.pagePadding,
        itemCount: 5,
        separatorBuilder: (_, _) => VSpace.sm,
        itemBuilder: (_, _) => const SkeletonListItem(
          hasAvatar: true,
          hasSubtitle: true,
          lineCount: 2,
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(SecurityContext securityContext) {
    return ClientsLoadMoreButton(
      isLoadingMore: _isLoadingMore,
      onLoadMore: () => _loadMoreClients(securityContext),
      loadedCount: _loadedClients.length,
    );
  }

  Future<void> _refreshClients(SecurityContext securityContext) async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScreenReaderAnnouncements.announceAction(context, 'Clients refreshed');
    }
  }

  List<Client> _sortClients(List<Client> clients) {
    switch (_sortOption) {
      case ClientSortOption.nameAsc:
        clients.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case ClientSortOption.nameDesc:
        clients.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case ClientSortOption.recentlyAdded:
        clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ClientSortOption.lastAppointment:
        clients.sort((a, b) {
          final aLast = a.lastAppointmentDate;
          final bLast = b.lastAppointmentDate;
          if (aLast == null && bLast == null) return 0;
          if (aLast == null) return 1;
          if (bLast == null) return -1;
          return bLast.compareTo(aLast);
        });
        break;
      case ClientSortOption.upcomingAppointment:
        clients.sort((a, b) {
          final aNext = _nextAppointments[a.id];
          final bNext = _nextAppointments[b.id];
          if (aNext == null && bNext == null) return 0;
          if (aNext == null) return 1;
          if (bNext == null) return -1;
          return aNext.compareTo(bNext);
        });
        break;
    }
    return clients;
  }

  void _captureAvailableTags(List<Client> clients) {
    final tags = <String>{};
    for (final client in clients) {
      tags.addAll(client.tags);
    }
    if (!_setEquals(tags, _availableTags)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _availableTags = tags;
          });
        }
      });
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  Map<String, DateTime> _computeNextAppointments(List<Appointment> upcoming) {
    final map = <String, DateTime>{};
    for (final appt in upcoming) {
      final existing = map[appt.clientId];
      final nextStart = appt.startTime;
      if (existing == null || nextStart.isBefore(existing)) {
        map[appt.clientId] = nextStart;
      }
    }
    return map;
  }

  void _navigateToClientDetail(Client client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailPage(clientId: client.id),
      ),
    );
  }

  void _showQuickActions(
    BuildContext context,
    Client client,
    dynamic authService,
    dynamic clientsRepository,
  ) {
    showClientsQuickActionsSheet(
      context: context,
      client: client,
      clientsRepository: clientsRepository,
      authService: authService,
      ref: ref,
      onNavigateToDetail: () => _navigateToClientDetail(client),
    );
  }

  void _showNewClientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewClientDialog(),
    );
  }
}
