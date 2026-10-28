// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invite {

 String get id; String get businessId;/// Email address this invite was sent to
 String get email;/// Role that will be assigned to the user who accepts this invite
 String get role;/// SHA-256 hash of the invite token (never plaintext)
 String get tokenHash;/// User ID of the admin/owner who created this invite
 String get createdBy;/// When the invite was created
@_TimestampConverter() DateTime get createdAt;/// When the invite expires
@_TimestampConverter() DateTime get expiresAt;/// Current status of the invite
 InviteStatus get status;/// When the invite was accepted (optional)
@_NullableTimestampConverter() DateTime? get acceptedAt;/// User ID of the person who accepted this invite (optional)
 String? get acceptedBy;/// Optional notes about this invite (no PHI)
 String? get notes;
/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCopyWith<Invite> get copyWith => _$InviteCopyWithImpl<Invite>(this as Invite, _$identity);

  /// Serializes this Invite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.tokenHash, tokenHash) || other.tokenHash == tokenHash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.acceptedBy, acceptedBy) || other.acceptedBy == acceptedBy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,email,role,tokenHash,createdBy,createdAt,expiresAt,status,acceptedAt,acceptedBy,notes);

@override
String toString() {
  return 'Invite(id: $id, businessId: $businessId, email: $email, role: $role, tokenHash: $tokenHash, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, status: $status, acceptedAt: $acceptedAt, acceptedBy: $acceptedBy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $InviteCopyWith<$Res>  {
  factory $InviteCopyWith(Invite value, $Res Function(Invite) _then) = _$InviteCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String email, String role, String tokenHash, String createdBy,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime expiresAt, InviteStatus status,@_NullableTimestampConverter() DateTime? acceptedAt, String? acceptedBy, String? notes
});




}
/// @nodoc
class _$InviteCopyWithImpl<$Res>
    implements $InviteCopyWith<$Res> {
  _$InviteCopyWithImpl(this._self, this._then);

  final Invite _self;
  final $Res Function(Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? email = null,Object? role = null,Object? tokenHash = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? status = null,Object? acceptedAt = freezed,Object? acceptedBy = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,tokenHash: null == tokenHash ? _self.tokenHash : tokenHash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedBy: freezed == acceptedBy ? _self.acceptedBy : acceptedBy // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invite].
extension InvitePatterns on Invite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invite value)  $default,){
final _that = this;
switch (_that) {
case _Invite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invite value)?  $default,){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String email,  String role,  String tokenHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  InviteStatus status, @_NullableTimestampConverter()  DateTime? acceptedAt,  String? acceptedBy,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.businessId,_that.email,_that.role,_that.tokenHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.status,_that.acceptedAt,_that.acceptedBy,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String email,  String role,  String tokenHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  InviteStatus status, @_NullableTimestampConverter()  DateTime? acceptedAt,  String? acceptedBy,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _Invite():
return $default(_that.id,_that.businessId,_that.email,_that.role,_that.tokenHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.status,_that.acceptedAt,_that.acceptedBy,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String email,  String role,  String tokenHash,  String createdBy, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime expiresAt,  InviteStatus status, @_NullableTimestampConverter()  DateTime? acceptedAt,  String? acceptedBy,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.businessId,_that.email,_that.role,_that.tokenHash,_that.createdBy,_that.createdAt,_that.expiresAt,_that.status,_that.acceptedAt,_that.acceptedBy,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invite extends Invite {
  const _Invite({required this.id, required this.businessId, required this.email, required this.role, required this.tokenHash, required this.createdBy, @_TimestampConverter() required this.createdAt, @_TimestampConverter() required this.expiresAt, required this.status, @_NullableTimestampConverter() this.acceptedAt, this.acceptedBy, this.notes}): super._();
  factory _Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

@override final  String id;
@override final  String businessId;
/// Email address this invite was sent to
@override final  String email;
/// Role that will be assigned to the user who accepts this invite
@override final  String role;
/// SHA-256 hash of the invite token (never plaintext)
@override final  String tokenHash;
/// User ID of the admin/owner who created this invite
@override final  String createdBy;
/// When the invite was created
@override@_TimestampConverter() final  DateTime createdAt;
/// When the invite expires
@override@_TimestampConverter() final  DateTime expiresAt;
/// Current status of the invite
@override final  InviteStatus status;
/// When the invite was accepted (optional)
@override@_NullableTimestampConverter() final  DateTime? acceptedAt;
/// User ID of the person who accepted this invite (optional)
@override final  String? acceptedBy;
/// Optional notes about this invite (no PHI)
@override final  String? notes;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCopyWith<_Invite> get copyWith => __$InviteCopyWithImpl<_Invite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.tokenHash, tokenHash) || other.tokenHash == tokenHash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.acceptedBy, acceptedBy) || other.acceptedBy == acceptedBy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,email,role,tokenHash,createdBy,createdAt,expiresAt,status,acceptedAt,acceptedBy,notes);

@override
String toString() {
  return 'Invite(id: $id, businessId: $businessId, email: $email, role: $role, tokenHash: $tokenHash, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, status: $status, acceptedAt: $acceptedAt, acceptedBy: $acceptedBy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$InviteCopyWith<$Res> implements $InviteCopyWith<$Res> {
  factory _$InviteCopyWith(_Invite value, $Res Function(_Invite) _then) = __$InviteCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String email, String role, String tokenHash, String createdBy,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime expiresAt, InviteStatus status,@_NullableTimestampConverter() DateTime? acceptedAt, String? acceptedBy, String? notes
});




}
/// @nodoc
class __$InviteCopyWithImpl<$Res>
    implements _$InviteCopyWith<$Res> {
  __$InviteCopyWithImpl(this._self, this._then);

  final _Invite _self;
  final $Res Function(_Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? email = null,Object? role = null,Object? tokenHash = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? status = null,Object? acceptedAt = freezed,Object? acceptedBy = freezed,Object? notes = freezed,}) {
  return _then(_Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,tokenHash: null == tokenHash ? _self.tokenHash : tokenHash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedBy: freezed == acceptedBy ? _self.acceptedBy : acceptedBy // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
