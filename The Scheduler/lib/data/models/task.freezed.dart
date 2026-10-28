// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id; String get businessId; String get title; String? get description;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get dueDate; TaskPriority get priority; TaskStatus get status;/// The provider/staff member assigned to this task
 String? get assignedToProviderId; String? get assignedToProviderName;/// Optional link to a client
 String? get linkedClientId; String? get linkedClientName;/// Optional link to an appointment
 String? get linkedAppointmentId;/// When task was completed
@NullableTimestampConverter() DateTime? get completedAt;/// User who created the task
 String? get createdByUserId; String? get createdByUserName;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedToProviderId, assignedToProviderId) || other.assignedToProviderId == assignedToProviderId)&&(identical(other.assignedToProviderName, assignedToProviderName) || other.assignedToProviderName == assignedToProviderName)&&(identical(other.linkedClientId, linkedClientId) || other.linkedClientId == linkedClientId)&&(identical(other.linkedClientName, linkedClientName) || other.linkedClientName == linkedClientName)&&(identical(other.linkedAppointmentId, linkedAppointmentId) || other.linkedAppointmentId == linkedAppointmentId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.createdByUserName, createdByUserName) || other.createdByUserName == createdByUserName)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,title,description,createdAt,dueDate,priority,status,assignedToProviderId,assignedToProviderName,linkedClientId,linkedClientName,linkedAppointmentId,completedAt,createdByUserId,createdByUserName,updatedAt);

@override
String toString() {
  return 'Task(id: $id, businessId: $businessId, title: $title, description: $description, createdAt: $createdAt, dueDate: $dueDate, priority: $priority, status: $status, assignedToProviderId: $assignedToProviderId, assignedToProviderName: $assignedToProviderName, linkedClientId: $linkedClientId, linkedClientName: $linkedClientName, linkedAppointmentId: $linkedAppointmentId, completedAt: $completedAt, createdByUserId: $createdByUserId, createdByUserName: $createdByUserName, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String title, String? description,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? dueDate, TaskPriority priority, TaskStatus status, String? assignedToProviderId, String? assignedToProviderName, String? linkedClientId, String? linkedClientName, String? linkedAppointmentId,@NullableTimestampConverter() DateTime? completedAt, String? createdByUserId, String? createdByUserName,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? title = null,Object? description = freezed,Object? createdAt = null,Object? dueDate = freezed,Object? priority = null,Object? status = null,Object? assignedToProviderId = freezed,Object? assignedToProviderName = freezed,Object? linkedClientId = freezed,Object? linkedClientName = freezed,Object? linkedAppointmentId = freezed,Object? completedAt = freezed,Object? createdByUserId = freezed,Object? createdByUserName = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,assignedToProviderId: freezed == assignedToProviderId ? _self.assignedToProviderId : assignedToProviderId // ignore: cast_nullable_to_non_nullable
as String?,assignedToProviderName: freezed == assignedToProviderName ? _self.assignedToProviderName : assignedToProviderName // ignore: cast_nullable_to_non_nullable
as String?,linkedClientId: freezed == linkedClientId ? _self.linkedClientId : linkedClientId // ignore: cast_nullable_to_non_nullable
as String?,linkedClientName: freezed == linkedClientName ? _self.linkedClientName : linkedClientName // ignore: cast_nullable_to_non_nullable
as String?,linkedAppointmentId: freezed == linkedAppointmentId ? _self.linkedAppointmentId : linkedAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,createdByUserName: freezed == createdByUserName ? _self.createdByUserName : createdByUserName // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String title,  String? description, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? dueDate,  TaskPriority priority,  TaskStatus status,  String? assignedToProviderId,  String? assignedToProviderName,  String? linkedClientId,  String? linkedClientName,  String? linkedAppointmentId, @NullableTimestampConverter()  DateTime? completedAt,  String? createdByUserId,  String? createdByUserName, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.businessId,_that.title,_that.description,_that.createdAt,_that.dueDate,_that.priority,_that.status,_that.assignedToProviderId,_that.assignedToProviderName,_that.linkedClientId,_that.linkedClientName,_that.linkedAppointmentId,_that.completedAt,_that.createdByUserId,_that.createdByUserName,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String title,  String? description, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? dueDate,  TaskPriority priority,  TaskStatus status,  String? assignedToProviderId,  String? assignedToProviderName,  String? linkedClientId,  String? linkedClientName,  String? linkedAppointmentId, @NullableTimestampConverter()  DateTime? completedAt,  String? createdByUserId,  String? createdByUserName, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.businessId,_that.title,_that.description,_that.createdAt,_that.dueDate,_that.priority,_that.status,_that.assignedToProviderId,_that.assignedToProviderName,_that.linkedClientId,_that.linkedClientName,_that.linkedAppointmentId,_that.completedAt,_that.createdByUserId,_that.createdByUserName,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String title,  String? description, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? dueDate,  TaskPriority priority,  TaskStatus status,  String? assignedToProviderId,  String? assignedToProviderName,  String? linkedClientId,  String? linkedClientName,  String? linkedAppointmentId, @NullableTimestampConverter()  DateTime? completedAt,  String? createdByUserId,  String? createdByUserName, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.businessId,_that.title,_that.description,_that.createdAt,_that.dueDate,_that.priority,_that.status,_that.assignedToProviderId,_that.assignedToProviderName,_that.linkedClientId,_that.linkedClientName,_that.linkedAppointmentId,_that.completedAt,_that.createdByUserId,_that.createdByUserName,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task extends Task {
  const _Task({required this.id, required this.businessId, required this.title, this.description, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.dueDate, this.priority = TaskPriority.medium, this.status = TaskStatus.pending, this.assignedToProviderId, this.assignedToProviderName, this.linkedClientId, this.linkedClientName, this.linkedAppointmentId, @NullableTimestampConverter() this.completedAt, this.createdByUserId, this.createdByUserName, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String title;
@override final  String? description;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? dueDate;
@override@JsonKey() final  TaskPriority priority;
@override@JsonKey() final  TaskStatus status;
/// The provider/staff member assigned to this task
@override final  String? assignedToProviderId;
@override final  String? assignedToProviderName;
/// Optional link to a client
@override final  String? linkedClientId;
@override final  String? linkedClientName;
/// Optional link to an appointment
@override final  String? linkedAppointmentId;
/// When task was completed
@override@NullableTimestampConverter() final  DateTime? completedAt;
/// User who created the task
@override final  String? createdByUserId;
@override final  String? createdByUserName;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedToProviderId, assignedToProviderId) || other.assignedToProviderId == assignedToProviderId)&&(identical(other.assignedToProviderName, assignedToProviderName) || other.assignedToProviderName == assignedToProviderName)&&(identical(other.linkedClientId, linkedClientId) || other.linkedClientId == linkedClientId)&&(identical(other.linkedClientName, linkedClientName) || other.linkedClientName == linkedClientName)&&(identical(other.linkedAppointmentId, linkedAppointmentId) || other.linkedAppointmentId == linkedAppointmentId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.createdByUserName, createdByUserName) || other.createdByUserName == createdByUserName)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,title,description,createdAt,dueDate,priority,status,assignedToProviderId,assignedToProviderName,linkedClientId,linkedClientName,linkedAppointmentId,completedAt,createdByUserId,createdByUserName,updatedAt);

