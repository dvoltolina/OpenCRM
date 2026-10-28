import 'dart:developer' as developer;

import '../../data/models/experiment.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/experiments_repository.dart';
import 'variant_assigner.dart';

/// Service for managing A/B experiments.
///
/// Provides high-level operations for creating, running, and analyzing
/// experiments. Handles variant assignment and conversion tracking.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class ExperimentService {
  ExperimentService({
    ExperimentsRepository? repository,
    VariantAssigner? variantAssigner,
  })  : _repository = repository ?? ExperimentsRepository(),
        _variantAssigner = variantAssigner ?? VariantAssigner();

  final ExperimentsRepository _repository;
  final VariantAssigner _variantAssigner;

  // Cache for active experiments
  final Map<String, List<Experiment>> _activeExperimentsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(minutes: 5);

  // ===== EXPERIMENT LIFECYCLE =====

  /// Create a new experiment.
  Future<Experiment> createExperiment({
    required SecurityContext context,
    required String name,
    required ExperimentType type,
    required List<ExperimentVariant> variants,
    String? description,
    int? targetSampleSize,
    int minimumRunDays = 7,
    int maximumRunDays = 30,
    String primaryMetric = 'prediction_accuracy',
    List<String> secondaryMetrics = const [],
    double requiredConfidence = 0.95,
    List<String> tags = const [],
  }) async {
    // Validate variants
    _validateVariants(variants);

    final experiment = Experiment(
      id: '', // Will be set by repository
      businessId: context.businessId,
      name: name,
      description: description,
      type: type,
      status: ExperimentStatus.draft,
      variants: variants,
      createdAt: DateTime.now(),
      createdBy: context.userId,
      targetSampleSize: targetSampleSize,
      minimumRunDays: minimumRunDays,
      maximumRunDays: maximumRunDays,
      primaryMetric: primaryMetric,
      secondaryMetrics: secondaryMetrics,
      requiredConfidence: requiredConfidence,
      tags: tags,
    );

    final created = await _repository.createExperiment(
      context: context,
      experiment: experiment,
    );

    _invalidateCache(context.businessId);

    developer.log(
      'Created experiment: ${created.id} (${created.name})',
      name: 'ExperimentService',
    );

    return created;
  }

  /// Create a simple A/B experiment with control and one treatment.
  Future<Experiment> createSimpleABExperiment({
    required SecurityContext context,
    required String name,
    required ExperimentType type,
    required Map<String, dynamic> treatmentConfig,
    String? description,
    int controlTrafficPercent = 50,
    Map<String, dynamic>? controlConfig,
  }) async {
    final variants = [
      ExperimentVariant.control(
        trafficPercentage: controlTrafficPercent,
        config: controlConfig,
      ),
      ExperimentVariant.treatment(
        id: 'treatment_a',
        name: 'Treatment A',
        trafficPercentage: 100 - controlTrafficPercent,
        config: treatmentConfig,
      ),
    ];

    return createExperiment(
      context: context,
      name: name,
      type: type,
      variants: variants,
      description: description,
    );
  }

  /// Activate an experiment.
  Future<Experiment> activateExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    final experiment = await _repository.activateExperiment(
      context,
      experimentId,
    );

    _invalidateCache(context.businessId);

    developer.log(
      'Activated experiment: $experimentId',
      name: 'ExperimentService',
    );

    return experiment;
  }

  /// Pause an experiment.
  Future<Experiment> pauseExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    final experiment = await _repository.pauseExperiment(
      context,
      experimentId,
    );

    _invalidateCache(context.businessId);

    developer.log(
      'Paused experiment: $experimentId',
      name: 'ExperimentService',
    );

    return experiment;
  }

  /// Complete an experiment with optional winning variant.
  Future<Experiment> completeExperiment(
    SecurityContext context,
    String experimentId, {
    String? winningVariantId,
    bool autoSelectWinner = false,
  }) async {
    String? winner = winningVariantId;

    if (autoSelectWinner && winner == null) {
      final experiment = await _repository.getExperiment(context, experimentId);
      if (experiment != null) {
        final best = experiment.bestPerformingVariant;
        if (best != null && experiment.isVariantWinning(best.id)) {
          winner = best.id;
        }
      }
    }

    final experiment = await _repository.completeExperiment(
      context,
      experimentId,
      winningVariantId: winner,
    );

    _invalidateCache(context.businessId);

    developer.log(
      'Completed experiment: $experimentId (winner: $winner)',
      name: 'ExperimentService',
    );

    return experiment;
  }

  /// Cancel an experiment.
  Future<void> cancelExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    await _repository.cancelExperiment(context, experimentId);
    _invalidateCache(context.businessId);

    developer.log(
      'Cancelled experiment: $experimentId',
      name: 'ExperimentService',
    );
  }

  // ===== VARIANT ASSIGNMENT =====

  /// Get or assign a variant for a user in an active experiment.
  ///
  /// If user already has an assignment, returns that variant.
  /// Otherwise, assigns a new variant based on traffic allocation.
  Future<ExperimentAssignmentResult> getOrAssignVariant({
    required SecurityContext context,
    required String experimentId,
    required String userId,
    String? entityId,
    String? entityType,
  }) async {
    // Check for existing assignment
    final existing = await _repository.getAssignment(
      context,
      experimentId: experimentId,
      userId: userId,
      entityId: entityId,
    );

    if (existing != null) {
      final experiment = await _repository.getExperiment(context, experimentId);
      final variant = experiment?.getVariant(existing.variantId);

      return ExperimentAssignmentResult(
        assignment: existing,
        variant: variant,
        isNewAssignment: false,
      );
    }

    // Get experiment and assign variant
    final experiment = await _repository.getExperiment(context, experimentId);
    if (experiment == null) {
      return ExperimentAssignmentResult.notFound();
    }

    final variant = _variantAssigner.assignVariant(
      experiment: experiment,
      userId: userId,
      entityId: entityId,
    );

    if (variant == null) {
      return ExperimentAssignmentResult.notEligible();
    }

    // Record assignment
    final assignment = await _repository.recordAssignment(
      context: context,
      experimentId: experimentId,
      variantId: variant.id,
      userId: userId,
      entityId: entityId,
      entityType: entityType,
    );

    return ExperimentAssignmentResult(
      assignment: assignment,
      variant: variant,
      isNewAssignment: true,
    );
  }

  /// Get variant config for a user in an experiment (without recording).
  Future<Map<String, dynamic>?> getVariantConfig({
    required SecurityContext context,
    required String experimentId,
    required String userId,
    String? entityId,
  }) async {
    // Check for existing assignment first
    final existing = await _repository.getAssignment(
      context,
      experimentId: experimentId,
      userId: userId,
      entityId: entityId,
    );

    if (existing != null) {
      final experiment = await _repository.getExperiment(context, experimentId);
      return experiment?.getVariant(existing.variantId)?.config;
    }

    // Preview assignment
    final experiment = await _repository.getExperiment(context, experimentId);
    if (experiment == null) return null;

    final variant = _variantAssigner.previewAssignment(
      experiment: experiment,
      userId: userId,
      entityId: entityId,
    );

    return variant?.config;
  }

  /// Record a conversion for an assignment.
  Future<void> recordConversion(
    SecurityContext context, {
    required String assignmentId,
    Map<String, dynamic>? metadata,
  }) async {
    await _repository.recordConversion(
      context,
      assignmentId: assignmentId,
      metadata: metadata,
    );

    developer.log(
      'Recorded conversion for assignment: $assignmentId',
      name: 'ExperimentService',
    );
  }

  // ===== QUERIES =====

  /// Get active experiments for a business.
  Future<List<Experiment>> getActiveExperiments(SecurityContext context) async {
    // Check cache
    final cached = _getCachedExperiments(context.businessId);
    if (cached != null) {
      return cached;
    }

    final experiments = await _repository.getActiveExperiments(context);

    // Update cache
    _activeExperimentsCache[context.businessId] = experiments;
    _cacheTimestamps[context.businessId] = DateTime.now();

    return experiments;
  }

  /// Get experiments by type.
  Future<List<Experiment>> getExperimentsByType(
    SecurityContext context,
    ExperimentType type,
  ) async {
    return _repository.getExperiments(context, type: type);
  }

  /// Get experiment by ID.
  Future<Experiment?> getExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    return _repository.getExperiment(context, experimentId);
  }

  /// Stream experiment updates.
  Stream<Experiment?> watchExperiment(
    SecurityContext context,
    String experimentId,
  ) {
    return _repository.watchExperiment(context, experimentId);
  }

  /// Find active experiment for a specific feature.
  Future<Experiment?> findActiveExperimentForFeature(
    SecurityContext context,
    String featureKey,
  ) async {
    final experiments = await getActiveExperiments(context);

    for (final exp in experiments) {
      // Check if any variant config references this feature
      for (final variant in exp.variants) {
        if (variant.config.containsKey(featureKey)) {
          return exp;
        }
      }
    }

    return null;
  }

  // ===== ANALYSIS =====

  /// Get experiment results summary.
  Future<ExperimentResults> getExperimentResults(
    SecurityContext context,
    String experimentId,
  ) async {
    final experiment = await _repository.getExperiment(context, experimentId);
    if (experiment == null) {
      throw Exception('Experiment not found: $experimentId');
    }

    final assignments = await _repository.getAssignments(
      context,
      experimentId,
    );

    final variantResults = <String, VariantResults>{};

    for (final variant in experiment.variants) {
      final variantAssignments =
          assignments.where((a) => a.variantId == variant.id).toList();
      final conversions =
          variantAssignments.where((a) => a.converted == true).length;

      variantResults[variant.id] = VariantResults(
        variantId: variant.id,
        variantName: variant.name,
        isControl: variant.isControl,
        assignmentCount: variantAssignments.length,
        conversionCount: conversions,
        conversionRate: variantAssignments.isNotEmpty
            ? conversions / variantAssignments.length
            : 0,
      );
    }

    // Calculate lift compared to control
    final controlResults = variantResults.values
        .where((r) => r.isControl)
        .firstOrNull;

    if (controlResults != null) {
      for (final result in variantResults.values) {
        if (!result.isControl && controlResults.conversionRate > 0) {
          final lift = (result.conversionRate - controlResults.conversionRate) /
              controlResults.conversionRate *
              100;
          variantResults[result.variantId] = VariantResults(
            variantId: result.variantId,
            variantName: result.variantName,
            isControl: result.isControl,
            assignmentCount: result.assignmentCount,
            conversionCount: result.conversionCount,
            conversionRate: result.conversionRate,
            liftOverControl: lift,
          );
        }
      }
    }

    return ExperimentResults(
      experimentId: experimentId,
      experimentName: experiment.name,
      status: experiment.status,
      totalAssignments: experiment.totalAssignments,
      daysRunning: experiment.daysRunning,
      variantResults: variantResults,
      winningVariantId: experiment.winningVariantId,
      hasReachedMinimumDuration: experiment.hasReachedMinimumDuration,
      hasReachedTargetSampleSize: experiment.hasReachedTargetSampleSize,
    );
  }

  // ===== HELPERS =====

  void _validateVariants(List<ExperimentVariant> variants) {
    if (variants.isEmpty) {
      throw ArgumentError('Experiment must have at least one variant');
    }

    final totalTraffic = variants.fold<int>(
      0,
      (sum, v) => sum + v.trafficPercentage,
    );

    if (totalTraffic != 100) {
      throw ArgumentError(
        'Variant traffic percentages must sum to 100 (got $totalTraffic)',
      );
    }

    final controlCount = variants.where((v) => v.isControl).length;
    if (controlCount > 1) {
      throw ArgumentError('Experiment can only have one control variant');
    }
  }

  List<Experiment>? _getCachedExperiments(String businessId) {
    final timestamp = _cacheTimestamps[businessId];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _activeExperimentsCache.remove(businessId);
      _cacheTimestamps.remove(businessId);
      return null;
    }

    return _activeExperimentsCache[businessId];
  }

  void _invalidateCache(String businessId) {
    _activeExperimentsCache.remove(businessId);
    _cacheTimestamps.remove(businessId);
  }
}

