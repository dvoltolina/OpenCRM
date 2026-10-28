import 'package:flutter/material.dart';

import '../../../../data/models/security_context.dart';

class JoinCodesTab extends StatelessWidget {
  const JoinCodesTab({
    super.key,
    required this.securityContext,
    required this.onCreateCode,
  });

  final SecurityContext securityContext;
  final VoidCallback onCreateCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO(RW2): Uncomment when repository is available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Join Codes',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create shareable join codes for staff to join your business.\n\n'
              'Note: Join code management requires models and repository implementation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateCode,
            icon: const Icon(Icons.add),
            label: const Text('Create Join Code'),
          ),
        ],
      ),
    );

    // Actual implementation (uncomment when repository is available):
    /*
    final joinCodesAsync = ref.watch(joinCodesStreamProvider);

    return joinCodesAsync.when(
      data: (codes) {
        if (codes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                const Text('No join codes yet'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onCreateCode,
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Code'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: codes.length,
          itemBuilder: (context, index) {
            final code = codes[index];
            return JoinCodeListTile(
              joinCode: code,
              onCopy: () => _copyCodeToClipboard(context, code),
              onRevoke: () => _revokeJoinCode(context, securityContext, code),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        SafeErrorHandler.handle(error, context: 'Loading join codes', stackTrace: stackTrace);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(UserMessages.loadError),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(joinCodesStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
    */
  }
}
