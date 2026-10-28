// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'waitlist_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaitlistEntry {

 String get id; String get businessId; String? get clientId; String get clientName; String? get clientEmail; String? get clientPhone; String get serviceId; String? get serviceName; String? get providerId; String? get providerName; String? get locationId; List<int> get preferredDaysOfWeek; List<TimeOfDayPreference> get timeOfDayPreferences;@TimestampConverter() DateTime get earliestDate;@TimestampConverter() DateTime get latestDate; double get priorityScore; NotificationPreference get notificationPreference; WaitlistStatus get status;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;@NullableTimestampConverter() DateTime? get lastNotifiedAt;@NullableTimestampConverter() DateTime? get responseExpiresAt;@NullableTimestampConverter() DateTime? get expiresAt; String? get notes;
/// Create a copy of WaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitlistEntryCopyWith<WaitlistEntry> get copyWith => _$WaitlistEntryCopyWithImpl<WaitlistEntry>(this as WaitlistEntry, _$identity);

  /// Serializes this WaitlistEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitlistEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&const DeepCollectionEquality().equals(other.preferredDaysOfWeek, preferredDaysOfWeek)&&const DeepCollectionEquality().equals(other.timeOfDayPreferences, timeOfDayPreferences)&&(identical(other.earliestDate, earliestDate) || other.earliestDate == earliestDate)&&(identical(other.latestDate, latestDate) || other.latestDate == latestDate)&&(identical(other.priorityScore, priorityScore) || other.priorityScore == priorityScore)&&(identical(other.notificationPreference, notificationPreference) || other.notificationPreference == notificationPreference)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastNotifiedAt, lastNotifiedAt) || other.lastNotifiedAt == lastNotifiedAt)&&(identical(other.responseExpiresAt, responseExpiresAt) || other.responseExpiresAt == responseExpiresAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,clientId,clientName,clientEmail,clientPhone,serviceId,serviceName,providerId,providerName,locationId,const DeepCollectionEquality().hash(preferredDaysOfWeek),const DeepCollectionEquality().hash(timeOfDayPreferences),earliestDate,latestDate,priorityScore,notificationPreference,status,createdAt,updatedAt,lastNotifiedAt,responseExpiresAt,expiresAt,notes]);

