// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationParticipant {

 String get id; String get name; String? get avatarUrl; bool get isStaff;/// Last time this participant read the conversation
@NullableTimestampConverter() DateTime? get lastReadAt;
/// Create a copy of ConversationParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationParticipantCopyWith<ConversationParticipant> get copyWith => _$ConversationParticipantCopyWithImpl<ConversationParticipant>(this as ConversationParticipant, _$identity);

  /// Serializes this ConversationParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl,isStaff,lastReadAt);

@override
String toString() {
  return 'ConversationParticipant(id: $id, name: $name, avatarUrl: $avatarUrl, isStaff: $isStaff, lastReadAt: $lastReadAt)';
}


}

/// @nodoc
abstract mixin class $ConversationParticipantCopyWith<$Res>  {
  factory $ConversationParticipantCopyWith(ConversationParticipant value, $Res Function(ConversationParticipant) _then) = _$ConversationParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? avatarUrl, bool isStaff,@NullableTimestampConverter() DateTime? lastReadAt
});




}
/// @nodoc
class _$ConversationParticipantCopyWithImpl<$Res>
    implements $ConversationParticipantCopyWith<$Res> {
  _$ConversationParticipantCopyWithImpl(this._self, this._then);

  final ConversationParticipant _self;
  final $Res Function(ConversationParticipant) _then;

/// Create a copy of ConversationParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,Object? isStaff = null,Object? lastReadAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationParticipant].
extension ConversationParticipantPatterns on ConversationParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationParticipant value)  $default,){
final _that = this;
switch (_that) {
case _ConversationParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl,  bool isStaff, @NullableTimestampConverter()  DateTime? lastReadAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationParticipant() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl,_that.isStaff,_that.lastReadAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl,  bool isStaff, @NullableTimestampConverter()  DateTime? lastReadAt)  $default,) {final _that = this;
switch (_that) {
case _ConversationParticipant():
return $default(_that.id,_that.name,_that.avatarUrl,_that.isStaff,_that.lastReadAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? avatarUrl,  bool isStaff, @NullableTimestampConverter()  DateTime? lastReadAt)?  $default,) {final _that = this;
switch (_that) {
case _ConversationParticipant() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl,_that.isStaff,_that.lastReadAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationParticipant implements ConversationParticipant {
  const _ConversationParticipant({required this.id, required this.name, this.avatarUrl, this.isStaff = false, @NullableTimestampConverter() this.lastReadAt});
  factory _ConversationParticipant.fromJson(Map<String, dynamic> json) => _$ConversationParticipantFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isStaff;
/// Last time this participant read the conversation
@override@NullableTimestampConverter() final  DateTime? lastReadAt;

/// Create a copy of ConversationParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationParticipantCopyWith<_ConversationParticipant> get copyWith => __$ConversationParticipantCopyWithImpl<_ConversationParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl,isStaff,lastReadAt);

@override
String toString() {
  return 'ConversationParticipant(id: $id, name: $name, avatarUrl: $avatarUrl, isStaff: $isStaff, lastReadAt: $lastReadAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationParticipantCopyWith<$Res> implements $ConversationParticipantCopyWith<$Res> {
  factory _$ConversationParticipantCopyWith(_ConversationParticipant value, $Res Function(_ConversationParticipant) _then) = __$ConversationParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? avatarUrl, bool isStaff,@NullableTimestampConverter() DateTime? lastReadAt
});




}
/// @nodoc
class __$ConversationParticipantCopyWithImpl<$Res>
    implements _$ConversationParticipantCopyWith<$Res> {
  __$ConversationParticipantCopyWithImpl(this._self, this._then);

  final _ConversationParticipant _self;
  final $Res Function(_ConversationParticipant) _then;

/// Create a copy of ConversationParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,Object? isStaff = null,Object? lastReadAt = freezed,}) {
  return _then(_ConversationParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Conversation {

 String get id; String get businessId; List<ConversationParticipant> get participants;/// User IDs of all participants for querying
 List<String> get participantIds; String? get subject;/// Optional link to related appointment
 String? get appointmentId;/// Last message preview for list display
 String? get lastMessageText; String? get lastMessageSenderId;@NullableTimestampConverter() DateTime? get lastMessageAt;/// Unread count per user: { oderId: count }
 Map<String, int> get unreadCounts;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;/// If true, only staff can initiate messages (client can reply)
 bool get staffInitiatedOnly;/// Archived conversations are hidden but not deleted
 bool get isArchived;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&const DeepCollectionEquality().equals(other.participants, participants)&&const DeepCollectionEquality().equals(other.participantIds, participantIds)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&const DeepCollectionEquality().equals(other.unreadCounts, unreadCounts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.staffInitiatedOnly, staffInitiatedOnly) || other.staffInitiatedOnly == staffInitiatedOnly)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,const DeepCollectionEquality().hash(participants),const DeepCollectionEquality().hash(participantIds),subject,appointmentId,lastMessageText,lastMessageSenderId,lastMessageAt,const DeepCollectionEquality().hash(unreadCounts),createdAt,updatedAt,staffInitiatedOnly,isArchived);

@override
String toString() {
  return 'Conversation(id: $id, businessId: $businessId, participants: $participants, participantIds: $participantIds, subject: $subject, appointmentId: $appointmentId, lastMessageText: $lastMessageText, lastMessageSenderId: $lastMessageSenderId, lastMessageAt: $lastMessageAt, unreadCounts: $unreadCounts, createdAt: $createdAt, updatedAt: $updatedAt, staffInitiatedOnly: $staffInitiatedOnly, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, List<ConversationParticipant> participants, List<String> participantIds, String? subject, String? appointmentId, String? lastMessageText, String? lastMessageSenderId,@NullableTimestampConverter() DateTime? lastMessageAt, Map<String, int> unreadCounts,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, bool staffInitiatedOnly, bool isArchived
});




}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? participants = null,Object? participantIds = null,Object? subject = freezed,Object? appointmentId = freezed,Object? lastMessageText = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageAt = freezed,Object? unreadCounts = null,Object? createdAt = null,Object? updatedAt = freezed,Object? staffInitiatedOnly = null,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<ConversationParticipant>,participantIds: null == participantIds ? _self.participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unreadCounts: null == unreadCounts ? _self.unreadCounts : unreadCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,staffInitiatedOnly: null == staffInitiatedOnly ? _self.staffInitiatedOnly : staffInitiatedOnly // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  List<ConversationParticipant> participants,  List<String> participantIds,  String? subject,  String? appointmentId,  String? lastMessageText,  String? lastMessageSenderId, @NullableTimestampConverter()  DateTime? lastMessageAt,  Map<String, int> unreadCounts, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  bool staffInitiatedOnly,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.businessId,_that.participants,_that.participantIds,_that.subject,_that.appointmentId,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt,_that.unreadCounts,_that.createdAt,_that.updatedAt,_that.staffInitiatedOnly,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  List<ConversationParticipant> participants,  List<String> participantIds,  String? subject,  String? appointmentId,  String? lastMessageText,  String? lastMessageSenderId, @NullableTimestampConverter()  DateTime? lastMessageAt,  Map<String, int> unreadCounts, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  bool staffInitiatedOnly,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.businessId,_that.participants,_that.participantIds,_that.subject,_that.appointmentId,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt,_that.unreadCounts,_that.createdAt,_that.updatedAt,_that.staffInitiatedOnly,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  List<ConversationParticipant> participants,  List<String> participantIds,  String? subject,  String? appointmentId,  String? lastMessageText,  String? lastMessageSenderId, @NullableTimestampConverter()  DateTime? lastMessageAt,  Map<String, int> unreadCounts, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  bool staffInitiatedOnly,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.businessId,_that.participants,_that.participantIds,_that.subject,_that.appointmentId,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt,_that.unreadCounts,_that.createdAt,_that.updatedAt,_that.staffInitiatedOnly,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({required this.id, required this.businessId, required final  List<ConversationParticipant> participants, required final  List<String> participantIds, this.subject, this.appointmentId, this.lastMessageText, this.lastMessageSenderId, @NullableTimestampConverter() this.lastMessageAt, final  Map<String, int> unreadCounts = const {}, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt, this.staffInitiatedOnly = false, this.isArchived = false}): _participants = participants,_participantIds = participantIds,_unreadCounts = unreadCounts;
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
@override final  String businessId;
 final  List<ConversationParticipant> _participants;
@override List<ConversationParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

/// User IDs of all participants for querying
 final  List<String> _participantIds;
/// User IDs of all participants for querying
@override List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}

