import 'dart:async';

import 'package:flutter/material.dart';

/// A large, prominent elapsed time display that updates every second.
///
/// Shows time in HH:MM:SS format using a monospace font for readability.
/// Automatically disposes the timer when unmounted.
class ElapsedTimeCounter extends StatefulWidget {
  const ElapsedTimeCounter({
    super.key,
    required this.since,
    this.style,
    this.prefix,
    this.onBreak = false,
  });

  /// The start time to calculate elapsed duration from.
  final DateTime since;

  /// Optional text style override.
  final TextStyle? style;

  /// Optional prefix text (e.g., "On Break: ").
  final String? prefix;

  /// Whether currently on break (changes color).
  final bool onBreak;

  @override
  State<ElapsedTimeCounter> createState() => _ElapsedTimeCounterState();
}

class _ElapsedTimeCounterState extends State<ElapsedTimeCounter> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _startTimer();
  }

  @override
  void didUpdateWidget(ElapsedTimeCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.since != widget.since) {
      _updateElapsed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.since);
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.displayMedium?.copyWith(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
      color: widget.onBreak
          ? theme.colorScheme.tertiary
          : theme.colorScheme.primary,
    );

    final formattedTime = _formatDuration(_elapsed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefix != null)
          Text(
            widget.prefix!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          formattedTime,
          style: widget.style ?? defaultStyle,
          semanticsLabel: 'Elapsed time: $formattedTime',
        ),
      ],
    );
  }
}

/// A compact elapsed time display for use in cards and lists.
class CompactElapsedTime extends StatefulWidget {
  const CompactElapsedTime({
    super.key,
    required this.since,
    this.style,
  });

  final DateTime since;
  final TextStyle? style;

  @override
  State<CompactElapsedTime> createState() => _CompactElapsedTimeState();
}

class _CompactElapsedTimeState extends State<CompactElapsedTime> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.since);
    });
  }

  String _formatCompact(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatCompact(_elapsed),
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
