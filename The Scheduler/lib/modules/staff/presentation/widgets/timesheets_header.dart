import 'package:flutter/material.dart';

import '../../../../core/services/payroll_export_service.dart';
import 'period_selector.dart';

/// Header widget for timesheets page with search and export options.
class TimesheetsHeader extends StatelessWidget {
  const TimesheetsHeader({
    super.key,
    required this.searchController,
    required this.isExporting,
    required this.onExportCSV,
    required this.onExportPayroll,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final bool isExporting;
  final VoidCallback onExportCSV;
  final ValueChanged<PayrollFormat> onExportPayroll;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with period selector and export
          Row(
            children: [
              Text(
                'Timesheets',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: PeriodSelector()),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                enabled: !isExporting,
                tooltip: 'Export options',
                onSelected: (value) {
                  if (value == 'csv') {
                    onExportCSV();
                  } else if (value == 'generic') {
                    onExportPayroll(PayrollFormat.genericCSV);
                  } else if (value == 'quickbooks') {
                    onExportPayroll(PayrollFormat.quickBooks);
                  } else if (value == 'adp') {
                    onExportPayroll(PayrollFormat.adp);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('Export CSV'),
                      subtitle: Text('Detailed timesheet data'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Payroll Exports',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'generic',
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Generic Payroll CSV'),
                      subtitle: Text('Universal format'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'quickbooks',
                    child: ListTile(
                      leading: Icon(Icons.account_balance),
                      title: Text('QuickBooks'),
                      subtitle: Text('IIF format'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'adp',
                    child: ListTile(
                      leading: Icon(Icons.business),
                      title: Text('ADP'),
                      subtitle: Text('Workforce Now format'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: FilledButton.tonalIcon(
                  onPressed: null, // Handled by PopupMenuButton
                  icon: isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Export'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          SizedBox(
            width: 300,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}
