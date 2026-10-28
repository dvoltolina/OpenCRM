// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftCardRedemption {

/// Unique redemption ID
 String get id;/// Gift card ID this redemption belongs to
 String get giftCardId;/// Appointment ID this redemption was applied to
 String get appointmentId;/// Amount redeemed in cents
 int get amountCents;/// When the redemption occurred
@TimestampConverter() DateTime get redeemedAt;/// Client ID who redeemed the gift card
 String get redeemedByClientId;
/// Create a copy of GiftCardRedemption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftCardRedemptionCopyWith<GiftCardRedemption> get copyWith => _$GiftCardRedemptionCopyWithImpl<GiftCardRedemption>(this as GiftCardRedemption, _$identity);

  /// Serializes this GiftCardRedemption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftCardRedemption&&(identical(other.id, id) || other.id == id)&&(identical(other.giftCardId, giftCardId) || other.giftCardId == giftCardId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.redeemedByClientId, redeemedByClientId) || other.redeemedByClientId == redeemedByClientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,giftCardId,appointmentId,amountCents,redeemedAt,redeemedByClientId);

@override
String toString() {
  return 'GiftCardRedemption(id: $id, giftCardId: $giftCardId, appointmentId: $appointmentId, amountCents: $amountCents, redeemedAt: $redeemedAt, redeemedByClientId: $redeemedByClientId)';
}


}

