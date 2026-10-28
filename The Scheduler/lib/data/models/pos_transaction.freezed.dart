// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PosLineItem {

/// Product ID
 String get productId;/// Product name (denormalized for receipt)
 String get productName;/// SKU (denormalized for receipt)
 String? get sku;/// Quantity purchased
 int get quantity;/// Unit price in cents at time of sale
 int get unitPriceCents;/// Total for this line item in cents (quantity * unitPrice - discount)
 int get totalCents;/// Discount applied to this line item in cents
 int get discountCents;/// Reason for discount if applied
 String? get discountReason;/// Tax amount for this line item in cents
 int get taxCents;/// Whether this item is taxable
 bool get taxable;
/// Create a copy of PosLineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PosLineItemCopyWith<PosLineItem> get copyWith => _$PosLineItemCopyWithImpl<PosLineItem>(this as PosLineItem, _$identity);

  /// Serializes this PosLineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PosLineItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.taxable, taxable) || other.taxable == taxable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,unitPriceCents,totalCents,discountCents,discountReason,taxCents,taxable);

@override
String toString() {
  return 'PosLineItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, unitPriceCents: $unitPriceCents, totalCents: $totalCents, discountCents: $discountCents, discountReason: $discountReason, taxCents: $taxCents, taxable: $taxable)';
}


}

