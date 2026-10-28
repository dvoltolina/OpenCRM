import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/accounting_sync_service.dart';
import '../../../../data/models/accounting_connection.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/models/sync_record.dart';
import '../../../../data/repositories/accounting_connection_repository.dart';

/// Panel showing sync history and allowing retry of failed syncs.
///
/// Displays:
/// - Summary of sync status
/// - Recent sync records with status
/// - Retry failed button
class SyncHistoryPanel extends ConsumerStatefulWidget {
  const SyncHistoryPanel({
    required this.connection,
    required this.onRetryComplete,
    super.key,
  });

  final AccountingConnection connection;
  final VoidCallback onRetryComplete;

  @override
  ConsumerState<SyncHistoryPanel> createState() => _SyncHistoryPanelState();
}

class _SyncHistoryPanelState extends ConsumerState<SyncHistoryPanel> {
  final AccountingConnectionRepository _connectionRepo =
      AccountingConnectionRepository();
  final AccountingSyncService _syncService = AccountingSyncService();

  bool _isLoading = true;
  bool _isRetrying = false;
  String? _errorMessage;
  List<SyncRecord> _recentRecords = [];
  SyncStatusSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSyncHistory();
  }

  Future<SecurityContext> _getSecurityContext() async {
    final authService = ref.read(authStateServiceProvider);
    final profile = await authService.getCurrentUserProfile();
    if (profile == null) {
      throw Exception('User not authenticated');
    }
    return SecurityContext(
      userId: profile.id,
      businessId: profile.businessId,
      role: profile.role,
    );
  }

  Future<void> _loadSyncHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final context = await _getSecurityContext();

      // Load recent sync records
      _recentRecords = await _connectionRepo.getRecentSyncRecords(
        context: context,
        filter: SyncRecordFilter(
          connectionId: widget.connection.id,
          limit: 20,
        ),
      );

      // Load sync status summary
      _summary = await _syncService.getSyncStatus(
        context: context,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sync history: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryFailed() async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    try {
      final securityContext = await _getSecurityContext();

      final result = await _syncService.retryFailedSyncs(
        context: securityContext,
      );

      widget.onRetryComplete();
      await _loadSyncHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Retry complete: ${result.successCount} succeeded, '
              '${result.failedCount} failed',
            ),
            backgroundColor:
                result.failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Retry failed: $e';
      });
    } finally {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Sync History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadSyncHistory,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 16),
            ],

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Summary cards
              if (_summary != null) _buildSummary(theme),
              const SizedBox(height: 16),

              // Recent records
              Text(
                'Recent Activity',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_recentRecords.isEmpty)
                _buildEmptyState(theme)
              else
                _buildRecordsList(theme),

              // Retry button (if there are failures)
              if (_summary != null && _summary!.failedCount > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRetrying ? null : _retryFailed,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.replay),
                    label: Text(
                      'Retry ${_summary!.failedCount} Failed Items',
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    // Count synced items from records
    final syncedCount = _recentRecords.where(
      (r) => r.status == SyncStatus.success,
    ).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            theme,
            Icons.check_circle,
            Colors.green,
            'Synced',
            syncedCount.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            theme,
            Icons.pending,
            Colors.orange,
            'Pending',
            _summary!.pendingCount.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            theme,
            Icons.error,
            Colors.red,
            'Failed',
            _summary!.failedCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.sync_disabled,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No sync activity yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Run a sync to see activity here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentRecords.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = _recentRecords[index];
        return _buildRecordTile(theme, record);
      },
    );
  }

  Widget _buildRecordTile(ThemeData theme, SyncRecord record) {
    final (statusColor, statusIcon) = switch (record.status) {
      SyncStatus.success => (Colors.green, Icons.check_circle),
      SyncStatus.failed => (Colors.red, Icons.error),
      SyncStatus.pending => (Colors.orange, Icons.pending),
      SyncStatus.skipped => (Colors.grey, Icons.skip_next),
    };

    return ExpansionTile(
      leading: Icon(statusIcon, color: statusColor, size: 20),
      title: Text(
        record.displaySummary,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        record.syncedAtDisplay,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: record.isFailed && record.canRetry
          ? const Icon(Icons.replay, size: 16)
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Local ID', record.localId),
              if (record.remoteId != null)
                _buildDetailRow('Remote ID', record.remoteId!),
              _buildDetailRow('Type', record.localType.displayName),
              _buildDetailRow('Direction', record.syncDirection.displayName),
              _buildDetailRow(
                'Time',
                DateFormat.yMMMd().add_jm().format(record.syncedAt),
              ),
              if (record.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
