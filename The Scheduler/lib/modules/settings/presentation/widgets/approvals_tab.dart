import 'package:flutter/material.dart';

import '../../../../data/models/security_context.dart';

class ApprovalsTab extends StatelessWidget {
  const ApprovalsTab({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    // TODO(RW2): Uncomment when repository is available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pending_actions, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Pending Approvals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Review and approve join requests from staff.\n\n'
              'Note: Approval flow requires models and repository implementation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    // Actual implementation (uncomment when repository is available):
    /*
    final requestsAsync = ref.watch(pendingRequestsStreamProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending approvals'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return JoinRequestListTile(
              joinRequest: request,
              onApprove: () => _approveJoinRequest(context, securityContext, request),
              onDeny: () => _denyJoinRequest(context, securityContext, request),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        SafeErrorHandler.handle(error, context: 'Loading join requests', stackTrace: stackTrace);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(UserMessages.loadError),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(pendingRequestsStreamProvider),
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
