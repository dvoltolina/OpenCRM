// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overbooking_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OverbookingSlot _$OverbookingSlotFromJson(Map<String, dynamic> json) =>
    _OverbookingSlot(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      providerId: json['providerId'] as String,
      locationId: json['locationId'] as String?,
      slotDate: const TimestampConverter().fromJson(json['slotDate']),
      slotStartTime: const TimestampConverter().fromJson(json['slotStartTime']),
      slotEndTime: const TimestampConverter().fromJson(json['slotEndTime']),
      serviceId: json['serviceId'] as String?,
      currentBookings: (json['currentBookings'] as num).toInt(),
      baseCapacity: (json['baseCapacity'] as num).toInt(),
      safeOverbookCount: (json['safeOverbookCount'] as num).toInt(),
      acceptedOverbooks: (json['acceptedOverbooks'] as num?)?.toInt() ?? 0,
      weightedNoshowProbability: (json['weightedNoshowProbability'] as num)
          .toDouble(),
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      historicalNoshowRate: (json['historicalNoshowRate'] as num?)?.toDouble(),
      status:
          $enumDecodeNullable(_$OverbookingStatusEnumMap, json['status']) ??
          OverbookingStatus.available,
      outcome:
          $enumDecodeNullable(_$OverbookingOutcomeEnumMap, json['outcome']) ??
          OverbookingOutcome.pending,
      expectedRevenueCents: (json['expectedRevenueCents'] as num).toInt(),
      projectedRevenueCents: (json['projectedRevenueCents'] as num).toInt(),
      riskRevenueCents: (json['riskRevenueCents'] as num).toInt(),
      appointmentIds: (json['appointmentIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      overbookedAppointmentIds:
          (json['overbookedAppointmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hasVipClients: json['hasVipClients'] as bool? ?? false,
      isGroupSession: json['isGroupSession'] as bool? ?? false,
      providerOptedOut: json['providerOptedOut'] as bool? ?? false,
      exclusionReason: json['exclusionReason'] as String?,
      calculatedAt: const TimestampConverter().fromJson(json['calculatedAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      algorithmVersion: json['algorithmVersion'] as String? ?? '1.0.0',
    );

Map<String, dynamic> _$OverbookingSlotToJson(
  _OverbookingSlot instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'providerId': instance.providerId,
  'locationId': instance.locationId,
  'slotDate': const TimestampConverter().toJson(instance.slotDate),
  'slotStartTime': const TimestampConverter().toJson(instance.slotStartTime),
  'slotEndTime': const TimestampConverter().toJson(instance.slotEndTime),
  'serviceId': instance.serviceId,
  'currentBookings': instance.currentBookings,
  'baseCapacity': instance.baseCapacity,
  'safeOverbookCount': instance.safeOverbookCount,
  'acceptedOverbooks': instance.acceptedOverbooks,
  'weightedNoshowProbability': instance.weightedNoshowProbability,
  'averageConfidence': instance.averageConfidence,
  'historicalNoshowRate': instance.historicalNoshowRate,
  'status': _$OverbookingStatusEnumMap[instance.status]!,
  'outcome': _$OverbookingOutcomeEnumMap[instance.outcome]!,
  'expectedRevenueCents': instance.expectedRevenueCents,
  'projectedRevenueCents': instance.projectedRevenueCents,
  'riskRevenueCents': instance.riskRevenueCents,
  'appointmentIds': instance.appointmentIds,
  'overbookedAppointmentIds': instance.overbookedAppointmentIds,
  'hasVipClients': instance.hasVipClients,
  'isGroupSession': instance.isGroupSession,
  'providerOptedOut': instance.providerOptedOut,
  'exclusionReason': instance.exclusionReason,
  'calculatedAt': const TimestampConverter().toJson(instance.calculatedAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'algorithmVersion': instance.algorithmVersion,
};

const _$OverbookingStatusEnumMap = {
  OverbookingStatus.available: 'available',
  OverbookingStatus.atCapacity: 'atCapacity',
  OverbookingStatus.pending: 'pending',
  OverbookingStatus.filled: 'filled',
  OverbookingStatus.declined: 'declined',
  OverbookingStatus.resolved: 'resolved',
};

const _$OverbookingOutcomeEnumMap = {
  OverbookingOutcome.noshowOccurred: 'noshowOccurred',
  OverbookingOutcome.doubleBooked: 'doubleBooked',
  OverbookingOutcome.overbookCancelled: 'overbookCancelled',
  OverbookingOutcome.originalCancelled: 'originalCancelled',
  OverbookingOutcome.pending: 'pending',
};

_DailyOverbookingSummary _$DailyOverbookingSummaryFromJson(
  Map<String, dynamic> json,
) => _DailyOverbookingSummary(
  providerId: json['providerId'] as String,
  businessId: json['businessId'] as String,
  date: const TimestampConverter().fromJson(json['date']),
  totalSlots: (json['totalSlots'] as num).toInt(),
  slotsWithOpportunity: (json['slotsWithOpportunity'] as num).toInt(),
  totalSafeOverbookCapacity: (json['totalSafeOverbookCapacity'] as num).toInt(),
  totalAcceptedOverbooks: (json['totalAcceptedOverbooks'] as num).toInt(),
  expectedAdditionalRevenueCents:
      (json['expectedAdditionalRevenueCents'] as num).toInt(),
  averageNoshowProbability: (json['averageNoshowProbability'] as num)
      .toDouble(),
  excludedSlots: (json['excludedSlots'] as num).toInt(),
  calculatedAt: const TimestampConverter().fromJson(json['calculatedAt']),
);

Map<String, dynamic> _$DailyOverbookingSummaryToJson(
  _DailyOverbookingSummary instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'businessId': instance.businessId,
  'date': const TimestampConverter().toJson(instance.date),
  'totalSlots': instance.totalSlots,
  'slotsWithOpportunity': instance.slotsWithOpportunity,
  'totalSafeOverbookCapacity': instance.totalSafeOverbookCapacity,
  'totalAcceptedOverbooks': instance.totalAcceptedOverbooks,
  'expectedAdditionalRevenueCents': instance.expectedAdditionalRevenueCents,
  'averageNoshowProbability': instance.averageNoshowProbability,
  'excludedSlots': instance.excludedSlots,
  'calculatedAt': const TimestampConverter().toJson(instance.calculatedAt),
};

_OverbookingOutcomeRecord _$OverbookingOutcomeRecordFromJson(
  Map<String, dynamic> json,
) => _OverbookingOutcomeRecord(
  id: json['id'] as String,
  overbookingSlotId: json['overbookingSlotId'] as String,
  businessId: json['businessId'] as String,
  providerId: json['providerId'] as String,
  slotDateTime: const TimestampConverter().fromJson(json['slotDateTime']),
  predictedNoshowProbability: (json['predictedNoshowProbability'] as num)
      .toDouble(),
  actualOutcome: $enumDecode(
    _$OverbookingOutcomeEnumMap,
    json['actualOutcome'],
  ),
  predictionAccurate: json['predictionAccurate'] as bool,
  revenueImpactCents: (json['revenueImpactCents'] as num).toInt(),
  overbookedCount: (json['overbookedCount'] as num).toInt(),
  actualNoshowCount: (json['actualNoshowCount'] as num).toInt(),
  algorithmVersion: json['algorithmVersion'] as String,
  recordedAt: const TimestampConverter().fromJson(json['recordedAt']),
);

Map<String, dynamic> _$OverbookingOutcomeRecordToJson(
  _OverbookingOutcomeRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'overbookingSlotId': instance.overbookingSlotId,
  'businessId': instance.businessId,
  'providerId': instance.providerId,
  'slotDateTime': const TimestampConverter().toJson(instance.slotDateTime),
  'predictedNoshowProbability': instance.predictedNoshowProbability,
  'actualOutcome': _$OverbookingOutcomeEnumMap[instance.actualOutcome]!,
  'predictionAccurate': instance.predictionAccurate,
  'revenueImpactCents': instance.revenueImpactCents,
  'overbookedCount': instance.overbookedCount,
  'actualNoshowCount': instance.actualNoshowCount,
  'algorithmVersion': instance.algorithmVersion,
  'recordedAt': const TimestampConverter().toJson(instance.recordedAt),
};
