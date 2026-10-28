import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/accounting_connection.dart';

/// Card widget showing accounting connection status.
///
/// Displays:
/// - Provider logo and name
/// - Connection status indicator
/// - Connected company name
/// - Last sync time
/// - Disconnect/reconnect actions
class AccountingConnectionCard extends StatelessWidget {
  const AccountingConnectionCard({
    required this.connection,
    required this.onDisconnect,
    required this.onReconnect,
    super.key,
  });

  final AccountingConnection connection;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _buildProviderLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.provider.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (connection.providerCompanyName != null)
                        Text(
                          connection.providerCompanyName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(theme),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Connection details
            _buildDetailRow(
              context,
              Icons.business,
              'Company ID',
              connection.providerCompanyId,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Connected',
              _formatDate(connection.connectedAt),
            ),
            if (connection.lastSyncAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.sync,
                'Last Sync',
                _formatDate(connection.lastSyncAt),
              ),
            ],
            if (connection.lastSyncError != null) ...[
              const SizedBox(height: 8),
              _buildErrorRow(context),
            ],
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (connection.status == ConnectionStatus.expired ||
                    connection.status == ConnectionStatus.error)
                  TextButton.icon(
                    onPressed: onReconnect,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDisconnect,
                  icon: Icon(
                    Icons.link_off,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Disconnect',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderLogo() {
    // Use provider-specific colors as placeholder for logos
    final color = connection.provider == AccountingProvider.quickbooks
        ? const Color(0xFF2CA01C) // QuickBooks green
        : const Color(0xFF13B5EA); // Xero blue

    final icon = connection.provider == AccountingProvider.quickbooks
        ? Icons.calculate
        : Icons.auto_graph;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final (color, label, icon) = switch (connection.status) {
      ConnectionStatus.active => (
          Colors.green,
          'Connected',
          Icons.check_circle,
        ),
      ConnectionStatus.expired => (
          Colors.orange,
          'Expired',
          Icons.warning,
        ),
      ConnectionStatus.error => (
          Colors.red,
          'Error',
          Icons.error,
        ),
      ConnectionStatus.disconnected => (
          Colors.grey,
          'Disconnected',
          Icons.link_off,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connection.lastSyncError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat.yMMMd().format(date);
  }
}
