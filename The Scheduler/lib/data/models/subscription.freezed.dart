// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subscription {

/// Unique subscription ID (Stripe subscription ID)
 String get id;/// Business ID this subscription belongs to
 String get businessId;/// Current subscription tier
 SubscriptionTier get tier;/// Current status
 SubscriptionStatus get status;/// Stripe customer ID
 String get stripeCustomerId;/// Stripe subscription ID (if applicable)
 String? get stripeSubscriptionId;/// Stripe price ID being charged
 String? get stripePriceId;/// Current period start (when billing cycle started)
@TimestampConverter() DateTime get currentPeriodStart;/// Current period end (when billing cycle ends)
@TimestampConverter() DateTime get currentPeriodEnd;/// Whether subscription will cancel at period end
 bool get cancelAtPeriodEnd;/// Trial end date (if in trial)
@NullableTimestampConverter() DateTime? get trialEnd;/// Date subscription was created
@TimestampConverter() DateTime get createdAt;/// Date subscription was last updated
@TimestampConverter() DateTime get updatedAt;/// Date subscription was canceled (if applicable)
@NullableTimestampConverter() DateTime? get canceledAt;/// Additional add-ons purchased (e.g., extra SMS, providers)
 Map<String, dynamic> get addOns;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.status, status) || other.status == status)&&(identical(other.stripeCustomerId, stripeCustomerId) || other.stripeCustomerId == stripeCustomerId)&&(identical(other.stripeSubscriptionId, stripeSubscriptionId) || other.stripeSubscriptionId == stripeSubscriptionId)&&(identical(other.stripePriceId, stripePriceId) || other.stripePriceId == stripePriceId)&&(identical(other.currentPeriodStart, currentPeriodStart) || other.currentPeriodStart == currentPeriodStart)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.trialEnd, trialEnd) || other.trialEnd == trialEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&const DeepCollectionEquality().equals(other.addOns, addOns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,tier,status,stripeCustomerId,stripeSubscriptionId,stripePriceId,currentPeriodStart,currentPeriodEnd,cancelAtPeriodEnd,trialEnd,createdAt,updatedAt,canceledAt,const DeepCollectionEquality().hash(addOns));

@override
String toString() {
  return 'Subscription(id: $id, businessId: $businessId, tier: $tier, status: $status, stripeCustomerId: $stripeCustomerId, stripeSubscriptionId: $stripeSubscriptionId, stripePriceId: $stripePriceId, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, trialEnd: $trialEnd, createdAt: $createdAt, updatedAt: $updatedAt, canceledAt: $canceledAt, addOns: $addOns)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, SubscriptionTier tier, SubscriptionStatus status, String stripeCustomerId, String? stripeSubscriptionId, String? stripePriceId,@TimestampConverter() DateTime currentPeriodStart,@TimestampConverter() DateTime currentPeriodEnd, bool cancelAtPeriodEnd,@NullableTimestampConverter() DateTime? trialEnd,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? canceledAt, Map<String, dynamic> addOns
});




}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? tier = null,Object? status = null,Object? stripeCustomerId = null,Object? stripeSubscriptionId = freezed,Object? stripePriceId = freezed,Object? currentPeriodStart = null,Object? currentPeriodEnd = null,Object? cancelAtPeriodEnd = null,Object? trialEnd = freezed,Object? createdAt = null,Object? updatedAt = null,Object? canceledAt = freezed,Object? addOns = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SubscriptionTier,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,stripeCustomerId: null == stripeCustomerId ? _self.stripeCustomerId : stripeCustomerId // ignore: cast_nullable_to_non_nullable
as String,stripeSubscriptionId: freezed == stripeSubscriptionId ? _self.stripeSubscriptionId : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
as String?,stripePriceId: freezed == stripePriceId ? _self.stripePriceId : stripePriceId // ignore: cast_nullable_to_non_nullable
as String?,currentPeriodStart: null == currentPeriodStart ? _self.currentPeriodStart : currentPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,currentPeriodEnd: null == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,trialEnd: freezed == trialEnd ? _self.trialEnd : trialEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,addOns: null == addOns ? _self.addOns : addOns // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  SubscriptionTier tier,  SubscriptionStatus status,  String stripeCustomerId,  String? stripeSubscriptionId,  String? stripePriceId, @TimestampConverter()  DateTime currentPeriodStart, @TimestampConverter()  DateTime currentPeriodEnd,  bool cancelAtPeriodEnd, @NullableTimestampConverter()  DateTime? trialEnd, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? canceledAt,  Map<String, dynamic> addOns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.businessId,_that.tier,_that.status,_that.stripeCustomerId,_that.stripeSubscriptionId,_that.stripePriceId,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.trialEnd,_that.createdAt,_that.updatedAt,_that.canceledAt,_that.addOns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  SubscriptionTier tier,  SubscriptionStatus status,  String stripeCustomerId,  String? stripeSubscriptionId,  String? stripePriceId, @TimestampConverter()  DateTime currentPeriodStart, @TimestampConverter()  DateTime currentPeriodEnd,  bool cancelAtPeriodEnd, @NullableTimestampConverter()  DateTime? trialEnd, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? canceledAt,  Map<String, dynamic> addOns)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.businessId,_that.tier,_that.status,_that.stripeCustomerId,_that.stripeSubscriptionId,_that.stripePriceId,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.trialEnd,_that.createdAt,_that.updatedAt,_that.canceledAt,_that.addOns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  SubscriptionTier tier,  SubscriptionStatus status,  String stripeCustomerId,  String? stripeSubscriptionId,  String? stripePriceId, @TimestampConverter()  DateTime currentPeriodStart, @TimestampConverter()  DateTime currentPeriodEnd,  bool cancelAtPeriodEnd, @NullableTimestampConverter()  DateTime? trialEnd, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? canceledAt,  Map<String, dynamic> addOns)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.businessId,_that.tier,_that.status,_that.stripeCustomerId,_that.stripeSubscriptionId,_that.stripePriceId,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.trialEnd,_that.createdAt,_that.updatedAt,_that.canceledAt,_that.addOns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription extends Subscription {
  const _Subscription({required this.id, required this.businessId, required this.tier, required this.status, required this.stripeCustomerId, this.stripeSubscriptionId, this.stripePriceId, @TimestampConverter() required this.currentPeriodStart, @TimestampConverter() required this.currentPeriodEnd, this.cancelAtPeriodEnd = false, @NullableTimestampConverter() this.trialEnd, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt, @NullableTimestampConverter() this.canceledAt, final  Map<String, dynamic> addOns = const {}}): _addOns = addOns,super._();
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

