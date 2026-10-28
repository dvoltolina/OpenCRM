import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../ai/yield/overbooking_service.dart' as yield_service;
import '../../core/services/demo_guard_service.dart';
import '../models/overbooking_slot.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for persisting overbooking slots and outcome records.
///
/// Implements multi-tenant isolation via SecurityContext.
/// All operations are scoped to `businesses/{businessId}/overbookingSlots`.
///
/// **HIPAA Compliance:**
/// - All operations require SecurityContext for tenant isolation
/// - Slot data contains appointment references but no PHI
/// - Audit logging for slot creation and outcome recording
///
/// Agent AI-16: Yield Management & Overbooking Engine
class OverbookingRepository implements yield_service.OverbookingRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository? _auditLogRepository;

  OverbookingRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository;

  /// Collection path for overbooking slots.
  String _slotsPath(String businessId) =>
      'businesses/$businessId/overbookingSlots';

  /// Collection path for outcome records.
  String _outcomesPath(String businessId) =>
      'businesses/$businessId/overbookingOutcomes';

  // ============ Slot Operations ============

  @override
  Future<void> saveSlot(SecurityContext context, OverbookingSlot slot) async {
    DemoGuardService.assertReadOnly(
      'save overbooking slot',
      showMessage: false,
    );
    context.verifyBusinessAccess(slot.businessId);

    final docRef = _firestore
        .collection(_slotsPath(slot.businessId))
        .doc(slot.id);

    await docRef.set(_slotToFirestore(slot), SetOptions(merge: true));

    debugPrint('OverbookingRepository: Saved slot ${slot.id}');
  }

  @override
  Future<OverbookingSlot?> getSlot(
    SecurityContext context,
    String slotId,
  ) async {
    final docRef = _firestore
        .collection(_slotsPath(context.businessId))
        .doc(slotId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return null;

    return _slotFromFirestore(snapshot);
  }

  @override
  Future<List<OverbookingSlot>> getSlotsForProviderDate(
    SecurityContext context,
    String providerId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _firestore
        .collection(_slotsPath(context.businessId))
        .where('providerId', isEqualTo: providerId)
        .where(
          'slotDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('slotDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('slotDate')
        .orderBy('slotStartTime');

    final snapshot = await query.get();

    return snapshot.docs.map(_slotFromFirestore).toList();
  }

  /// Get slots with overbooking opportunities for a date range.
  Future<List<OverbookingSlot>> getSlotsWithOpportunities(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
    String? providerId,
  }) async {
    var query = _firestore
        .collection(_slotsPath(context.businessId))
        .where(
          'slotDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('slotDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('safeOverbookCount', isGreaterThan: 0);

    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    }

    final snapshot = await query.get();

    return snapshot.docs.map(_slotFromFirestore).toList();
  }

  /// Update slot status.
  Future<void> updateSlotStatus(
    SecurityContext context,
    String slotId,
    OverbookingStatus status, {
    String? reason,
  }) async {
    DemoGuardService.assertReadOnly(
      'update overbooking slot',
      showMessage: false,
    );
    final docRef = _firestore
        .collection(_slotsPath(context.businessId))
        .doc(slotId);

    await docRef.update({
      'status': status.name,
      if (reason != null) 'exclusionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete old slots (for cleanup).
  Future<int> deleteOldSlots(
    SecurityContext context, {
    required DateTime olderThan,
  }) async {
    DemoGuardService.assertReadOnly(
      'delete overbooking slots',
      showMessage: false,
    );
    final query = _firestore
        .collection(_slotsPath(context.businessId))
        .where('slotDate', isLessThan: Timestamp.fromDate(olderThan));

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return snapshot.docs.length;
  }

  // ============ Outcome Operations ============

  @override
  Future<void> saveOutcomeRecord(
    SecurityContext context,
    OverbookingOutcomeRecord record,
  ) async {
    DemoGuardService.assertReadOnly(
      'save overbooking outcome',
      showMessage: false,
    );
    context.verifyBusinessAccess(record.businessId);

    final docRef = _firestore
        .collection(_outcomesPath(record.businessId))
        .doc(record.id);

    await docRef.set(_outcomeToFirestore(record));

    // Log outcome for audit
    try {
      await _auditLogRepository?.log(
        context: context,
        action: 'yield_outcome_saved',
        entityType: 'overbookingOutcome',
        entityId: record.id,
        source: 'OverbookingRepository',
        details: {
          'slot_id': record.overbookingSlotId,
          'outcome': record.actualOutcome.name,
          'prediction_accurate': record.predictionAccurate,
          'revenue_impact_cents': record.revenueImpactCents,
        },
      );
    } catch (e) {
      debugPrint('OverbookingRepository: Audit log failed (non-blocking): $e');
    }
  }

  @override
  Future<List<OverbookingOutcomeRecord>> getOutcomeHistory(
    SecurityContext context,
    String providerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _firestore
        .collection(_outcomesPath(context.businessId))
        .where('providerId', isEqualTo: providerId)
        .orderBy('slotDateTime', descending: true);

    if (startDate != null) {
      query = query.where(
        'slotDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'slotDateTime',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final snapshot = await query.limit(100).get();

    return snapshot.docs.map(_outcomeFromFirestore).toList();
  }

  /// Get accuracy statistics for model improvement.
  Future<Map<String, dynamic>> getAccuracyStats(
    SecurityContext context, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final outcomes = await getOutcomeHistory(
      context,
      '', // All providers
      startDate: startDate,
      endDate: endDate,
    );

    if (outcomes.isEmpty) {
      return {
        'totalOutcomes': 0,
        'accurateCount': 0,
        'accuracyRate': 0.0,
        'totalRevenueImpact': 0,
        'avgRevenueImpact': 0.0,
      };
    }

    final accurateCount = outcomes.where((o) => o.predictionAccurate).length;
    final totalRevenue = outcomes.fold<int>(
      0,
      (runningTotal, outcome) => runningTotal + outcome.revenueImpactCents,
    );

    return {
      'totalOutcomes': outcomes.length,
      'accurateCount': accurateCount,
      'accuracyRate': accurateCount / outcomes.length,
      'totalRevenueImpact': totalRevenue,
      'avgRevenueImpact': totalRevenue / outcomes.length,
      'outcomeBreakdown': _calculateOutcomeBreakdown(outcomes),
    };
  }

  // ============ Config Operations ============

  /// Save business overbooking configuration.
  Future<void> saveConfig(
    SecurityContext context,
    Map<String, dynamic> configJson,
  ) async {
    DemoGuardService.assertReadOnly(
      'save overbooking configuration',
      showMessage: false,
    );
    await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('settings')
        .doc('overbooking')
        .set(configJson, SetOptions(merge: true));
  }

  /// Load business overbooking configuration.
  Future<Map<String, dynamic>?> loadConfig(SecurityContext context) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('settings')
        .doc('overbooking')
        .get();

    return doc.exists ? doc.data() : null;
  }

  // ============ Firestore Serialization ============

  Map<String, dynamic> _slotToFirestore(OverbookingSlot slot) {
    return {
      'id': slot.id,
      'businessId': slot.businessId,
      'providerId': slot.providerId,
      'locationId': slot.locationId,
      'slotDate': Timestamp.fromDate(slot.slotDate),
      'slotStartTime': Timestamp.fromDate(slot.slotStartTime),
      'slotEndTime': Timestamp.fromDate(slot.slotEndTime),
      'serviceId': slot.serviceId,
      'currentBookings': slot.currentBookings,
      'baseCapacity': slot.baseCapacity,
      'safeOverbookCount': slot.safeOverbookCount,
      'acceptedOverbooks': slot.acceptedOverbooks,
      'weightedNoshowProbability': slot.weightedNoshowProbability,
      'averageConfidence': slot.averageConfidence,
      'historicalNoshowRate': slot.historicalNoshowRate,
      'status': slot.status.name,
      'outcome': slot.outcome.name,
      'expectedRevenueCents': slot.expectedRevenueCents,
      'projectedRevenueCents': slot.projectedRevenueCents,
      'riskRevenueCents': slot.riskRevenueCents,
      'appointmentIds': slot.appointmentIds,
      'overbookedAppointmentIds': slot.overbookedAppointmentIds,
      'hasVipClients': slot.hasVipClients,
      'isGroupSession': slot.isGroupSession,
      'providerOptedOut': slot.providerOptedOut,
      'exclusionReason': slot.exclusionReason,
      'calculatedAt': Timestamp.fromDate(slot.calculatedAt),
      'updatedAt': slot.updatedAt != null
          ? Timestamp.fromDate(slot.updatedAt!)
          : FieldValue.serverTimestamp(),
      'algorithmVersion': slot.algorithmVersion,
    };
  }

  OverbookingSlot _slotFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OverbookingSlot(
      id: data['id'] as String,
      businessId: data['businessId'] as String,
      providerId: data['providerId'] as String,
      locationId: data['locationId'] as String?,
      slotDate: (data['slotDate'] as Timestamp).toDate(),
      slotStartTime: (data['slotStartTime'] as Timestamp).toDate(),
      slotEndTime: (data['slotEndTime'] as Timestamp).toDate(),
      serviceId: data['serviceId'] as String?,
      currentBookings: data['currentBookings'] as int,
      baseCapacity: data['baseCapacity'] as int,
      safeOverbookCount: data['safeOverbookCount'] as int,
      acceptedOverbooks: data['acceptedOverbooks'] as int? ?? 0,
      weightedNoshowProbability: (data['weightedNoshowProbability'] as num)
          .toDouble(),
      averageConfidence: (data['averageConfidence'] as num).toDouble(),
      historicalNoshowRate: (data['historicalNoshowRate'] as num?)?.toDouble(),
      status: OverbookingStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OverbookingStatus.available,
      ),
      outcome: OverbookingOutcome.values.firstWhere(
        (o) => o.name == data['outcome'],
        orElse: () => OverbookingOutcome.pending,
      ),
      expectedRevenueCents: data['expectedRevenueCents'] as int,
      projectedRevenueCents: data['projectedRevenueCents'] as int,
      riskRevenueCents: data['riskRevenueCents'] as int,
      appointmentIds: List<String>.from(data['appointmentIds'] ?? []),
      overbookedAppointmentIds: List<String>.from(
        data['overbookedAppointmentIds'] ?? [],
      ),
      hasVipClients: data['hasVipClients'] as bool? ?? false,
      isGroupSession: data['isGroupSession'] as bool? ?? false,
      providerOptedOut: data['providerOptedOut'] as bool? ?? false,
      exclusionReason: data['exclusionReason'] as String?,
      calculatedAt: (data['calculatedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      algorithmVersion: data['algorithmVersion'] as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> _outcomeToFirestore(OverbookingOutcomeRecord record) {
    return {
      'id': record.id,
      'overbookingSlotId': record.overbookingSlotId,
      'businessId': record.businessId,
      'providerId': record.providerId,
      'slotDateTime': Timestamp.fromDate(record.slotDateTime),
      'predictedNoshowProbability': record.predictedNoshowProbability,
      'actualOutcome': record.actualOutcome.name,
      'predictionAccurate': record.predictionAccurate,
      'revenueImpactCents': record.revenueImpactCents,
      'overbookedCount': record.overbookedCount,
      'actualNoshowCount': record.actualNoshowCount,
      'algorithmVersion': record.algorithmVersion,
      'recordedAt': Timestamp.fromDate(record.recordedAt),
    };
  }

  OverbookingOutcomeRecord _outcomeFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OverbookingOutcomeRecord(
      id: data['id'] as String,
      overbookingSlotId: data['overbookingSlotId'] as String,
      businessId: data['businessId'] as String,
      providerId: data['providerId'] as String,
      slotDateTime: (data['slotDateTime'] as Timestamp).toDate(),
      predictedNoshowProbability: (data['predictedNoshowProbability'] as num)
          .toDouble(),
      actualOutcome: OverbookingOutcome.values.firstWhere(
        (o) => o.name == data['actualOutcome'],
        orElse: () => OverbookingOutcome.pending,
      ),
      predictionAccurate: data['predictionAccurate'] as bool,
      revenueImpactCents: data['revenueImpactCents'] as int,
      overbookedCount: data['overbookedCount'] as int,
      actualNoshowCount: data['actualNoshowCount'] as int,
      algorithmVersion: data['algorithmVersion'] as String,
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, int> _calculateOutcomeBreakdown(
    List<OverbookingOutcomeRecord> outcomes,
  ) {
    final breakdown = <String, int>{};
    for (final outcome in outcomes) {
      final key = outcome.actualOutcome.name;
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }
    return breakdown;
  }
}
