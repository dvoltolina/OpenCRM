import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/security_context.dart';

/// Client search dialog for selecting a client in Quick Sale.
class ClientSearchDialog extends ConsumerStatefulWidget {
  const ClientSearchDialog({super.key, required this.securityContext});

  final SecurityContext securityContext;

  @override
  ConsumerState<ClientSearchDialog> createState() => _ClientSearchDialogState();
}

class _ClientSearchDialogState extends ConsumerState<ClientSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(clientsStreamProvider(widget.securityContext));

    return AlertDialog(
      title: const Text('Select Client'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  var filtered = clients;
                  if (_searchQuery.isNotEmpty) {
                    filtered = clients.where((c) {
                      return c.fullName.toLowerCase().contains(_searchQuery) ||
                          (c.email?.toLowerCase().contains(_searchQuery) ?? false) ||
                          (c.phone?.contains(_searchQuery) ?? false);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No clients found'
                            : 'No matching clients',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final client = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(client.initials),
                        ),
                        title: Text(client.fullName),
                        subtitle: client.email != null ? Text(client.email!) : null,
                        onTap: () => Navigator.pop(context, client),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Error loading clients')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context), // Walk-in sale
          child: const Text('Skip (Walk-in)'),
        ),
      ],
    );
  }
}

/// Result from the discount dialog.
class DiscountResult {
  const DiscountResult({required this.amountCents, this.reason});
  final int amountCents;
  final String? reason;
}

/// Discount editing dialog for Quick Sale.
class DiscountDialog extends StatefulWidget {
  const DiscountDialog({
    super.key,
    required this.currentDiscountCents,
    required this.maxDiscountCents,
    this.currentReason,
  });

  final int currentDiscountCents;
  final int maxDiscountCents;
  final String? currentReason;

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  bool _isPercent = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentDiscountCents > 0
          ? (widget.currentDiscountCents / 100).toStringAsFixed(2)
          : '',
    );
    _reasonController = TextEditingController(text: widget.currentReason);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _discountCents {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text);
    if (parsed == null) return 0;

    if (_isPercent) {
      return ((parsed / 100) * widget.maxDiscountCents).round();
    }
    return (parsed * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply Discount'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Discount Amount',
                      prefixText: _isPercent ? null : '\$ ',
                      suffixText: _isPercent ? '%' : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('\$')),
                    ButtonSegment(value: true, label: Text('%')),
                  ],
                  selected: {_isPercent},
                  onSelectionChanged: (selection) {
                    setState(() => _isPercent = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Loyalty discount, Promotion',
              ),
            ),
            const SizedBox(height: 16),
            if (_discountCents > 0)
              Text(
                'Discount: \$${(_discountCents / 100).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentDiscountCents > 0)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              DiscountResult(amountCents: 0, reason: null),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: () {
            final discount = _discountCents.clamp(0, widget.maxDiscountCents);
            Navigator.pop(
              context,
              DiscountResult(
                amountCents: discount,
                reason: _reasonController.text.trim().isNotEmpty
                    ? _reasonController.text.trim()
                    : null,
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