/// @nodoc
abstract mixin class $PosLineItemCopyWith<$Res>  {
  factory $PosLineItemCopyWith(PosLineItem value, $Res Function(PosLineItem) _then) = _$PosLineItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, String? sku, int quantity, int unitPriceCents, int totalCents, int discountCents, String? discountReason, int taxCents, bool taxable
});




}
/// @nodoc
class _$PosLineItemCopyWithImpl<$Res>
    implements $PosLineItemCopyWith<$Res> {
  _$PosLineItemCopyWithImpl(this._self, this._then);

  final PosLineItem _self;
  final $Res Function(PosLineItem) _then;

/// Create a copy of PosLineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? sku = freezed,Object? quantity = null,Object? unitPriceCents = null,Object? totalCents = null,Object? discountCents = null,Object? discountReason = freezed,Object? taxCents = null,Object? taxable = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PosLineItem].
extension PosLineItemPatterns on PosLineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PosLineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PosLineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PosLineItem value)  $default,){
final _that = this;
switch (_that) {
case _PosLineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PosLineItem value)?  $default,){
final _that = this;
switch (_that) {
case _PosLineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  String? sku,  int quantity,  int unitPriceCents,  int totalCents,  int discountCents,  String? discountReason,  int taxCents,  bool taxable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PosLineItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.unitPriceCents,_that.totalCents,_that.discountCents,_that.discountReason,_that.taxCents,_that.taxable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  String? sku,  int quantity,  int unitPriceCents,  int totalCents,  int discountCents,  String? discountReason,  int taxCents,  bool taxable)  $default,) {final _that = this;
switch (_that) {
case _PosLineItem():
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.unitPriceCents,_that.totalCents,_that.discountCents,_that.discountReason,_that.taxCents,_that.taxable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  String? sku,  int quantity,  int unitPriceCents,  int totalCents,  int discountCents,  String? discountReason,  int taxCents,  bool taxable)?  $default,) {final _that = this;
switch (_that) {
case _PosLineItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.unitPriceCents,_that.totalCents,_that.discountCents,_that.discountReason,_that.taxCents,_that.taxable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PosLineItem extends PosLineItem {
  const _PosLineItem({required this.productId, required this.productName, this.sku, required this.quantity, required this.unitPriceCents, required this.totalCents, this.discountCents = 0, this.discountReason, this.taxCents = 0, this.taxable = true}): super._();
  factory _PosLineItem.fromJson(Map<String, dynamic> json) => _$PosLineItemFromJson(json);

/// Product ID
@override final  String productId;
/// Product name (denormalized for receipt)
@override final  String productName;
/// SKU (denormalized for receipt)
@override final  String? sku;
/// Quantity purchased
@override final  int quantity;
/// Unit price in cents at time of sale
@override final  int unitPriceCents;
/// Total for this line item in cents (quantity * unitPrice - discount)
@override final  int totalCents;
/// Discount applied to this line item in cents
@override@JsonKey() final  int discountCents;
/// Reason for discount if applied
@override final  String? discountReason;
/// Tax amount for this line item in cents
@override@JsonKey() final  int taxCents;
/// Whether this item is taxable
@override@JsonKey() final  bool taxable;

/// Create a copy of PosLineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PosLineItemCopyWith<_PosLineItem> get copyWith => __$PosLineItemCopyWithImpl<_PosLineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PosLineItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PosLineItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.taxable, taxable) || other.taxable == taxable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,unitPriceCents,totalCents,discountCents,discountReason,taxCents,taxable);

@override
String toString() {
  return 'PosLineItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, unitPriceCents: $unitPriceCents, totalCents: $totalCents, discountCents: $discountCents, discountReason: $discountReason, taxCents: $taxCents, taxable: $taxable)';
}


}

/// @nodoc
abstract mixin class _$PosLineItemCopyWith<$Res> implements $PosLineItemCopyWith<$Res> {
  factory _$PosLineItemCopyWith(_PosLineItem value, $Res Function(_PosLineItem) _then) = __$PosLineItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, String? sku, int quantity, int unitPriceCents, int totalCents, int discountCents, String? discountReason, int taxCents, bool taxable
});




}
/// @nodoc
class __$PosLineItemCopyWithImpl<$Res>
    implements _$PosLineItemCopyWith<$Res> {
  __$PosLineItemCopyWithImpl(this._self, this._then);

  final _PosLineItem _self;
  final $Res Function(_PosLineItem) _then;

/// Create a copy of PosLineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? sku = freezed,Object? quantity = null,Object? unitPriceCents = null,Object? totalCents = null,Object? discountCents = null,Object? discountReason = freezed,Object? taxCents = null,Object? taxable = null,}) {
  return _then(_PosLineItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SplitPaymentDetail {

/// Payment method for this split
 PosPaymentMethod get method;/// Amount in cents for this split
 int get amountCents;/// Reference (card last 4, gift card code, etc.)
 String? get reference;/// Stripe payment ID if card
 String? get stripePaymentId;/// Gift card code if gift card
 String? get giftCardCode;
/// Create a copy of SplitPaymentDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitPaymentDetailCopyWith<SplitPaymentDetail> get copyWith => _$SplitPaymentDetailCopyWithImpl<SplitPaymentDetail>(this as SplitPaymentDetail, _$identity);

  /// Serializes this SplitPaymentDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitPaymentDetail&&(identical(other.method, method) || other.method == method)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.stripePaymentId, stripePaymentId) || other.stripePaymentId == stripePaymentId)&&(identical(other.giftCardCode, giftCardCode) || other.giftCardCode == giftCardCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,amountCents,reference,stripePaymentId,giftCardCode);

@override
String toString() {
  return 'SplitPaymentDetail(method: $method, amountCents: $amountCents, reference: $reference, stripePaymentId: $stripePaymentId, giftCardCode: $giftCardCode)';
}


}

/// @nodoc
abstract mixin class $SplitPaymentDetailCopyWith<$Res>  {
  factory $SplitPaymentDetailCopyWith(SplitPaymentDetail value, $Res Function(SplitPaymentDetail) _then) = _$SplitPaymentDetailCopyWithImpl;
@useResult
$Res call({
 PosPaymentMethod method, int amountCents, String? reference, String? stripePaymentId, String? giftCardCode
});




}
/// @nodoc
class _$SplitPaymentDetailCopyWithImpl<$Res>
    implements $SplitPaymentDetailCopyWith<$Res> {
  _$SplitPaymentDetailCopyWithImpl(this._self, this._then);

  final SplitPaymentDetail _self;
  final $Res Function(SplitPaymentDetail) _then;

/// Create a copy of SplitPaymentDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? amountCents = null,Object? reference = freezed,Object? stripePaymentId = freezed,Object? giftCardCode = freezed,}) {
  return _then(_self.copyWith(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PosPaymentMethod,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,stripePaymentId: freezed == stripePaymentId ? _self.stripePaymentId : stripePaymentId // ignore: cast_nullable_to_non_nullable
as String?,giftCardCode: freezed == giftCardCode ? _self.giftCardCode : giftCardCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitPaymentDetail].
extension SplitPaymentDetailPatterns on SplitPaymentDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitPaymentDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitPaymentDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitPaymentDetail value)  $default,){
final _that = this;
switch (_that) {
case _SplitPaymentDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitPaymentDetail value)?  $default,){
final _that = this;
switch (_that) {
case _SplitPaymentDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PosPaymentMethod method,  int amountCents,  String? reference,  String? stripePaymentId,  String? giftCardCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitPaymentDetail() when $default != null:
return $default(_that.method,_that.amountCents,_that.reference,_that.stripePaymentId,_that.giftCardCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PosPaymentMethod method,  int amountCents,  String? reference,  String? stripePaymentId,  String? giftCardCode)  $default,) {final _that = this;
switch (_that) {
case _SplitPaymentDetail():
return $default(_that.method,_that.amountCents,_that.reference,_that.stripePaymentId,_that.giftCardCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PosPaymentMethod method,  int amountCents,  String? reference,  String? stripePaymentId,  String? giftCardCode)?  $default,) {final _that = this;
switch (_that) {
case _SplitPaymentDetail() when $default != null:
return $default(_that.method,_that.amountCents,_that.reference,_that.stripePaymentId,_that.giftCardCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitPaymentDetail extends SplitPaymentDetail {
  const _SplitPaymentDetail({required this.method, required this.amountCents, this.reference, this.stripePaymentId, this.giftCardCode}): super._();
  factory _SplitPaymentDetail.fromJson(Map<String, dynamic> json) => _$SplitPaymentDetailFromJson(json);

/// Payment method for this split
@override final  PosPaymentMethod method;
/// Amount in cents for this split
@override final  int amountCents;
/// Reference (card last 4, gift card code, etc.)
@override final  String? reference;
/// Stripe payment ID if card
@override final  String? stripePaymentId;
/// Gift card code if gift card
@override final  String? giftCardCode;

/// Create a copy of SplitPaymentDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitPaymentDetailCopyWith<_SplitPaymentDetail> get copyWith => __$SplitPaymentDetailCopyWithImpl<_SplitPaymentDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitPaymentDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitPaymentDetail&&(identical(other.method, method) || other.method == method)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.stripePaymentId, stripePaymentId) || other.stripePaymentId == stripePaymentId)&&(identical(other.giftCardCode, giftCardCode) || other.giftCardCode == giftCardCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,amountCents,reference,stripePaymentId,giftCardCode);

@override
String toString() {
  return 'SplitPaymentDetail(method: $method, amountCents: $amountCents, reference: $reference, stripePaymentId: $stripePaymentId, giftCardCode: $giftCardCode)';
}


}

/// @nodoc
abstract mixin class _$SplitPaymentDetailCopyWith<$Res> implements $SplitPaymentDetailCopyWith<$Res> {
  factory _$SplitPaymentDetailCopyWith(_SplitPaymentDetail value, $Res Function(_SplitPaymentDetail) _then) = __$SplitPaymentDetailCopyWithImpl;
@override @useResult
$Res call({
 PosPaymentMethod method, int amountCents, String? reference, String? stripePaymentId, String? giftCardCode
});




}
/// @nodoc
class __$SplitPaymentDetailCopyWithImpl<$Res>
    implements _$SplitPaymentDetailCopyWith<$Res> {
  __$SplitPaymentDetailCopyWithImpl(this._self, this._then);

  final _SplitPaymentDetail _self;
  final $Res Function(_SplitPaymentDetail) _then;

/// Create a copy of SplitPaymentDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? amountCents = null,Object? reference = freezed,Object? stripePaymentId = freezed,Object? giftCardCode = freezed,}) {
  return _then(_SplitPaymentDetail(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PosPaymentMethod,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,stripePaymentId: freezed == stripePaymentId ? _self.stripePaymentId : stripePaymentId // ignore: cast_nullable_to_non_nullable
as String?,giftCardCode: freezed == giftCardCode ? _self.giftCardCode : giftCardCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PosTransaction {

/// Unique transaction ID
 String get id;/// Business ID
 String get businessId;/// Transaction date and time
@TimestampConverter() DateTime get transactionDate;/// Staff ID who processed the sale
 String get staffId;/// Staff name (denormalized for display)
 String? get staffName;/// Optional client ID (null for walk-in)
 String? get clientId;/// Client name (denormalized for receipt)
 String? get clientName;/// Optional linked appointment ID (if sold during appointment)
 String? get appointmentId;/// Line items in this transaction
 List<PosLineItem> get lineItems;/// Subtotal in cents (sum of line item totals before tax)
 int get subtotalCents;/// Tax amount in cents
 int get taxCents;/// Tax rate applied (e.g., 0.0825 for 8.25%)
 double get taxRate;/// Discount on entire transaction in cents
 int get discountCents;/// Discount reason if applied
 String? get discountReason;/// Total in cents (subtotal + tax - discount)
 int get totalCents;/// Primary payment method
 PosPaymentMethod get paymentMethod;/// Payment status
 PaymentStatus get paymentStatus;/// Stripe Payment Intent ID (if card payment)
 String? get stripePaymentId;/// Gift card code (if gift card payment)
 String? get giftCardCode;/// Split payment details (if split payment)
 List<SplitPaymentDetail> get splitPayments;/// Cash tendered (for cash payments)
 int? get cashTenderedCents;/// Change given (for cash payments)
 int? get changeCents;/// Receipt number for customer reference
 String? get receiptNumber;/// Receipt URL (PDF or email link)
 String? get receiptUrl;/// Whether receipt was emailed to customer
 bool get receiptEmailed;/// Internal notes about the transaction
 String? get notes;/// Whether transaction was voided
 bool get isVoided;/// Void reason if voided
 String? get voidReason;/// When transaction was voided
@NullableTimestampConverter() DateTime? get voidedAt;/// Who voided the transaction
 String? get voidedBy;/// When the transaction was created
@TimestampConverter() DateTime get createdAt;/// When the transaction was last updated
@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of PosTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PosTransactionCopyWith<PosTransaction> get copyWith => _$PosTransactionCopyWithImpl<PosTransaction>(this as PosTransaction, _$identity);

  /// Serializes this PosTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PosTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.staffName, staffName) || other.staffName == staffName)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&const DeepCollectionEquality().equals(other.lineItems, lineItems)&&(identical(other.subtotalCents, subtotalCents) || other.subtotalCents == subtotalCents)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.taxRate, taxRate) || other.taxRate == taxRate)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.stripePaymentId, stripePaymentId) || other.stripePaymentId == stripePaymentId)&&(identical(other.giftCardCode, giftCardCode) || other.giftCardCode == giftCardCode)&&const DeepCollectionEquality().equals(other.splitPayments, splitPayments)&&(identical(other.cashTenderedCents, cashTenderedCents) || other.cashTenderedCents == cashTenderedCents)&&(identical(other.changeCents, changeCents) || other.changeCents == changeCents)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptEmailed, receiptEmailed) || other.receiptEmailed == receiptEmailed)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isVoided, isVoided) || other.isVoided == isVoided)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.voidedBy, voidedBy) || other.voidedBy == voidedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,transactionDate,staffId,staffName,clientId,clientName,appointmentId,const DeepCollectionEquality().hash(lineItems),subtotalCents,taxCents,taxRate,discountCents,discountReason,totalCents,paymentMethod,paymentStatus,stripePaymentId,giftCardCode,const DeepCollectionEquality().hash(splitPayments),cashTenderedCents,changeCents,receiptNumber,receiptUrl,receiptEmailed,notes,isVoided,voidReason,voidedAt,voidedBy,createdAt,updatedAt]);

@override
String toString() {
  return 'PosTransaction(id: $id, businessId: $businessId, transactionDate: $transactionDate, staffId: $staffId, staffName: $staffName, clientId: $clientId, clientName: $clientName, appointmentId: $appointmentId, lineItems: $lineItems, subtotalCents: $subtotalCents, taxCents: $taxCents, taxRate: $taxRate, discountCents: $discountCents, discountReason: $discountReason, totalCents: $totalCents, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, stripePaymentId: $stripePaymentId, giftCardCode: $giftCardCode, splitPayments: $splitPayments, cashTenderedCents: $cashTenderedCents, changeCents: $changeCents, receiptNumber: $receiptNumber, receiptUrl: $receiptUrl, receiptEmailed: $receiptEmailed, notes: $notes, isVoided: $isVoided, voidReason: $voidReason, voidedAt: $voidedAt, voidedBy: $voidedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PosTransactionCopyWith<$Res>  {
  factory $PosTransactionCopyWith(PosTransaction value, $Res Function(PosTransaction) _then) = _$PosTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String businessId,@TimestampConverter() DateTime transactionDate, String staffId, String? staffName, String? clientId, String? clientName, String? appointmentId, List<PosLineItem> lineItems, int subtotalCents, int taxCents, double taxRate, int discountCents, String? discountReason, int totalCents, PosPaymentMethod paymentMethod, PaymentStatus paymentStatus, String? stripePaymentId, String? giftCardCode, List<SplitPaymentDetail> splitPayments, int? cashTenderedCents, int? changeCents, String? receiptNumber, String? receiptUrl, bool receiptEmailed, String? notes, bool isVoided, String? voidReason,@NullableTimestampConverter() DateTime? voidedAt, String? voidedBy,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$PosTransactionCopyWithImpl<$Res>
    implements $PosTransactionCopyWith<$Res> {
  _$PosTransactionCopyWithImpl(this._self, this._then);

  final PosTransaction _self;
  final $Res Function(PosTransaction) _then;

/// Create a copy of PosTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? transactionDate = null,Object? staffId = null,Object? staffName = freezed,Object? clientId = freezed,Object? clientName = freezed,Object? appointmentId = freezed,Object? lineItems = null,Object? subtotalCents = null,Object? taxCents = null,Object? taxRate = null,Object? discountCents = null,Object? discountReason = freezed,Object? totalCents = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? stripePaymentId = freezed,Object? giftCardCode = freezed,Object? splitPayments = null,Object? cashTenderedCents = freezed,Object? changeCents = freezed,Object? receiptNumber = freezed,Object? receiptUrl = freezed,Object? receiptEmailed = null,Object? notes = freezed,Object? isVoided = null,Object? voidReason = freezed,Object? voidedAt = freezed,Object? voidedBy = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,staffName: freezed == staffName ? _self.staffName : staffName // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientName: freezed == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,lineItems: null == lineItems ? _self.lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<PosLineItem>,subtotalCents: null == subtotalCents ? _self.subtotalCents : subtotalCents // ignore: cast_nullable_to_non_nullable
as int,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,taxRate: null == taxRate ? _self.taxRate : taxRate // ignore: cast_nullable_to_non_nullable
as double,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PosPaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,stripePaymentId: freezed == stripePaymentId ? _self.stripePaymentId : stripePaymentId // ignore: cast_nullable_to_non_nullable
as String?,giftCardCode: freezed == giftCardCode ? _self.giftCardCode : giftCardCode // ignore: cast_nullable_to_non_nullable
as String?,splitPayments: null == splitPayments ? _self.splitPayments : splitPayments // ignore: cast_nullable_to_non_nullable
as List<SplitPaymentDetail>,cashTenderedCents: freezed == cashTenderedCents ? _self.cashTenderedCents : cashTenderedCents // ignore: cast_nullable_to_non_nullable
as int?,changeCents: freezed == changeCents ? _self.changeCents : changeCents // ignore: cast_nullable_to_non_nullable
as int?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptEmailed: null == receiptEmailed ? _self.receiptEmailed : receiptEmailed // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isVoided: null == isVoided ? _self.isVoided : isVoided // ignore: cast_nullable_to_non_nullable
as bool,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidedBy: freezed == voidedBy ? _self.voidedBy : voidedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PosTransaction].
extension PosTransactionPatterns on PosTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PosTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PosTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PosTransaction value)  $default,){
final _that = this;
switch (_that) {
case _PosTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PosTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _PosTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId, @TimestampConverter()  DateTime transactionDate,  String staffId,  String? staffName,  String? clientId,  String? clientName,  String? appointmentId,  List<PosLineItem> lineItems,  int subtotalCents,  int taxCents,  double taxRate,  int discountCents,  String? discountReason,  int totalCents,  PosPaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentId,  String? giftCardCode,  List<SplitPaymentDetail> splitPayments,  int? cashTenderedCents,  int? changeCents,  String? receiptNumber,  String? receiptUrl,  bool receiptEmailed,  String? notes,  bool isVoided,  String? voidReason, @NullableTimestampConverter()  DateTime? voidedAt,  String? voidedBy, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PosTransaction() when $default != null:
return $default(_that.id,_that.businessId,_that.transactionDate,_that.staffId,_that.staffName,_that.clientId,_that.clientName,_that.appointmentId,_that.lineItems,_that.subtotalCents,_that.taxCents,_that.taxRate,_that.discountCents,_that.discountReason,_that.totalCents,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentId,_that.giftCardCode,_that.splitPayments,_that.cashTenderedCents,_that.changeCents,_that.receiptNumber,_that.receiptUrl,_that.receiptEmailed,_that.notes,_that.isVoided,_that.voidReason,_that.voidedAt,_that.voidedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId, @TimestampConverter()  DateTime transactionDate,  String staffId,  String? staffName,  String? clientId,  String? clientName,  String? appointmentId,  List<PosLineItem> lineItems,  int subtotalCents,  int taxCents,  double taxRate,  int discountCents,  String? discountReason,  int totalCents,  PosPaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentId,  String? giftCardCode,  List<SplitPaymentDetail> splitPayments,  int? cashTenderedCents,  int? changeCents,  String? receiptNumber,  String? receiptUrl,  bool receiptEmailed,  String? notes,  bool isVoided,  String? voidReason, @NullableTimestampConverter()  DateTime? voidedAt,  String? voidedBy, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PosTransaction():
return $default(_that.id,_that.businessId,_that.transactionDate,_that.staffId,_that.staffName,_that.clientId,_that.clientName,_that.appointmentId,_that.lineItems,_that.subtotalCents,_that.taxCents,_that.taxRate,_that.discountCents,_that.discountReason,_that.totalCents,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentId,_that.giftCardCode,_that.splitPayments,_that.cashTenderedCents,_that.changeCents,_that.receiptNumber,_that.receiptUrl,_that.receiptEmailed,_that.notes,_that.isVoided,_that.voidReason,_that.voidedAt,_that.voidedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId, @TimestampConverter()  DateTime transactionDate,  String staffId,  String? staffName,  String? clientId,  String? clientName,  String? appointmentId,  List<PosLineItem> lineItems,  int subtotalCents,  int taxCents,  double taxRate,  int discountCents,  String? discountReason,  int totalCents,  PosPaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? stripePaymentId,  String? giftCardCode,  List<SplitPaymentDetail> splitPayments,  int? cashTenderedCents,  int? changeCents,  String? receiptNumber,  String? receiptUrl,  bool receiptEmailed,  String? notes,  bool isVoided,  String? voidReason, @NullableTimestampConverter()  DateTime? voidedAt,  String? voidedBy, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PosTransaction() when $default != null:
return $default(_that.id,_that.businessId,_that.transactionDate,_that.staffId,_that.staffName,_that.clientId,_that.clientName,_that.appointmentId,_that.lineItems,_that.subtotalCents,_that.taxCents,_that.taxRate,_that.discountCents,_that.discountReason,_that.totalCents,_that.paymentMethod,_that.paymentStatus,_that.stripePaymentId,_that.giftCardCode,_that.splitPayments,_that.cashTenderedCents,_that.changeCents,_that.receiptNumber,_that.receiptUrl,_that.receiptEmailed,_that.notes,_that.isVoided,_that.voidReason,_that.voidedAt,_that.voidedBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PosTransaction extends PosTransaction {
  const _PosTransaction({required this.id, required this.businessId, @TimestampConverter() required this.transactionDate, required this.staffId, this.staffName, this.clientId, this.clientName, this.appointmentId, required final  List<PosLineItem> lineItems, required this.subtotalCents, required this.taxCents, this.taxRate = 0.0, this.discountCents = 0, this.discountReason, required this.totalCents, required this.paymentMethod, required this.paymentStatus, this.stripePaymentId, this.giftCardCode, final  List<SplitPaymentDetail> splitPayments = const [], this.cashTenderedCents, this.changeCents, this.receiptNumber, this.receiptUrl, this.receiptEmailed = false, this.notes, this.isVoided = false, this.voidReason, @NullableTimestampConverter() this.voidedAt, this.voidedBy, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _lineItems = lineItems,_splitPayments = splitPayments,super._();
  factory _PosTransaction.fromJson(Map<String, dynamic> json) => _$PosTransactionFromJson(json);

/// Unique transaction ID
@override final  String id;
/// Business ID
@override final  String businessId;
/// Transaction date and time
@override@TimestampConverter() final  DateTime transactionDate;
/// Staff ID who processed the sale
@override final  String staffId;
/// Staff name (denormalized for display)
@override final  String? staffName;
/// Optional client ID (null for walk-in)
@override final  String? clientId;
/// Client name (denormalized for receipt)
@override final  String? clientName;
/// Optional linked appointment ID (if sold during appointment)
@override final  String? appointmentId;
/// Line items in this transaction
 final  List<PosLineItem> _lineItems;
/// Line items in this transaction
@override List<PosLineItem> get lineItems {
  if (_lineItems is EqualUnmodifiableListView) return _lineItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineItems);
}

/// Subtotal in cents (sum of line item totals before tax)
@override final  int subtotalCents;
/// Tax amount in cents
@override final  int taxCents;
/// Tax rate applied (e.g., 0.0825 for 8.25%)
@override@JsonKey() final  double taxRate;
/// Discount on entire transaction in cents
@override@JsonKey() final  int discountCents;
/// Discount reason if applied
@override final  String? discountReason;
/// Total in cents (subtotal + tax - discount)
@override final  int totalCents;
/// Primary payment method
@override final  PosPaymentMethod paymentMethod;
/// Payment status
@override final  PaymentStatus paymentStatus;
/// Stripe Payment Intent ID (if card payment)
@override final  String? stripePaymentId;
/// Gift card code (if gift card payment)
@override final  String? giftCardCode;
/// Split payment details (if split payment)
 final  List<SplitPaymentDetail> _splitPayments;
/// Split payment details (if split payment)
@override@JsonKey() List<SplitPaymentDetail> get splitPayments {
  if (_splitPayments is EqualUnmodifiableListView) return _splitPayments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_splitPayments);
}

/// Cash tendered (for cash payments)
@override final  int? cashTenderedCents;
/// Change given (for cash payments)
@override final  int? changeCents;
/// Receipt number for customer reference
@override final  String? receiptNumber;
/// Receipt URL (PDF or email link)
@override final  String? receiptUrl;
/// Whether receipt was emailed to customer
@override@JsonKey() final  bool receiptEmailed;
/// Internal notes about the transaction
@override final  String? notes;
/// Whether transaction was voided
@override@JsonKey() final  bool isVoided;
/// Void reason if voided
@override final  String? voidReason;
/// When transaction was voided
@override@NullableTimestampConverter() final  DateTime? voidedAt;
/// Who voided the transaction
@override final  String? voidedBy;
/// When the transaction was created
@override@TimestampConverter() final  DateTime createdAt;
/// When the transaction was last updated
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of PosTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PosTransactionCopyWith<_PosTransaction> get copyWith => __$PosTransactionCopyWithImpl<_PosTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PosTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PosTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.staffName, staffName) || other.staffName == staffName)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&const DeepCollectionEquality().equals(other._lineItems, _lineItems)&&(identical(other.subtotalCents, subtotalCents) || other.subtotalCents == subtotalCents)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.taxRate, taxRate) || other.taxRate == taxRate)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.stripePaymentId, stripePaymentId) || other.stripePaymentId == stripePaymentId)&&(identical(other.giftCardCode, giftCardCode) || other.giftCardCode == giftCardCode)&&const DeepCollectionEquality().equals(other._splitPayments, _splitPayments)&&(identical(other.cashTenderedCents, cashTenderedCents) || other.cashTenderedCents == cashTenderedCents)&&(identical(other.changeCents, changeCents) || other.changeCents == changeCents)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptEmailed, receiptEmailed) || other.receiptEmailed == receiptEmailed)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isVoided, isVoided) || other.isVoided == isVoided)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.voidedBy, voidedBy) || other.voidedBy == voidedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,transactionDate,staffId,staffName,clientId,clientName,appointmentId,const DeepCollectionEquality().hash(_lineItems),subtotalCents,taxCents,taxRate,discountCents,discountReason,totalCents,paymentMethod,paymentStatus,stripePaymentId,giftCardCode,const DeepCollectionEquality().hash(_splitPayments),cashTenderedCents,changeCents,receiptNumber,receiptUrl,receiptEmailed,notes,isVoided,voidReason,voidedAt,voidedBy,createdAt,updatedAt]);

@override
String toString() {
  return 'PosTransaction(id: $id, businessId: $businessId, transactionDate: $transactionDate, staffId: $staffId, staffName: $staffName, clientId: $clientId, clientName: $clientName, appointmentId: $appointmentId, lineItems: $lineItems, subtotalCents: $subtotalCents, taxCents: $taxCents, taxRate: $taxRate, discountCents: $discountCents, discountReason: $discountReason, totalCents: $totalCents, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, stripePaymentId: $stripePaymentId, giftCardCode: $giftCardCode, splitPayments: $splitPayments, cashTenderedCents: $cashTenderedCents, changeCents: $changeCents, receiptNumber: $receiptNumber, receiptUrl: $receiptUrl, receiptEmailed: $receiptEmailed, notes: $notes, isVoided: $isVoided, voidReason: $voidReason, voidedAt: $voidedAt, voidedBy: $voidedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PosTransactionCopyWith<$Res> implements $PosTransactionCopyWith<$Res> {
  factory _$PosTransactionCopyWith(_PosTransaction value, $Res Function(_PosTransaction) _then) = __$PosTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId,@TimestampConverter() DateTime transactionDate, String staffId, String? staffName, String? clientId, String? clientName, String? appointmentId, List<PosLineItem> lineItems, int subtotalCents, int taxCents, double taxRate, int discountCents, String? discountReason, int totalCents, PosPaymentMethod paymentMethod, PaymentStatus paymentStatus, String? stripePaymentId, String? giftCardCode, List<SplitPaymentDetail> splitPayments, int? cashTenderedCents, int? changeCents, String? receiptNumber, String? receiptUrl, bool receiptEmailed, String? notes, bool isVoided, String? voidReason,@NullableTimestampConverter() DateTime? voidedAt, String? voidedBy,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$PosTransactionCopyWithImpl<$Res>
    implements _$PosTransactionCopyWith<$Res> {
  __$PosTransactionCopyWithImpl(this._self, this._then);

  final _PosTransaction _self;
  final $Res Function(_PosTransaction) _then;

/// Create a copy of PosTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? transactionDate = null,Object? staffId = null,Object? staffName = freezed,Object? clientId = freezed,Object? clientName = freezed,Object? appointmentId = freezed,Object? lineItems = null,Object? subtotalCents = null,Object? taxCents = null,Object? taxRate = null,Object? discountCents = null,Object? discountReason = freezed,Object? totalCents = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? stripePaymentId = freezed,Object? giftCardCode = freezed,Object? splitPayments = null,Object? cashTenderedCents = freezed,Object? changeCents = freezed,Object? receiptNumber = freezed,Object? receiptUrl = freezed,Object? receiptEmailed = null,Object? notes = freezed,Object? isVoided = null,Object? voidReason = freezed,Object? voidedAt = freezed,Object? voidedBy = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_PosTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,staffName: freezed == staffName ? _self.staffName : staffName // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientName: freezed == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,lineItems: null == lineItems ? _self._lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<PosLineItem>,subtotalCents: null == subtotalCents ? _self.subtotalCents : subtotalCents // ignore: cast_nullable_to_non_nullable
as int,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,taxRate: null == taxRate ? _self.taxRate : taxRate // ignore: cast_nullable_to_non_nullable
as double,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PosPaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,stripePaymentId: freezed == stripePaymentId ? _self.stripePaymentId : stripePaymentId // ignore: cast_nullable_to_non_nullable
as String?,giftCardCode: freezed == giftCardCode ? _self.giftCardCode : giftCardCode // ignore: cast_nullable_to_non_nullable
as String?,splitPayments: null == splitPayments ? _self._splitPayments : splitPayments // ignore: cast_nullable_to_non_nullable
as List<SplitPaymentDetail>,cashTenderedCents: freezed == cashTenderedCents ? _self.cashTenderedCents : cashTenderedCents // ignore: cast_nullable_to_non_nullable
as int?,changeCents: freezed == changeCents ? _self.changeCents : changeCents // ignore: cast_nullable_to_non_nullable
as int?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptEmailed: null == receiptEmailed ? _self.receiptEmailed : receiptEmailed // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isVoided: null == isVoided ? _self.isVoided : isVoided // ignore: cast_nullable_to_non_nullable
as bool,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidedBy: freezed == voidedBy ? _self.voidedBy : voidedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CartItem {

/// Product ID
 String get productId;/// Product name
 String get productName;/// SKU
 String? get sku;/// Unit price in cents
 int get unitPriceCents;/// Quantity in cart
 int get quantity;/// Whether item is taxable
 bool get taxable;/// Optional discount in cents
 int get discountCents;/// Discount reason
 String? get discountReason;
/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartItemCopyWith<CartItem> get copyWith => _$CartItemCopyWithImpl<CartItem>(this as CartItem, _$identity);

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.taxable, taxable) || other.taxable == taxable)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,unitPriceCents,quantity,taxable,discountCents,discountReason);

@override
String toString() {
  return 'CartItem(productId: $productId, productName: $productName, sku: $sku, unitPriceCents: $unitPriceCents, quantity: $quantity, taxable: $taxable, discountCents: $discountCents, discountReason: $discountReason)';
}


}

/// @nodoc
abstract mixin class $CartItemCopyWith<$Res>  {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) _then) = _$CartItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, String? sku, int unitPriceCents, int quantity, bool taxable, int discountCents, String? discountReason
});




}
/// @nodoc
class _$CartItemCopyWithImpl<$Res>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._self, this._then);

  final CartItem _self;
  final $Res Function(CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? sku = freezed,Object? unitPriceCents = null,Object? quantity = null,Object? taxable = null,Object? discountCents = null,Object? discountReason = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CartItem].
