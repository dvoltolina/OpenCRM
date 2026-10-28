// Reusable animation utilities and micro-interactions
// Agent 8: Mobile & UI Polish
// Part of animation system

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'accessibility_helpers.dart';

// Re-export flutter_animate so consuming files get the .ms/.seconds extensions
export 'package:flutter_animate/flutter_animate.dart' show NumDurationExtensions;

/// Extension on Widget to add common animations easily
extension AnimationExtensions on Widget {
  /// Fade in animation
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: curve);
  }

  /// Slide in from bottom (for dialogs, sheets)
  Widget slideInFromBottom({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Offset offset = const Offset(0, 0.2),
  }) {
    return animate(delay: delay)
        .slideY(begin: offset.dy, duration: duration, curve: Curves.easeOut);
  }

  /// Slide in from right (for list items)
  Widget slideInFromRight({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return animate(delay: delay)
        .slideX(begin: 0.2, duration: duration, curve: Curves.easeOut);
  }

  /// Scale animation (for buttons, icons)
  Widget scaleIn({
    Duration duration = const Duration(milliseconds: 200),
    Duration delay = Duration.zero,
  }) {
    return animate(delay: delay)
        .scale(begin: const Offset(0.8, 0.8), duration: duration);
  }

  /// Shimmer effect
  Widget shimmer({
    Duration duration = const Duration(milliseconds: 1500),
    Color? color,
  }) {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: duration, color: color);
  }

  /// Shake animation (for errors)
  Widget shake({
    Duration duration = const Duration(milliseconds: 500),
    double offset = 10,
  }) {
    return animate()
        .shake(duration: duration, hz: 4, offset: Offset(offset, 0));
  }

  /// Success checkmark animation
  Widget successScale() {
    return animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1.2, 1.2),
          duration: const Duration(milliseconds: 200),
        )
        .then()
        .scale(
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 100),
        );
  }
}

/// Animated page transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.right,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.up:
                begin = const Offset(0, 1);
                break;
              case AxisDirection.down:
                begin = const Offset(0, -1);
                break;
              case AxisDirection.left:
                begin = const Offset(1, 0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1, 0);
                break;
            }

            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

  final Widget page;
  final AxisDirection direction;
  final Duration duration;
}

/// Fade page transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );

  final Widget page;
  final Duration duration;
}

/// Scale and fade page transition (for modals)
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 250),
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              alignment: alignment,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Alignment alignment;
}

/// Navigation helper extension for easier page transitions
extension NavigationExtensions on BuildContext {
  /// Navigate with slide transition (default: slide from right)
  Future<T?> pushSlide<T>(
    Widget page, {
    AxisDirection direction = AxisDirection.left,
    Duration? duration,
  }) {
    return Navigator.of(this).push<T>(
      SlidePageRoute<T>(
        page: page,
        direction: direction,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate with fade transition
  Future<T?> pushFade<T>(
    Widget page, {
    Duration? duration,
  }) {
    return Navigator.of(this).push<T>(
      FadePageRoute<T>(
        page: page,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate with scale transition (for modals)
  Future<T?> pushScale<T>(
    Widget page, {
    Duration? duration,
    Alignment alignment = Alignment.center,
  }) {
    return Navigator.of(this).push<T>(
      ScalePageRoute<T>(
        page: page,
        duration: duration ?? const Duration(milliseconds: 250),
        alignment: alignment,
      ),
    );
  }

  /// Navigate and replace with slide transition
  Future<T?> pushReplacementSlide<T, TO>(
    Widget page, {
    AxisDirection direction = AxisDirection.left,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      SlidePageRoute<T>(page: page, direction: direction),
      result: result,
    );
  }

  /// Navigate and remove until with slide transition
  Future<T?> pushAndRemoveUntilSlide<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate, {
    AxisDirection direction = AxisDirection.left,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      SlidePageRoute<T>(page: page, direction: direction),
      predicate,
    );
  }

  /// Pop with announcement for accessibility
  void popWithAnnouncement(String announcement) {
    // Import needed: import '../../ui/accessibility_helpers.dart';
    ScreenReaderAnnouncements.announceNavigation(this, announcement);
    Navigator.of(this).pop();
  }
}

/// Animated button with tap feedback
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).primaryColor,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animated list item with staggered animation
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = 50,
  });

  final int index;
  final Widget child;
  final int baseDelay;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: Duration(milliseconds: baseDelay * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

/// Loading indicator with fade
class AnimatedLoadingIndicator extends StatelessWidget {
  const AnimatedLoadingIndicator({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ).fadeIn(),
    );
  }
}

/// Success feedback widget
class SuccessFeedback extends StatelessWidget {
  const SuccessFeedback({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const successColor = Color(0xFF10B981); // AppColors.success

    return Card(
      color: successColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: successColor, size: 32).successScale(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: successColor,
                    ),
              ),
            ),
          ],
        ).fadeIn().slideInFromBottom(),
      ),
    );
  }
}

/// Error feedback widget
class ErrorFeedback extends StatelessWidget {
  const ErrorFeedback({
    super.key,
    required this.message,
    this.icon = Icons.error,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.error, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
              ),
            ),
          ],
        ),
      ).shake().fadeIn(),
    );
  }
}