@override final  String? subject;
/// Optional link to related appointment
@override final  String? appointmentId;
/// Last message preview for list display
@override final  String? lastMessageText;
@override final  String? lastMessageSenderId;
@override@NullableTimestampConverter() final  DateTime? lastMessageAt;
/// Unread count per user: { oderId: count }
 final  Map<String, int> _unreadCounts;
/// Unread count per user: { oderId: count }
@override@JsonKey() Map<String, int> get unreadCounts {
  if (_unreadCounts is EqualUnmodifiableMapView) return _unreadCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_unreadCounts);
}

@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// If true, only staff can initiate messages (client can reply)
@override@JsonKey() final  bool staffInitiatedOnly;
/// Archived conversations are hidden but not deleted
@override@JsonKey() final  bool isArchived;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&const DeepCollectionEquality().equals(other._participants, _participants)&&const DeepCollectionEquality().equals(other._participantIds, _participantIds)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&const DeepCollectionEquality().equals(other._unreadCounts, _unreadCounts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.staffInitiatedOnly, staffInitiatedOnly) || other.staffInitiatedOnly == staffInitiatedOnly)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,const DeepCollectionEquality().hash(_participants),const DeepCollectionEquality().hash(_participantIds),subject,appointmentId,lastMessageText,lastMessageSenderId,lastMessageAt,const DeepCollectionEquality().hash(_unreadCounts),createdAt,updatedAt,staffInitiatedOnly,isArchived);

