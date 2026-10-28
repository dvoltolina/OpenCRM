// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BreakPeriod {

@_TimestampConverter() DateTime get startTime;@_NullableTimestampConverter() DateTime? get endTime; BreakType get type;
/// Create a copy of BreakPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreakPeriodCopyWith<BreakPeriod> get copyWith => _$BreakPeriodCopyWithImpl<BreakPeriod>(this as BreakPeriod, _$identity);

  /// Serializes this BreakPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreakPeriod&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,type);

@override
String toString() {
  return 'BreakPeriod(startTime: $startTime, endTime: $endTime, type: $type)';
}


}

/// @nodoc
abstract mixin class $BreakPeriodCopyWith<$Res>  {
  factory $BreakPeriodCopyWith(BreakPeriod value, $Res Function(BreakPeriod) _then) = _$BreakPeriodCopyWithImpl;
@useResult
$Res call({
@_TimestampConverter() DateTime startTime,@_NullableTimestampConverter() DateTime? endTime, BreakType type
});




}
/// @nodoc
class _$BreakPeriodCopyWithImpl<$Res>
    implements $BreakPeriodCopyWith<$Res> {
  _$BreakPeriodCopyWithImpl(this._self, this._then);

  final BreakPeriod _self;
  final $Res Function(BreakPeriod) _then;

/// Create a copy of BreakPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startTime = null,Object? endTime = freezed,Object? type = null,}) {
  return _then(_self.copyWith(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BreakType,
  ));
}

}


