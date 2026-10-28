import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/payroll_export_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/timesheet_summary.dart';
import '../providers/timesheet_providers.dart';
import 'timesheet_detail_page.dart';
import 'widgets/timesheet_summary_bar.dart';
import 'widgets/timesheets_filter_bar.dart';
import 'widgets/timesheets_header.dart';
import 'widgets/timesheets_list.dart';

/// Admin page for managing staff timesheets.
///
/// Displays timesheet summaries for all staff in the selected pay period,
/// with filtering, search, and export capabilities.
class TimesheetsPage extends ConsumerStatefulWidget {
  const TimesheetsPage({super.key});

  @override
  ConsumerState<TimesheetsPage> createState() => _TimesheetsPageState();
}

class _TimesheetsPageState extends ConsumerState<TimesheetsPage> {
  final _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContext = ref.watch(currentSecurityContextProvider);

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header with period selector and actions
          TimesheetsHeader(
            searchController: _searchController,
            isExporting: _isExporting,
            onExportCSV: () => _exportTimesheets(securityContext),
            onExportPayroll: (format) => _exportPayroll(securityContext, format),
            onSearchChanged: (query) {
              ref.read(timesheetSearchQueryProvider.notifier).state = query;
            },
          ),

          // Filter chips
          const TimesheetsFilterBar(),

          // Timesheet list
          Expanded(
            child: TimesheetsList(
              context: securityContext,
              onTimesheetTap: (timesheet) => _openDetail(timesheet),
              onApprove: (timesheet) => _approveTimesheet(securityContext, timesheet),
            ),
          ),

          // Summary bar at bottom
          TimesheetSummaryBar(context: securityContext),
        ],
      ),
    );
  }

  void _openDetail(TimesheetSummary timesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimesheetDetailPage(
          staffId: timesheet.staffId,
          staffName: timesheet.staffName,
        ),
      ),
    );
  }

  Future<void> _approveTimesheet(
    SecurityContext context,
    TimesheetSummary timesheet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Timesheet'),
        content: Text(
          'Approve all ${timesheet.pendingEntriesCount} pending entries for ${timesheet.staffName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Implement bulk approval via TimeEntryRepository
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text('Approved timesheet for ${timesheet.staffName}'),
        backgroundColor: Colors.green,
      ),
    );

    // Refresh the list
    ref.invalidate(timesheetSummariesProvider);
  }

  Future<void> _exportTimesheets(SecurityContext context) async {
    setState(() => _isExporting = true);

    try {
      final service = ref.read(timesheetServiceProvider);
      final timesheets = await ref.read(timesheetSummariesProvider(context).future);

      final csv = service.exportToCSV(
        timesheets: timesheets,
        includeEntryDetails: true,
      );

      if (!mounted) return;
      await _showExportDialog('Timesheet CSV Export', csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportPayroll(SecurityContext context, PayrollFormat format) async {
    setState(() => _isExporting = true);

    try {
      final timesheets = await ref.read(timesheetSummariesProvider(context).future);
      final periodStart = ref.read(selectedPayPeriodStartProvider);
      final periodEnd = ref.read(selectedPayPeriodEndProvider);

      final payrollService = PayrollExportService();
      final export = payrollService.exportTimesheets(
        timesheets: timesheets,
        format: format,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      if (!mounted) return;
      await _showExportDialog('${format.displayName} Export', export);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showExportDialog(String title, String content) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${content.split('\n').length} lines generated',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              VSpace.xs,
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: SelectableText(
                      content,
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
