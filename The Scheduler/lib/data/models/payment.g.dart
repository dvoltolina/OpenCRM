// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  appointmentId: json['appointmentId'] as String,
  clientId: json['clientId'] as String,
  amountCents: (json['amountCents'] as num).toInt(),
  currency: json['currency'] as String? ?? 'USD',
  status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
  type: $enumDecode(_$PaymentTypeEnumMap, json['type']),
  stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
  stripeChargeId: json['stripeChargeId'] as String?,
  stripeRefundId: json['stripeRefundId'] as String?,
  cardLast4: json['cardLast4'] as String?,
  cardBrand: json['cardBrand'] as String?,
  paymentMethodDescription: json['paymentMethodDescription'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  completedAt: const NullableTimestampConverter().fromJson(json['completedAt']),
  refundedAt: const NullableTimestampConverter().fromJson(json['refundedAt']),
  refundAmountCents: (json['refundAmountCents'] as num?)?.toInt(),
  parentPaymentId: json['parentPaymentId'] as String?,
  reason: json['reason'] as String?,
  errorMessage: json['errorMessage'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'appointmentId': instance.appointmentId,
  'clientId': instance.clientId,
  'amountCents': instance.amountCents,
  'currency': instance.currency,
  'status': _$PaymentStatusEnumMap[instance.status]!,
  'type': _$PaymentTypeEnumMap[instance.type]!,
  'stripePaymentIntentId': instance.stripePaymentIntentId,
  'stripeChargeId': instance.stripeChargeId,
  'stripeRefundId': instance.stripeRefundId,
  'cardLast4': instance.cardLast4,
  'cardBrand': instance.cardBrand,
  'paymentMethodDescription': instance.paymentMethodDescription,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'completedAt': const NullableTimestampConverter().toJson(
    instance.completedAt,
  ),
  'refundedAt': const NullableTimestampConverter().toJson(instance.refundedAt),
  'refundAmountCents': instance.refundAmountCents,
  'parentPaymentId': instance.parentPaymentId,
  'reason': instance.reason,
  'errorMessage': instance.errorMessage,
  'notes': instance.notes,
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.none: 'none',
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.partiallyRefunded: 'partially_refunded',
};

const _$PaymentTypeEnumMap = {
  PaymentType.deposit: 'deposit',
  PaymentType.full: 'full',
  PaymentType.subscription: 'subscription',
  PaymentType.rescheduleFee: 'reschedule_fee',
  PaymentType.cancellationFee: 'cancellation_fee',
  PaymentType.refund: 'refund',
};