@override
String toString() {
  return 'Conversation(id: $id, businessId: $businessId, participants: $participants, participantIds: $participantIds, subject: $subject, appointmentId: $appointmentId, lastMessageText: $lastMessageText, lastMessageSenderId: $lastMessageSenderId, lastMessageAt: $lastMessageAt, unreadCounts: $unreadCounts, createdAt: $createdAt, updatedAt: $updatedAt, staffInitiatedOnly: $staffInitiatedOnly, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, List<ConversationParticipant> participants, List<String> participantIds, String? subject, String? appointmentId, String? lastMessageText, String? lastMessageSenderId,@NullableTimestampConverter() DateTime? lastMessageAt, Map<String, int> unreadCounts,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, bool staffInitiatedOnly, bool isArchived
});




}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? participants = null,Object? participantIds = null,Object? subject = freezed,Object? appointmentId = freezed,Object? lastMessageText = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageAt = freezed,Object? unreadCounts = null,Object? createdAt = null,Object? updatedAt = freezed,Object? staffInitiatedOnly = null,Object? isArchived = null,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ConversationParticipant>,participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unreadCounts: null == unreadCounts ? _self._unreadCounts : unreadCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,staffInitiatedOnly: null == staffInitiatedOnly ? _self.staffInitiatedOnly : staffInitiatedOnly // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MessageAttachment {

 String get id; String get fileName; String get url; String get mimeType; int? get sizeBytes;
/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentCopyWith<MessageAttachment> get copyWith => _$MessageAttachmentCopyWithImpl<MessageAttachment>(this as MessageAttachment, _$identity);

  /// Serializes this MessageAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.url, url) || other.url == url)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,url,mimeType,sizeBytes);

