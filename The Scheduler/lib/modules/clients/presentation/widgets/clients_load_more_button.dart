import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Load more button for pagination
/// Updated by Agent U3 (2025-11-29) - Uses design tokens
class ClientsLoadMoreButton extends StatelessWidget {
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final int loadedCount;

  const ClientsLoadMoreButton({
    super.key,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.loadedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: isLoadingMore
            ? SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: Text('Load More ($loadedCount loaded)'),
              ),
      ),
    );
  }
}
