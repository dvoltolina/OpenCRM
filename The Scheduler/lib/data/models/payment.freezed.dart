// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {

/// Unique payment ID
 String get id;/// Business ID
 String get businessId;/// Appointment ID this payment is for
 String get appointmentId;/// Client ID who made the payment
 String get clientId;/// Payment amount in cents (USD)
 int get amountCents;/// Currency code (default USD)
 String get currency;/// Payment status
 PaymentStatus get status;/// Payment type
 PaymentType get type;/// Stripe Payment Intent ID
 String? get stripePaymentIntentId;/// Stripe Charge ID
 String? get stripeChargeId;/// Stripe Refund ID (when money is returned)
 String? get stripeRefundId;/// Last 4 digits of card used (if card payment)
 String? get cardLast4;/// Card brand (visa, mastercard, etc.)
 String? get cardBrand;/// Payment method description
 String? get paymentMethodDescription;/// Date payment was created
@TimestampConverter() DateTime get createdAt;/// Date payment was completed
@NullableTimestampConverter() DateTime? get completedAt;/// Date payment was refunded
@NullableTimestampConverter() DateTime? get refundedAt;/// Refund amount in cents (if refunded)
 int? get refundAmountCents;/// Parent payment ID for related fees or refunds
 String? get parentPaymentId;/// Audit reason/context for this payment (refund reason, etc.)
 String? get reason;/// Error message if payment failed
 String? get errorMessage;/// Notes about the payment
 String? get notes;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&(identical(other.stripeChargeId, stripeChargeId) || other.stripeChargeId == stripeChargeId)&&(identical(other.stripeRefundId, stripeRefundId) || other.stripeRefundId == stripeRefundId)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.cardBrand, cardBrand) || other.cardBrand == cardBrand)&&(identical(other.paymentMethodDescription, paymentMethodDescription) || other.paymentMethodDescription == paymentMethodDescription)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.refundedAt, refundedAt) || other.refundedAt == refundedAt)&&(identical(other.refundAmountCents, refundAmountCents) || other.refundAmountCents == refundAmountCents)&&(identical(other.parentPaymentId, parentPaymentId) || other.parentPaymentId == parentPaymentId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,amountCents,currency,status,type,stripePaymentIntentId,stripeChargeId,stripeRefundId,cardLast4,cardBrand,paymentMethodDescription,createdAt,completedAt,refundedAt,refundAmountCents,parentPaymentId,reason,errorMessage,notes]);