@override
String toString() {
  return 'Task(id: $id, businessId: $businessId, title: $title, description: $description, createdAt: $createdAt, dueDate: $dueDate, priority: $priority, status: $status, assignedToProviderId: $assignedToProviderId, assignedToProviderName: $assignedToProviderName, linkedClientId: $linkedClientId, linkedClientName: $linkedClientName, linkedAppointmentId: $linkedAppointmentId, completedAt: $completedAt, createdByUserId: $createdByUserId, createdByUserName: $createdByUserName, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String title, String? description,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? dueDate, TaskPriority priority, TaskStatus status, String? assignedToProviderId, String? assignedToProviderName, String? linkedClientId, String? linkedClientName, String? linkedAppointmentId,@NullableTimestampConverter() DateTime? completedAt, String? createdByUserId, String? createdByUserName,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? title = null,Object? description = freezed,Object? createdAt = null,Object? dueDate = freezed,Object? priority = null,Object? status = null,Object? assignedToProviderId = freezed,Object? assignedToProviderName = freezed,Object? linkedClientId = freezed,Object? linkedClientName = freezed,Object? linkedAppointmentId = freezed,Object? completedAt = freezed,Object? createdByUserId = freezed,Object? createdByUserName = freezed,Object? updatedAt = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,assignedToProviderId: freezed == assignedToProviderId ? _self.assignedToProviderId : assignedToProviderId // ignore: cast_nullable_to_non_nullable
as String?,assignedToProviderName: freezed == assignedToProviderName ? _self.assignedToProviderName : assignedToProviderName // ignore: cast_nullable_to_non_nullable
as String?,linkedClientId: freezed == linkedClientId ? _self.linkedClientId : linkedClientId // ignore: cast_nullable_to_non_nullable
as String?,linkedClientName: freezed == linkedClientName ? _self.linkedClientName : linkedClientName // ignore: cast_nullable_to_non_nullable
as String?,linkedAppointmentId: freezed == linkedAppointmentId ? _self.linkedAppointmentId : linkedAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,createdByUserName: freezed == createdByUserName ? _self.createdByUserName : createdByUserName // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
