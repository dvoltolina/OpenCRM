import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

typedef AppKanbanItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isDragging,
);

typedef AppKanbanItemMoved<T> = void Function(
  T item,
  String fromColumnId,
  String toColumnId,
  int toIndex,
);

class AppKanbanColumn<T> {
  const AppKanbanColumn({
    required this.id,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.trailing,
  });

  final String id;
  final String title;
  final List<T> items;
  final AppKanbanItemBuilder<T> itemBuilder;
  final Widget? trailing;
}

class _KanbanPayload<T> {
  const _KanbanPayload({
    required this.item,
    required this.fromColumnId,
    required this.fromIndex,
  });

  final T item;
  final String fromColumnId;
  final int fromIndex;
}

/// Opinionated Kanban board with drag-and-drop and tokenized styling.
class AppKanbanBoard<T> extends StatelessWidget {
  const AppKanbanBoard({
    super.key,
    required this.columns,
    this.onItemMoved,
    this.crossAxisSpacing = AppSpacing.md,
    this.columnWidth = 320,
  });

  final List<AppKanbanColumn<T>> columns;
  final AppKanbanItemMoved<T>? onItemMoved;
  final double crossAxisSpacing;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in columns) ...[
            _KanbanColumn<T>(
              column: column,
              onItemMoved: onItemMoved,
              width: columnWidth,
            ),
            SizedBox(width: crossAxisSpacing),
          ],
        ],
      ),
    );
  }
}

class _KanbanColumn<T> extends StatelessWidget {
  const _KanbanColumn({
    required this.column,
    required this.onItemMoved,
    required this.width,
  });

  final AppKanbanColumn<T> column;
  final AppKanbanItemMoved<T>? onItemMoved;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              column.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (column.trailing != null) column.trailing!,
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return DragTarget<_KanbanPayload<T>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final data = details.data;
        onItemMoved?.call(
          data.item,
          data.fromColumnId,
          column.id,
          column.items.length,
        );
      },
      builder: (context, candidate, rejected) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadius.card),
              bottomRight: Radius.circular(AppRadius.card),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < column.items.length; i++) ...[
                _DraggableCard<T>(
                  item: column.items[i],
                  columnId: column.id,
                  index: i,
                  builder: column.itemBuilder,
                  onItemMoved: onItemMoved,
                ),
                if (i != column.items.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
              if (candidate.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DropPlaceholder(isActive: true),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DraggableCard<T> extends StatelessWidget {
  const _DraggableCard({
    required this.item,
    required this.columnId,
    required this.index,
    required this.builder,
    required this.onItemMoved,
  });

  final T item;
  final String columnId;
  final int index;
  final AppKanbanItemBuilder<T> builder;
  final AppKanbanItemMoved<T>? onItemMoved;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<_KanbanPayload<T>>(
      data: _KanbanPayload(item: item, fromColumnId: columnId, fromIndex: index),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: const [AppShadows.modal],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: builder(context, item, true),
            ),
          ),
        ),
      ),
      childWhenDragging: const _DropPlaceholder(),
      feedbackOffset: const Offset(0, -8),
      child: DragTarget<_KanbanPayload<T>>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          final data = details.data;
          onItemMoved?.call(
            data.item,
            data.fromColumnId,
            columnId,
            index,
          );
        },
        builder: (context, candidate, rejected) {
          final isActive = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: AppDuration.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              boxShadow: const [AppShadows.card],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: builder(context, item, false),
            ),
          );
        },
      ),
    );
  }
}

class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder({this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        isActive ? 'Release to drop' : 'Drag to move',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