@override
String toString() {
  return 'MessageAttachment(id: $id, fileName: $fileName, url: $url, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentCopyWith<$Res>  {
  factory $MessageAttachmentCopyWith(MessageAttachment value, $Res Function(MessageAttachment) _then) = _$MessageAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String url, String mimeType, int? sizeBytes
});




}
/// @nodoc
class _$MessageAttachmentCopyWithImpl<$Res>
    implements $MessageAttachmentCopyWith<$Res> {
  _$MessageAttachmentCopyWithImpl(this._self, this._then);

  final MessageAttachment _self;
  final $Res Function(MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? url = null,Object? mimeType = null,Object? sizeBytes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachment].
extension MessageAttachmentPatterns on MessageAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachment value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String url,  String mimeType,  int? sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.fileName,_that.url,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String url,  String mimeType,  int? sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment():
return $default(_that.id,_that.fileName,_that.url,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String url,  String mimeType,  int? sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.fileName,_that.url,_that.mimeType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageAttachment implements MessageAttachment {
  const _MessageAttachment({required this.id, required this.fileName, required this.url, required this.mimeType, this.sizeBytes});
  factory _MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);

@override final  String id;
@override final  String fileName;
@override final  String url;
@override final  String mimeType;
@override final  int? sizeBytes;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentCopyWith<_MessageAttachment> get copyWith => __$MessageAttachmentCopyWithImpl<_MessageAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.url, url) || other.url == url)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,url,mimeType,sizeBytes);

@override
String toString() {
  return 'MessageAttachment(id: $id, fileName: $fileName, url: $url, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentCopyWith<$Res> implements $MessageAttachmentCopyWith<$Res> {
  factory _$MessageAttachmentCopyWith(_MessageAttachment value, $Res Function(_MessageAttachment) _then) = __$MessageAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String url, String mimeType, int? sizeBytes
});




}
/// @nodoc
class __$MessageAttachmentCopyWithImpl<$Res>
    implements _$MessageAttachmentCopyWith<$Res> {
  __$MessageAttachmentCopyWithImpl(this._self, this._then);

  final _MessageAttachment _self;
  final $Res Function(_MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? url = null,Object? mimeType = null,Object? sizeBytes = freezed,}) {
  return _then(_MessageAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Message {

 String get id; String get conversationId; String get senderId; String get senderName; String get content;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get editedAt; bool get isEdited; bool get isDeleted;/// For soft delete - show "This message was deleted"
 String? get deletedByUserId;/// Attachments (images, files)
 List<MessageAttachment> get attachments;/// Read receipts: { oderId: readAt }
@TimestampMapConverter() Map<String, DateTime> get readBy;/// System message (e.g., "X joined the conversation")
 bool get isSystemMessage;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedByUserId, deletedByUserId) || other.deletedByUserId == deletedByUserId)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.readBy, readBy)&&(identical(other.isSystemMessage, isSystemMessage) || other.isSystemMessage == isSystemMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,senderName,content,createdAt,editedAt,isEdited,isDeleted,deletedByUserId,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(readBy),isSystemMessage);

