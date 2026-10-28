// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PosLineItem _$PosLineItemFromJson(Map<String, dynamic> json) => _PosLineItem(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  sku: json['sku'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  unitPriceCents: (json['unitPriceCents'] as num).toInt(),
  totalCents: (json['totalCents'] as num).toInt(),
  discountCents: (json['discountCents'] as num?)?.toInt() ?? 0,
  discountReason: json['discountReason'] as String?,
  taxCents: (json['taxCents'] as num?)?.toInt() ?? 0,
  taxable: json['taxable'] as bool? ?? true,
);

Map<String, dynamic> _$PosLineItemToJson(_PosLineItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'sku': instance.sku,
      'quantity': instance.quantity,
      'unitPriceCents': instance.unitPriceCents,
      'totalCents': instance.totalCents,
      'discountCents': instance.discountCents,
      'discountReason': instance.discountReason,
      'taxCents': instance.taxCents,
      'taxable': instance.taxable,
    };

_SplitPaymentDetail _$SplitPaymentDetailFromJson(Map<String, dynamic> json) =>
    _SplitPaymentDetail(
      method: $enumDecode(_$PosPaymentMethodEnumMap, json['method']),
      amountCents: (json['amountCents'] as num).toInt(),
      reference: json['reference'] as String?,
      stripePaymentId: json['stripePaymentId'] as String?,
      giftCardCode: json['giftCardCode'] as String?,
    );

Map<String, dynamic> _$SplitPaymentDetailToJson(_SplitPaymentDetail instance) =>
    <String, dynamic>{
      'method': _$PosPaymentMethodEnumMap[instance.method]!,
      'amountCents': instance.amountCents,
      'reference': instance.reference,
      'stripePaymentId': instance.stripePaymentId,
      'giftCardCode': instance.giftCardCode,
    };

const _$PosPaymentMethodEnumMap = {
  PosPaymentMethod.card: 'card',
  PosPaymentMethod.cash: 'cash',
  PosPaymentMethod.giftCard: 'gift_card',
  PosPaymentMethod.split: 'split',
  PosPaymentMethod.account: 'account',
};

_PosTransaction _$PosTransactionFromJson(
  Map<String, dynamic> json,
) => _PosTransaction(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  transactionDate: const TimestampConverter().fromJson(json['transactionDate']),
  staffId: json['staffId'] as String,
  staffName: json['staffName'] as String?,
  clientId: json['clientId'] as String?,
  clientName: json['clientName'] as String?,
  appointmentId: json['appointmentId'] as String?,
  lineItems: (json['lineItems'] as List<dynamic>)
      .map((e) => PosLineItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotalCents: (json['subtotalCents'] as num).toInt(),
  taxCents: (json['taxCents'] as num).toInt(),
  taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
  discountCents: (json['discountCents'] as num?)?.toInt() ?? 0,
  discountReason: json['discountReason'] as String?,
  totalCents: (json['totalCents'] as num).toInt(),
  paymentMethod: $enumDecode(_$PosPaymentMethodEnumMap, json['paymentMethod']),
  paymentStatus: $enumDecode(_$PaymentStatusEnumMap, json['paymentStatus']),
  stripePaymentId: json['stripePaymentId'] as String?,
  giftCardCode: json['giftCardCode'] as String?,
  splitPayments:
      (json['splitPayments'] as List<dynamic>?)
          ?.map((e) => SplitPaymentDetail.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  cashTenderedCents: (json['cashTenderedCents'] as num?)?.toInt(),
  changeCents: (json['changeCents'] as num?)?.toInt(),
  receiptNumber: json['receiptNumber'] as String?,
  receiptUrl: json['receiptUrl'] as String?,
  receiptEmailed: json['receiptEmailed'] as bool? ?? false,
  notes: json['notes'] as String?,
  isVoided: json['isVoided'] as bool? ?? false,
  voidReason: json['voidReason'] as String?,
  voidedAt: const NullableTimestampConverter().fromJson(json['voidedAt']),
  voidedBy: json['voidedBy'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$PosTransactionToJson(
  _PosTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'transactionDate': const TimestampConverter().toJson(
    instance.transactionDate,
  ),
  'staffId': instance.staffId,
  'staffName': instance.staffName,
  'clientId': instance.clientId,
  'clientName': instance.clientName,
  'appointmentId': instance.appointmentId,
  'lineItems': instance.lineItems.map((e) => e.toJson()).toList(),
  'subtotalCents': instance.subtotalCents,
  'taxCents': instance.taxCents,
  'taxRate': instance.taxRate,
  'discountCents': instance.discountCents,
  'discountReason': instance.discountReason,
  'totalCents': instance.totalCents,
  'paymentMethod': _$PosPaymentMethodEnumMap[instance.paymentMethod]!,
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'stripePaymentId': instance.stripePaymentId,
  'giftCardCode': instance.giftCardCode,
  'splitPayments': instance.splitPayments.map((e) => e.toJson()).toList(),
  'cashTenderedCents': instance.cashTenderedCents,
  'changeCents': instance.changeCents,
  'receiptNumber': instance.receiptNumber,
  'receiptUrl': instance.receiptUrl,
  'receiptEmailed': instance.receiptEmailed,
  'notes': instance.notes,
  'isVoided': instance.isVoided,
  'voidReason': instance.voidReason,
  'voidedAt': const NullableTimestampConverter().toJson(instance.voidedAt),
  'voidedBy': instance.voidedBy,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.none: 'none',
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.partiallyRefunded: 'partially_refunded',
};

_CartItem _$CartItemFromJson(Map<String, dynamic> json) => _CartItem(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  sku: json['sku'] as String?,
  unitPriceCents: (json['unitPriceCents'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  taxable: json['taxable'] as bool? ?? true,
  discountCents: (json['discountCents'] as num?)?.toInt() ?? 0,
  discountReason: json['discountReason'] as String?,
);

Map<String, dynamic> _$CartItemToJson(_CartItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'sku': instance.sku,
  'unitPriceCents': instance.unitPriceCents,
  'quantity': instance.quantity,
  'taxable': instance.taxable,
  'discountCents': instance.discountCents,
  'discountReason': instance.discountReason,
};
