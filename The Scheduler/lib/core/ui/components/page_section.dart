// PageSection - Consistent section containers
// Created by Agent P0 (2025-11-28)
// Provides standardized section layout with headers

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'section_header.dart';
import 'spacing_helpers.dart';

/// Page section with optional header and consistent spacing
///
/// Creates visually distinct sections within a page with:
/// - Optional section header with title/subtitle
/// - Optional action button
/// - Consistent vertical spacing
/// - Left-aligned content
///
/// Usage:
/// ```dart
/// PageSection(
///   title: 'Upcoming Appointments',
///   subtitle: 'Next 7 days',
///   action: TextButton(
///     onPressed: _seeAll,
///     child: Text('See All'),
///   ),
///   child: AppointmentsList(),
/// )
/// ```
class PageSection extends StatelessWidget {
  const PageSection({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.showDivider = false,
    this.padding,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            SectionHeader(
              title: title!,
              subtitle: subtitle,
              actionLabel: action != null ? '' : null,
              onAction: action != null ? () {} : null,
              padding: EdgeInsets.zero,
            ),
            if (action != null)
              Align(
                alignment: Alignment.centerRight,
                child: action!,
              ),
            VSpace.md,
          ],
          child,
          if (showDivider) ...[
            VSpace.lg,
            const Divider(),
          ],
        ],
      ),
    );
  }
}

/// Card-based section with elevation and padding
///
/// Wraps content in a card for visual separation
class CardSection extends StatelessWidget {
  const CardSection({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null;

    return Card(
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          VSpace.xxs,
                          Text(
                            subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    HSpace.sm,
                    action!,
                  ],
                ],
              ),
              VSpace.md,
              const Divider(),
              VSpace.md,
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Collapsible section with expansion panel
///
/// Section that can be expanded/collapsed
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(widget.title),
        subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
        initiallyExpanded: widget.initiallyExpanded,
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
