// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Service {

 String get id; String get businessId; String get name; int get durationMinutes; double get price; String? get description; String? get category; List<String> get providerIds; List<String> get requiredResources; String? get intakeFormTemplateId; int? get bufferMinutes;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCopyWith<Service> get copyWith => _$ServiceCopyWithImpl<Service>(this as Service, _$identity);

  /// Serializes this Service to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Service&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.providerIds, providerIds)&&const DeepCollectionEquality().equals(other.requiredResources, requiredResources)&&(identical(other.intakeFormTemplateId, intakeFormTemplateId) || other.intakeFormTemplateId == intakeFormTemplateId)&&(identical(other.bufferMinutes, bufferMinutes) || other.bufferMinutes == bufferMinutes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,durationMinutes,price,description,category,const DeepCollectionEquality().hash(providerIds),const DeepCollectionEquality().hash(requiredResources),intakeFormTemplateId,bufferMinutes,createdAt,updatedAt);

@override
String toString() {
  return 'Service(id: $id, businessId: $businessId, name: $name, durationMinutes: $durationMinutes, price: $price, description: $description, category: $category, providerIds: $providerIds, requiredResources: $requiredResources, intakeFormTemplateId: $intakeFormTemplateId, bufferMinutes: $bufferMinutes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ServiceCopyWith<$Res>  {
  factory $ServiceCopyWith(Service value, $Res Function(Service) _then) = _$ServiceCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, int durationMinutes, double price, String? description, String? category, List<String> providerIds, List<String> requiredResources, String? intakeFormTemplateId, int? bufferMinutes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ServiceCopyWithImpl<$Res>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._self, this._then);

  final Service _self;
  final $Res Function(Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? durationMinutes = null,Object? price = null,Object? description = freezed,Object? category = freezed,Object? providerIds = null,Object? requiredResources = null,Object? intakeFormTemplateId = freezed,Object? bufferMinutes = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,providerIds: null == providerIds ? _self.providerIds : providerIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiredResources: null == requiredResources ? _self.requiredResources : requiredResources // ignore: cast_nullable_to_non_nullable
as List<String>,intakeFormTemplateId: freezed == intakeFormTemplateId ? _self.intakeFormTemplateId : intakeFormTemplateId // ignore: cast_nullable_to_non_nullable
as String?,bufferMinutes: freezed == bufferMinutes ? _self.bufferMinutes : bufferMinutes // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Service].
extension ServicePatterns on Service {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Service value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Service value)  $default,){
final _that = this;
switch (_that) {
case _Service():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Service value)?  $default,){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  int durationMinutes,  double price,  String? description,  String? category,  List<String> providerIds,  List<String> requiredResources,  String? intakeFormTemplateId,  int? bufferMinutes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.durationMinutes,_that.price,_that.description,_that.category,_that.providerIds,_that.requiredResources,_that.intakeFormTemplateId,_that.bufferMinutes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  int durationMinutes,  double price,  String? description,  String? category,  List<String> providerIds,  List<String> requiredResources,  String? intakeFormTemplateId,  int? bufferMinutes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Service():
return $default(_that.id,_that.businessId,_that.name,_that.durationMinutes,_that.price,_that.description,_that.category,_that.providerIds,_that.requiredResources,_that.intakeFormTemplateId,_that.bufferMinutes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  int durationMinutes,  double price,  String? description,  String? category,  List<String> providerIds,  List<String> requiredResources,  String? intakeFormTemplateId,  int? bufferMinutes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.durationMinutes,_that.price,_that.description,_that.category,_that.providerIds,_that.requiredResources,_that.intakeFormTemplateId,_that.bufferMinutes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Service extends Service {
  const _Service({required this.id, required this.businessId, required this.name, required this.durationMinutes, required this.price, this.description, this.category, final  List<String> providerIds = const [], final  List<String> requiredResources = const [], this.intakeFormTemplateId, this.bufferMinutes, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _providerIds = providerIds,_requiredResources = requiredResources,super._();
  factory _Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String name;
@override final  int durationMinutes;
@override final  double price;
@override final  String? description;
@override final  String? category;
 final  List<String> _providerIds;
@override@JsonKey() List<String> get providerIds {
  if (_providerIds is EqualUnmodifiableListView) return _providerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_providerIds);
}

 final  List<String> _requiredResources;
@override@JsonKey() List<String> get requiredResources {
  if (_requiredResources is EqualUnmodifiableListView) return _requiredResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredResources);
}

@override final  String? intakeFormTemplateId;
@override final  int? bufferMinutes;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCopyWith<_Service> get copyWith => __$ServiceCopyWithImpl<_Service>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Service&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._providerIds, _providerIds)&&const DeepCollectionEquality().equals(other._requiredResources, _requiredResources)&&(identical(other.intakeFormTemplateId, intakeFormTemplateId) || other.intakeFormTemplateId == intakeFormTemplateId)&&(identical(other.bufferMinutes, bufferMinutes) || other.bufferMinutes == bufferMinutes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,durationMinutes,price,description,category,const DeepCollectionEquality().hash(_providerIds),const DeepCollectionEquality().hash(_requiredResources),intakeFormTemplateId,bufferMinutes,createdAt,updatedAt);

@override
String toString() {
  return 'Service(id: $id, businessId: $businessId, name: $name, durationMinutes: $durationMinutes, price: $price, description: $description, category: $category, providerIds: $providerIds, requiredResources: $requiredResources, intakeFormTemplateId: $intakeFormTemplateId, bufferMinutes: $bufferMinutes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$ServiceCopyWith(_Service value, $Res Function(_Service) _then) = __$ServiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, int durationMinutes, double price, String? description, String? category, List<String> providerIds, List<String> requiredResources, String? intakeFormTemplateId, int? bufferMinutes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ServiceCopyWithImpl<$Res>
    implements _$ServiceCopyWith<$Res> {
  __$ServiceCopyWithImpl(this._self, this._then);

  final _Service _self;
  final $Res Function(_Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? durationMinutes = null,Object? price = null,Object? description = freezed,Object? category = freezed,Object? providerIds = null,Object? requiredResources = null,Object? intakeFormTemplateId = freezed,Object? bufferMinutes = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_Service(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,providerIds: null == providerIds ? _self._providerIds : providerIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiredResources: null == requiredResources ? _self._requiredResources : requiredResources // ignore: cast_nullable_to_non_nullable
as List<String>,intakeFormTemplateId: freezed == intakeFormTemplateId ? _self.intakeFormTemplateId : intakeFormTemplateId // ignore: cast_nullable_to_non_nullable
as String?,bufferMinutes: freezed == bufferMinutes ? _self.bufferMinutes : bufferMinutes // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
