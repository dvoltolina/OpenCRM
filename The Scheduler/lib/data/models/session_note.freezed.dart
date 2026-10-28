// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionNoteAudit {

 String get id; String get action;// 'created', 'viewed', 'edited', 'deleted'
 String get userId; String get userFullName;@TimestampConverter() DateTime get timestamp; String? get ipAddress; String? get userAgent; String? get changesSummary;
/// Create a copy of SessionNoteAudit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionNoteAuditCopyWith<SessionNoteAudit> get copyWith => _$SessionNoteAuditCopyWithImpl<SessionNoteAudit>(this as SessionNoteAudit, _$identity);

  /// Serializes this SessionNoteAudit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNoteAudit&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.changesSummary, changesSummary) || other.changesSummary == changesSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,userId,userFullName,timestamp,ipAddress,userAgent,changesSummary);

@override
String toString() {
  return 'SessionNoteAudit(id: $id, action: $action, userId: $userId, userFullName: $userFullName, timestamp: $timestamp, ipAddress: $ipAddress, userAgent: $userAgent, changesSummary: $changesSummary)';
}


}

/// @nodoc
abstract mixin class $SessionNoteAuditCopyWith<$Res>  {
  factory $SessionNoteAuditCopyWith(SessionNoteAudit value, $Res Function(SessionNoteAudit) _then) = _$SessionNoteAuditCopyWithImpl;
@useResult
$Res call({
 String id, String action, String userId, String userFullName,@TimestampConverter() DateTime timestamp, String? ipAddress, String? userAgent, String? changesSummary
});




}
/// @nodoc
class _$SessionNoteAuditCopyWithImpl<$Res>
    implements $SessionNoteAuditCopyWith<$Res> {
  _$SessionNoteAuditCopyWithImpl(this._self, this._then);

  final SessionNoteAudit _self;
  final $Res Function(SessionNoteAudit) _then;

/// Create a copy of SessionNoteAudit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? userId = null,Object? userFullName = null,Object? timestamp = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? changesSummary = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: null == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,changesSummary: freezed == changesSummary ? _self.changesSummary : changesSummary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionNoteAudit].
extension SessionNoteAuditPatterns on SessionNoteAudit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionNoteAudit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionNoteAudit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionNoteAudit value)  $default,){
final _that = this;
switch (_that) {
case _SessionNoteAudit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionNoteAudit value)?  $default,){
final _that = this;
switch (_that) {
case _SessionNoteAudit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  String userId,  String userFullName, @TimestampConverter()  DateTime timestamp,  String? ipAddress,  String? userAgent,  String? changesSummary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionNoteAudit() when $default != null:
return $default(_that.id,_that.action,_that.userId,_that.userFullName,_that.timestamp,_that.ipAddress,_that.userAgent,_that.changesSummary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  String userId,  String userFullName, @TimestampConverter()  DateTime timestamp,  String? ipAddress,  String? userAgent,  String? changesSummary)  $default,) {final _that = this;
switch (_that) {
case _SessionNoteAudit():
return $default(_that.id,_that.action,_that.userId,_that.userFullName,_that.timestamp,_that.ipAddress,_that.userAgent,_that.changesSummary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  String userId,  String userFullName, @TimestampConverter()  DateTime timestamp,  String? ipAddress,  String? userAgent,  String? changesSummary)?  $default,) {final _that = this;
switch (_that) {
case _SessionNoteAudit() when $default != null:
return $default(_that.id,_that.action,_that.userId,_that.userFullName,_that.timestamp,_that.ipAddress,_that.userAgent,_that.changesSummary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionNoteAudit implements SessionNoteAudit {
  const _SessionNoteAudit({required this.id, required this.action, required this.userId, required this.userFullName, @TimestampConverter() required this.timestamp, this.ipAddress, this.userAgent, this.changesSummary});
  factory _SessionNoteAudit.fromJson(Map<String, dynamic> json) => _$SessionNoteAuditFromJson(json);

@override final  String id;
@override final  String action;
// 'created', 'viewed', 'edited', 'deleted'
@override final  String userId;
@override final  String userFullName;
@override@TimestampConverter() final  DateTime timestamp;
@override final  String? ipAddress;
@override final  String? userAgent;
@override final  String? changesSummary;

/// Create a copy of SessionNoteAudit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionNoteAuditCopyWith<_SessionNoteAudit> get copyWith => __$SessionNoteAuditCopyWithImpl<_SessionNoteAudit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionNoteAuditToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionNoteAudit&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.changesSummary, changesSummary) || other.changesSummary == changesSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,userId,userFullName,timestamp,ipAddress,userAgent,changesSummary);

@override
String toString() {
  return 'SessionNoteAudit(id: $id, action: $action, userId: $userId, userFullName: $userFullName, timestamp: $timestamp, ipAddress: $ipAddress, userAgent: $userAgent, changesSummary: $changesSummary)';
}


}

/// @nodoc
abstract mixin class _$SessionNoteAuditCopyWith<$Res> implements $SessionNoteAuditCopyWith<$Res> {
  factory _$SessionNoteAuditCopyWith(_SessionNoteAudit value, $Res Function(_SessionNoteAudit) _then) = __$SessionNoteAuditCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, String userId, String userFullName,@TimestampConverter() DateTime timestamp, String? ipAddress, String? userAgent, String? changesSummary
});




}
/// @nodoc
class __$SessionNoteAuditCopyWithImpl<$Res>
    implements _$SessionNoteAuditCopyWith<$Res> {
  __$SessionNoteAuditCopyWithImpl(this._self, this._then);

  final _SessionNoteAudit _self;
  final $Res Function(_SessionNoteAudit) _then;

/// Create a copy of SessionNoteAudit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? userId = null,Object? userFullName = null,Object? timestamp = null,Object? ipAddress = freezed,Object? userAgent = freezed,Object? changesSummary = freezed,}) {
  return _then(_SessionNoteAudit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: null == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,changesSummary: freezed == changesSummary ? _self.changesSummary : changesSummary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SessionNote {

 String get id; String get businessId; String get appointmentId; String get clientId; String get providerId; SessionNoteType get noteType;/// Visibility/access level for this note
 SessionNoteVisibility get visibility;/// Encrypted note content (encrypted with business encryption key)
 String get encryptedContent;/// Plain text title/summary (NOT encrypted, for listing)
 String? get title;/// Tags for categorization (NOT encrypted)
 List<String> get tags;/// Whether this note is locked for editing
 bool get isLocked;/// Creation timestamp
@TimestampConverter() DateTime get createdAt;/// Last modification timestamp
@NullableTimestampConverter() DateTime? get updatedAt;/// Created by user ID
 String get createdBy;/// Created by user full name (cached for display)
 String get createdByName;/// Last edited by user ID
 String? get lastEditedBy;/// Last edited by user full name
 String? get lastEditedByName;/// Audit trail (access and modification log)
 List<SessionNoteAudit> get auditLog;/// Retention policy: never delete even if appointment is deleted
 bool get retainIndefinitely;/// For psychotherapy notes: extra protected, different disclosure rules
 bool get isPsychotherapyNote;
/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionNoteCopyWith<SessionNote> get copyWith => _$SessionNoteCopyWithImpl<SessionNote>(this as SessionNote, _$identity);

  /// Serializes this SessionNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNote&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.noteType, noteType) || other.noteType == noteType)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.encryptedContent, encryptedContent) || other.encryptedContent == encryptedContent)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.lastEditedBy, lastEditedBy) || other.lastEditedBy == lastEditedBy)&&(identical(other.lastEditedByName, lastEditedByName) || other.lastEditedByName == lastEditedByName)&&const DeepCollectionEquality().equals(other.auditLog, auditLog)&&(identical(other.retainIndefinitely, retainIndefinitely) || other.retainIndefinitely == retainIndefinitely)&&(identical(other.isPsychotherapyNote, isPsychotherapyNote) || other.isPsychotherapyNote == isPsychotherapyNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,providerId,noteType,visibility,encryptedContent,title,const DeepCollectionEquality().hash(tags),isLocked,createdAt,updatedAt,createdBy,createdByName,lastEditedBy,lastEditedByName,const DeepCollectionEquality().hash(auditLog),retainIndefinitely,isPsychotherapyNote]);

@override
String toString() {
  return 'SessionNote(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, providerId: $providerId, noteType: $noteType, visibility: $visibility, encryptedContent: $encryptedContent, title: $title, tags: $tags, isLocked: $isLocked, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, createdByName: $createdByName, lastEditedBy: $lastEditedBy, lastEditedByName: $lastEditedByName, auditLog: $auditLog, retainIndefinitely: $retainIndefinitely, isPsychotherapyNote: $isPsychotherapyNote)';
}


}

/// @nodoc
abstract mixin class $SessionNoteCopyWith<$Res>  {
  factory $SessionNoteCopyWith(SessionNote value, $Res Function(SessionNote) _then) = _$SessionNoteCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String providerId, SessionNoteType noteType, SessionNoteVisibility visibility, String encryptedContent, String? title, List<String> tags, bool isLocked,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, String createdBy, String createdByName, String? lastEditedBy, String? lastEditedByName, List<SessionNoteAudit> auditLog, bool retainIndefinitely, bool isPsychotherapyNote
});




}
/// @nodoc
class _$SessionNoteCopyWithImpl<$Res>
    implements $SessionNoteCopyWith<$Res> {
  _$SessionNoteCopyWithImpl(this._self, this._then);

  final SessionNote _self;
  final $Res Function(SessionNote) _then;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? providerId = null,Object? noteType = null,Object? visibility = null,Object? encryptedContent = null,Object? title = freezed,Object? tags = null,Object? isLocked = null,Object? createdAt = null,Object? updatedAt = freezed,Object? createdBy = null,Object? createdByName = null,Object? lastEditedBy = freezed,Object? lastEditedByName = freezed,Object? auditLog = null,Object? retainIndefinitely = null,Object? isPsychotherapyNote = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,noteType: null == noteType ? _self.noteType : noteType // ignore: cast_nullable_to_non_nullable
as SessionNoteType,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SessionNoteVisibility,encryptedContent: null == encryptedContent ? _self.encryptedContent : encryptedContent // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,lastEditedBy: freezed == lastEditedBy ? _self.lastEditedBy : lastEditedBy // ignore: cast_nullable_to_non_nullable
as String?,lastEditedByName: freezed == lastEditedByName ? _self.lastEditedByName : lastEditedByName // ignore: cast_nullable_to_non_nullable
as String?,auditLog: null == auditLog ? _self.auditLog : auditLog // ignore: cast_nullable_to_non_nullable
as List<SessionNoteAudit>,retainIndefinitely: null == retainIndefinitely ? _self.retainIndefinitely : retainIndefinitely // ignore: cast_nullable_to_non_nullable
as bool,isPsychotherapyNote: null == isPsychotherapyNote ? _self.isPsychotherapyNote : isPsychotherapyNote // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionNote].
extension SessionNotePatterns on SessionNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionNote value)  $default,){
final _that = this;
switch (_that) {
case _SessionNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionNote value)?  $default,){
final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  SessionNoteType noteType,  SessionNoteVisibility visibility,  String encryptedContent,  String? title,  List<String> tags,  bool isLocked, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String createdBy,  String createdByName,  String? lastEditedBy,  String? lastEditedByName,  List<SessionNoteAudit> auditLog,  bool retainIndefinitely,  bool isPsychotherapyNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.noteType,_that.visibility,_that.encryptedContent,_that.title,_that.tags,_that.isLocked,_that.createdAt,_that.updatedAt,_that.createdBy,_that.createdByName,_that.lastEditedBy,_that.lastEditedByName,_that.auditLog,_that.retainIndefinitely,_that.isPsychotherapyNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  SessionNoteType noteType,  SessionNoteVisibility visibility,  String encryptedContent,  String? title,  List<String> tags,  bool isLocked, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String createdBy,  String createdByName,  String? lastEditedBy,  String? lastEditedByName,  List<SessionNoteAudit> auditLog,  bool retainIndefinitely,  bool isPsychotherapyNote)  $default,) {final _that = this;
switch (_that) {
case _SessionNote():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.noteType,_that.visibility,_that.encryptedContent,_that.title,_that.tags,_that.isLocked,_that.createdAt,_that.updatedAt,_that.createdBy,_that.createdByName,_that.lastEditedBy,_that.lastEditedByName,_that.auditLog,_that.retainIndefinitely,_that.isPsychotherapyNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  SessionNoteType noteType,  SessionNoteVisibility visibility,  String encryptedContent,  String? title,  List<String> tags,  bool isLocked, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String createdBy,  String createdByName,  String? lastEditedBy,  String? lastEditedByName,  List<SessionNoteAudit> auditLog,  bool retainIndefinitely,  bool isPsychotherapyNote)?  $default,) {final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.noteType,_that.visibility,_that.encryptedContent,_that.title,_that.tags,_that.isLocked,_that.createdAt,_that.updatedAt,_that.createdBy,_that.createdByName,_that.lastEditedBy,_that.lastEditedByName,_that.auditLog,_that.retainIndefinitely,_that.isPsychotherapyNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionNote implements SessionNote {
  const _SessionNote({required this.id, required this.businessId, required this.appointmentId, required this.clientId, required this.providerId, required this.noteType, this.visibility = SessionNoteVisibility.providerOnly, required this.encryptedContent, this.title, final  List<String> tags = const [], this.isLocked = false, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt, required this.createdBy, required this.createdByName, this.lastEditedBy, this.lastEditedByName, final  List<SessionNoteAudit> auditLog = const [], this.retainIndefinitely = true, this.isPsychotherapyNote = false}): _tags = tags,_auditLog = auditLog;
  factory _SessionNote.fromJson(Map<String, dynamic> json) => _$SessionNoteFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String appointmentId;
@override final  String clientId;
@override final  String providerId;
@override final  SessionNoteType noteType;
/// Visibility/access level for this note
@override@JsonKey() final  SessionNoteVisibility visibility;
/// Encrypted note content (encrypted with business encryption key)
@override final  String encryptedContent;
/// Plain text title/summary (NOT encrypted, for listing)
@override final  String? title;
/// Tags for categorization (NOT encrypted)
 final  List<String> _tags;
/// Tags for categorization (NOT encrypted)
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Whether this note is locked for editing
@override@JsonKey() final  bool isLocked;
/// Creation timestamp
@override@TimestampConverter() final  DateTime createdAt;
/// Last modification timestamp
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// Created by user ID
@override final  String createdBy;
/// Created by user full name (cached for display)
@override final  String createdByName;
/// Last edited by user ID
@override final  String? lastEditedBy;
/// Last edited by user full name
@override final  String? lastEditedByName;
/// Audit trail (access and modification log)
 final  List<SessionNoteAudit> _auditLog;
/// Audit trail (access and modification log)
@override@JsonKey() List<SessionNoteAudit> get auditLog {
  if (_auditLog is EqualUnmodifiableListView) return _auditLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_auditLog);
}

/// Retention policy: never delete even if appointment is deleted
@override@JsonKey() final  bool retainIndefinitely;
/// For psychotherapy notes: extra protected, different disclosure rules
@override@JsonKey() final  bool isPsychotherapyNote;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionNoteCopyWith<_SessionNote> get copyWith => __$SessionNoteCopyWithImpl<_SessionNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionNote&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.noteType, noteType) || other.noteType == noteType)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.encryptedContent, encryptedContent) || other.encryptedContent == encryptedContent)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.lastEditedBy, lastEditedBy) || other.lastEditedBy == lastEditedBy)&&(identical(other.lastEditedByName, lastEditedByName) || other.lastEditedByName == lastEditedByName)&&const DeepCollectionEquality().equals(other._auditLog, _auditLog)&&(identical(other.retainIndefinitely, retainIndefinitely) || other.retainIndefinitely == retainIndefinitely)&&(identical(other.isPsychotherapyNote, isPsychotherapyNote) || other.isPsychotherapyNote == isPsychotherapyNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,providerId,noteType,visibility,encryptedContent,title,const DeepCollectionEquality().hash(_tags),isLocked,createdAt,updatedAt,createdBy,createdByName,lastEditedBy,lastEditedByName,const DeepCollectionEquality().hash(_auditLog),retainIndefinitely,isPsychotherapyNote]);

