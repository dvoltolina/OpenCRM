// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Business {

 String get id; String get name; String? get description; String? get contactEmail; String? get contactPhone;@_TimestampConverter() DateTime get createdAt;/// Industry type - determines default HIPAA compliance settings
 BusinessIndustry get industry;/// Whether this business requires HIPAA compliance.
/// Auto-set based on industry, but can be manually enabled.
 bool get requiresHipaaCompliance;/// Whether MFA is enabled for admin/owner roles.
/// Auto-enabled for HIPAA businesses, optional for others.
 bool get mfaEnabled;
/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessCopyWith<Business> get copyWith => _$BusinessCopyWithImpl<Business>(this as Business, _$identity);

  /// Serializes this Business to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.requiresHipaaCompliance, requiresHipaaCompliance) || other.requiresHipaaCompliance == requiresHipaaCompliance)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,contactEmail,contactPhone,createdAt,industry,requiresHipaaCompliance,mfaEnabled);

@override
String toString() {
  return 'Business(id: $id, name: $name, description: $description, contactEmail: $contactEmail, contactPhone: $contactPhone, createdAt: $createdAt, industry: $industry, requiresHipaaCompliance: $requiresHipaaCompliance, mfaEnabled: $mfaEnabled)';
}


}

/// @nodoc
abstract mixin class $BusinessCopyWith<$Res>  {
  factory $BusinessCopyWith(Business value, $Res Function(Business) _then) = _$BusinessCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? contactEmail, String? contactPhone,@_TimestampConverter() DateTime createdAt, BusinessIndustry industry, bool requiresHipaaCompliance, bool mfaEnabled
});




}
/// @nodoc
class _$BusinessCopyWithImpl<$Res>
    implements $BusinessCopyWith<$Res> {
  _$BusinessCopyWithImpl(this._self, this._then);

  final Business _self;
  final $Res Function(Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? contactEmail = freezed,Object? contactPhone = freezed,Object? createdAt = null,Object? industry = null,Object? requiresHipaaCompliance = null,Object? mfaEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,industry: null == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as BusinessIndustry,requiresHipaaCompliance: null == requiresHipaaCompliance ? _self.requiresHipaaCompliance : requiresHipaaCompliance // ignore: cast_nullable_to_non_nullable
as bool,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Business].
extension BusinessPatterns on Business {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Business value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Business value)  $default,){
final _that = this;
switch (_that) {
case _Business():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Business value)?  $default,){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? contactEmail,  String? contactPhone, @_TimestampConverter()  DateTime createdAt,  BusinessIndustry industry,  bool requiresHipaaCompliance,  bool mfaEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.contactEmail,_that.contactPhone,_that.createdAt,_that.industry,_that.requiresHipaaCompliance,_that.mfaEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? contactEmail,  String? contactPhone, @_TimestampConverter()  DateTime createdAt,  BusinessIndustry industry,  bool requiresHipaaCompliance,  bool mfaEnabled)  $default,) {final _that = this;
switch (_that) {
case _Business():
return $default(_that.id,_that.name,_that.description,_that.contactEmail,_that.contactPhone,_that.createdAt,_that.industry,_that.requiresHipaaCompliance,_that.mfaEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? contactEmail,  String? contactPhone, @_TimestampConverter()  DateTime createdAt,  BusinessIndustry industry,  bool requiresHipaaCompliance,  bool mfaEnabled)?  $default,) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.contactEmail,_that.contactPhone,_that.createdAt,_that.industry,_that.requiresHipaaCompliance,_that.mfaEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Business implements Business {
  const _Business({required this.id, required this.name, this.description, this.contactEmail, this.contactPhone, @_TimestampConverter() required this.createdAt, this.industry = BusinessIndustry.other, this.requiresHipaaCompliance = false, this.mfaEnabled = false});
  factory _Business.fromJson(Map<String, dynamic> json) => _$BusinessFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String? contactEmail;
@override final  String? contactPhone;
@override@_TimestampConverter() final  DateTime createdAt;
/// Industry type - determines default HIPAA compliance settings
@override@JsonKey() final  BusinessIndustry industry;
/// Whether this business requires HIPAA compliance.
/// Auto-set based on industry, but can be manually enabled.
@override@JsonKey() final  bool requiresHipaaCompliance;
/// Whether MFA is enabled for admin/owner roles.
/// Auto-enabled for HIPAA businesses, optional for others.
@override@JsonKey() final  bool mfaEnabled;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessCopyWith<_Business> get copyWith => __$BusinessCopyWithImpl<_Business>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.requiresHipaaCompliance, requiresHipaaCompliance) || other.requiresHipaaCompliance == requiresHipaaCompliance)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,contactEmail,contactPhone,createdAt,industry,requiresHipaaCompliance,mfaEnabled);

@override
String toString() {
  return 'Business(id: $id, name: $name, description: $description, contactEmail: $contactEmail, contactPhone: $contactPhone, createdAt: $createdAt, industry: $industry, requiresHipaaCompliance: $requiresHipaaCompliance, mfaEnabled: $mfaEnabled)';
}


}

/// @nodoc
abstract mixin class _$BusinessCopyWith<$Res> implements $BusinessCopyWith<$Res> {
  factory _$BusinessCopyWith(_Business value, $Res Function(_Business) _then) = __$BusinessCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? contactEmail, String? contactPhone,@_TimestampConverter() DateTime createdAt, BusinessIndustry industry, bool requiresHipaaCompliance, bool mfaEnabled
});




}
/// @nodoc
class __$BusinessCopyWithImpl<$Res>
    implements _$BusinessCopyWith<$Res> {
  __$BusinessCopyWithImpl(this._self, this._then);

  final _Business _self;
  final $Res Function(_Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? contactEmail = freezed,Object? contactPhone = freezed,Object? createdAt = null,Object? industry = null,Object? requiresHipaaCompliance = null,Object? mfaEnabled = null,}) {
  return _then(_Business(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,industry: null == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as BusinessIndustry,requiresHipaaCompliance: null == requiresHipaaCompliance ? _self.requiresHipaaCompliance : requiresHipaaCompliance // ignore: cast_nullable_to_non_nullable
as bool,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
