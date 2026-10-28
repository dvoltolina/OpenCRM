import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Represents the current state of the time clock for a staff member.
///
/// This is a UI-friendly model derived from the active time entry.
/// It provides convenient properties for rendering clock state.
@immutable
class ClockState {
  const ClockState({
    required this.isClockedIn,
    required this.isOnBreak,
    this.clockInTime,
    this.currentBreakStart,
    this.currentBreakType,
    this.activeEntryId,
    this.totalBreakMinutes = 0,
  });

  /// Creates a ClockState indicating not clocked in.
  const ClockState.notClockedIn()
      : isClockedIn = false,
        isOnBreak = false,
        clockInTime = null,
        currentBreakStart = null,
        currentBreakType = null,
        activeEntryId = null,
        totalBreakMinutes = 0;

  /// Whether the staff member is currently clocked in.
  final bool isClockedIn;

  /// Whether the staff member is currently on break.
  final bool isOnBreak;

  /// When the staff member clocked in (null if not clocked in).
  final DateTime? clockInTime;

  /// When the current break started (null if not on break).
  final DateTime? currentBreakStart;

  /// Type of the current break ('meal' or 'rest').
  final String? currentBreakType;

  /// ID of the active time entry (null if not clocked in).
  final String? activeEntryId;

  /// Total break minutes taken so far (excluding current break).
  final int totalBreakMinutes;

  /// Creates a ClockState from a time entry database row.
  ///
  /// The [entry] parameter should be a TimeEntriesTableData object.
  /// Returns [ClockState.notClockedIn] if entry is null.
  factory ClockState.fromEntry(dynamic entry) {
    if (entry == null) {
      return const ClockState.notClockedIn();
    }

    // Parse breaks from JSON
    List<Map<String, dynamic>> breaks = [];
    try {
      final breaksJson = entry.breaksJson as String? ?? '[]';
      breaks = (jsonDecode(breaksJson) as List)
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ClockState: Failed to parse breaks JSON: $e');
    }

    // Check if currently on break (last break has no endTime)
    bool isOnBreak = false;
    DateTime? currentBreakStart;
    String? currentBreakType;

    if (breaks.isNotEmpty) {
      final lastBreak = breaks.last;
      if (lastBreak['endTime'] == null) {
        isOnBreak = true;
        currentBreakStart = DateTime.tryParse(lastBreak['startTime'] as String? ?? '');
        currentBreakType = lastBreak['type'] as String?;
      }
    }

    // Calculate total break minutes (completed breaks only)
    int totalBreakMinutes = 0;
    for (final br in breaks) {
      if (br['endTime'] != null) {
        final start = DateTime.tryParse(br['startTime'] as String? ?? '');
        final end = DateTime.tryParse(br['endTime'] as String? ?? '');
        if (start != null && end != null) {
          totalBreakMinutes += end.difference(start).inMinutes;
        }
      }
    }

    return ClockState(
      isClockedIn: true,
      isOnBreak: isOnBreak,
      clockInTime: entry.clockInTime as DateTime?,
      currentBreakStart: currentBreakStart,
      currentBreakType: currentBreakType,
      activeEntryId: entry.id as String?,
      totalBreakMinutes: totalBreakMinutes,
    );
  }

  /// Duration since clock-in (or zero if not clocked in).
  Duration get elapsedDuration {
    if (clockInTime == null) return Duration.zero;
    return DateTime.now().difference(clockInTime!);
  }

  /// Duration of current break (or zero if not on break).
  Duration get currentBreakDuration {
    if (currentBreakStart == null) return Duration.zero;
    return DateTime.now().difference(currentBreakStart!);
  }

  /// Elapsed hours as a decimal (e.g., 2.5 hours).
  double get elapsedHours => elapsedDuration.inMinutes / 60.0;

  /// Worked duration (elapsed minus all breaks).
  Duration get workedDuration {
    if (clockInTime == null) return Duration.zero;

    final totalElapsed = elapsedDuration;
    final breaksDuration = Duration(minutes: totalBreakMinutes) +
        (isOnBreak ? currentBreakDuration : Duration.zero);

    return totalElapsed - breaksDuration;
  }

  /// Worked hours as a decimal.
  double get workedHours => workedDuration.inMinutes / 60.0;

  /// Formats elapsed time as HH:MM:SS.
  String get elapsedFormatted => _formatDuration(elapsedDuration);

  /// Formats worked time as HH:MM:SS.
  String get workedFormatted => _formatDuration(workedDuration);

  /// Formats current break time as HH:MM:SS.
  String get breakFormatted => _formatDuration(currentBreakDuration);

  /// Helper to format Duration as HH:MM:SS.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockState &&
          runtimeType == other.runtimeType &&
          isClockedIn == other.isClockedIn &&
          isOnBreak == other.isOnBreak &&
          clockInTime == other.clockInTime &&
          currentBreakStart == other.currentBreakStart &&
          currentBreakType == other.currentBreakType &&
          activeEntryId == other.activeEntryId &&
          totalBreakMinutes == other.totalBreakMinutes;

  @override
  int get hashCode =>
      Object.hash(
        isClockedIn,
        isOnBreak,
        clockInTime,
        currentBreakStart,
        currentBreakType,
        activeEntryId,
        totalBreakMinutes,
      );

  @override
  String toString() =>
      'ClockState(clocked=${isClockedIn ? 'in' : 'out'}, '
      'break=$isOnBreak, entry=$activeEntryId)';
}

/// Break types supported by the time clock.
enum BreakType {
  /// Meal break (typically 30+ minutes).
  meal,

  /// Rest break (typically 10-15 minutes).
  rest,
}

/// Extension to convert BreakType to string.
extension BreakTypeExtension on BreakType {
  String get value {
    switch (this) {
      case BreakType.meal:
        return 'meal';
      case BreakType.rest:
        return 'rest';
    }
  }

  String get displayName {
    switch (this) {
      case BreakType.meal:
        return 'Meal Break';
      case BreakType.rest:
        return 'Rest Break';
    }
  }
}

/// Helper to parse BreakType from string.
BreakType? breakTypeFromString(String? value) {
  switch (value) {
    case 'meal':
      return BreakType.meal;
    case 'rest':
      return BreakType.rest;
    default:
      return null;
  }
}