/// @nodoc
abstract mixin class $GiftCardRedemptionCopyWith<$Res>  {
  factory $GiftCardRedemptionCopyWith(GiftCardRedemption value, $Res Function(GiftCardRedemption) _then) = _$GiftCardRedemptionCopyWithImpl;
@useResult
$Res call({
 String id, String giftCardId, String appointmentId, int amountCents,@TimestampConverter() DateTime redeemedAt, String redeemedByClientId
});




}
/// @nodoc
class _$GiftCardRedemptionCopyWithImpl<$Res>
    implements $GiftCardRedemptionCopyWith<$Res> {
  _$GiftCardRedemptionCopyWithImpl(this._self, this._then);

  final GiftCardRedemption _self;
  final $Res Function(GiftCardRedemption) _then;

/// Create a copy of GiftCardRedemption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? giftCardId = null,Object? appointmentId = null,Object? amountCents = null,Object? redeemedAt = null,Object? redeemedByClientId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,giftCardId: null == giftCardId ? _self.giftCardId : giftCardId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,redeemedAt: null == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime,redeemedByClientId: null == redeemedByClientId ? _self.redeemedByClientId : redeemedByClientId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftCardRedemption].
extension GiftCardRedemptionPatterns on GiftCardRedemption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftCardRedemption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftCardRedemption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftCardRedemption value)  $default,){
final _that = this;
switch (_that) {
case _GiftCardRedemption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftCardRedemption value)?  $default,){
final _that = this;
switch (_that) {
case _GiftCardRedemption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String giftCardId,  String appointmentId,  int amountCents, @TimestampConverter()  DateTime redeemedAt,  String redeemedByClientId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftCardRedemption() when $default != null:
return $default(_that.id,_that.giftCardId,_that.appointmentId,_that.amountCents,_that.redeemedAt,_that.redeemedByClientId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String giftCardId,  String appointmentId,  int amountCents, @TimestampConverter()  DateTime redeemedAt,  String redeemedByClientId)  $default,) {final _that = this;
switch (_that) {
case _GiftCardRedemption():
return $default(_that.id,_that.giftCardId,_that.appointmentId,_that.amountCents,_that.redeemedAt,_that.redeemedByClientId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String giftCardId,  String appointmentId,  int amountCents, @TimestampConverter()  DateTime redeemedAt,  String redeemedByClientId)?  $default,) {final _that = this;
switch (_that) {
case _GiftCardRedemption() when $default != null:
return $default(_that.id,_that.giftCardId,_that.appointmentId,_that.amountCents,_that.redeemedAt,_that.redeemedByClientId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftCardRedemption extends GiftCardRedemption {
  const _GiftCardRedemption({required this.id, required this.giftCardId, required this.appointmentId, required this.amountCents, @TimestampConverter() required this.redeemedAt, required this.redeemedByClientId}): super._();
  factory _GiftCardRedemption.fromJson(Map<String, dynamic> json) => _$GiftCardRedemptionFromJson(json);

/// Unique redemption ID
@override final  String id;
/// Gift card ID this redemption belongs to
@override final  String giftCardId;
/// Appointment ID this redemption was applied to
@override final  String appointmentId;
/// Amount redeemed in cents
@override final  int amountCents;
/// When the redemption occurred
@override@TimestampConverter() final  DateTime redeemedAt;
/// Client ID who redeemed the gift card
@override final  String redeemedByClientId;

/// Create a copy of GiftCardRedemption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftCardRedemptionCopyWith<_GiftCardRedemption> get copyWith => __$GiftCardRedemptionCopyWithImpl<_GiftCardRedemption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftCardRedemptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftCardRedemption&&(identical(other.id, id) || other.id == id)&&(identical(other.giftCardId, giftCardId) || other.giftCardId == giftCardId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.redeemedByClientId, redeemedByClientId) || other.redeemedByClientId == redeemedByClientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,giftCardId,appointmentId,amountCents,redeemedAt,redeemedByClientId);

@override
String toString() {
  return 'GiftCardRedemption(id: $id, giftCardId: $giftCardId, appointmentId: $appointmentId, amountCents: $amountCents, redeemedAt: $redeemedAt, redeemedByClientId: $redeemedByClientId)';
}


}

/// @nodoc
abstract mixin class _$GiftCardRedemptionCopyWith<$Res> implements $GiftCardRedemptionCopyWith<$Res> {
  factory _$GiftCardRedemptionCopyWith(_GiftCardRedemption value, $Res Function(_GiftCardRedemption) _then) = __$GiftCardRedemptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String giftCardId, String appointmentId, int amountCents,@TimestampConverter() DateTime redeemedAt, String redeemedByClientId
});




}
/// @nodoc
class __$GiftCardRedemptionCopyWithImpl<$Res>
    implements _$GiftCardRedemptionCopyWith<$Res> {
  __$GiftCardRedemptionCopyWithImpl(this._self, this._then);

  final _GiftCardRedemption _self;
  final $Res Function(_GiftCardRedemption) _then;

/// Create a copy of GiftCardRedemption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? giftCardId = null,Object? appointmentId = null,Object? amountCents = null,Object? redeemedAt = null,Object? redeemedByClientId = null,}) {
  return _then(_GiftCardRedemption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,giftCardId: null == giftCardId ? _self.giftCardId : giftCardId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,redeemedAt: null == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime,redeemedByClientId: null == redeemedByClientId ? _self.redeemedByClientId : redeemedByClientId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GiftCard {

/// Unique gift card ID
 String get id;/// Business ID this gift card belongs to
 String get businessId;/// Unique redemption code (e.g., "GIFT-ABCD-1234")
 String get code;/// Original amount in cents
 int get originalAmountCents;/// Remaining balance in cents
 int get remainingBalanceCents;/// Currency code (default USD)
 String get currency;/// Gift card status
 GiftCardStatus get status;/// When the gift card was activated (payment completed)
@NullableTimestampConverter() DateTime? get activatedAt;/// When the gift card expires (null = never expires)
@NullableTimestampConverter() DateTime? get expiresAt;/// Purchaser email address
 String get purchaserEmail;/// Purchaser name (optional)
 String? get purchaserName;/// When the gift card was purchased
@TimestampConverter() DateTime get purchasedAt;/// Stripe payment ID
 String? get paymentId;/// Recipient email address (for emailed cards)
 String? get recipientEmail;/// Recipient name
 String? get recipientName;/// Personal message from purchaser to recipient
 String? get personalMessage;/// Whether the gift card email was delivered successfully
 bool get delivered;/// When the gift card was created
@TimestampConverter() DateTime get createdAt;/// When the gift card was last redeemed
@NullableTimestampConverter() DateTime? get lastRedeemedAt;/// List of redemptions against this gift card
 List<GiftCardRedemption> get redemptions;/// Selected design template ID
 String? get templateId;/// Custom image URL (overrides template)
 String? get customImageUrl;
/// Create a copy of GiftCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftCardCopyWith<GiftCard> get copyWith => _$GiftCardCopyWithImpl<GiftCard>(this as GiftCard, _$identity);

  /// Serializes this GiftCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftCard&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.code, code) || other.code == code)&&(identical(other.originalAmountCents, originalAmountCents) || other.originalAmountCents == originalAmountCents)&&(identical(other.remainingBalanceCents, remainingBalanceCents) || other.remainingBalanceCents == remainingBalanceCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.purchaserEmail, purchaserEmail) || other.purchaserEmail == purchaserEmail)&&(identical(other.purchaserName, purchaserName) || other.purchaserName == purchaserName)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.recipientEmail, recipientEmail) || other.recipientEmail == recipientEmail)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalMessage, personalMessage) || other.personalMessage == personalMessage)&&(identical(other.delivered, delivered) || other.delivered == delivered)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRedeemedAt, lastRedeemedAt) || other.lastRedeemedAt == lastRedeemedAt)&&const DeepCollectionEquality().equals(other.redemptions, redemptions)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.customImageUrl, customImageUrl) || other.customImageUrl == customImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,code,originalAmountCents,remainingBalanceCents,currency,status,activatedAt,expiresAt,purchaserEmail,purchaserName,purchasedAt,paymentId,recipientEmail,recipientName,personalMessage,delivered,createdAt,lastRedeemedAt,const DeepCollectionEquality().hash(redemptions),templateId,customImageUrl]);

@override
String toString() {
  return 'GiftCard(id: $id, businessId: $businessId, code: $code, originalAmountCents: $originalAmountCents, remainingBalanceCents: $remainingBalanceCents, currency: $currency, status: $status, activatedAt: $activatedAt, expiresAt: $expiresAt, purchaserEmail: $purchaserEmail, purchaserName: $purchaserName, purchasedAt: $purchasedAt, paymentId: $paymentId, recipientEmail: $recipientEmail, recipientName: $recipientName, personalMessage: $personalMessage, delivered: $delivered, createdAt: $createdAt, lastRedeemedAt: $lastRedeemedAt, redemptions: $redemptions, templateId: $templateId, customImageUrl: $customImageUrl)';
}


}

/// @nodoc
abstract mixin class $GiftCardCopyWith<$Res>  {
  factory $GiftCardCopyWith(GiftCard value, $Res Function(GiftCard) _then) = _$GiftCardCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String code, int originalAmountCents, int remainingBalanceCents, String currency, GiftCardStatus status,@NullableTimestampConverter() DateTime? activatedAt,@NullableTimestampConverter() DateTime? expiresAt, String purchaserEmail, String? purchaserName,@TimestampConverter() DateTime purchasedAt, String? paymentId, String? recipientEmail, String? recipientName, String? personalMessage, bool delivered,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? lastRedeemedAt, List<GiftCardRedemption> redemptions, String? templateId, String? customImageUrl
});




}
/// @nodoc
class _$GiftCardCopyWithImpl<$Res>
    implements $GiftCardCopyWith<$Res> {
  _$GiftCardCopyWithImpl(this._self, this._then);

  final GiftCard _self;
  final $Res Function(GiftCard) _then;

/// Create a copy of GiftCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? code = null,Object? originalAmountCents = null,Object? remainingBalanceCents = null,Object? currency = null,Object? status = null,Object? activatedAt = freezed,Object? expiresAt = freezed,Object? purchaserEmail = null,Object? purchaserName = freezed,Object? purchasedAt = null,Object? paymentId = freezed,Object? recipientEmail = freezed,Object? recipientName = freezed,Object? personalMessage = freezed,Object? delivered = null,Object? createdAt = null,Object? lastRedeemedAt = freezed,Object? redemptions = null,Object? templateId = freezed,Object? customImageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,originalAmountCents: null == originalAmountCents ? _self.originalAmountCents : originalAmountCents // ignore: cast_nullable_to_non_nullable
as int,remainingBalanceCents: null == remainingBalanceCents ? _self.remainingBalanceCents : remainingBalanceCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GiftCardStatus,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchaserEmail: null == purchaserEmail ? _self.purchaserEmail : purchaserEmail // ignore: cast_nullable_to_non_nullable
as String,purchaserName: freezed == purchaserName ? _self.purchaserName : purchaserName // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,recipientEmail: freezed == recipientEmail ? _self.recipientEmail : recipientEmail // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalMessage: freezed == personalMessage ? _self.personalMessage : personalMessage // ignore: cast_nullable_to_non_nullable
as String?,delivered: null == delivered ? _self.delivered : delivered // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastRedeemedAt: freezed == lastRedeemedAt ? _self.lastRedeemedAt : lastRedeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,redemptions: null == redemptions ? _self.redemptions : redemptions // ignore: cast_nullable_to_non_nullable
as List<GiftCardRedemption>,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,customImageUrl: freezed == customImageUrl ? _self.customImageUrl : customImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftCard].
extension GiftCardPatterns on GiftCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftCard value)  $default,){
final _that = this;
switch (_that) {
case _GiftCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftCard value)?  $default,){
final _that = this;
switch (_that) {
case _GiftCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String code,  int originalAmountCents,  int remainingBalanceCents,  String currency,  GiftCardStatus status, @NullableTimestampConverter()  DateTime? activatedAt, @NullableTimestampConverter()  DateTime? expiresAt,  String purchaserEmail,  String? purchaserName, @TimestampConverter()  DateTime purchasedAt,  String? paymentId,  String? recipientEmail,  String? recipientName,  String? personalMessage,  bool delivered, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? lastRedeemedAt,  List<GiftCardRedemption> redemptions,  String? templateId,  String? customImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftCard() when $default != null:
return $default(_that.id,_that.businessId,_that.code,_that.originalAmountCents,_that.remainingBalanceCents,_that.currency,_that.status,_that.activatedAt,_that.expiresAt,_that.purchaserEmail,_that.purchaserName,_that.purchasedAt,_that.paymentId,_that.recipientEmail,_that.recipientName,_that.personalMessage,_that.delivered,_that.createdAt,_that.lastRedeemedAt,_that.redemptions,_that.templateId,_that.customImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String code,  int originalAmountCents,  int remainingBalanceCents,  String currency,  GiftCardStatus status, @NullableTimestampConverter()  DateTime? activatedAt, @NullableTimestampConverter()  DateTime? expiresAt,  String purchaserEmail,  String? purchaserName, @TimestampConverter()  DateTime purchasedAt,  String? paymentId,  String? recipientEmail,  String? recipientName,  String? personalMessage,  bool delivered, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? lastRedeemedAt,  List<GiftCardRedemption> redemptions,  String? templateId,  String? customImageUrl)  $default,) {final _that = this;
switch (_that) {
case _GiftCard():
return $default(_that.id,_that.businessId,_that.code,_that.originalAmountCents,_that.remainingBalanceCents,_that.currency,_that.status,_that.activatedAt,_that.expiresAt,_that.purchaserEmail,_that.purchaserName,_that.purchasedAt,_that.paymentId,_that.recipientEmail,_that.recipientName,_that.personalMessage,_that.delivered,_that.createdAt,_that.lastRedeemedAt,_that.redemptions,_that.templateId,_that.customImageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String code,  int originalAmountCents,  int remainingBalanceCents,  String currency,  GiftCardStatus status, @NullableTimestampConverter()  DateTime? activatedAt, @NullableTimestampConverter()  DateTime? expiresAt,  String purchaserEmail,  String? purchaserName, @TimestampConverter()  DateTime purchasedAt,  String? paymentId,  String? recipientEmail,  String? recipientName,  String? personalMessage,  bool delivered, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? lastRedeemedAt,  List<GiftCardRedemption> redemptions,  String? templateId,  String? customImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _GiftCard() when $default != null:
return $default(_that.id,_that.businessId,_that.code,_that.originalAmountCents,_that.remainingBalanceCents,_that.currency,_that.status,_that.activatedAt,_that.expiresAt,_that.purchaserEmail,_that.purchaserName,_that.purchasedAt,_that.paymentId,_that.recipientEmail,_that.recipientName,_that.personalMessage,_that.delivered,_that.createdAt,_that.lastRedeemedAt,_that.redemptions,_that.templateId,_that.customImageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftCard extends GiftCard {
  const _GiftCard({required this.id, required this.businessId, required this.code, required this.originalAmountCents, required this.remainingBalanceCents, this.currency = 'usd', required this.status, @NullableTimestampConverter() this.activatedAt, @NullableTimestampConverter() this.expiresAt, required this.purchaserEmail, this.purchaserName, @TimestampConverter() required this.purchasedAt, this.paymentId, this.recipientEmail, this.recipientName, this.personalMessage, this.delivered = false, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.lastRedeemedAt, final  List<GiftCardRedemption> redemptions = const [], this.templateId, this.customImageUrl}): _redemptions = redemptions,super._();
  factory _GiftCard.fromJson(Map<String, dynamic> json) => _$GiftCardFromJson(json);

/// Unique gift card ID
@override final  String id;
/// Business ID this gift card belongs to
@override final  String businessId;
/// Unique redemption code (e.g., "GIFT-ABCD-1234")
@override final  String code;
/// Original amount in cents
@override final  int originalAmountCents;
/// Remaining balance in cents
@override final  int remainingBalanceCents;
/// Currency code (default USD)
@override@JsonKey() final  String currency;
/// Gift card status
@override final  GiftCardStatus status;
/// When the gift card was activated (payment completed)
@override@NullableTimestampConverter() final  DateTime? activatedAt;
/// When the gift card expires (null = never expires)
@override@NullableTimestampConverter() final  DateTime? expiresAt;
/// Purchaser email address
@override final  String purchaserEmail;
/// Purchaser name (optional)
@override final  String? purchaserName;
/// When the gift card was purchased
@override@TimestampConverter() final  DateTime purchasedAt;
/// Stripe payment ID
@override final  String? paymentId;
/// Recipient email address (for emailed cards)
@override final  String? recipientEmail;
/// Recipient name
@override final  String? recipientName;
/// Personal message from purchaser to recipient
@override final  String? personalMessage;
/// Whether the gift card email was delivered successfully
@override@JsonKey() final  bool delivered;
/// When the gift card was created
@override@TimestampConverter() final  DateTime createdAt;
/// When the gift card was last redeemed
@override@NullableTimestampConverter() final  DateTime? lastRedeemedAt;
/// List of redemptions against this gift card
 final  List<GiftCardRedemption> _redemptions;
/// List of redemptions against this gift card
@override@JsonKey() List<GiftCardRedemption> get redemptions {
  if (_redemptions is EqualUnmodifiableListView) return _redemptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redemptions);
}

/// Selected design template ID
@override final  String? templateId;
/// Custom image URL (overrides template)
@override final  String? customImageUrl;

/// Create a copy of GiftCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftCardCopyWith<_GiftCard> get copyWith => __$GiftCardCopyWithImpl<_GiftCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftCard&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.code, code) || other.code == code)&&(identical(other.originalAmountCents, originalAmountCents) || other.originalAmountCents == originalAmountCents)&&(identical(other.remainingBalanceCents, remainingBalanceCents) || other.remainingBalanceCents == remainingBalanceCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.purchaserEmail, purchaserEmail) || other.purchaserEmail == purchaserEmail)&&(identical(other.purchaserName, purchaserName) || other.purchaserName == purchaserName)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.recipientEmail, recipientEmail) || other.recipientEmail == recipientEmail)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalMessage, personalMessage) || other.personalMessage == personalMessage)&&(identical(other.delivered, delivered) || other.delivered == delivered)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastRedeemedAt, lastRedeemedAt) || other.lastRedeemedAt == lastRedeemedAt)&&const DeepCollectionEquality().equals(other._redemptions, _redemptions)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.customImageUrl, customImageUrl) || other.customImageUrl == customImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,code,originalAmountCents,remainingBalanceCents,currency,status,activatedAt,expiresAt,purchaserEmail,purchaserName,purchasedAt,paymentId,recipientEmail,recipientName,personalMessage,delivered,createdAt,lastRedeemedAt,const DeepCollectionEquality().hash(_redemptions),templateId,customImageUrl]);

@override
String toString() {
  return 'GiftCard(id: $id, businessId: $businessId, code: $code, originalAmountCents: $originalAmountCents, remainingBalanceCents: $remainingBalanceCents, currency: $currency, status: $status, activatedAt: $activatedAt, expiresAt: $expiresAt, purchaserEmail: $purchaserEmail, purchaserName: $purchaserName, purchasedAt: $purchasedAt, paymentId: $paymentId, recipientEmail: $recipientEmail, recipientName: $recipientName, personalMessage: $personalMessage, delivered: $delivered, createdAt: $createdAt, lastRedeemedAt: $lastRedeemedAt, redemptions: $redemptions, templateId: $templateId, customImageUrl: $customImageUrl)';
}


}

/// @nodoc
abstract mixin class _$GiftCardCopyWith<$Res> implements $GiftCardCopyWith<$Res> {
  factory _$GiftCardCopyWith(_GiftCard value, $Res Function(_GiftCard) _then) = __$GiftCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String code, int originalAmountCents, int remainingBalanceCents, String currency, GiftCardStatus status,@NullableTimestampConverter() DateTime? activatedAt,@NullableTimestampConverter() DateTime? expiresAt, String purchaserEmail, String? purchaserName,@TimestampConverter() DateTime purchasedAt, String? paymentId, String? recipientEmail, String? recipientName, String? personalMessage, bool delivered,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? lastRedeemedAt, List<GiftCardRedemption> redemptions, String? templateId, String? customImageUrl
});




}
/// @nodoc
class __$GiftCardCopyWithImpl<$Res>
    implements _$GiftCardCopyWith<$Res> {
  __$GiftCardCopyWithImpl(this._self, this._then);

  final _GiftCard _self;
  final $Res Function(_GiftCard) _then;

/// Create a copy of GiftCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? code = null,Object? originalAmountCents = null,Object? remainingBalanceCents = null,Object? currency = null,Object? status = null,Object? activatedAt = freezed,Object? expiresAt = freezed,Object? purchaserEmail = null,Object? purchaserName = freezed,Object? purchasedAt = null,Object? paymentId = freezed,Object? recipientEmail = freezed,Object? recipientName = freezed,Object? personalMessage = freezed,Object? delivered = null,Object? createdAt = null,Object? lastRedeemedAt = freezed,Object? redemptions = null,Object? templateId = freezed,Object? customImageUrl = freezed,}) {
  return _then(_GiftCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,originalAmountCents: null == originalAmountCents ? _self.originalAmountCents : originalAmountCents // ignore: cast_nullable_to_non_nullable
as int,remainingBalanceCents: null == remainingBalanceCents ? _self.remainingBalanceCents : remainingBalanceCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GiftCardStatus,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchaserEmail: null == purchaserEmail ? _self.purchaserEmail : purchaserEmail // ignore: cast_nullable_to_non_nullable
as String,purchaserName: freezed == purchaserName ? _self.purchaserName : purchaserName // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,recipientEmail: freezed == recipientEmail ? _self.recipientEmail : recipientEmail // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalMessage: freezed == personalMessage ? _self.personalMessage : personalMessage // ignore: cast_nullable_to_non_nullable
as String?,delivered: null == delivered ? _self.delivered : delivered // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastRedeemedAt: freezed == lastRedeemedAt ? _self.lastRedeemedAt : lastRedeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,redemptions: null == redemptions ? _self._redemptions : redemptions // ignore: cast_nullable_to_non_nullable
as List<GiftCardRedemption>,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,customImageUrl: freezed == customImageUrl ? _self.customImageUrl : customImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