@override
String toString() {
  return 'Payment(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, amountCents: $amountCents, currency: $currency, status: $status, type: $type, stripePaymentIntentId: $stripePaymentIntentId, stripeChargeId: $stripeChargeId, stripeRefundId: $stripeRefundId, cardLast4: $cardLast4, cardBrand: $cardBrand, paymentMethodDescription: $paymentMethodDescription, createdAt: $createdAt, completedAt: $completedAt, refundedAt: $refundedAt, refundAmountCents: $refundAmountCents, parentPaymentId: $parentPaymentId, reason: $reason, errorMessage: $errorMessage, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, int amountCents, String currency, PaymentStatus status, PaymentType type, String? stripePaymentIntentId, String? stripeChargeId, String? stripeRefundId, String? cardLast4, String? cardBrand, String? paymentMethodDescription,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? completedAt,@NullableTimestampConverter() DateTime? refundedAt, int? refundAmountCents, String? parentPaymentId, String? reason, String? errorMessage, String? notes
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? amountCents = null,Object? currency = null,Object? status = null,Object? type = null,Object? stripePaymentIntentId = freezed,Object? stripeChargeId = freezed,Object? stripeRefundId = freezed,Object? cardLast4 = freezed,Object? cardBrand = freezed,Object? paymentMethodDescription = freezed,Object? createdAt = null,Object? completedAt = freezed,Object? refundedAt = freezed,Object? refundAmountCents = freezed,Object? parentPaymentId = freezed,Object? reason = freezed,Object? errorMessage = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PaymentType,stripePaymentIntentId: freezed == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,stripeChargeId: freezed == stripeChargeId ? _self.stripeChargeId : stripeChargeId // ignore: cast_nullable_to_non_nullable
as String?,stripeRefundId: freezed == stripeRefundId ? _self.stripeRefundId : stripeRefundId // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,cardBrand: freezed == cardBrand ? _self.cardBrand : cardBrand // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDescription: freezed == paymentMethodDescription ? _self.paymentMethodDescription : paymentMethodDescription // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundedAt: freezed == refundedAt ? _self.refundedAt : refundedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundAmountCents: freezed == refundAmountCents ? _self.refundAmountCents : refundAmountCents // ignore: cast_nullable_to_non_nullable
as int?,parentPaymentId: freezed == parentPaymentId ? _self.parentPaymentId : parentPaymentId // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  int amountCents,  String currency,  PaymentStatus status,  PaymentType type,  String? stripePaymentIntentId,  String? stripeChargeId,  String? stripeRefundId,  String? cardLast4,  String? cardBrand,  String? paymentMethodDescription, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? completedAt, @NullableTimestampConverter()  DateTime? refundedAt,  int? refundAmountCents,  String? parentPaymentId,  String? reason,  String? errorMessage,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.amountCents,_that.currency,_that.status,_that.type,_that.stripePaymentIntentId,_that.stripeChargeId,_that.stripeRefundId,_that.cardLast4,_that.cardBrand,_that.paymentMethodDescription,_that.createdAt,_that.completedAt,_that.refundedAt,_that.refundAmountCents,_that.parentPaymentId,_that.reason,_that.errorMessage,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  int amountCents,  String currency,  PaymentStatus status,  PaymentType type,  String? stripePaymentIntentId,  String? stripeChargeId,  String? stripeRefundId,  String? cardLast4,  String? cardBrand,  String? paymentMethodDescription, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? completedAt, @NullableTimestampConverter()  DateTime? refundedAt,  int? refundAmountCents,  String? parentPaymentId,  String? reason,  String? errorMessage,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.amountCents,_that.currency,_that.status,_that.type,_that.stripePaymentIntentId,_that.stripeChargeId,_that.stripeRefundId,_that.cardLast4,_that.cardBrand,_that.paymentMethodDescription,_that.createdAt,_that.completedAt,_that.refundedAt,_that.refundAmountCents,_that.parentPaymentId,_that.reason,_that.errorMessage,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  int amountCents,  String currency,  PaymentStatus status,  PaymentType type,  String? stripePaymentIntentId,  String? stripeChargeId,  String? stripeRefundId,  String? cardLast4,  String? cardBrand,  String? paymentMethodDescription, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? completedAt, @NullableTimestampConverter()  DateTime? refundedAt,  int? refundAmountCents,  String? parentPaymentId,  String? reason,  String? errorMessage,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.amountCents,_that.currency,_that.status,_that.type,_that.stripePaymentIntentId,_that.stripeChargeId,_that.stripeRefundId,_that.cardLast4,_that.cardBrand,_that.paymentMethodDescription,_that.createdAt,_that.completedAt,_that.refundedAt,_that.refundAmountCents,_that.parentPaymentId,_that.reason,_that.errorMessage,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payment extends Payment {
  const _Payment({required this.id, required this.businessId, required this.appointmentId, required this.clientId, required this.amountCents, this.currency = 'USD', required this.status, required this.type, this.stripePaymentIntentId, this.stripeChargeId, this.stripeRefundId, this.cardLast4, this.cardBrand, this.paymentMethodDescription, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.completedAt, @NullableTimestampConverter() this.refundedAt, this.refundAmountCents, this.parentPaymentId, this.reason, this.errorMessage, this.notes}): super._();
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

/// Unique payment ID
@override final  String id;
/// Business ID
@override final  String businessId;
/// Appointment ID this payment is for
@override final  String appointmentId;
/// Client ID who made the payment
@override final  String clientId;
/// Payment amount in cents (USD)
@override final  int amountCents;
/// Currency code (default USD)
@override@JsonKey() final  String currency;
/// Payment status
@override final  PaymentStatus status;
/// Payment type
@override final  PaymentType type;
/// Stripe Payment Intent ID
@override final  String? stripePaymentIntentId;
/// Stripe Charge ID
@override final  String? stripeChargeId;
/// Stripe Refund ID (when money is returned)
@override final  String? stripeRefundId;
/// Last 4 digits of card used (if card payment)
@override final  String? cardLast4;
/// Card brand (visa, mastercard, etc.)
@override final  String? cardBrand;
/// Payment method description
@override final  String? paymentMethodDescription;
/// Date payment was created
@override@TimestampConverter() final  DateTime createdAt;
/// Date payment was completed
@override@NullableTimestampConverter() final  DateTime? completedAt;
/// Date payment was refunded
@override@NullableTimestampConverter() final  DateTime? refundedAt;
/// Refund amount in cents (if refunded)
@override final  int? refundAmountCents;
/// Parent payment ID for related fees or refunds
@override final  String? parentPaymentId;
/// Audit reason/context for this payment (refund reason, etc.)
@override final  String? reason;
/// Error message if payment failed
@override final  String? errorMessage;
/// Notes about the payment
@override final  String? notes;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&(identical(other.stripeChargeId, stripeChargeId) || other.stripeChargeId == stripeChargeId)&&(identical(other.stripeRefundId, stripeRefundId) || other.stripeRefundId == stripeRefundId)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.cardBrand, cardBrand) || other.cardBrand == cardBrand)&&(identical(other.paymentMethodDescription, paymentMethodDescription) || other.paymentMethodDescription == paymentMethodDescription)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.refundedAt, refundedAt) || other.refundedAt == refundedAt)&&(identical(other.refundAmountCents, refundAmountCents) || other.refundAmountCents == refundAmountCents)&&(identical(other.parentPaymentId, parentPaymentId) || other.parentPaymentId == parentPaymentId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,amountCents,currency,status,type,stripePaymentIntentId,stripeChargeId,stripeRefundId,cardLast4,cardBrand,paymentMethodDescription,createdAt,completedAt,refundedAt,refundAmountCents,parentPaymentId,reason,errorMessage,notes]);

