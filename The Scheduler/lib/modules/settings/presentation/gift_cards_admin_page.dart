import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/gift_card.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/gift_card_repository.dart';
import 'widgets/gift_card_detail_sheet.dart';
import 'widgets/gift_card_empty_state.dart';
import 'widgets/gift_card_filter_bar.dart';
import 'widgets/gift_card_list_tile.dart';
import 'widgets/gift_card_manual_issuance_dialog.dart';
import 'widgets/gift_card_stats_header.dart';
import 'widgets/gift_card_template_dialog.dart';

/// Admin page for managing gift cards.
///
/// Features:
/// - Stats header (total sold, outstanding, redeemed)
/// - Filterable/sortable gift card list
/// - Detail sheet with admin actions
/// - Template management
/// - Manual issuance
class GiftCardsAdminPage extends ConsumerStatefulWidget {
  const GiftCardsAdminPage({super.key});

  @override
  ConsumerState<GiftCardsAdminPage> createState() => _GiftCardsAdminPageState();
}

class _GiftCardsAdminPageState extends ConsumerState<GiftCardsAdminPage> {
  GiftCardStatus? _statusFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(UserMessages.loadError)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: Text('Authentication required.'));
        }
        return AppPageScaffold(
          title: 'Gift Cards',
          showBackButton: false,
          showAppBar: false,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showManualIssuanceDialog(context),
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Issue Gift Card'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Manage Templates',
              onPressed: () => _showTemplateDialog(context),
            ),
            HSpace.xs,
          ],
          body: _buildContent(context, securityContext),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SecurityContext securityContext) {
    final giftCardService = ref.watch(giftCardServiceProvider);

    return Column(
      children: [
        // Stats Header
        FutureBuilder<GiftCardStats>(
          future: giftCardService.getGiftCardStats(securityContext),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const GiftCardStatsHeaderSkeleton();
            }
            final stats = snapshot.data ?? GiftCardStats.empty();
            return GiftCardStatsHeader(stats: stats);
          },
        ),
        const Divider(height: 1),
        // Filter Bar
        GiftCardFilterBar(
          statusFilter: _statusFilter,
          searchQuery: _searchQuery,
          searchController: _searchController,
          onStatusChanged: (status) => setState(() => _statusFilter = status),
          onSearchChanged: (query) => setState(() => _searchQuery = query),
        ),
        const Divider(height: 1),
        // Gift Card List
        Expanded(
          child: StreamBuilder<List<GiftCard>>(
            stream: giftCardService.watchGiftCards(
              securityContext,
              status: _statusFilter,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(UserMessages.loadError));
              }

              var giftCards = snapshot.data ?? [];

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                giftCards = giftCards.where((card) {
                  return card.code.toLowerCase().contains(query) ||
                      (card.purchaserEmail.toLowerCase().contains(query)) ||
                      (card.recipientEmail?.toLowerCase().contains(query) ?? false);
                }).toList();
              }

              if (giftCards.isEmpty) {
                return GiftCardEmptyState(
                  hasFilter: _statusFilter != null || _searchQuery.isNotEmpty,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16, top: 16),
                itemCount: giftCards.length,
                separatorBuilder: (_, _) => VSpace.sm,
                itemBuilder: (context, index) {
                  final card = giftCards[index];
                  return GiftCardListTile(
                    giftCard: card,
                    onTap: () => _showDetailSheet(context, securityContext, card),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetailSheet(
    BuildContext context,
    SecurityContext securityContext,
    GiftCard giftCard,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GiftCardDetailSheet(
        giftCard: giftCard,
        securityContext: securityContext,
      ),
    );
  }

  void _showTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GiftCardTemplateDialog(),
    );
  }

  void _showManualIssuanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GiftCardManualIssuanceDialog(),
    );
  }
}