@override
String toString() {
  return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, senderName: $senderName, content: $content, createdAt: $createdAt, editedAt: $editedAt, isEdited: $isEdited, isDeleted: $isDeleted, deletedByUserId: $deletedByUserId, attachments: $attachments, readBy: $readBy, isSystemMessage: $isSystemMessage)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String senderId, String senderName, String content,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? editedAt, bool isEdited, bool isDeleted, String? deletedByUserId, List<MessageAttachment> attachments,@TimestampMapConverter() Map<String, DateTime> readBy, bool isSystemMessage
});




}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? senderName = null,Object? content = null,Object? createdAt = null,Object? editedAt = freezed,Object? isEdited = null,Object? isDeleted = null,Object? deletedByUserId = freezed,Object? attachments = null,Object? readBy = null,Object? isSystemMessage = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedByUserId: freezed == deletedByUserId ? _self.deletedByUserId : deletedByUserId // ignore: cast_nullable_to_non_nullable
as String?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,readBy: null == readBy ? _self.readBy : readBy // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,isSystemMessage: null == isSystemMessage ? _self.isSystemMessage : isSystemMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String senderName,  String content, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? editedAt,  bool isEdited,  bool isDeleted,  String? deletedByUserId,  List<MessageAttachment> attachments, @TimestampMapConverter()  Map<String, DateTime> readBy,  bool isSystemMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.senderName,_that.content,_that.createdAt,_that.editedAt,_that.isEdited,_that.isDeleted,_that.deletedByUserId,_that.attachments,_that.readBy,_that.isSystemMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String senderName,  String content, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? editedAt,  bool isEdited,  bool isDeleted,  String? deletedByUserId,  List<MessageAttachment> attachments, @TimestampMapConverter()  Map<String, DateTime> readBy,  bool isSystemMessage)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.conversationId,_that.senderId,_that.senderName,_that.content,_that.createdAt,_that.editedAt,_that.isEdited,_that.isDeleted,_that.deletedByUserId,_that.attachments,_that.readBy,_that.isSystemMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String senderId,  String senderName,  String content, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? editedAt,  bool isEdited,  bool isDeleted,  String? deletedByUserId,  List<MessageAttachment> attachments, @TimestampMapConverter()  Map<String, DateTime> readBy,  bool isSystemMessage)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.senderName,_that.content,_that.createdAt,_that.editedAt,_that.isEdited,_that.isDeleted,_that.deletedByUserId,_that.attachments,_that.readBy,_that.isSystemMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({required this.id, required this.conversationId, required this.senderId, required this.senderName, required this.content, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.editedAt, this.isEdited = false, this.isDeleted = false, this.deletedByUserId, final  List<MessageAttachment> attachments = const [], @TimestampMapConverter() final  Map<String, DateTime> readBy = const {}, this.isSystemMessage = false}): _attachments = attachments,_readBy = readBy;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  String conversationId;
@override final  String senderId;
@override final  String senderName;
@override final  String content;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? editedAt;
@override@JsonKey() final  bool isEdited;
@override@JsonKey() final  bool isDeleted;
/// For soft delete - show "This message was deleted"
@override final  String? deletedByUserId;
/// Attachments (images, files)
 final  List<MessageAttachment> _attachments;
/// Attachments (images, files)
@override@JsonKey() List<MessageAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

/// Read receipts: { oderId: readAt }
 final  Map<String, DateTime> _readBy;
/// Read receipts: { oderId: readAt }
@override@JsonKey()@TimestampMapConverter() Map<String, DateTime> get readBy {
  if (_readBy is EqualUnmodifiableMapView) return _readBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_readBy);
}

/// System message (e.g., "X joined the conversation")
@override@JsonKey() final  bool isSystemMessage;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedByUserId, deletedByUserId) || other.deletedByUserId == deletedByUserId)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._readBy, _readBy)&&(identical(other.isSystemMessage, isSystemMessage) || other.isSystemMessage == isSystemMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,senderName,content,createdAt,editedAt,isEdited,isDeleted,deletedByUserId,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_readBy),isSystemMessage);

@override
String toString() {
  return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, senderName: $senderName, content: $content, createdAt: $createdAt, editedAt: $editedAt, isEdited: $isEdited, isDeleted: $isDeleted, deletedByUserId: $deletedByUserId, attachments: $attachments, readBy: $readBy, isSystemMessage: $isSystemMessage)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String senderId, String senderName, String content,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? editedAt, bool isEdited, bool isDeleted, String? deletedByUserId, List<MessageAttachment> attachments,@TimestampMapConverter() Map<String, DateTime> readBy, bool isSystemMessage
});




}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? senderName = null,Object? content = null,Object? createdAt = null,Object? editedAt = freezed,Object? isEdited = null,Object? isDeleted = null,Object? deletedByUserId = freezed,Object? attachments = null,Object? readBy = null,Object? isSystemMessage = null,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedByUserId: freezed == deletedByUserId ? _self.deletedByUserId : deletedByUserId // ignore: cast_nullable_to_non_nullable
as String?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,readBy: null == readBy ? _self._readBy : readBy // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,isSystemMessage: null == isSystemMessage ? _self.isSystemMessage : isSystemMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
