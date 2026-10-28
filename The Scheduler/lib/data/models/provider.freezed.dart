// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Provider {

 String get id; String get businessId; String get firstName; String get lastName; String? get email; String? get phone; String? get stripeAccountId; String? get bio; List<String> get specializations; List<String> get serviceIds; List<String> get locationIds; String get colorHex;// Blue default
@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of Provider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCopyWith<Provider> get copyWith => _$ProviderCopyWithImpl<Provider>(this as Provider, _$identity);

  /// Serializes this Provider to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Provider&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.stripeAccountId, stripeAccountId) || other.stripeAccountId == stripeAccountId)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.specializations, specializations)&&const DeepCollectionEquality().equals(other.serviceIds, serviceIds)&&const DeepCollectionEquality().equals(other.locationIds, locationIds)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,firstName,lastName,email,phone,stripeAccountId,bio,const DeepCollectionEquality().hash(specializations),const DeepCollectionEquality().hash(serviceIds),const DeepCollectionEquality().hash(locationIds),colorHex,createdAt,updatedAt);

@override
String toString() {
  return 'Provider(id: $id, businessId: $businessId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, stripeAccountId: $stripeAccountId, bio: $bio, specializations: $specializations, serviceIds: $serviceIds, locationIds: $locationIds, colorHex: $colorHex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProviderCopyWith<$Res>  {
  factory $ProviderCopyWith(Provider value, $Res Function(Provider) _then) = _$ProviderCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String firstName, String lastName, String? email, String? phone, String? stripeAccountId, String? bio, List<String> specializations, List<String> serviceIds, List<String> locationIds, String colorHex,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ProviderCopyWithImpl<$Res>
    implements $ProviderCopyWith<$Res> {
  _$ProviderCopyWithImpl(this._self, this._then);

  final Provider _self;
  final $Res Function(Provider) _then;

/// Create a copy of Provider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? firstName = null,Object? lastName = null,Object? email = freezed,Object? phone = freezed,Object? stripeAccountId = freezed,Object? bio = freezed,Object? specializations = null,Object? serviceIds = null,Object? locationIds = null,Object? colorHex = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,stripeAccountId: freezed == stripeAccountId ? _self.stripeAccountId : stripeAccountId // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,specializations: null == specializations ? _self.specializations : specializations // ignore: cast_nullable_to_non_nullable
as List<String>,serviceIds: null == serviceIds ? _self.serviceIds : serviceIds // ignore: cast_nullable_to_non_nullable
as List<String>,locationIds: null == locationIds ? _self.locationIds : locationIds // ignore: cast_nullable_to_non_nullable
as List<String>,colorHex: null == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Provider].
extension ProviderPatterns on Provider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Provider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Provider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Provider value)  $default,){
final _that = this;
switch (_that) {
case _Provider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Provider value)?  $default,){
final _that = this;
switch (_that) {
case _Provider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? stripeAccountId,  String? bio,  List<String> specializations,  List<String> serviceIds,  List<String> locationIds,  String colorHex, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Provider() when $default != null:
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.stripeAccountId,_that.bio,_that.specializations,_that.serviceIds,_that.locationIds,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? stripeAccountId,  String? bio,  List<String> specializations,  List<String> serviceIds,  List<String> locationIds,  String colorHex, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Provider():
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.stripeAccountId,_that.bio,_that.specializations,_that.serviceIds,_that.locationIds,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? stripeAccountId,  String? bio,  List<String> specializations,  List<String> serviceIds,  List<String> locationIds,  String colorHex, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Provider() when $default != null:
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.stripeAccountId,_that.bio,_that.specializations,_that.serviceIds,_that.locationIds,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Provider extends Provider {
  const _Provider({required this.id, required this.businessId, required this.firstName, required this.lastName, this.email, this.phone, this.stripeAccountId, this.bio, final  List<String> specializations = const [], final  List<String> serviceIds = const [], final  List<String> locationIds = const [], this.colorHex = '4285F4', @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _specializations = specializations,_serviceIds = serviceIds,_locationIds = locationIds,super._();
  factory _Provider.fromJson(Map<String, dynamic> json) => _$ProviderFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String firstName;
@override final  String lastName;
@override final  String? email;
@override final  String? phone;
@override final  String? stripeAccountId;
@override final  String? bio;
 final  List<String> _specializations;
@override@JsonKey() List<String> get specializations {
  if (_specializations is EqualUnmodifiableListView) return _specializations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_specializations);
}

 final  List<String> _serviceIds;
@override@JsonKey() List<String> get serviceIds {
  if (_serviceIds is EqualUnmodifiableListView) return _serviceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceIds);
}

 final  List<String> _locationIds;
@override@JsonKey() List<String> get locationIds {
  if (_locationIds is EqualUnmodifiableListView) return _locationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locationIds);
}

@override@JsonKey() final  String colorHex;
// Blue default
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of Provider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCopyWith<_Provider> get copyWith => __$ProviderCopyWithImpl<_Provider>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Provider&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.stripeAccountId, stripeAccountId) || other.stripeAccountId == stripeAccountId)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._specializations, _specializations)&&const DeepCollectionEquality().equals(other._serviceIds, _serviceIds)&&const DeepCollectionEquality().equals(other._locationIds, _locationIds)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,firstName,lastName,email,phone,stripeAccountId,bio,const DeepCollectionEquality().hash(_specializations),const DeepCollectionEquality().hash(_serviceIds),const DeepCollectionEquality().hash(_locationIds),colorHex,createdAt,updatedAt);

@override
String toString() {
  return 'Provider(id: $id, businessId: $businessId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, stripeAccountId: $stripeAccountId, bio: $bio, specializations: $specializations, serviceIds: $serviceIds, locationIds: $locationIds, colorHex: $colorHex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProviderCopyWith<$Res> implements $ProviderCopyWith<$Res> {
  factory _$ProviderCopyWith(_Provider value, $Res Function(_Provider) _then) = __$ProviderCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String firstName, String lastName, String? email, String? phone, String? stripeAccountId, String? bio, List<String> specializations, List<String> serviceIds, List<String> locationIds, String colorHex,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ProviderCopyWithImpl<$Res>
    implements _$ProviderCopyWith<$Res> {
  __$ProviderCopyWithImpl(this._self, this._then);

  final _Provider _self;
  final $Res Function(_Provider) _then;

/// Create a copy of Provider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? firstName = null,Object? lastName = null,Object? email = freezed,Object? phone = freezed,Object? stripeAccountId = freezed,Object? bio = freezed,Object? specializations = null,Object? serviceIds = null,Object? locationIds = null,Object? colorHex = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_Provider(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,stripeAccountId: freezed == stripeAccountId ? _self.stripeAccountId : stripeAccountId // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,specializations: null == specializations ? _self._specializations : specializations // ignore: cast_nullable_to_non_nullable
as List<String>,serviceIds: null == serviceIds ? _self._serviceIds : serviceIds // ignore: cast_nullable_to_non_nullable
as List<String>,locationIds: null == locationIds ? _self._locationIds : locationIds // ignore: cast_nullable_to_non_nullable
as List<String>,colorHex: null == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
