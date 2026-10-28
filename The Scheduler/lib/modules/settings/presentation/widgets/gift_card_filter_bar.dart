import 'package:flutter/material.dart';

import '../../../../data/models/gift_card.dart';

/// Filter bar for gift cards with status chips and search
class GiftCardFilterBar extends StatelessWidget {
  const GiftCardFilterBar({
    required this.statusFilter,
    required this.searchQuery,
    required this.searchController,
    required this.onStatusChanged,
    required this.onSearchChanged,
    super.key,
  });

  final GiftCardStatus? statusFilter;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<GiftCardStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: statusFilter == null,
                    onSelected: (_) => onStatusChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...GiftCardStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(status)),
                        selected: statusFilter == status,
                        onSelected: (_) => onStatusChanged(status),
                        avatar: CircleAvatar(
                          backgroundColor: _statusColor(status),
                          radius: 6,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Search field
          SizedBox(
            width: 250,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search code or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(GiftCardStatus status) {
    switch (status) {
      case GiftCardStatus.pending:
        return 'Pending';
      case GiftCardStatus.active:
        return 'Active';
      case GiftCardStatus.depleted:
        return 'Depleted';
      case GiftCardStatus.expired:
        return 'Expired';
      case GiftCardStatus.voided:
        return 'Voided';
    }
  }

  Color _statusColor(GiftCardStatus status) {
    switch (status) {
      case GiftCardStatus.pending:
        return Colors.orange;
      case GiftCardStatus.active:
        return Colors.green;
      case GiftCardStatus.depleted:
        return Colors.grey;
      case GiftCardStatus.expired:
        return Colors.red;
      case GiftCardStatus.voided:
        return Colors.red.shade900;
    }
  }
}