/// Unique subscription ID (Stripe subscription ID)
@override final  String id;
/// Business ID this subscription belongs to
@override final  String businessId;
/// Current subscription tier
@override final  SubscriptionTier tier;
/// Current status
@override final  SubscriptionStatus status;
/// Stripe customer ID
@override final  String stripeCustomerId;
/// Stripe subscription ID (if applicable)
@override final  String? stripeSubscriptionId;
/// Stripe price ID being charged
@override final  String? stripePriceId;
/// Current period start (when billing cycle started)
@override@TimestampConverter() final  DateTime currentPeriodStart;
/// Current period end (when billing cycle ends)
@override@TimestampConverter() final  DateTime currentPeriodEnd;
/// Whether subscription will cancel at period end
@override@JsonKey() final  bool cancelAtPeriodEnd;
/// Trial end date (if in trial)
@override@NullableTimestampConverter() final  DateTime? trialEnd;
/// Date subscription was created
@override@TimestampConverter() final  DateTime createdAt;
/// Date subscription was last updated
@override@TimestampConverter() final  DateTime updatedAt;
/// Date subscription was canceled (if applicable)
@override@NullableTimestampConverter() final  DateTime? canceledAt;
/// Additional add-ons purchased (e.g., extra SMS, providers)
 final  Map<String, dynamic> _addOns;
/// Additional add-ons purchased (e.g., extra SMS, providers)
@override@JsonKey() Map<String, dynamic> get addOns {
  if (_addOns is EqualUnmodifiableMapView) return _addOns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_addOns);
}


/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.status, status) || other.status == status)&&(identical(other.stripeCustomerId, stripeCustomerId) || other.stripeCustomerId == stripeCustomerId)&&(identical(other.stripeSubscriptionId, stripeSubscriptionId) || other.stripeSubscriptionId == stripeSubscriptionId)&&(identical(other.stripePriceId, stripePriceId) || other.stripePriceId == stripePriceId)&&(identical(other.currentPeriodStart, currentPeriodStart) || other.currentPeriodStart == currentPeriodStart)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.trialEnd, trialEnd) || other.trialEnd == trialEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&const DeepCollectionEquality().equals(other._addOns, _addOns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,tier,status,stripeCustomerId,stripeSubscriptionId,stripePriceId,currentPeriodStart,currentPeriodEnd,cancelAtPeriodEnd,trialEnd,createdAt,updatedAt,canceledAt,const DeepCollectionEquality().hash(_addOns));

@override
String toString() {
  return 'Subscription(id: $id, businessId: $businessId, tier: $tier, status: $status, stripeCustomerId: $stripeCustomerId, stripeSubscriptionId: $stripeSubscriptionId, stripePriceId: $stripePriceId, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, trialEnd: $trialEnd, createdAt: $createdAt, updatedAt: $updatedAt, canceledAt: $canceledAt, addOns: $addOns)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, SubscriptionTier tier, SubscriptionStatus status, String stripeCustomerId, String? stripeSubscriptionId, String? stripePriceId,@TimestampConverter() DateTime currentPeriodStart,@TimestampConverter() DateTime currentPeriodEnd, bool cancelAtPeriodEnd,@NullableTimestampConverter() DateTime? trialEnd,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? canceledAt, Map<String, dynamic> addOns
});




}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? tier = null,Object? status = null,Object? stripeCustomerId = null,Object? stripeSubscriptionId = freezed,Object? stripePriceId = freezed,Object? currentPeriodStart = null,Object? currentPeriodEnd = null,Object? cancelAtPeriodEnd = null,Object? trialEnd = freezed,Object? createdAt = null,Object? updatedAt = null,Object? canceledAt = freezed,Object? addOns = null,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SubscriptionTier,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,stripeCustomerId: null == stripeCustomerId ? _self.stripeCustomerId : stripeCustomerId // ignore: cast_nullable_to_non_nullable
as String,stripeSubscriptionId: freezed == stripeSubscriptionId ? _self.stripeSubscriptionId : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
as String?,stripePriceId: freezed == stripePriceId ? _self.stripePriceId : stripePriceId // ignore: cast_nullable_to_non_nullable
as String?,currentPeriodStart: null == currentPeriodStart ? _self.currentPeriodStart : currentPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,currentPeriodEnd: null == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,trialEnd: freezed == trialEnd ? _self.trialEnd : trialEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,addOns: null == addOns ? _self._addOns : addOns // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