/// Adds pattern-matching-related methods to [BreakPeriod].
extension BreakPeriodPatterns on BreakPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreakPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreakPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreakPeriod value)  $default,){
final _that = this;
switch (_that) {
case _BreakPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreakPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _BreakPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@_TimestampConverter()  DateTime startTime, @_NullableTimestampConverter()  DateTime? endTime,  BreakType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreakPeriod() when $default != null:
return $default(_that.startTime,_that.endTime,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@_TimestampConverter()  DateTime startTime, @_NullableTimestampConverter()  DateTime? endTime,  BreakType type)  $default,) {final _that = this;
switch (_that) {
case _BreakPeriod():
return $default(_that.startTime,_that.endTime,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@_TimestampConverter()  DateTime startTime, @_NullableTimestampConverter()  DateTime? endTime,  BreakType type)?  $default,) {final _that = this;
switch (_that) {
case _BreakPeriod() when $default != null:
return $default(_that.startTime,_that.endTime,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BreakPeriod implements BreakPeriod {
  const _BreakPeriod({@_TimestampConverter() required this.startTime, @_NullableTimestampConverter() this.endTime, required this.type});
  factory _BreakPeriod.fromJson(Map<String, dynamic> json) => _$BreakPeriodFromJson(json);

@override@_TimestampConverter() final  DateTime startTime;
@override@_NullableTimestampConverter() final  DateTime? endTime;
@override final  BreakType type;

/// Create a copy of BreakPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreakPeriodCopyWith<_BreakPeriod> get copyWith => __$BreakPeriodCopyWithImpl<_BreakPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BreakPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreakPeriod&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,type);

@override
String toString() {
  return 'BreakPeriod(startTime: $startTime, endTime: $endTime, type: $type)';
}


}

/// @nodoc
abstract mixin class _$BreakPeriodCopyWith<$Res> implements $BreakPeriodCopyWith<$Res> {
  factory _$BreakPeriodCopyWith(_BreakPeriod value, $Res Function(_BreakPeriod) _then) = __$BreakPeriodCopyWithImpl;
@override @useResult
$Res call({
@_TimestampConverter() DateTime startTime,@_NullableTimestampConverter() DateTime? endTime, BreakType type
});




}
/// @nodoc
class __$BreakPeriodCopyWithImpl<$Res>
    implements _$BreakPeriodCopyWith<$Res> {
  __$BreakPeriodCopyWithImpl(this._self, this._then);

  final _BreakPeriod _self;
  final $Res Function(_BreakPeriod) _then;

/// Create a copy of BreakPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startTime = null,Object? endTime = freezed,Object? type = null,}) {
  return _then(_BreakPeriod(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BreakType,
  ));
}


}


/// @nodoc
mixin _$TimeEntry {

 String get id; String get businessId; String get staffId;// Clock in/out times
@_TimestampConverter() DateTime get clockInTime;@_NullableTimestampConverter() DateTime? get clockOutTime;// Clock-in location tracking (GPS)
 double? get clockInLatitude; double? get clockInLongitude; String? get clockInAddress;// Clock-out location tracking (GPS)
 double? get clockOutLatitude; double? get clockOutLongitude; String? get clockOutAddress;// Geo-fence validation
/// Business location ID if clocked in at a known location
 String? get clockInLocationId;/// Business location ID if clocked out at a known location
 String? get clockOutLocationId;/// True if clock-in was outside the geo-fence radius
 bool get clockInOutsideGeofence;/// True if clock-out was outside the geo-fence radius
 bool get clockOutOutsideGeofence;// Breaks
 List<BreakPeriod> get breaks;// Calculated fields (set on clock out)
/// Total minutes between clock-in and clock-out
 int? get totalMinutes;/// Total break time in minutes
 int? get breakMinutes;/// Worked minutes (totalMinutes - breakMinutes)
 int? get workedMinutes;// Status & approval
 TimeEntryStatus get status;/// User ID of manager who approved/rejected
 String? get approvedByUserId;/// When the entry was approved/rejected
@_NullableTimestampConverter() DateTime? get approvedAt;/// Reason for rejection (if status is rejected)
 String? get rejectionReason;// Notes
/// Notes added by staff member
 String? get staffNotes;/// Notes added by manager
 String? get managerNotes;// Audit fields
@_TimestampConverter() DateTime get createdAt;@_TimestampConverter() DateTime get updatedAt;
/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeEntryCopyWith<TimeEntry> get copyWith => _$TimeEntryCopyWithImpl<TimeEntry>(this as TimeEntry, _$identity);

  /// Serializes this TimeEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.clockInTime, clockInTime) || other.clockInTime == clockInTime)&&(identical(other.clockOutTime, clockOutTime) || other.clockOutTime == clockOutTime)&&(identical(other.clockInLatitude, clockInLatitude) || other.clockInLatitude == clockInLatitude)&&(identical(other.clockInLongitude, clockInLongitude) || other.clockInLongitude == clockInLongitude)&&(identical(other.clockInAddress, clockInAddress) || other.clockInAddress == clockInAddress)&&(identical(other.clockOutLatitude, clockOutLatitude) || other.clockOutLatitude == clockOutLatitude)&&(identical(other.clockOutLongitude, clockOutLongitude) || other.clockOutLongitude == clockOutLongitude)&&(identical(other.clockOutAddress, clockOutAddress) || other.clockOutAddress == clockOutAddress)&&(identical(other.clockInLocationId, clockInLocationId) || other.clockInLocationId == clockInLocationId)&&(identical(other.clockOutLocationId, clockOutLocationId) || other.clockOutLocationId == clockOutLocationId)&&(identical(other.clockInOutsideGeofence, clockInOutsideGeofence) || other.clockInOutsideGeofence == clockInOutsideGeofence)&&(identical(other.clockOutOutsideGeofence, clockOutOutsideGeofence) || other.clockOutOutsideGeofence == clockOutOutsideGeofence)&&const DeepCollectionEquality().equals(other.breaks, breaks)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.breakMinutes, breakMinutes) || other.breakMinutes == breakMinutes)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedByUserId, approvedByUserId) || other.approvedByUserId == approvedByUserId)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.staffNotes, staffNotes) || other.staffNotes == staffNotes)&&(identical(other.managerNotes, managerNotes) || other.managerNotes == managerNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,staffId,clockInTime,clockOutTime,clockInLatitude,clockInLongitude,clockInAddress,clockOutLatitude,clockOutLongitude,clockOutAddress,clockInLocationId,clockOutLocationId,clockInOutsideGeofence,clockOutOutsideGeofence,const DeepCollectionEquality().hash(breaks),totalMinutes,breakMinutes,workedMinutes,status,approvedByUserId,approvedAt,rejectionReason,staffNotes,managerNotes,createdAt,updatedAt]);

@override
String toString() {
  return 'TimeEntry(id: $id, businessId: $businessId, staffId: $staffId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockInAddress: $clockInAddress, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, clockOutAddress: $clockOutAddress, clockInLocationId: $clockInLocationId, clockOutLocationId: $clockOutLocationId, clockInOutsideGeofence: $clockInOutsideGeofence, clockOutOutsideGeofence: $clockOutOutsideGeofence, breaks: $breaks, totalMinutes: $totalMinutes, breakMinutes: $breakMinutes, workedMinutes: $workedMinutes, status: $status, approvedByUserId: $approvedByUserId, approvedAt: $approvedAt, rejectionReason: $rejectionReason, staffNotes: $staffNotes, managerNotes: $managerNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TimeEntryCopyWith<$Res>  {
  factory $TimeEntryCopyWith(TimeEntry value, $Res Function(TimeEntry) _then) = _$TimeEntryCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String staffId,@_TimestampConverter() DateTime clockInTime,@_NullableTimestampConverter() DateTime? clockOutTime, double? clockInLatitude, double? clockInLongitude, String? clockInAddress, double? clockOutLatitude, double? clockOutLongitude, String? clockOutAddress, String? clockInLocationId, String? clockOutLocationId, bool clockInOutsideGeofence, bool clockOutOutsideGeofence, List<BreakPeriod> breaks, int? totalMinutes, int? breakMinutes, int? workedMinutes, TimeEntryStatus status, String? approvedByUserId,@_NullableTimestampConverter() DateTime? approvedAt, String? rejectionReason, String? staffNotes, String? managerNotes,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$TimeEntryCopyWithImpl<$Res>
    implements $TimeEntryCopyWith<$Res> {
  _$TimeEntryCopyWithImpl(this._self, this._then);

  final TimeEntry _self;
  final $Res Function(TimeEntry) _then;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? staffId = null,Object? clockInTime = null,Object? clockOutTime = freezed,Object? clockInLatitude = freezed,Object? clockInLongitude = freezed,Object? clockInAddress = freezed,Object? clockOutLatitude = freezed,Object? clockOutLongitude = freezed,Object? clockOutAddress = freezed,Object? clockInLocationId = freezed,Object? clockOutLocationId = freezed,Object? clockInOutsideGeofence = null,Object? clockOutOutsideGeofence = null,Object? breaks = null,Object? totalMinutes = freezed,Object? breakMinutes = freezed,Object? workedMinutes = freezed,Object? status = null,Object? approvedByUserId = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? staffNotes = freezed,Object? managerNotes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,clockInTime: null == clockInTime ? _self.clockInTime : clockInTime // ignore: cast_nullable_to_non_nullable
as DateTime,clockOutTime: freezed == clockOutTime ? _self.clockOutTime : clockOutTime // ignore: cast_nullable_to_non_nullable
as DateTime?,clockInLatitude: freezed == clockInLatitude ? _self.clockInLatitude : clockInLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockInLongitude: freezed == clockInLongitude ? _self.clockInLongitude : clockInLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockInAddress: freezed == clockInAddress ? _self.clockInAddress : clockInAddress // ignore: cast_nullable_to_non_nullable
as String?,clockOutLatitude: freezed == clockOutLatitude ? _self.clockOutLatitude : clockOutLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLongitude: freezed == clockOutLongitude ? _self.clockOutLongitude : clockOutLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutAddress: freezed == clockOutAddress ? _self.clockOutAddress : clockOutAddress // ignore: cast_nullable_to_non_nullable
as String?,clockInLocationId: freezed == clockInLocationId ? _self.clockInLocationId : clockInLocationId // ignore: cast_nullable_to_non_nullable
as String?,clockOutLocationId: freezed == clockOutLocationId ? _self.clockOutLocationId : clockOutLocationId // ignore: cast_nullable_to_non_nullable
as String?,clockInOutsideGeofence: null == clockInOutsideGeofence ? _self.clockInOutsideGeofence : clockInOutsideGeofence // ignore: cast_nullable_to_non_nullable
as bool,clockOutOutsideGeofence: null == clockOutOutsideGeofence ? _self.clockOutOutsideGeofence : clockOutOutsideGeofence // ignore: cast_nullable_to_non_nullable
as bool,breaks: null == breaks ? _self.breaks : breaks // ignore: cast_nullable_to_non_nullable
as List<BreakPeriod>,totalMinutes: freezed == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int?,breakMinutes: freezed == breakMinutes ? _self.breakMinutes : breakMinutes // ignore: cast_nullable_to_non_nullable
as int?,workedMinutes: freezed == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimeEntryStatus,approvedByUserId: freezed == approvedByUserId ? _self.approvedByUserId : approvedByUserId // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,staffNotes: freezed == staffNotes ? _self.staffNotes : staffNotes // ignore: cast_nullable_to_non_nullable
as String?,managerNotes: freezed == managerNotes ? _self.managerNotes : managerNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeEntry].
extension TimeEntryPatterns on TimeEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeEntry value)  $default,){
final _that = this;
switch (_that) {
case _TimeEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String staffId, @_TimestampConverter()  DateTime clockInTime, @_NullableTimestampConverter()  DateTime? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  String? clockInAddress,  double? clockOutLatitude,  double? clockOutLongitude,  String? clockOutAddress,  String? clockInLocationId,  String? clockOutLocationId,  bool clockInOutsideGeofence,  bool clockOutOutsideGeofence,  List<BreakPeriod> breaks,  int? totalMinutes,  int? breakMinutes,  int? workedMinutes,  TimeEntryStatus status,  String? approvedByUserId, @_NullableTimestampConverter()  DateTime? approvedAt,  String? rejectionReason,  String? staffNotes,  String? managerNotes, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.staffId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockInAddress,_that.clockOutLatitude,_that.clockOutLongitude,_that.clockOutAddress,_that.clockInLocationId,_that.clockOutLocationId,_that.clockInOutsideGeofence,_that.clockOutOutsideGeofence,_that.breaks,_that.totalMinutes,_that.breakMinutes,_that.workedMinutes,_that.status,_that.approvedByUserId,_that.approvedAt,_that.rejectionReason,_that.staffNotes,_that.managerNotes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String staffId, @_TimestampConverter()  DateTime clockInTime, @_NullableTimestampConverter()  DateTime? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  String? clockInAddress,  double? clockOutLatitude,  double? clockOutLongitude,  String? clockOutAddress,  String? clockInLocationId,  String? clockOutLocationId,  bool clockInOutsideGeofence,  bool clockOutOutsideGeofence,  List<BreakPeriod> breaks,  int? totalMinutes,  int? breakMinutes,  int? workedMinutes,  TimeEntryStatus status,  String? approvedByUserId, @_NullableTimestampConverter()  DateTime? approvedAt,  String? rejectionReason,  String? staffNotes,  String? managerNotes, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TimeEntry():
return $default(_that.id,_that.businessId,_that.staffId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockInAddress,_that.clockOutLatitude,_that.clockOutLongitude,_that.clockOutAddress,_that.clockInLocationId,_that.clockOutLocationId,_that.clockInOutsideGeofence,_that.clockOutOutsideGeofence,_that.breaks,_that.totalMinutes,_that.breakMinutes,_that.workedMinutes,_that.status,_that.approvedByUserId,_that.approvedAt,_that.rejectionReason,_that.staffNotes,_that.managerNotes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String staffId, @_TimestampConverter()  DateTime clockInTime, @_NullableTimestampConverter()  DateTime? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  String? clockInAddress,  double? clockOutLatitude,  double? clockOutLongitude,  String? clockOutAddress,  String? clockInLocationId,  String? clockOutLocationId,  bool clockInOutsideGeofence,  bool clockOutOutsideGeofence,  List<BreakPeriod> breaks,  int? totalMinutes,  int? breakMinutes,  int? workedMinutes,  TimeEntryStatus status,  String? approvedByUserId, @_NullableTimestampConverter()  DateTime? approvedAt,  String? rejectionReason,  String? staffNotes,  String? managerNotes, @_TimestampConverter()  DateTime createdAt, @_TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.staffId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockInAddress,_that.clockOutLatitude,_that.clockOutLongitude,_that.clockOutAddress,_that.clockInLocationId,_that.clockOutLocationId,_that.clockInOutsideGeofence,_that.clockOutOutsideGeofence,_that.breaks,_that.totalMinutes,_that.breakMinutes,_that.workedMinutes,_that.status,_that.approvedByUserId,_that.approvedAt,_that.rejectionReason,_that.staffNotes,_that.managerNotes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeEntry implements TimeEntry {
  const _TimeEntry({required this.id, required this.businessId, required this.staffId, @_TimestampConverter() required this.clockInTime, @_NullableTimestampConverter() this.clockOutTime, this.clockInLatitude, this.clockInLongitude, this.clockInAddress, this.clockOutLatitude, this.clockOutLongitude, this.clockOutAddress, this.clockInLocationId, this.clockOutLocationId, this.clockInOutsideGeofence = false, this.clockOutOutsideGeofence = false, final  List<BreakPeriod> breaks = const [], this.totalMinutes, this.breakMinutes, this.workedMinutes, required this.status, this.approvedByUserId, @_NullableTimestampConverter() this.approvedAt, this.rejectionReason, this.staffNotes, this.managerNotes, @_TimestampConverter() required this.createdAt, @_TimestampConverter() required this.updatedAt}): _breaks = breaks;
  factory _TimeEntry.fromJson(Map<String, dynamic> json) => _$TimeEntryFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String staffId;
// Clock in/out times
@override@_TimestampConverter() final  DateTime clockInTime;
@override@_NullableTimestampConverter() final  DateTime? clockOutTime;
// Clock-in location tracking (GPS)
@override final  double? clockInLatitude;
@override final  double? clockInLongitude;
@override final  String? clockInAddress;
// Clock-out location tracking (GPS)
@override final  double? clockOutLatitude;
@override final  double? clockOutLongitude;
@override final  String? clockOutAddress;
// Geo-fence validation
/// Business location ID if clocked in at a known location
@override final  String? clockInLocationId;
/// Business location ID if clocked out at a known location
@override final  String? clockOutLocationId;
/// True if clock-in was outside the geo-fence radius
@override@JsonKey() final  bool clockInOutsideGeofence;
/// True if clock-out was outside the geo-fence radius
@override@JsonKey() final  bool clockOutOutsideGeofence;
// Breaks
 final  List<BreakPeriod> _breaks;
// Breaks
@override@JsonKey() List<BreakPeriod> get breaks {
  if (_breaks is EqualUnmodifiableListView) return _breaks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breaks);
}

// Calculated fields (set on clock out)
/// Total minutes between clock-in and clock-out
@override final  int? totalMinutes;
/// Total break time in minutes
@override final  int? breakMinutes;
/// Worked minutes (totalMinutes - breakMinutes)
@override final  int? workedMinutes;
// Status & approval
@override final  TimeEntryStatus status;
/// User ID of manager who approved/rejected
@override final  String? approvedByUserId;
/// When the entry was approved/rejected
@override@_NullableTimestampConverter() final  DateTime? approvedAt;
/// Reason for rejection (if status is rejected)
@override final  String? rejectionReason;
// Notes
/// Notes added by staff member
@override final  String? staffNotes;
/// Notes added by manager
@override final  String? managerNotes;
// Audit fields
@override@_TimestampConverter() final  DateTime createdAt;
@override@_TimestampConverter() final  DateTime updatedAt;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeEntryCopyWith<_TimeEntry> get copyWith => __$TimeEntryCopyWithImpl<_TimeEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.clockInTime, clockInTime) || other.clockInTime == clockInTime)&&(identical(other.clockOutTime, clockOutTime) || other.clockOutTime == clockOutTime)&&(identical(other.clockInLatitude, clockInLatitude) || other.clockInLatitude == clockInLatitude)&&(identical(other.clockInLongitude, clockInLongitude) || other.clockInLongitude == clockInLongitude)&&(identical(other.clockInAddress, clockInAddress) || other.clockInAddress == clockInAddress)&&(identical(other.clockOutLatitude, clockOutLatitude) || other.clockOutLatitude == clockOutLatitude)&&(identical(other.clockOutLongitude, clockOutLongitude) || other.clockOutLongitude == clockOutLongitude)&&(identical(other.clockOutAddress, clockOutAddress) || other.clockOutAddress == clockOutAddress)&&(identical(other.clockInLocationId, clockInLocationId) || other.clockInLocationId == clockInLocationId)&&(identical(other.clockOutLocationId, clockOutLocationId) || other.clockOutLocationId == clockOutLocationId)&&(identical(other.clockInOutsideGeofence, clockInOutsideGeofence) || other.clockInOutsideGeofence == clockInOutsideGeofence)&&(identical(other.clockOutOutsideGeofence, clockOutOutsideGeofence) || other.clockOutOutsideGeofence == clockOutOutsideGeofence)&&const DeepCollectionEquality().equals(other._breaks, _breaks)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.breakMinutes, breakMinutes) || other.breakMinutes == breakMinutes)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedByUserId, approvedByUserId) || other.approvedByUserId == approvedByUserId)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.staffNotes, staffNotes) || other.staffNotes == staffNotes)&&(identical(other.managerNotes, managerNotes) || other.managerNotes == managerNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,staffId,clockInTime,clockOutTime,clockInLatitude,clockInLongitude,clockInAddress,clockOutLatitude,clockOutLongitude,clockOutAddress,clockInLocationId,clockOutLocationId,clockInOutsideGeofence,clockOutOutsideGeofence,const DeepCollectionEquality().hash(_breaks),totalMinutes,breakMinutes,workedMinutes,status,approvedByUserId,approvedAt,rejectionReason,staffNotes,managerNotes,createdAt,updatedAt]);

