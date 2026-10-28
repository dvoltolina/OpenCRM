// Loading skeleton widgets for smooth loading states
// Agent 8: Mobile & UI Polish
// Part of animation system

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper for loading states
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: baseColor ??
          (isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest),
      highlightColor: highlightColor ??
          (isDark ? colorScheme.surfaceContainer : colorScheme.surfaceContainerLow),
      child: child,
    );
  }
}

/// Skeleton for list item cards
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({
    super.key,
    this.hasAvatar = false,
    this.hasSubtitle = true,
    this.lineCount = 2,
  });

  final bool hasAvatar;
  final bool hasSubtitle;
  final int lineCount;

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAvatar) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: double.infinity * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                    for (var i = 0; i < lineCount; i++) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: double.infinity * (0.8 - i * 0.2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for calendar cells
class SkeletonCalendarCell extends StatelessWidget {
  const SkeletonCalendarCell({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: double.infinity * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for form fields
class SkeletonFormField extends StatelessWidget {
  const SkeletonFormField({
    super.key,
    this.hasLabel = true,
  });

  final bool hasLabel;

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLabel) ...[
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for chart widgets
class SkeletonChart extends StatelessWidget {
  const SkeletonChart({
    super.key,
    this.height = 200,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton for grid cards (dashboard KPIs, etc.)
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.height = 100,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: Card(
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to build list of skeleton items
Widget buildSkeletonList({
  int count = 5,
  bool hasAvatar = false,
  bool hasSubtitle = true,
  int lineCount = 2,
}) {
  return ListView.builder(
    itemCount: count,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemBuilder: (context, index) => SkeletonListItem(
      hasAvatar: hasAvatar,
      hasSubtitle: hasSubtitle,
      lineCount: lineCount,
    ),
  );
}

/// Helper to build grid of skeleton cards
Widget buildSkeletonGrid({
  int count = 4,
  int crossAxisCount = 2,
  double cardHeight = 100,
}) {
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
    ),
    itemCount: count,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemBuilder: (context, index) => SkeletonCard(height: cardHeight),
  );
}

