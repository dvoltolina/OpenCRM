// Audit Log Viewer Screen
//
// Displays security audit logs for the staff app.
// Shows authentication events, data access, and security events.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/audit_log_service.dart';

// Re-export for convenience
export '../../../core/services/audit_log_service.dart'
    show AuditEventType, AuditSeverity, AuditLogEntry;

/// Provider for audit logs.
final auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final service = ref.watch(auditLogServiceProvider);
  if (!service.isInitialized) {
    await service.initialize();
  }
  return service.logs;
});

/// Extension for AuditLogEntry UI helpers.
extension AuditLogEntryUI on AuditLogEntry {
  /// Icon for this event type.
  IconData get icon {
    switch (type) {
      case AuditEventType.authentication:
        return Icons.login;
      case AuditEventType.dataAccess:
        return Icons.visibility;
      case AuditEventType.dataModification:
        return Icons.edit;
      case AuditEventType.security:
        return Icons.security;
      case AuditEventType.sync:
        return Icons.sync;
      case AuditEventType.system:
        return Icons.settings;
    }
  }

  /// Color for this severity.
  Color severityColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case AuditSeverity.info:
        return colorScheme.primary;
      case AuditSeverity.warning:
        return Colors.orange;
      case AuditSeverity.error:
        return colorScheme.error;
      case AuditSeverity.critical:
        return Colors.red.shade900;
    }
  }
}

/// Audit log viewer screen.
class AuditLogViewerScreen extends ConsumerStatefulWidget {
  const AuditLogViewerScreen({super.key});

  @override
  ConsumerState<AuditLogViewerScreen> createState() =>
      _AuditLogViewerScreenState();
}

class _AuditLogViewerScreenState extends ConsumerState<AuditLogViewerScreen> {
  AuditEventType? _selectedType;
  AuditSeverity? _selectedSeverity;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportLogs,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_hasActiveFilters) _buildActiveFilters(),

          // Log list
          Expanded(
            child: logsAsync.when(
              data: (logs) => _buildLogList(_filterLogs(logs)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load audit logs: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(auditLogsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedType != null || _selectedSeverity != null || _dateRange != null;

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedType != null)
            FilterChip(
              label: Text(_selectedType!.name),
              onDeleted: () => setState(() => _selectedType = null),
              onSelected: (_) {},
            ),
          if (_selectedSeverity != null)
            FilterChip(
              label: Text(_selectedSeverity!.name),
              onDeleted: () => setState(() => _selectedSeverity = null),
              onSelected: (_) {},
            ),
          if (_dateRange != null)
            FilterChip(
              label: Text(
                '${DateFormat.MMMd().format(_dateRange!.start)} - ${DateFormat.MMMd().format(_dateRange!.end)}',
              ),
              onDeleted: () => setState(() => _dateRange = null),
              onSelected: (_) {},
            ),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear all'),
            ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<AuditLogEntry> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No audit logs found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(auditLogsProvider.future),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _AuditLogTile(
            entry: log,
            onTap: () => _showLogDetails(log),
          );
        },
      ),
    );
  }

  List<AuditLogEntry> _filterLogs(List<AuditLogEntry> logs) {
    return logs.where((log) {
      if (_selectedType != null && log.type != _selectedType) {
        return false;
      }
      if (_selectedSeverity != null && log.severity != _selectedSeverity) {
        return false;
      }
      if (_dateRange != null) {
        if (log.timestamp.isBefore(_dateRange!.start) ||
            log.timestamp.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet(
        selectedType: _selectedType,
        selectedSeverity: _selectedSeverity,
        dateRange: _dateRange,
        onApply: (type, severity, range) {
          setState(() {
            _selectedType = type;
            _selectedSeverity = severity;
            _dateRange = range;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedSeverity = null;
      _dateRange = null;
    });
  }

  void _showLogDetails(AuditLogEntry log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LogDetailsSheet(entry: log),
    );
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}

/// Single audit log tile.
class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({
    required this.entry,
    required this.onTap,
  });

  final AuditLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.MMMd();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: entry.severityColor(context).withValues(alpha: 0.2),
        child: Icon(
          entry.icon,
          color: entry.severityColor(context),
          size: 20,
        ),
      ),
      title: Text(
        entry.action,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${dateFormat.format(entry.timestamp)} at ${timeFormat.format(entry.timestamp)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: _buildSeverityIndicator(context),
      onTap: onTap,
    );
  }

  Widget _buildSeverityIndicator(BuildContext context) {
    if (entry.severity == AuditSeverity.info) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: entry.severityColor(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        entry.severity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: entry.severityColor(context),
        ),
      ),
    );
  }
}

/// Filter sheet for audit logs.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedType,
    required this.selectedSeverity,
    required this.dateRange,
    required this.onApply,
  });

  final AuditEventType? selectedType;
  final AuditSeverity? selectedSeverity;
  final DateTimeRange? dateRange;
  final void Function(
    AuditEventType? type,
    AuditSeverity? severity,
    DateTimeRange? range,
  ) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AuditEventType? _type;
  late AuditSeverity? _severity;
  late DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _severity = widget.selectedSeverity;
    _range = widget.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Audit Logs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Event type
          Text('Event Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final type in AuditEventType.values)
                FilterChip(
                  label: Text(type.name),
                  selected: _type == type,
                  onSelected: (selected) {
                    setState(() => _type = selected ? type : null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Severity
          Text('Severity', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final severity in AuditSeverity.values)
                FilterChip(
                  label: Text(severity.name),
                  selected: _severity == severity,
                  onSelected: (selected) {
                    setState(() => _severity = selected ? severity : null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_type, _severity, _range),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Details sheet for a single audit log entry.
class _LogDetailsSheet extends StatelessWidget {
  const _LogDetailsSheet({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jms();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(entry.icon, color: entry.severityColor(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.action,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          _DetailRow(
            label: 'Date',
            value: dateFormat.format(entry.timestamp),
          ),
          _DetailRow(
            label: 'Time',
            value: timeFormat.format(entry.timestamp),
          ),
          _DetailRow(
            label: 'Type',
            value: entry.type.name,
          ),
          _DetailRow(
            label: 'Severity',
            value: entry.severity.name.toUpperCase(),
            valueColor: entry.severityColor(context),
          ),
          if (entry.details != null)
            _DetailRow(
              label: 'Details',
              value: entry.details!,
            ),
          if (entry.deviceInfo != null)
            _DetailRow(
              label: 'Device',
              value: entry.deviceInfo!,
            ),
          if (entry.ipAddress != null)
            _DetailRow(
              label: 'IP Address',
              value: entry.ipAddress!,
            ),
          _DetailRow(
            label: 'Event ID',
            value: entry.id,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
