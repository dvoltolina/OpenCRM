import 'package:flutter/material.dart';

/// Empty state widget for gift cards list
class GiftCardEmptyState extends StatelessWidget {
  const GiftCardEmptyState({required this.hasFilter, super.key});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No gift cards match your filters' : 'No gift cards yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try adjusting your search or filters'
                : 'Gift cards will appear here when purchased',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
