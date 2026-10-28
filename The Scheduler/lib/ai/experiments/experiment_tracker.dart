import 'dart:developer' as developer;

import '../../data/models/experiment.dart';
import '../../data/models/security_context.dart';
import 'experiment_service.dart';

/// Tracks experiment exposures and conversions for analytics.
///
/// Provides a simplified API for UI components to track when users
/// are exposed to experiment variants and when they convert.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class ExperimentTracker {
  ExperimentTracker({
    required ExperimentService experimentService,
  }) : _experimentService = experimentService;

  final ExperimentService _experimentService;

  // Track recent exposures to avoid duplicate logging
  final Map<String, Set<String>> _recentExposures = {};
  final Map<String, DateTime> _exposureTimestamps = {};
  static const _exposureDedupeWindow = Duration(minutes: 30);

  // ===== EXPOSURE TRACKING =====

  /// Track that a user was exposed to an experiment variant.
  ///
  /// Call this when showing AI-powered UI to the user. Returns the
  /// assigned variant config for configuring the UI.
  Future<ExposureResult> trackExposure({
    required SecurityContext context,
    required String experimentId,
    String? entityId,
    String? entityType,
  }) async {
    // Check for recent duplicate
    if (_isDuplicateExposure(context.userId, experimentId, entityId)) {
      developer.log(
        'Skipping duplicate exposure: $experimentId for ${context.userId}',
        name: 'ExperimentTracker',
      );

      // Return cached assignment
      final cached = await _experimentService.getVariantConfig(
        context: context,
        experimentId: experimentId,
        userId: context.userId,
        entityId: entityId,
      );

      return ExposureResult(
        tracked: false,
        isDuplicate: true,
        config: cached,
      );
    }

    // Get or assign variant
    final result = await _experimentService.getOrAssignVariant(
      context: context,
      experimentId: experimentId,
      userId: context.userId,
      entityId: entityId,
      entityType: entityType,
    );

    if (!result.isSuccess) {
      developer.log(
        'Failed to track exposure: ${result.error}',
        name: 'ExperimentTracker',
      );

      return ExposureResult(
        tracked: false,
        error: result.error,
      );
    }

    // Mark exposure
    _recordExposure(context.userId, experimentId, entityId);

    developer.log(
      'Tracked exposure: $experimentId -> ${result.variant?.id}',
      name: 'ExperimentTracker',
    );

    return ExposureResult(
      tracked: true,
      assignmentId: result.assignment?.id,
      variantId: result.variant?.id,
      variantName: result.variant?.name,
      isControl: result.variant?.isControl ?? false,
      config: result.config,
    );
  }

  /// Get variant configuration without tracking exposure.
  ///
  /// Use this for configuration checks that shouldn't be tracked.
  Future<Map<String, dynamic>?> peekVariantConfig({
    required SecurityContext context,
    required String experimentId,
    String? entityId,
  }) async {
    return _experimentService.getVariantConfig(
      context: context,
      experimentId: experimentId,
      userId: context.userId,
      entityId: entityId,
    );
  }

  /// Check if user is in treatment group for an experiment.
  Future<bool> isInTreatment({
    required SecurityContext context,
    required String experimentId,
    String? entityId,
  }) async {
    final config = await peekVariantConfig(
      context: context,
      experimentId: experimentId,
      entityId: entityId,
    );

    // If there's a config, check the assignment
    if (config != null) {
      final result = await _experimentService.getOrAssignVariant(
        context: context,
        experimentId: experimentId,
        userId: context.userId,
        entityId: entityId,
      );

      return result.variant != null && !result.variant!.isControl;
    }

    return false;
  }

  // ===== CONVERSION TRACKING =====

  /// Track a conversion event for a user in an experiment.
  ///
  /// Call this when the user takes a desired action (e.g., confirms
  /// a prediction was helpful).
  Future<bool> trackConversion({
    required SecurityContext context,
    required String assignmentId,
    String? conversionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _experimentService.recordConversion(
        context,
        assignmentId: assignmentId,
        metadata: {
          'conversionType': conversionType,
          ...?metadata,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      developer.log(
        'Tracked conversion: $assignmentId (type: $conversionType)',
        name: 'ExperimentTracker',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to track conversion: $e',
        name: 'ExperimentTracker',
        error: e,
      );
      return false;
    }
  }

  /// Track conversion by experiment ID (looks up assignment).
  Future<bool> trackConversionByExperiment({
    required SecurityContext context,
    required String experimentId,
    String? entityId,
    String? conversionType,
    Map<String, dynamic>? metadata,
  }) async {
    // Get assignment
    final result = await _experimentService.getOrAssignVariant(
      context: context,
      experimentId: experimentId,
      userId: context.userId,
      entityId: entityId,
    );

    if (!result.isSuccess || result.assignment == null) {
      developer.log(
        'No assignment found for conversion tracking',
        name: 'ExperimentTracker',
      );
      return false;
    }

    return trackConversion(
      context: context,
      assignmentId: result.assignment!.id,
      conversionType: conversionType,
      metadata: metadata,
    );
  }

  // ===== FEATURE FLAGS =====

  /// Get a feature flag value from an experiment.
  ///
  /// Returns the value from the user's assigned variant config,
  /// or the default value if not found.
  Future<T> getFeatureFlag<T>({
    required SecurityContext context,
    required String experimentId,
    required String flagKey,
    required T defaultValue,
    String? entityId,
  }) async {
    final config = await peekVariantConfig(
      context: context,
      experimentId: experimentId,
      entityId: entityId,
    );

    if (config == null || !config.containsKey(flagKey)) {
      return defaultValue;
    }

    final value = config[flagKey];
    if (value is T) {
      return value;
    }

    // Type conversion for common cases
    if (T == double && value is int) {
      return (value.toDouble()) as T;
    }

    if (T == int && value is double) {
      return (value.toInt()) as T;
    }

    return defaultValue;
  }

  /// Check if a boolean feature flag is enabled.
  Future<bool> isFeatureEnabled({
    required SecurityContext context,
    required String experimentId,
    required String flagKey,
    String? entityId,
    bool defaultValue = false,
  }) async {
    return getFeatureFlag<bool>(
      context: context,
      experimentId: experimentId,
      flagKey: flagKey,
      defaultValue: defaultValue,
      entityId: entityId,
    );
  }

  // ===== AUTO-TRACKING =====

  /// Create a tracked wrapper for experiment-controlled UI.
  ///
  /// Use this to automatically track exposure when building UI.
  Future<TrackedExperiment> trackAndGetConfig({
    required SecurityContext context,
    required String experimentId,
    String? entityId,
    String? entityType,
  }) async {
    final exposure = await trackExposure(
      context: context,
      experimentId: experimentId,
      entityId: entityId,
      entityType: entityType,
    );

    return TrackedExperiment(
      experimentId: experimentId,
      assignmentId: exposure.assignmentId,
      variantId: exposure.variantId,
      config: exposure.config ?? {},
      isControl: exposure.isControl,
      track: (conversionType, metadata) => trackConversion(
        context: context,
        assignmentId: exposure.assignmentId!,
        conversionType: conversionType,
        metadata: metadata,
      ),
    );
  }

  // ===== BATCH OPERATIONS =====

  /// Get all active experiments user is enrolled in.
  Future<List<ActiveEnrollment>> getActiveEnrollments(
    SecurityContext context,
  ) async {
    final experiments = await _experimentService.getActiveExperiments(context);
    final enrollments = <ActiveEnrollment>[];

    for (final experiment in experiments) {
      final result = await _experimentService.getOrAssignVariant(
        context: context,
        experimentId: experiment.id,
        userId: context.userId,
      );

      if (result.isSuccess && result.assignment != null) {
        enrollments.add(ActiveEnrollment(
          experimentId: experiment.id,
          experimentName: experiment.name,
          experimentType: experiment.type,
          variantId: result.variant!.id,
          variantName: result.variant!.name,
          isControl: result.variant!.isControl,
          assignedAt: result.assignment!.assignedAt,
        ));
      }
    }

    return enrollments;
  }

  // ===== HELPERS =====

  bool _isDuplicateExposure(String userId, String experimentId, String? entityId) {
    final key = _exposureKey(experimentId, entityId);
    final userExposures = _recentExposures[userId];

    if (userExposures == null) return false;

    // Clean up old exposures
    _cleanupExpiredExposures(userId);

    return userExposures.contains(key);
  }

  void _recordExposure(String userId, String experimentId, String? entityId) {
    final key = _exposureKey(experimentId, entityId);

    _recentExposures.putIfAbsent(userId, () => <String>{});
    _recentExposures[userId]!.add(key);
    _exposureTimestamps['$userId:$key'] = DateTime.now();
  }

  void _cleanupExpiredExposures(String userId) {
    final userExposures = _recentExposures[userId];
    if (userExposures == null) return;

    final now = DateTime.now();
    final toRemove = <String>[];

    for (final key in userExposures) {
      final timestamp = _exposureTimestamps['$userId:$key'];
      if (timestamp == null || now.difference(timestamp) > _exposureDedupeWindow) {
        toRemove.add(key);
        _exposureTimestamps.remove('$userId:$key');
      }
    }

    for (final key in toRemove) {
      userExposures.remove(key);
    }
  }

  String _exposureKey(String experimentId, String? entityId) {
    return entityId != null ? '$experimentId:$entityId' : experimentId;
  }

  /// Clear exposure cache for a user.
  void clearExposureCache(String userId) {
    final userExposures = _recentExposures[userId];
    if (userExposures != null) {
      for (final key in userExposures) {
        _exposureTimestamps.remove('$userId:$key');
      }
    }
    _recentExposures.remove(userId);
  }
}

/// Result of an exposure tracking operation.
class ExposureResult {
  const ExposureResult({
    required this.tracked,
    this.isDuplicate = false,
    this.assignmentId,
    this.variantId,
    this.variantName,
    this.isControl = false,
    this.config,
    this.error,
  });

  final bool tracked;
  final bool isDuplicate;
  final String? assignmentId;
  final String? variantId;
  final String? variantName;
  final bool isControl;
  final Map<String, dynamic>? config;
  final String? error;

  bool get isSuccess => error == null;
}

/// Wrapper for a tracked experiment with conversion callback.
class TrackedExperiment {
  const TrackedExperiment({
    required this.experimentId,
    required this.config,
    required this.track,
    this.assignmentId,
    this.variantId,
    this.isControl = false,
  });

  final String experimentId;
  final String? assignmentId;
  final String? variantId;
  final bool isControl;
  final Map<String, dynamic> config;
  final Future<bool> Function(String? conversionType, Map<String, dynamic>? metadata) track;

  T getConfig<T>(String key, T defaultValue) {
    final value = config[key];
    if (value is T) return value;
    return defaultValue;
  }

  Future<bool> trackConversion({
    String? conversionType,
    Map<String, dynamic>? metadata,
  }) {
    return track(conversionType, metadata);
  }
}

/// Information about a user's active experiment enrollment.
class ActiveEnrollment {
  const ActiveEnrollment({
    required this.experimentId,
    required this.experimentName,
    required this.experimentType,
    required this.variantId,
    required this.variantName,
    required this.isControl,
    required this.assignedAt,
  });

  final String experimentId;
  final String experimentName;
  final ExperimentType experimentType;
  final String variantId;
  final String variantName;
  final bool isControl;
  final DateTime assignedAt;
}