extension CartItemPatterns on CartItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartItem value)  $default,){
final _that = this;
switch (_that) {
case _CartItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartItem value)?  $default,){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  String? sku,  int unitPriceCents,  int quantity,  bool taxable,  int discountCents,  String? discountReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.unitPriceCents,_that.quantity,_that.taxable,_that.discountCents,_that.discountReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  String? sku,  int unitPriceCents,  int quantity,  bool taxable,  int discountCents,  String? discountReason)  $default,) {final _that = this;
switch (_that) {
case _CartItem():
return $default(_that.productId,_that.productName,_that.sku,_that.unitPriceCents,_that.quantity,_that.taxable,_that.discountCents,_that.discountReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  String? sku,  int unitPriceCents,  int quantity,  bool taxable,  int discountCents,  String? discountReason)?  $default,) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.unitPriceCents,_that.quantity,_that.taxable,_that.discountCents,_that.discountReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartItem extends CartItem {
  const _CartItem({required this.productId, required this.productName, this.sku, required this.unitPriceCents, required this.quantity, this.taxable = true, this.discountCents = 0, this.discountReason}): super._();
  factory _CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);

/// Product ID
@override final  String productId;
/// Product name
@override final  String productName;
/// SKU
@override final  String? sku;
/// Unit price in cents
@override final  int unitPriceCents;
/// Quantity in cart
@override final  int quantity;
/// Whether item is taxable
@override@JsonKey() final  bool taxable;
/// Optional discount in cents
@override@JsonKey() final  int discountCents;
/// Discount reason
@override final  String? discountReason;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartItemCopyWith<_CartItem> get copyWith => __$CartItemCopyWithImpl<_CartItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.taxable, taxable) || other.taxable == taxable)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,unitPriceCents,quantity,taxable,discountCents,discountReason);

@override
String toString() {
  return 'CartItem(productId: $productId, productName: $productName, sku: $sku, unitPriceCents: $unitPriceCents, quantity: $quantity, taxable: $taxable, discountCents: $discountCents, discountReason: $discountReason)';
}


}

/// @nodoc
abstract mixin class _$CartItemCopyWith<$Res> implements $CartItemCopyWith<$Res> {
  factory _$CartItemCopyWith(_CartItem value, $Res Function(_CartItem) _then) = __$CartItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, String? sku, int unitPriceCents, int quantity, bool taxable, int discountCents, String? discountReason
});




}
/// @nodoc
class __$CartItemCopyWithImpl<$Res>
    implements _$CartItemCopyWith<$Res> {
  __$CartItemCopyWithImpl(this._self, this._then);

  final _CartItem _self;
  final $Res Function(_CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? sku = freezed,Object? unitPriceCents = null,Object? quantity = null,Object? taxable = null,Object? discountCents = null,Object? discountReason = freezed,}) {
  return _then(_CartItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