@override
String toString() {
  return 'WaitlistEntry(id: $id, businessId: $businessId, clientId: $clientId, clientName: $clientName, clientEmail: $clientEmail, clientPhone: $clientPhone, serviceId: $serviceId, serviceName: $serviceName, providerId: $providerId, providerName: $providerName, locationId: $locationId, preferredDaysOfWeek: $preferredDaysOfWeek, timeOfDayPreferences: $timeOfDayPreferences, earliestDate: $earliestDate, latestDate: $latestDate, priorityScore: $priorityScore, notificationPreference: $notificationPreference, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, lastNotifiedAt: $lastNotifiedAt, responseExpiresAt: $responseExpiresAt, expiresAt: $expiresAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $WaitlistEntryCopyWith<$Res>  {
  factory $WaitlistEntryCopyWith(WaitlistEntry value, $Res Function(WaitlistEntry) _then) = _$WaitlistEntryCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String? clientId, String clientName, String? clientEmail, String? clientPhone, String serviceId, String? serviceName, String? providerId, String? providerName, String? locationId, List<int> preferredDaysOfWeek, List<TimeOfDayPreference> timeOfDayPreferences,@TimestampConverter() DateTime earliestDate,@TimestampConverter() DateTime latestDate, double priorityScore, NotificationPreference notificationPreference, WaitlistStatus status,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? lastNotifiedAt,@NullableTimestampConverter() DateTime? responseExpiresAt,@NullableTimestampConverter() DateTime? expiresAt, String? notes
});




}
/// @nodoc
class _$WaitlistEntryCopyWithImpl<$Res>
    implements $WaitlistEntryCopyWith<$Res> {
  _$WaitlistEntryCopyWithImpl(this._self, this._then);

  final WaitlistEntry _self;
  final $Res Function(WaitlistEntry) _then;

/// Create a copy of WaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? clientId = freezed,Object? clientName = null,Object? clientEmail = freezed,Object? clientPhone = freezed,Object? serviceId = null,Object? serviceName = freezed,Object? providerId = freezed,Object? providerName = freezed,Object? locationId = freezed,Object? preferredDaysOfWeek = null,Object? timeOfDayPreferences = null,Object? earliestDate = null,Object? latestDate = null,Object? priorityScore = null,Object? notificationPreference = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? lastNotifiedAt = freezed,Object? responseExpiresAt = freezed,Object? expiresAt = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientEmail: freezed == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String?,clientPhone: freezed == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String?,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,preferredDaysOfWeek: null == preferredDaysOfWeek ? _self.preferredDaysOfWeek : preferredDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,timeOfDayPreferences: null == timeOfDayPreferences ? _self.timeOfDayPreferences : timeOfDayPreferences // ignore: cast_nullable_to_non_nullable
as List<TimeOfDayPreference>,earliestDate: null == earliestDate ? _self.earliestDate : earliestDate // ignore: cast_nullable_to_non_nullable
as DateTime,latestDate: null == latestDate ? _self.latestDate : latestDate // ignore: cast_nullable_to_non_nullable
as DateTime,priorityScore: null == priorityScore ? _self.priorityScore : priorityScore // ignore: cast_nullable_to_non_nullable
as double,notificationPreference: null == notificationPreference ? _self.notificationPreference : notificationPreference // ignore: cast_nullable_to_non_nullable
as NotificationPreference,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WaitlistStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastNotifiedAt: freezed == lastNotifiedAt ? _self.lastNotifiedAt : lastNotifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,responseExpiresAt: freezed == responseExpiresAt ? _self.responseExpiresAt : responseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitlistEntry].
extension WaitlistEntryPatterns on WaitlistEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitlistEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitlistEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitlistEntry value)  $default,){
final _that = this;
switch (_that) {
case _WaitlistEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitlistEntry value)?  $default,){
final _that = this;
switch (_that) {
case _WaitlistEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String? clientId,  String clientName,  String? clientEmail,  String? clientPhone,  String serviceId,  String? serviceName,  String? providerId,  String? providerName,  String? locationId,  List<int> preferredDaysOfWeek,  List<TimeOfDayPreference> timeOfDayPreferences, @TimestampConverter()  DateTime earliestDate, @TimestampConverter()  DateTime latestDate,  double priorityScore,  NotificationPreference notificationPreference,  WaitlistStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? lastNotifiedAt, @NullableTimestampConverter()  DateTime? responseExpiresAt, @NullableTimestampConverter()  DateTime? expiresAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitlistEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.clientName,_that.clientEmail,_that.clientPhone,_that.serviceId,_that.serviceName,_that.providerId,_that.providerName,_that.locationId,_that.preferredDaysOfWeek,_that.timeOfDayPreferences,_that.earliestDate,_that.latestDate,_that.priorityScore,_that.notificationPreference,_that.status,_that.createdAt,_that.updatedAt,_that.lastNotifiedAt,_that.responseExpiresAt,_that.expiresAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String? clientId,  String clientName,  String? clientEmail,  String? clientPhone,  String serviceId,  String? serviceName,  String? providerId,  String? providerName,  String? locationId,  List<int> preferredDaysOfWeek,  List<TimeOfDayPreference> timeOfDayPreferences, @TimestampConverter()  DateTime earliestDate, @TimestampConverter()  DateTime latestDate,  double priorityScore,  NotificationPreference notificationPreference,  WaitlistStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? lastNotifiedAt, @NullableTimestampConverter()  DateTime? responseExpiresAt, @NullableTimestampConverter()  DateTime? expiresAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _WaitlistEntry():
return $default(_that.id,_that.businessId,_that.clientId,_that.clientName,_that.clientEmail,_that.clientPhone,_that.serviceId,_that.serviceName,_that.providerId,_that.providerName,_that.locationId,_that.preferredDaysOfWeek,_that.timeOfDayPreferences,_that.earliestDate,_that.latestDate,_that.priorityScore,_that.notificationPreference,_that.status,_that.createdAt,_that.updatedAt,_that.lastNotifiedAt,_that.responseExpiresAt,_that.expiresAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String? clientId,  String clientName,  String? clientEmail,  String? clientPhone,  String serviceId,  String? serviceName,  String? providerId,  String? providerName,  String? locationId,  List<int> preferredDaysOfWeek,  List<TimeOfDayPreference> timeOfDayPreferences, @TimestampConverter()  DateTime earliestDate, @TimestampConverter()  DateTime latestDate,  double priorityScore,  NotificationPreference notificationPreference,  WaitlistStatus status, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? lastNotifiedAt, @NullableTimestampConverter()  DateTime? responseExpiresAt, @NullableTimestampConverter()  DateTime? expiresAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _WaitlistEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.clientName,_that.clientEmail,_that.clientPhone,_that.serviceId,_that.serviceName,_that.providerId,_that.providerName,_that.locationId,_that.preferredDaysOfWeek,_that.timeOfDayPreferences,_that.earliestDate,_that.latestDate,_that.priorityScore,_that.notificationPreference,_that.status,_that.createdAt,_that.updatedAt,_that.lastNotifiedAt,_that.responseExpiresAt,_that.expiresAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitlistEntry extends WaitlistEntry {
  const _WaitlistEntry({required this.id, required this.businessId, this.clientId, required this.clientName, this.clientEmail, this.clientPhone, required this.serviceId, this.serviceName, this.providerId, this.providerName, this.locationId, final  List<int> preferredDaysOfWeek = const <int>[], final  List<TimeOfDayPreference> timeOfDayPreferences = const <TimeOfDayPreference>[TimeOfDayPreference.anytime], @TimestampConverter() required this.earliestDate, @TimestampConverter() required this.latestDate, this.priorityScore = 0.0, this.notificationPreference = NotificationPreference.email, this.status = WaitlistStatus.active, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt, @NullableTimestampConverter() this.lastNotifiedAt, @NullableTimestampConverter() this.responseExpiresAt, @NullableTimestampConverter() this.expiresAt, this.notes}): _preferredDaysOfWeek = preferredDaysOfWeek,_timeOfDayPreferences = timeOfDayPreferences,super._();
  factory _WaitlistEntry.fromJson(Map<String, dynamic> json) => _$WaitlistEntryFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String? clientId;
@override final  String clientName;
@override final  String? clientEmail;
@override final  String? clientPhone;
@override final  String serviceId;
@override final  String? serviceName;
@override final  String? providerId;
@override final  String? providerName;
@override final  String? locationId;
 final  List<int> _preferredDaysOfWeek;
@override@JsonKey() List<int> get preferredDaysOfWeek {
  if (_preferredDaysOfWeek is EqualUnmodifiableListView) return _preferredDaysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredDaysOfWeek);
}

 final  List<TimeOfDayPreference> _timeOfDayPreferences;
@override@JsonKey() List<TimeOfDayPreference> get timeOfDayPreferences {
  if (_timeOfDayPreferences is EqualUnmodifiableListView) return _timeOfDayPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeOfDayPreferences);
}

@override@TimestampConverter() final  DateTime earliestDate;
@override@TimestampConverter() final  DateTime latestDate;
@override@JsonKey() final  double priorityScore;
@override@JsonKey() final  NotificationPreference notificationPreference;
@override@JsonKey() final  WaitlistStatus status;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;
@override@NullableTimestampConverter() final  DateTime? lastNotifiedAt;
@override@NullableTimestampConverter() final  DateTime? responseExpiresAt;
@override@NullableTimestampConverter() final  DateTime? expiresAt;
@override final  String? notes;

/// Create a copy of WaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitlistEntryCopyWith<_WaitlistEntry> get copyWith => __$WaitlistEntryCopyWithImpl<_WaitlistEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitlistEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitlistEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&const DeepCollectionEquality().equals(other._preferredDaysOfWeek, _preferredDaysOfWeek)&&const DeepCollectionEquality().equals(other._timeOfDayPreferences, _timeOfDayPreferences)&&(identical(other.earliestDate, earliestDate) || other.earliestDate == earliestDate)&&(identical(other.latestDate, latestDate) || other.latestDate == latestDate)&&(identical(other.priorityScore, priorityScore) || other.priorityScore == priorityScore)&&(identical(other.notificationPreference, notificationPreference) || other.notificationPreference == notificationPreference)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastNotifiedAt, lastNotifiedAt) || other.lastNotifiedAt == lastNotifiedAt)&&(identical(other.responseExpiresAt, responseExpiresAt) || other.responseExpiresAt == responseExpiresAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,clientId,clientName,clientEmail,clientPhone,serviceId,serviceName,providerId,providerName,locationId,const DeepCollectionEquality().hash(_preferredDaysOfWeek),const DeepCollectionEquality().hash(_timeOfDayPreferences),earliestDate,latestDate,priorityScore,notificationPreference,status,createdAt,updatedAt,lastNotifiedAt,responseExpiresAt,expiresAt,notes]);

@override
String toString() {
  return 'WaitlistEntry(id: $id, businessId: $businessId, clientId: $clientId, clientName: $clientName, clientEmail: $clientEmail, clientPhone: $clientPhone, serviceId: $serviceId, serviceName: $serviceName, providerId: $providerId, providerName: $providerName, locationId: $locationId, preferredDaysOfWeek: $preferredDaysOfWeek, timeOfDayPreferences: $timeOfDayPreferences, earliestDate: $earliestDate, latestDate: $latestDate, priorityScore: $priorityScore, notificationPreference: $notificationPreference, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, lastNotifiedAt: $lastNotifiedAt, responseExpiresAt: $responseExpiresAt, expiresAt: $expiresAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$WaitlistEntryCopyWith<$Res> implements $WaitlistEntryCopyWith<$Res> {
  factory _$WaitlistEntryCopyWith(_WaitlistEntry value, $Res Function(_WaitlistEntry) _then) = __$WaitlistEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String? clientId, String clientName, String? clientEmail, String? clientPhone, String serviceId, String? serviceName, String? providerId, String? providerName, String? locationId, List<int> preferredDaysOfWeek, List<TimeOfDayPreference> timeOfDayPreferences,@TimestampConverter() DateTime earliestDate,@TimestampConverter() DateTime latestDate, double priorityScore, NotificationPreference notificationPreference, WaitlistStatus status,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? lastNotifiedAt,@NullableTimestampConverter() DateTime? responseExpiresAt,@NullableTimestampConverter() DateTime? expiresAt, String? notes
});




}
/// @nodoc
class __$WaitlistEntryCopyWithImpl<$Res>
    implements _$WaitlistEntryCopyWith<$Res> {
  __$WaitlistEntryCopyWithImpl(this._self, this._then);

  final _WaitlistEntry _self;
  final $Res Function(_WaitlistEntry) _then;

/// Create a copy of WaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? clientId = freezed,Object? clientName = null,Object? clientEmail = freezed,Object? clientPhone = freezed,Object? serviceId = null,Object? serviceName = freezed,Object? providerId = freezed,Object? providerName = freezed,Object? locationId = freezed,Object? preferredDaysOfWeek = null,Object? timeOfDayPreferences = null,Object? earliestDate = null,Object? latestDate = null,Object? priorityScore = null,Object? notificationPreference = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? lastNotifiedAt = freezed,Object? responseExpiresAt = freezed,Object? expiresAt = freezed,Object? notes = freezed,}) {
  return _then(_WaitlistEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientEmail: freezed == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String?,clientPhone: freezed == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String?,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,preferredDaysOfWeek: null == preferredDaysOfWeek ? _self._preferredDaysOfWeek : preferredDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,timeOfDayPreferences: null == timeOfDayPreferences ? _self._timeOfDayPreferences : timeOfDayPreferences // ignore: cast_nullable_to_non_nullable
as List<TimeOfDayPreference>,earliestDate: null == earliestDate ? _self.earliestDate : earliestDate // ignore: cast_nullable_to_non_nullable
as DateTime,latestDate: null == latestDate ? _self.latestDate : latestDate // ignore: cast_nullable_to_non_nullable
as DateTime,priorityScore: null == priorityScore ? _self.priorityScore : priorityScore // ignore: cast_nullable_to_non_nullable
as double,notificationPreference: null == notificationPreference ? _self.notificationPreference : notificationPreference // ignore: cast_nullable_to_non_nullable
as NotificationPreference,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WaitlistStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastNotifiedAt: freezed == lastNotifiedAt ? _self.lastNotifiedAt : lastNotifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,responseExpiresAt: freezed == responseExpiresAt ? _self.responseExpiresAt : responseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
