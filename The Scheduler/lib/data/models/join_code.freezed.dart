// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinCode {

 String get id; String get businessId;/// SHA-256 hash of the code (never plaintext)
 String get codeHash;/// User ID of the admin/owner who created this code
 String get createdBy;/// When the code was created
@_TimestampConverter() DateTime get createdAt;/// When the code expires
@_TimestampConverter() DateTime get expiresAt;/// Maximum number of times this code can be used
 int get maxUses;/// Current number of times this code has been used
 int get uses;/// Role that will be assigned to users who join with this code
 String get role;/// Current status of the join code
 JoinCodeStatus get status;/// When the code was last used (optional)
@_NullableTimestampConverter() DateTime? get lastUsedAt;/// User ID of the last person who used this code (optional)
 String? get lastUsedBy;/// Optional notes about this code (no PHI)
 String? get notes;
/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinCodeCopyWith<JoinCode> get copyWith => _$JoinCodeCopyWithImpl<JoinCode>(this as JoinCode, _$identity);

  /// Serializes this JoinCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCode&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.codeHash, codeHash) || other.codeHash == codeHash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.lastUsedBy, lastUsedBy) || other.lastUsedBy == lastUsedBy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,codeHash,createdBy,createdAt,expiresAt,maxUses,uses,role,status,lastUsedAt,lastUsedBy,notes);

@override
String toString() {
  return 'JoinCode(id: $id, businessId: $businessId, codeHash: $codeHash, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, maxUses: $maxUses, uses: $uses, role: $role, status: $status, lastUsedAt: $lastUsedAt, lastUsedBy: $lastUsedBy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $JoinCodeCopyWith<$Res>  {
  factory $JoinCodeCopyWith(JoinCode value, $Res Function(JoinCode) _then) = _$JoinCodeCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String codeHash, String createdBy,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime expiresAt, int maxUses, int uses, String role, JoinCodeStatus status,@_NullableTimestampConverter() DateTime? lastUsedAt, String? lastUsedBy, String? notes
});




}
/// @nodoc
class _$JoinCodeCopyWithImpl<$Res>
    implements $JoinCodeCopyWith<$Res> {
  _$JoinCodeCopyWithImpl(this._self, this._then);

  final JoinCode _self;
  final $Res Function(JoinCode) _then;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? codeHash = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? maxUses = null,Object? uses = null,Object? role = null,Object? status = null,Object? lastUsedAt = freezed,Object? lastUsedBy = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,codeHash: null == codeHash ? _self.codeHash : codeHash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinCodeStatus,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedBy: freezed == lastUsedBy ? _self.lastUsedBy : lastUsedBy // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinCode].
extension JoinCodePatterns on JoinCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinCode value)  $default,){
final _that = this;
switch (_that) {
case _JoinCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinCode value)?  $default,){
final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String codeHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  int maxUses,  int uses,  String role,  JoinCodeStatus status, @_NullableTimestampConverter()  DateTime? lastUsedAt,  String? lastUsedBy,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
return $default(_that.id,_that.businessId,_that.codeHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.uses,_that.role,_that.status,_that.lastUsedAt,_that.lastUsedBy,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String codeHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  int maxUses,  int uses,  String role,  JoinCodeStatus status, @_NullableTimestampConverter()  DateTime? lastUsedAt,  String? lastUsedBy,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _JoinCode():
return $default(_that.id,_that.businessId,_that.codeHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.uses,_that.role,_that.status,_that.lastUsedAt,_that.lastUsedBy,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String codeHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  int maxUses,  int uses,  String role,  JoinCodeStatus status, @_NullableTimestampConverter()  DateTime? lastUsedAt,  String? lastUsedBy,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
return $default(_that.id,_that.businessId,_that.codeHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.uses,_that.role,_that.status,_that.lastUsedAt,_that.lastUsedBy,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinCode extends JoinCode {
  const _JoinCode({required this.id, required this.businessId, required this.codeHash, required this.createdBy, @_TimestampConverter() required this.createdAt, @_TimestampConverter() required this.expiresAt, required this.maxUses, this.uses = 0, required this.role, required this.status, @_NullableTimestampConverter() this.lastUsedAt, this.lastUsedBy, this.notes}): super._();
  factory _JoinCode.fromJson(Map<String, dynamic> json) => _$JoinCodeFromJson(json);

@override final  String id;
@override final  String businessId;
/// SHA-256 hash of the code (never plaintext)
@override final  String codeHash;
/// User ID of the admin/owner who created this code
@override final  String createdBy;
/// When the code was created
@override@_TimestampConverter() final  DateTime createdAt;
/// When the code expires
@override@_TimestampConverter() final  DateTime expiresAt;
/// Maximum number of times this code can be used
@override final  int maxUses;
/// Current number of times this code has been used
@override@JsonKey() final  int uses;
/// Role that will be assigned to users who join with this code
@override final  String role;
/// Current status of the join code
@override final  JoinCodeStatus status;
/// When the code was last used (optional)
@override@_NullableTimestampConverter() final  DateTime? lastUsedAt;
/// User ID of the last person who used this code (optional)
@override final  String? lastUsedBy;
/// Optional notes about this code (no PHI)
@override final  String? notes;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinCodeCopyWith<_JoinCode> get copyWith => __$JoinCodeCopyWithImpl<_JoinCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinCode&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.codeHash, codeHash) || other.codeHash == codeHash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.uses, uses) || other.uses == uses)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.lastUsedBy, lastUsedBy) || other.lastUsedBy == lastUsedBy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,codeHash,createdBy,createdAt,expiresAt,maxUses,uses,role,status,lastUsedAt,lastUsedBy,notes);

@override
String toString() {
  return 'JoinCode(id: $id, businessId: $businessId, codeHash: $codeHash, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, maxUses: $maxUses, uses: $uses, role: $role, status: $status, lastUsedAt: $lastUsedAt, lastUsedBy: $lastUsedBy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$JoinCodeCopyWith<$Res> implements $JoinCodeCopyWith<$Res> {
  factory _$JoinCodeCopyWith(_JoinCode value, $Res Function(_JoinCode) _then) = __$JoinCodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String codeHash, String createdBy,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime expiresAt, int maxUses, int uses, String role, JoinCodeStatus status,@_NullableTimestampConverter() DateTime? lastUsedAt, String? lastUsedBy, String? notes
});




}
/// @nodoc
class __$JoinCodeCopyWithImpl<$Res>
    implements _$JoinCodeCopyWith<$Res> {
  __$JoinCodeCopyWithImpl(this._self, this._then);

  final _JoinCode _self;
  final $Res Function(_JoinCode) _then;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? codeHash = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? maxUses = null,Object? uses = null,Object? role = null,Object? status = null,Object? lastUsedAt = freezed,Object? lastUsedBy = freezed,Object? notes = freezed,}) {
  return _then(_JoinCode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,codeHash: null == codeHash ? _self.codeHash : codeHash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinCodeStatus,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedBy: freezed == lastUsedBy ? _self.lastUsedBy : lastUsedBy // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