@override
String toString() {
  return 'SessionNote(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, providerId: $providerId, noteType: $noteType, visibility: $visibility, encryptedContent: $encryptedContent, title: $title, tags: $tags, isLocked: $isLocked, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, createdByName: $createdByName, lastEditedBy: $lastEditedBy, lastEditedByName: $lastEditedByName, auditLog: $auditLog, retainIndefinitely: $retainIndefinitely, isPsychotherapyNote: $isPsychotherapyNote)';
}


}

/// @nodoc
abstract mixin class _$SessionNoteCopyWith<$Res> implements $SessionNoteCopyWith<$Res> {
  factory _$SessionNoteCopyWith(_SessionNote value, $Res Function(_SessionNote) _then) = __$SessionNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String providerId, SessionNoteType noteType, SessionNoteVisibility visibility, String encryptedContent, String? title, List<String> tags, bool isLocked,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, String createdBy, String createdByName, String? lastEditedBy, String? lastEditedByName, List<SessionNoteAudit> auditLog, bool retainIndefinitely, bool isPsychotherapyNote
});




}
/// @nodoc
class __$SessionNoteCopyWithImpl<$Res>
    implements _$SessionNoteCopyWith<$Res> {
  __$SessionNoteCopyWithImpl(this._self, this._then);

  final _SessionNote _self;
  final $Res Function(_SessionNote) _then;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? providerId = null,Object? noteType = null,Object? visibility = null,Object? encryptedContent = null,Object? title = freezed,Object? tags = null,Object? isLocked = null,Object? createdAt = null,Object? updatedAt = freezed,Object? createdBy = null,Object? createdByName = null,Object? lastEditedBy = freezed,Object? lastEditedByName = freezed,Object? auditLog = null,Object? retainIndefinitely = null,Object? isPsychotherapyNote = null,}) {
  return _then(_SessionNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,noteType: null == noteType ? _self.noteType : noteType // ignore: cast_nullable_to_non_nullable
as SessionNoteType,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SessionNoteVisibility,encryptedContent: null == encryptedContent ? _self.encryptedContent : encryptedContent // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,lastEditedBy: freezed == lastEditedBy ? _self.lastEditedBy : lastEditedBy // ignore: cast_nullable_to_non_nullable
as String?,lastEditedByName: freezed == lastEditedByName ? _self.lastEditedByName : lastEditedByName // ignore: cast_nullable_to_non_nullable
as String?,auditLog: null == auditLog ? _self._auditLog : auditLog // ignore: cast_nullable_to_non_nullable
as List<SessionNoteAudit>,retainIndefinitely: null == retainIndefinitely ? _self.retainIndefinitely : retainIndefinitely // ignore: cast_nullable_to_non_nullable
as bool,isPsychotherapyNote: null == isPsychotherapyNote ? _self.isPsychotherapyNote : isPsychotherapyNote // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
