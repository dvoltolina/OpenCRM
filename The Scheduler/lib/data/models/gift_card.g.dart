// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GiftCardRedemption _$GiftCardRedemptionFromJson(Map<String, dynamic> json) =>
    _GiftCardRedemption(
      id: json['id'] as String,
      giftCardId: json['giftCardId'] as String,
      appointmentId: json['appointmentId'] as String,
      amountCents: (json['amountCents'] as num).toInt(),
      redeemedAt: const TimestampConverter().fromJson(json['redeemedAt']),
      redeemedByClientId: json['redeemedByClientId'] as String,
    );

Map<String, dynamic> _$GiftCardRedemptionToJson(_GiftCardRedemption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'giftCardId': instance.giftCardId,
      'appointmentId': instance.appointmentId,
      'amountCents': instance.amountCents,
      'redeemedAt': const TimestampConverter().toJson(instance.redeemedAt),
      'redeemedByClientId': instance.redeemedByClientId,
    };

_GiftCard _$GiftCardFromJson(Map<String, dynamic> json) => _GiftCard(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  code: json['code'] as String,
  originalAmountCents: (json['originalAmountCents'] as num).toInt(),
  remainingBalanceCents: (json['remainingBalanceCents'] as num).toInt(),
  currency: json['currency'] as String? ?? 'usd',
  status: $enumDecode(_$GiftCardStatusEnumMap, json['status']),
  activatedAt: const NullableTimestampConverter().fromJson(json['activatedAt']),
  expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
  purchaserEmail: json['purchaserEmail'] as String,
  purchaserName: json['purchaserName'] as String?,
  purchasedAt: const TimestampConverter().fromJson(json['purchasedAt']),
  paymentId: json['paymentId'] as String?,
  recipientEmail: json['recipientEmail'] as String?,
  recipientName: json['recipientName'] as String?,
  personalMessage: json['personalMessage'] as String?,
  delivered: json['delivered'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  lastRedeemedAt: const NullableTimestampConverter().fromJson(
    json['lastRedeemedAt'],
  ),
  redemptions:
      (json['redemptions'] as List<dynamic>?)
          ?.map((e) => GiftCardRedemption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  templateId: json['templateId'] as String?,
  customImageUrl: json['customImageUrl'] as String?,
);

Map<String, dynamic> _$GiftCardToJson(_GiftCard instance) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'code': instance.code,
  'originalAmountCents': instance.originalAmountCents,
  'remainingBalanceCents': instance.remainingBalanceCents,
  'currency': instance.currency,
  'status': _$GiftCardStatusEnumMap[instance.status]!,
  'activatedAt': const NullableTimestampConverter().toJson(
    instance.activatedAt,
  ),
  'expiresAt': const NullableTimestampConverter().toJson(instance.expiresAt),
  'purchaserEmail': instance.purchaserEmail,
  'purchaserName': instance.purchaserName,
  'purchasedAt': const TimestampConverter().toJson(instance.purchasedAt),
  'paymentId': instance.paymentId,
  'recipientEmail': instance.recipientEmail,
  'recipientName': instance.recipientName,
  'personalMessage': instance.personalMessage,
  'delivered': instance.delivered,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'lastRedeemedAt': const NullableTimestampConverter().toJson(
    instance.lastRedeemedAt,
  ),
  'redemptions': instance.redemptions.map((e) => e.toJson()).toList(),
  'templateId': instance.templateId,
  'customImageUrl': instance.customImageUrl,
};

const _$GiftCardStatusEnumMap = {
  GiftCardStatus.pending: 'pending',
  GiftCardStatus.active: 'active',
  GiftCardStatus.depleted: 'depleted',
  GiftCardStatus.expired: 'expired',
  GiftCardStatus.voided: 'voided',
};