@override
String toString() {
  return 'Payment(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, amountCents: $amountCents, currency: $currency, status: $status, type: $type, stripePaymentIntentId: $stripePaymentIntentId, stripeChargeId: $stripeChargeId, stripeRefundId: $stripeRefundId, cardLast4: $cardLast4, cardBrand: $cardBrand, paymentMethodDescription: $paymentMethodDescription, createdAt: $createdAt, completedAt: $completedAt, refundedAt: $refundedAt, refundAmountCents: $refundAmountCents, parentPaymentId: $parentPaymentId, reason: $reason, errorMessage: $errorMessage, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, int amountCents, String currency, PaymentStatus status, PaymentType type, String? stripePaymentIntentId, String? stripeChargeId, String? stripeRefundId, String? cardLast4, String? cardBrand, String? paymentMethodDescription,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? completedAt,@NullableTimestampConverter() DateTime? refundedAt, int? refundAmountCents, String? parentPaymentId, String? reason, String? errorMessage, String? notes
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? amountCents = null,Object? currency = null,Object? status = null,Object? type = null,Object? stripePaymentIntentId = freezed,Object? stripeChargeId = freezed,Object? stripeRefundId = freezed,Object? cardLast4 = freezed,Object? cardBrand = freezed,Object? paymentMethodDescription = freezed,Object? createdAt = null,Object? completedAt = freezed,Object? refundedAt = freezed,Object? refundAmountCents = freezed,Object? parentPaymentId = freezed,Object? reason = freezed,Object? errorMessage = freezed,Object? notes = freezed,}) {
  return _then(_Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PaymentType,stripePaymentIntentId: freezed == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,stripeChargeId: freezed == stripeChargeId ? _self.stripeChargeId : stripeChargeId // ignore: cast_nullable_to_non_nullable
as String?,stripeRefundId: freezed == stripeRefundId ? _self.stripeRefundId : stripeRefundId // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,cardBrand: freezed == cardBrand ? _self.cardBrand : cardBrand // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDescription: freezed == paymentMethodDescription ? _self.paymentMethodDescription : paymentMethodDescription // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundedAt: freezed == refundedAt ? _self.refundedAt : refundedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundAmountCents: freezed == refundAmountCents ? _self.refundAmountCents : refundAmountCents // ignore: cast_nullable_to_non_nullable
as int?,parentPaymentId: freezed == parentPaymentId ? _self.parentPaymentId : parentPaymentId // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
