import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/experiment.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing A/B experiments.
///
/// Stores experiment definitions, variant assignments, and outcomes
/// for A/B testing of AI features.
///
/// HIPAA compliant: stores only aggregate metrics, no PHI.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class ExperimentsRepository {
  ExperimentsRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  // ===== EXPERIMENT CRUD =====

  /// Create a new experiment.
  Future<Experiment> createExperiment({
    required SecurityContext context,
    required Experiment experiment,
  }) async {
    final docRef = _experimentsCollection(context.businessId).doc();

    final experimentWithId = experiment.copyWith(
      id: docRef.id,
      businessId: context.businessId,
      createdAt: DateTime.now(),
      createdBy: context.userId,
    );

    await docRef.set(experimentWithId.toJson());

    _logAudit(
      context: context,
      action: 'experiment_created',
      entityType: 'experiment',
      entityId: docRef.id,
      details: {
        'name': experiment.name,
        'type': experiment.type.name,
        'variantCount': experiment.variants.length,
      },
    );

    return experimentWithId;
  }

  /// Get an experiment by ID.
  Future<Experiment?> getExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    final doc = await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .get();

    if (!doc.exists) return null;
    return Experiment.fromJson(doc.data()!);
  }

  /// Update an experiment.
  Future<Experiment> updateExperiment({
    required SecurityContext context,
    required Experiment experiment,
  }) async {
    final docRef = _experimentsCollection(context.businessId).doc(experiment.id);

    final updated = experiment.copyWith(updatedAt: DateTime.now());
    await docRef.update(updated.toJson());

    _logAudit(
      context: context,
      action: 'experiment_updated',
      entityType: 'experiment',
      entityId: experiment.id,
      details: {
        'status': experiment.status.name,
      },
    );

    return updated;
  }

  /// Delete an experiment (soft delete by setting status to cancelled).
  Future<void> cancelExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    await _experimentsCollection(context.businessId).doc(experimentId).update({
      'status': ExperimentStatus.cancelled.name,
      'endedAt': FieldValue.serverTimestamp(),
    });

    _logAudit(
      context: context,
      action: 'experiment_cancelled',
      entityType: 'experiment',
      entityId: experimentId,
      details: {},
    );
  }

  /// Activate an experiment.
  Future<Experiment> activateExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    final experiment = await getExperiment(context, experimentId);
    if (experiment == null) {
      throw Exception('Experiment not found: $experimentId');
    }

    if (!experiment.status.canBeActivated) {
      throw Exception('Experiment cannot be activated in status: ${experiment.status.name}');
    }

    if (!experiment.hasValidTrafficAllocation) {
      throw Exception('Traffic allocation does not sum to 100%');
    }

    final updated = experiment.copyWith(
      status: ExperimentStatus.active,
      startedAt: experiment.startedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .update(updated.toJson());

    _logAudit(
      context: context,
      action: 'experiment_activated',
      entityType: 'experiment',
      entityId: experimentId,
      details: {'variantCount': experiment.variants.length},
    );

    return updated;
  }

  /// Pause an experiment.
  Future<Experiment> pauseExperiment(
    SecurityContext context,
    String experimentId,
  ) async {
    final experiment = await getExperiment(context, experimentId);
    if (experiment == null) {
      throw Exception('Experiment not found: $experimentId');
    }

    if (!experiment.status.canBePaused) {
      throw Exception('Experiment cannot be paused in status: ${experiment.status.name}');
    }

    final updated = experiment.copyWith(
      status: ExperimentStatus.paused,
      updatedAt: DateTime.now(),
    );

    await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .update(updated.toJson());

    _logAudit(
      context: context,
      action: 'experiment_paused',
      entityType: 'experiment',
      entityId: experimentId,
      details: {},
    );

    return updated;
  }

  /// Complete an experiment with winning variant.
  Future<Experiment> completeExperiment(
    SecurityContext context,
    String experimentId, {
    String? winningVariantId,
  }) async {
    final experiment = await getExperiment(context, experimentId);
    if (experiment == null) {
      throw Exception('Experiment not found: $experimentId');
    }

    if (!experiment.status.canBeCompleted) {
      throw Exception('Experiment cannot be completed in status: ${experiment.status.name}');
    }

    final updated = experiment.copyWith(
      status: ExperimentStatus.completed,
      endedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      winningVariantId: winningVariantId,
    );

    await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .update(updated.toJson());

    _logAudit(
      context: context,
      action: 'experiment_completed',
      entityType: 'experiment',
      entityId: experimentId,
      details: {
        'winningVariantId': winningVariantId,
        'totalAssignments': experiment.totalAssignments,
      },
    );

    return updated;
  }

  /// Get all experiments for a business.
  Future<List<Experiment>> getExperiments(
    SecurityContext context, {
    ExperimentStatus? status,
    ExperimentType? type,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query =
        _experimentsCollection(context.businessId)
            .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Experiment.fromJson(doc.data())).toList();
  }

  /// Get active experiments for a business.
  Future<List<Experiment>> getActiveExperiments(SecurityContext context) async {
    return getExperiments(context, status: ExperimentStatus.active);
  }

  /// Stream an experiment for real-time updates.
  Stream<Experiment?> watchExperiment(
    SecurityContext context,
    String experimentId,
  ) {
    return _experimentsCollection(context.businessId)
        .doc(experimentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Experiment.fromJson(doc.data()!);
    });
  }

  // ===== VARIANT ASSIGNMENTS =====

  /// Record a variant assignment for a user.
  Future<ExperimentAssignment> recordAssignment({
    required SecurityContext context,
    required String experimentId,
    required String variantId,
    required String userId,
    String? entityId,
    String? entityType,
  }) async {
    final docRef = _assignmentsCollection(context.businessId).doc();

    final assignment = ExperimentAssignment(
      id: docRef.id,
      businessId: context.businessId,
      experimentId: experimentId,
      variantId: variantId,
      userId: userId,
      assignedAt: DateTime.now(),
      entityId: entityId,
      entityType: entityType,
    );

    await docRef.set(assignment.toJson());

    // Increment variant assignment count
    await _incrementVariantAssignment(context, experimentId, variantId);

    return assignment;
  }

  /// Get assignment for a user in an experiment.
  Future<ExperimentAssignment?> getAssignment(
    SecurityContext context, {
    required String experimentId,
    required String userId,
    String? entityId,
  }) async {
    Query<Map<String, dynamic>> query = _assignmentsCollection(context.businessId)
        .where('experimentId', isEqualTo: experimentId)
        .where('userId', isEqualTo: userId);

    if (entityId != null) {
      query = query.where('entityId', isEqualTo: entityId);
    }

    final snapshot = await query.limit(1).get();
    if (snapshot.docs.isEmpty) return null;

    return ExperimentAssignment.fromJson(snapshot.docs.first.data());
  }

  /// Record a conversion for an assignment.
  Future<void> recordConversion(
    SecurityContext context, {
    required String assignmentId,
    Map<String, dynamic>? metadata,
  }) async {
    final docRef = _assignmentsCollection(context.businessId).doc(assignmentId);

    await docRef.update({
      'converted': true,
      'convertedAt': FieldValue.serverTimestamp(),
      'conversionMetadata': metadata ?? {},
    });

    // Get assignment to increment variant conversion
    final doc = await docRef.get();
    if (doc.exists) {
      final assignment = ExperimentAssignment.fromJson(doc.data()!);
      await _incrementVariantConversion(
        context,
        assignment.experimentId,
        assignment.variantId,
      );
    }
  }

  /// Get all assignments for an experiment.
  Future<List<ExperimentAssignment>> getAssignments(
    SecurityContext context,
    String experimentId, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _assignmentsCollection(context.businessId)
        .where('experimentId', isEqualTo: experimentId)
        .orderBy('assignedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ExperimentAssignment.fromJson(doc.data()))
        .toList();
  }

  // ===== VARIANT STATS =====

  Future<void> _incrementVariantAssignment(
    SecurityContext context,
    String experimentId,
    String variantId,
  ) async {
    final experiment = await getExperiment(context, experimentId);
    if (experiment == null) return;

    final updatedVariants = experiment.variants.map((v) {
      if (v.id == variantId) {
        return v.copyWith(assignmentCount: v.assignmentCount + 1);
      }
      return v;
    }).toList();

    await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .update({'variants': updatedVariants.map((v) => v.toJson()).toList()});
  }

  Future<void> _incrementVariantConversion(
    SecurityContext context,
    String experimentId,
    String variantId,
  ) async {
    final experiment = await getExperiment(context, experimentId);
    if (experiment == null) return;

    final updatedVariants = experiment.variants.map((v) {
      if (v.id == variantId) {
        return v.copyWith(conversionCount: v.conversionCount + 1);
      }
      return v;
    }).toList();

    await _experimentsCollection(context.businessId)
        .doc(experimentId)
        .update({'variants': updatedVariants.map((v) => v.toJson()).toList()});
  }

  // ===== HELPERS =====

  CollectionReference<Map<String, dynamic>> _experimentsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('experiments');
  }

  CollectionReference<Map<String, dynamic>> _assignmentsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('experiment_assignments');
  }

  void _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) {
    _auditLogRepository
        .log(
          context: context,
          action: action,
          entityType: entityType,
          entityId: entityId,
          details: details,
          source: 'ExperimentsRepository',
        )
        .catchError((e) {
      developer.log(
        'Audit log failed (non-blocking): $e',
        name: 'ExperimentsRepository',
      );
    });
  }
}
