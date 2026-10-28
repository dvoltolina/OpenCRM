// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Appointment _$AppointmentFromJson(Map<String, dynamic> json) => _Appointment(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  clientId: json['clientId'] as String,
  providerId: json['providerId'] as String,
  serviceId: json['serviceId'] as String,
  serviceType: json['serviceType'] as String?,
  locationId: json['locationId'] as String,
  startTime: const TimestampConverter().fromJson(json['startTime']),
  endTime: const TimestampConverter().fromJson(json['endTime']),
  date: const TimestampConverter().fromJson(json['date']),
  status: $enumDecode(_$AppointmentStatusEnumMap, json['status']),
  notes: json['notes'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  requiresPayment: json['requiresPayment'] as bool? ?? false,
  paymentType:
      $enumDecodeNullable(_$PaymentTypeEnumMap, json['paymentType']) ??
      PaymentType.full,
  paymentAmountCents: (json['paymentAmountCents'] as num?)?.toInt(),
  paymentStatus:
      $enumDecodeNullable(_$PaymentStatusEnumMap, json['paymentStatus']) ??
      PaymentStatus.none,
  paymentId: json['paymentId'] as String?,
  refundEligible: json['refundEligible'] as bool? ?? false,
  refundStatus: $enumDecodeNullable(
    _$PaymentStatusEnumMap,
    json['refundStatus'],
  ),
  refundAmountCents: (json['refundAmountCents'] as num?)?.toInt(),
  refundRequestedAt: const NullableTimestampConverter().fromJson(
    json['refundRequestedAt'],
  ),
  refundProcessedAt: const NullableTimestampConverter().fromJson(
    json['refundProcessedAt'],
  ),
  refundPaymentId: json['refundPaymentId'] as String?,
  rescheduleFeeRequired: json['rescheduleFeeRequired'] as bool? ?? false,
  rescheduleFeeCents: (json['rescheduleFeeCents'] as num?)?.toInt(),
  rescheduleFeeStatus:
      $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['rescheduleFeeStatus'],
      ) ??
      PaymentStatus.none,
  reschedulePaymentId: json['reschedulePaymentId'] as String?,
  cancellationFeeRequired: json['cancellationFeeRequired'] as bool? ?? false,
  cancellationFeeCents: (json['cancellationFeeCents'] as num?)?.toInt(),
  cancellationFeeStatus:
      $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['cancellationFeeStatus'],
      ) ??
      PaymentStatus.none,
  cancellationPaymentId: json['cancellationPaymentId'] as String?,
  cancellationReason: json['cancellationReason'] as String?,
  cancellationCode: json['cancellationCode'] as String?,
  cancelledAt: const NullableTimestampConverter().fromJson(json['cancelledAt']),
  isRecurring: json['isRecurring'] as bool? ?? false,
  recurrenceId: json['recurrenceId'] as String?,
  recurrencePattern: json['recurrencePattern'] == null
      ? null
      : RecurrencePattern.fromJson(
          json['recurrencePattern'] as Map<String, dynamic>,
        ),
  isRecurrenceException: json['isRecurrenceException'] as bool? ?? false,
  originalStartTime: const NullableTimestampConverter().fromJson(
    json['originalStartTime'],
  ),
  isGroupSession: json['isGroupSession'] as bool? ?? false,
  capacity: (json['capacity'] as num?)?.toInt(),
  attendeeIds:
      (json['attendeeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  publicVisibility: json['publicVisibility'] as bool? ?? false,
  registrationDeadline: const NullableTimestampConverter().fromJson(
    json['registrationDeadline'],
  ),
);

Map<String, dynamic> _$AppointmentToJson(
  _Appointment instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'clientId': instance.clientId,
  'providerId': instance.providerId,
  'serviceId': instance.serviceId,
  'serviceType': instance.serviceType,
  'locationId': instance.locationId,
  'startTime': const TimestampConverter().toJson(instance.startTime),
  'endTime': const TimestampConverter().toJson(instance.endTime),
  'date': const TimestampConverter().toJson(instance.date),
  'status': _$AppointmentStatusEnumMap[instance.status]!,
  'notes': instance.notes,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'requiresPayment': instance.requiresPayment,
  'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
  'paymentAmountCents': instance.paymentAmountCents,
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'paymentId': instance.paymentId,
  'refundEligible': instance.refundEligible,
  'refundStatus': _$PaymentStatusEnumMap[instance.refundStatus],
  'refundAmountCents': instance.refundAmountCents,
  'refundRequestedAt': const NullableTimestampConverter().toJson(
    instance.refundRequestedAt,
  ),
  'refundProcessedAt': const NullableTimestampConverter().toJson(
    instance.refundProcessedAt,
  ),
  'refundPaymentId': instance.refundPaymentId,
  'rescheduleFeeRequired': instance.rescheduleFeeRequired,
  'rescheduleFeeCents': instance.rescheduleFeeCents,
  'rescheduleFeeStatus': _$PaymentStatusEnumMap[instance.rescheduleFeeStatus]!,
  'reschedulePaymentId': instance.reschedulePaymentId,
  'cancellationFeeRequired': instance.cancellationFeeRequired,
  'cancellationFeeCents': instance.cancellationFeeCents,
  'cancellationFeeStatus':
      _$PaymentStatusEnumMap[instance.cancellationFeeStatus]!,
  'cancellationPaymentId': instance.cancellationPaymentId,
  'cancellationReason': instance.cancellationReason,
  'cancellationCode': instance.cancellationCode,
  'cancelledAt': const NullableTimestampConverter().toJson(
    instance.cancelledAt,
  ),
  'isRecurring': instance.isRecurring,
  'recurrenceId': instance.recurrenceId,
  'recurrencePattern': instance.recurrencePattern?.toJson(),
  'isRecurrenceException': instance.isRecurrenceException,
  'originalStartTime': const NullableTimestampConverter().toJson(
    instance.originalStartTime,
  ),
  'isGroupSession': instance.isGroupSession,
  'capacity': instance.capacity,
  'attendeeIds': instance.attendeeIds,
  'publicVisibility': instance.publicVisibility,
  'registrationDeadline': const NullableTimestampConverter().toJson(
    instance.registrationDeadline,
  ),
};

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.pending: 'pending',
  AppointmentStatus.confirmed: 'confirmed',
  AppointmentStatus.cancelled: 'cancelled',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.noShow: 'noShow',
};

const _$PaymentTypeEnumMap = {
  PaymentType.deposit: 'deposit',
  PaymentType.full: 'full',
  PaymentType.subscription: 'subscription',
  PaymentType.rescheduleFee: 'reschedule_fee',
  PaymentType.cancellationFee: 'cancellation_fee',
  PaymentType.refund: 'refund',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.none: 'none',
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.partiallyRefunded: 'partially_refunded',
};
