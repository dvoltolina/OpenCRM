// Reusable state widgets for consistent UI patterns
// Provides standardized empty, error, and loading states across the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accessibility_helpers.dart';
import 'platform_helpers.dart';
import 'responsive_helpers.dart';

// ============================================================================
// EMPTY STATE WIDGET
// ============================================================================

/// Standardized empty state widget with icon, title, subtitle, and optional action
///
/// Usage:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inbox,
///   title: 'No appointments',
///   subtitle: 'Your appointments will appear here',
///   actionLabel: 'Create Appointment',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 80.0,
    this.iconColor,
    this.padding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectivePadding = padding ?? responsivePadding(context, mobile: 32);

    return SemanticWrapper(
      label: 'Empty state: $title',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: effectivePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: responsiveValue(
                    context,
                    mobile: iconSize * 0.6, // Reduced for better fit
                    tablet: iconSize * 0.7,
                    desktop: iconSize * 0.8,
                  ),
                  color: iconColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                SizedBox(
                  height: responsiveValue(context, mobile: 12.0, tablet: 16.0),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TouchTargets.ensure(
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add),
                        label: Text(actionLabel!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact empty state for use within cards or smaller spaces
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 32,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR STATE WIDGET
// ============================================================================

/// Standardized error state widget with icon, message, details, and actions
///
/// Usage:
/// ```dart
/// ErrorStateWidget(
///   error: exception,
///   message: 'Failed to load appointments',
///   onRetry: () => _loadData(),
///   showContactSupport: true,
/// )
/// ```
class ErrorStateWidget extends StatefulWidget {
  const ErrorStateWidget({
    super.key,
    required this.error,
    this.message,
    this.onRetry,
    this.showContactSupport = true,
    this.showDetails = true,
    this.padding,
    this.icon,
  });

  final Object error;
  final String? message;
  final VoidCallback? onRetry;
  final bool showContactSupport;
  final bool showDetails;
  final EdgeInsets? padding;
  final IconData? icon;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget> {
  bool _showErrorDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectivePadding =
        widget.padding ?? responsivePadding(context, mobile: 24);

    return SemanticWrapper(
      label: 'Error state: ${widget.message ?? "An error occurred"}',
      child: Center(
        child: Padding(
          padding: effectivePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon ?? Icons.error_outline,
                size: responsiveValue(context, mobile: 64.0, tablet: 72.0),
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                widget.message ?? 'Something went wrong',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an error while loading this content.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.showDetails) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showErrorDetails = !_showErrorDetails);
                    if (_showErrorDetails) {
                      ScreenReaderAnnouncements.announceAction(
                        context,
                        'Error details shown',
                      );
                    }
                  },
                  icon: Icon(
                    _showErrorDetails
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  label: Text(
                    _showErrorDetails ? 'Hide Details' : 'Show Details',
                  ),
                ),
                if (_showErrorDetails) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SelectableText(
                      widget.error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.onRetry != null)
                    TouchTargets.ensure(
                      child: FilledButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ),
                  if (widget.showContactSupport)
                    TextButton.icon(
                      onPressed: () => _showContactSupportDialog(context),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'If this problem persists, please contact support with:\n\n'
          '• What you were trying to do\n'
          '• The error details (if available)\n'
          '• When the error occurred',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Compact error display for inline use
class CompactErrorState extends StatelessWidget {
  const CompactErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              color: colorScheme.onErrorContainer,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING STATE WIDGET
// ============================================================================

/// Standardized loading state widget with spinner and optional message
///
/// Usage:
/// ```dart
/// LoadingStateWidget(
///   message: 'Loading appointments...',
/// )
/// ```
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    super.key,
    this.message,
    this.padding,
    this.size = 48.0,
  });

  final String? message;
  final EdgeInsets? padding;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding =
        padding ?? responsivePadding(context, mobile: 24);

    return SemanticWrapper(
      label: 'Loading: ${message ?? "content"}',
      child: Center(
        child: Padding(
          padding: effectivePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline loading indicator for smaller spaces
class InlineLoadingIndicator extends StatelessWidget {
  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size = 16.0,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// BUILDER HELPER FOR ASYNC DATA
// ============================================================================

/// Builder widget that handles AsyncValue states with consistent UI
///
/// Usage with Riverpod:
/// ```dart
/// final dataAsync = ref.watch(dataProvider);
/// return AsyncStateBuilder<MyData>(
///   asyncValue: dataAsync,
///   builder: (context, data) => MyWidget(data: data),
///   errorMessage: 'Failed to load data',
///   emptyMessage: 'No data available',
///   checkEmpty: (data) => data.isEmpty,
/// );
/// ```
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.loadingMessage,
    this.errorMessage,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.checkEmpty,
    this.onRetry,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;
  final String? errorMessage;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final bool Function(T data)? checkEmpty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        // Check if data is considered empty
        final isEmpty = checkEmpty?.call(data) ?? false;

        if (isEmpty && emptyMessage != null) {
          return EmptyStateWidget(
            icon: emptyIcon ?? Icons.inbox,
            title: emptyMessage!,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }

        return builder(context, data);
      },
      loading: () => LoadingStateWidget(message: loadingMessage),
      error: (error, stackTrace) => ErrorStateWidget(
        error: error,
        message: errorMessage,
        onRetry: onRetry,
      ),
    );
  }
}