/// Result of a variant assignment operation.
class ExperimentAssignmentResult {
  const ExperimentAssignmentResult({
    this.assignment,
    this.variant,
    required this.isNewAssignment,
    this.error,
  });

  factory ExperimentAssignmentResult.notFound() {
    return const ExperimentAssignmentResult(
      isNewAssignment: false,
      error: 'Experiment not found',
    );
  }

  factory ExperimentAssignmentResult.notEligible() {
    return const ExperimentAssignmentResult(
      isNewAssignment: false,
      error: 'User not eligible for experiment',
    );
  }

  final ExperimentAssignment? assignment;
  final ExperimentVariant? variant;
  final bool isNewAssignment;
  final String? error;

  bool get isSuccess => assignment != null && variant != null;
  bool get isError => error != null;

  Map<String, dynamic>? get config => variant?.config;
}

/// Aggregated results for an experiment.
class ExperimentResults {
  const ExperimentResults({
    required this.experimentId,
    required this.experimentName,
    required this.status,
    required this.totalAssignments,
    required this.variantResults,
    this.daysRunning,
    this.winningVariantId,
    this.hasReachedMinimumDuration = false,
    this.hasReachedTargetSampleSize = false,
  });

  final String experimentId;
  final String experimentName;
  final ExperimentStatus status;
  final int totalAssignments;
  final int? daysRunning;
  final Map<String, VariantResults> variantResults;
  final String? winningVariantId;
  final bool hasReachedMinimumDuration;
  final bool hasReachedTargetSampleSize;

  VariantResults? get controlResults =>
      variantResults.values.where((r) => r.isControl).firstOrNull;

  VariantResults? get bestPerformingVariant {
    if (variantResults.isEmpty) return null;
    return variantResults.values.reduce(
      (a, b) => a.conversionRate > b.conversionRate ? a : b,
    );
  }
}

/// Results for a single variant.
class VariantResults {
  const VariantResults({
    required this.variantId,
    required this.variantName,
    required this.isControl,
    required this.assignmentCount,
    required this.conversionCount,
    required this.conversionRate,
    this.liftOverControl,
  });

  final String variantId;
  final String variantName;
  final bool isControl;
  final int assignmentCount;
  final int conversionCount;
  final double conversionRate;
  final double? liftOverControl;

  double get conversionPercent => conversionRate * 100;
}