@override
String toString() {
  return 'TimeEntry(id: $id, businessId: $businessId, staffId: $staffId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockInAddress: $clockInAddress, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, clockOutAddress: $clockOutAddress, clockInLocationId: $clockInLocationId, clockOutLocationId: $clockOutLocationId, clockInOutsideGeofence: $clockInOutsideGeofence, clockOutOutsideGeofence: $clockOutOutsideGeofence, breaks: $breaks, totalMinutes: $totalMinutes, breakMinutes: $breakMinutes, workedMinutes: $workedMinutes, status: $status, approvedByUserId: $approvedByUserId, approvedAt: $approvedAt, rejectionReason: $rejectionReason, staffNotes: $staffNotes, managerNotes: $managerNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TimeEntryCopyWith<$Res> implements $TimeEntryCopyWith<$Res> {
  factory _$TimeEntryCopyWith(_TimeEntry value, $Res Function(_TimeEntry) _then) = __$TimeEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String staffId,@_TimestampConverter() DateTime clockInTime,@_NullableTimestampConverter() DateTime? clockOutTime, double? clockInLatitude, double? clockInLongitude, String? clockInAddress, double? clockOutLatitude, double? clockOutLongitude, String? clockOutAddress, String? clockInLocationId, String? clockOutLocationId, bool clockInOutsideGeofence, bool clockOutOutsideGeofence, List<BreakPeriod> breaks, int? totalMinutes, int? breakMinutes, int? workedMinutes, TimeEntryStatus status, String? approvedByUserId,@_NullableTimestampConverter() DateTime? approvedAt, String? rejectionReason, String? staffNotes, String? managerNotes,@_TimestampConverter() DateTime createdAt,@_TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$TimeEntryCopyWithImpl<$Res>
    implements _$TimeEntryCopyWith<$Res> {
  __$TimeEntryCopyWithImpl(this._self, this._then);

  final _TimeEntry _self;
  final $Res Function(_TimeEntry) _then;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? staffId = null,Object? clockInTime = null,Object? clockOutTime = freezed,Object? clockInLatitude = freezed,Object? clockInLongitude = freezed,Object? clockInAddress = freezed,Object? clockOutLatitude = freezed,Object? clockOutLongitude = freezed,Object? clockOutAddress = freezed,Object? clockInLocationId = freezed,Object? clockOutLocationId = freezed,Object? clockInOutsideGeofence = null,Object? clockOutOutsideGeofence = null,Object? breaks = null,Object? totalMinutes = freezed,Object? breakMinutes = freezed,Object? workedMinutes = freezed,Object? status = null,Object? approvedByUserId = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? staffNotes = freezed,Object? managerNotes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TimeEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,clockInTime: null == clockInTime ? _self.clockInTime : clockInTime // ignore: cast_nullable_to_non_nullable
as DateTime,clockOutTime: freezed == clockOutTime ? _self.clockOutTime : clockOutTime // ignore: cast_nullable_to_non_nullable
as DateTime?,clockInLatitude: freezed == clockInLatitude ? _self.clockInLatitude : clockInLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockInLongitude: freezed == clockInLongitude ? _self.clockInLongitude : clockInLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockInAddress: freezed == clockInAddress ? _self.clockInAddress : clockInAddress // ignore: cast_nullable_to_non_nullable
as String?,clockOutLatitude: freezed == clockOutLatitude ? _self.clockOutLatitude : clockOutLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLongitude: freezed == clockOutLongitude ? _self.clockOutLongitude : clockOutLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutAddress: freezed == clockOutAddress ? _self.clockOutAddress : clockOutAddress // ignore: cast_nullable_to_non_nullable
as String?,clockInLocationId: freezed == clockInLocationId ? _self.clockInLocationId : clockInLocationId // ignore: cast_nullable_to_non_nullable
as String?,clockOutLocationId: freezed == clockOutLocationId ? _self.clockOutLocationId : clockOutLocationId // ignore: cast_nullable_to_non_nullable
as String?,clockInOutsideGeofence: null == clockInOutsideGeofence ? _self.clockInOutsideGeofence : clockInOutsideGeofence // ignore: cast_nullable_to_non_nullable
as bool,clockOutOutsideGeofence: null == clockOutOutsideGeofence ? _self.clockOutOutsideGeofence : clockOutOutsideGeofence // ignore: cast_nullable_to_non_nullable
as bool,breaks: null == breaks ? _self._breaks : breaks // ignore: cast_nullable_to_non_nullable
as List<BreakPeriod>,totalMinutes: freezed == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int?,breakMinutes: freezed == breakMinutes ? _self.breakMinutes : breakMinutes // ignore: cast_nullable_to_non_nullable
as int?,workedMinutes: freezed == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimeEntryStatus,approvedByUserId: freezed == approvedByUserId ? _self.approvedByUserId : approvedByUserId // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,staffNotes: freezed == staffNotes ? _self.staffNotes : staffNotes // ignore: cast_nullable_to_non_nullable
as String?,managerNotes: freezed == managerNotes ? _self.managerNotes : managerNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
