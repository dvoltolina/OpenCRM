import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/business_search_result.dart';
import '../providers/client_portal_providers.dart';
import 'business_detail_page.dart';
import 'widgets/business_code_entry.dart';
import 'widgets/business_search_results.dart';

/// First screen clients see when opening the app.
///
/// Allows clients to:
/// 1. Search for businesses by name
/// 2. Enter a business code directly
/// 3. Sign in to existing account
///
/// HIPAA Note: No PHI on this page - public business search only
class BusinessDiscoveryPage extends ConsumerStatefulWidget {
  const BusinessDiscoveryPage({super.key});

  @override
  ConsumerState<BusinessDiscoveryPage> createState() =>
      _BusinessDiscoveryPageState();
}

class _BusinessDiscoveryPageState extends ConsumerState<BusinessDiscoveryPage> {
  final _searchController = TextEditingController();
  bool _showCodeEntry = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBusinessSelected(BusinessSearchResult business) {
    // Save selected business
    ref.read(selectedBusinessProvider.notifier).state = business;

    // Navigate to business detail page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessDetailPage(businessId: business.id),
      ),
    );
  }

  void _toggleCodeEntry() {
    setState(() {
      _showCodeEntry = !_showCodeEntry;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(businessSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Business'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App branding
              Icon(
                Icons.calendar_today,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              VSpace.md,
              Text(
                'The Scheduler',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.sm,
              Text(
                'Find and book with local businesses',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.xl,

              // Search input
              if (!_showCodeEntry) ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search for a business',
                    hintText: 'Business name...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(businessSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(businessSearchQueryProvider.notifier).state =
                        value;
                  },
                ),
                VSpace.md,

                // Search results
                searchResults.when(
                  data: (results) {
                    if (results.isEmpty &&
                        _searchController.text.trim().length >= 2) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              VSpace.md,
                              Text(
                                'No businesses found',
                                style: theme.textTheme.titleMedium,
                              ),
                              VSpace.sm,
                              Text(
                                'Try a different search term or use a business code',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return BusinessSearchResults(
                      results: results,
                      onBusinessSelected: _handleBusinessSelected,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          VSpace.md,
                          Text(
                            'Search failed',
                            style: theme.textTheme.titleMedium,
                          ),
                          VSpace.sm,
                          Text(
                            'Please try again',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                VSpace.lg,

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'or',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                VSpace.lg,

                // Toggle to code entry
                OutlinedButton.icon(
                  onPressed: _toggleCodeEntry,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Enter Business Code'),
                ),
              ],

              // Code entry
              if (_showCodeEntry) ...[
                BusinessCodeEntry(
                  onBusinessFound: _handleBusinessSelected,
                ),
                VSpace.lg,

                // Back to search
                TextButton.icon(
                  onPressed: _toggleCodeEntry,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Search'),
                ),
              ],

              VSpace.xl,

              // Divider
              const Divider(),
              VSpace.md,

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  HSpace.sm,
                  TextButton(
                    onPressed: () {
                      // Navigate to sign in
                      // TODO: Implement navigation to sign in page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign in flow not yet implemented'),
                        ),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
