import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Standardized data table wrapper that applies design tokens and supports
/// horizontal scrolling, optional header/footer, and dense layout.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.header,
    this.footer,
    this.columnSpacing,
    this.horizontalMargin,
    this.showCheckboxColumn = true,
    this.dataRowMinHeight = 48,
    this.dataRowMaxHeight = 64,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? header;
  final Widget? footer;
  final double? columnSpacing;
  final double? horizontalMargin;
  final bool showCheckboxColumn;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      columns: columns,
      rows: rows,
      columnSpacing: columnSpacing ?? AppSpacing.lg,
      horizontalMargin: horizontalMargin ?? AppSpacing.md,
      showCheckboxColumn: showCheckboxColumn,
      dataRowMinHeight: dataRowMinHeight,
      dataRowMaxHeight: dataRowMaxHeight,
      dividerThickness: 1,
      headingRowHeight: 52,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: header,
            ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.card),
              topRight: Radius.circular(AppRadius.card),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
