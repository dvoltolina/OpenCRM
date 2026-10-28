import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../data/models/experiment.dart';

/// Assigns users to experiment variants using consistent hashing.
///
/// Ensures users always get the same variant for a given experiment,
/// even across sessions or devices. Uses deterministic hashing to
/// distribute traffic according to configured percentages.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class VariantAssigner {
  VariantAssigner({
    this.salt = 'scheduler_experiments',
  });

  /// Salt added to hash for additional randomization
  final String salt;

  /// Assign a user to a variant for an experiment.
  ///
  /// Uses consistent hashing based on userId + experimentId to ensure
  /// the same user always gets the same variant for a given experiment.
  ///
  /// Returns null if experiment is not active or has no valid variants.
  ExperimentVariant? assignVariant({
    required Experiment experiment,
    required String userId,
    String? entityId,
  }) {
    // Only assign for active experiments
    if (!experiment.status.isRunning) {
      return null;
    }

    // Validate traffic allocation
    if (!experiment.hasValidTrafficAllocation) {
      return null;
    }

    if (experiment.variants.isEmpty) {
      return null;
    }

    // Generate deterministic bucket (0-99)
    final bucket = _getBucket(
      experimentId: experiment.id,
      userId: userId,
      entityId: entityId,
    );

    // Assign to variant based on traffic allocation
    return _selectVariant(experiment.variants, bucket);
  }

  /// Get the variant a user would be assigned to without recording.
  ///
  /// Useful for preview or checking assignment before recording.
  ExperimentVariant? previewAssignment({
    required Experiment experiment,
    required String userId,
    String? entityId,
  }) {
    return assignVariant(
      experiment: experiment,
      userId: userId,
      entityId: entityId,
    );
  }

  /// Check if a user would be in the treatment group.
  bool isInTreatment({
    required Experiment experiment,
    required String userId,
    String? entityId,
  }) {
    final variant = assignVariant(
      experiment: experiment,
      userId: userId,
      entityId: entityId,
    );
    return variant != null && !variant.isControl;
  }

  /// Get the configuration for a user's assigned variant.
  Map<String, dynamic>? getVariantConfig({
    required Experiment experiment,
    required String userId,
    String? entityId,
  }) {
    final variant = assignVariant(
      experiment: experiment,
      userId: userId,
      entityId: entityId,
    );
    return variant?.config;
  }

  /// Calculate the bucket (0-99) for a user in an experiment.
  int _getBucket({
    required String experimentId,
    required String userId,
    String? entityId,
  }) {
    // Create consistent hash input
    final hashInput = entityId != null
        ? '$salt:$experimentId:$userId:$entityId'
        : '$salt:$experimentId:$userId';

    // Generate SHA-256 hash
    final bytes = utf8.encode(hashInput);
    final digest = sha256.convert(bytes);

    // Use first 4 bytes as integer and mod 100 for bucket
    final hashInt = digest.bytes[0] << 24 |
        digest.bytes[1] << 16 |
        digest.bytes[2] << 8 |
        digest.bytes[3];

    return hashInt.abs() % 100;
  }

  /// Select variant based on bucket and traffic allocation.
  ExperimentVariant? _selectVariant(
    List<ExperimentVariant> variants,
    int bucket,
  ) {
    int cumulativePercentage = 0;

    for (final variant in variants) {
      cumulativePercentage += variant.trafficPercentage;
      if (bucket < cumulativePercentage) {
        return variant;
      }
    }

    // Fallback to last variant (should not happen with valid allocation)
    return variants.isNotEmpty ? variants.last : null;
  }

  /// Calculate expected distribution for validation.
  Map<String, double> calculateExpectedDistribution(
    List<ExperimentVariant> variants,
  ) {
    final total =
        variants.fold<int>(0, (sum, v) => sum + v.trafficPercentage);
    return {
      for (final v in variants)
        v.id: total > 0 ? v.trafficPercentage / total : 0,
    };
  }

  /// Simulate assignment distribution for testing.
  ///
  /// Generates [sampleSize] random user IDs and checks distribution.
  Map<String, int> simulateDistribution({
    required Experiment experiment,
    int sampleSize = 10000,
  }) {
    final counts = <String, int>{};
    final random = Random();

    for (var i = 0; i < sampleSize; i++) {
      final testUserId = 'test_${random.nextInt(1000000)}';
      final variant = assignVariant(
        experiment: experiment,
        userId: testUserId,
      );

      if (variant != null) {
        counts[variant.id] = (counts[variant.id] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Validate that actual distribution matches expected within tolerance.
  ValidationResult validateDistribution({
    required Experiment experiment,
    required Map<String, int> actualCounts,
    double tolerancePercent = 2.0,
  }) {
    final totalAssignments = actualCounts.values.fold<int>(0, (a, b) => a + b);
    if (totalAssignments == 0) {
      return ValidationResult(
        isValid: false,
        message: 'No assignments to validate',
        deviations: {},
      );
    }

    final deviations = <String, double>{};
    bool isValid = true;
    final messages = <String>[];

    for (final variant in experiment.variants) {
      final actualCount = actualCounts[variant.id] ?? 0;
      final actualPercent = (actualCount / totalAssignments) * 100;
      final expectedPercent = variant.trafficPercentage.toDouble();
      final deviation = (actualPercent - expectedPercent).abs();

      deviations[variant.id] = deviation;

      if (deviation > tolerancePercent) {
        isValid = false;
        messages.add(
          '${variant.name}: expected ${expectedPercent.toStringAsFixed(1)}%, '
          'got ${actualPercent.toStringAsFixed(1)}% '
          '(deviation: ${deviation.toStringAsFixed(2)}%)',
        );
      }
    }

    return ValidationResult(
      isValid: isValid,
      message: isValid
          ? 'Distribution within tolerance'
          : 'Distribution deviations: ${messages.join('; ')}',
      deviations: deviations,
    );
  }
}

/// Result of distribution validation.
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.message,
    required this.deviations,
  });

  /// Whether distribution is within acceptable tolerance
  final bool isValid;

  /// Human-readable validation message
  final String message;

  /// Deviation from expected for each variant (percentage points)
  final Map<String, double> deviations;

  @override
  String toString() => 'ValidationResult(isValid: $isValid, message: $message)';
}

/// Extension for checking experiment eligibility.
extension ExperimentEligibility on Experiment {
  /// Check if a user is eligible for this experiment.
  ///
  /// Override this for custom eligibility rules.
  bool isUserEligible(String userId, {Map<String, dynamic>? userContext}) {
    // Default: all users eligible for active experiments
    if (!status.isRunning) return false;

    // Could add custom rules here:
    // - Staff-only experiments
    // - Admin-only experiments
    // - Geography-based targeting
    // - User segment targeting

    return true;
  }

  /// Get the variant ID for configuration lookup.
  String? getVariantIdForConfig(
    VariantAssigner assigner,
    String userId, {
    String? entityId,
  }) {
    final variant = assigner.assignVariant(
      experiment: this,
      userId: userId,
      entityId: entityId,
    );
    return variant?.id;
  }
}
