// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_patterns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientPatterns {

/// Client ID these patterns belong to
 String get clientId;/// Business ID for multi-tenant isolation
 String get businessId;/// No-show rate by day of week (1=Monday, 7=Sunday)
/// Key: day number, Value: no-show rate (0.0-1.0)
 Map<int, double> get dayOfWeekNoshowRates;/// No-show rate by hour of day (0-23)
/// Key: hour, Value: no-show rate (0.0-1.0)
 Map<int, double> get hourOfDayNoshowRates;/// No-show rate by provider ID
/// Key: provider ID, Value: no-show rate (0.0-1.0)
 Map<String, double> get providerNoshowRates;/// Completed appointment count by provider
/// Key: provider ID, Value: completed count
 Map<String, int> get providerCompletedCounts;/// No-show rate by booking lead time bucket
/// Key: bucket name ("same_day", "1-3_days", "4-7_days", "8-14_days", "15+_days")
/// Value: no-show rate (0.0-1.0)
 Map<String, double> get leadTimeNoshowRates;/// Overall statistics
 int get totalAppointments; int get totalNoshows; int get totalCancellations; double get overallNoshowRate;/// Preferred booking patterns (derived from successful appointments)
 List<int> get preferredDaysOfWeek; List<int> get preferredHours; List<String> get preferredProviders;/// When these patterns were last calculated
 DateTime get calculatedAt;/// How many appointments were used to calculate these patterns
 int get sampleSize;
/// Create a copy of ClientPatterns
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientPatternsCopyWith<ClientPatterns> get copyWith => _$ClientPatternsCopyWithImpl<ClientPatterns>(this as ClientPatterns, _$identity);

  /// Serializes this ClientPatterns to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientPatterns&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&const DeepCollectionEquality().equals(other.dayOfWeekNoshowRates, dayOfWeekNoshowRates)&&const DeepCollectionEquality().equals(other.hourOfDayNoshowRates, hourOfDayNoshowRates)&&const DeepCollectionEquality().equals(other.providerNoshowRates, providerNoshowRates)&&const DeepCollectionEquality().equals(other.providerCompletedCounts, providerCompletedCounts)&&const DeepCollectionEquality().equals(other.leadTimeNoshowRates, leadTimeNoshowRates)&&(identical(other.totalAppointments, totalAppointments) || other.totalAppointments == totalAppointments)&&(identical(other.totalNoshows, totalNoshows) || other.totalNoshows == totalNoshows)&&(identical(other.totalCancellations, totalCancellations) || other.totalCancellations == totalCancellations)&&(identical(other.overallNoshowRate, overallNoshowRate) || other.overallNoshowRate == overallNoshowRate)&&const DeepCollectionEquality().equals(other.preferredDaysOfWeek, preferredDaysOfWeek)&&const DeepCollectionEquality().equals(other.preferredHours, preferredHours)&&const DeepCollectionEquality().equals(other.preferredProviders, preferredProviders)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,businessId,const DeepCollectionEquality().hash(dayOfWeekNoshowRates),const DeepCollectionEquality().hash(hourOfDayNoshowRates),const DeepCollectionEquality().hash(providerNoshowRates),const DeepCollectionEquality().hash(providerCompletedCounts),const DeepCollectionEquality().hash(leadTimeNoshowRates),totalAppointments,totalNoshows,totalCancellations,overallNoshowRate,const DeepCollectionEquality().hash(preferredDaysOfWeek),const DeepCollectionEquality().hash(preferredHours),const DeepCollectionEquality().hash(preferredProviders),calculatedAt,sampleSize);

@override
String toString() {
  return 'ClientPatterns(clientId: $clientId, businessId: $businessId, dayOfWeekNoshowRates: $dayOfWeekNoshowRates, hourOfDayNoshowRates: $hourOfDayNoshowRates, providerNoshowRates: $providerNoshowRates, providerCompletedCounts: $providerCompletedCounts, leadTimeNoshowRates: $leadTimeNoshowRates, totalAppointments: $totalAppointments, totalNoshows: $totalNoshows, totalCancellations: $totalCancellations, overallNoshowRate: $overallNoshowRate, preferredDaysOfWeek: $preferredDaysOfWeek, preferredHours: $preferredHours, preferredProviders: $preferredProviders, calculatedAt: $calculatedAt, sampleSize: $sampleSize)';
}


}

/// @nodoc
abstract mixin class $ClientPatternsCopyWith<$Res>  {
  factory $ClientPatternsCopyWith(ClientPatterns value, $Res Function(ClientPatterns) _then) = _$ClientPatternsCopyWithImpl;
@useResult
$Res call({
 String clientId, String businessId, Map<int, double> dayOfWeekNoshowRates, Map<int, double> hourOfDayNoshowRates, Map<String, double> providerNoshowRates, Map<String, int> providerCompletedCounts, Map<String, double> leadTimeNoshowRates, int totalAppointments, int totalNoshows, int totalCancellations, double overallNoshowRate, List<int> preferredDaysOfWeek, List<int> preferredHours, List<String> preferredProviders, DateTime calculatedAt, int sampleSize
});




}
/// @nodoc
class _$ClientPatternsCopyWithImpl<$Res>
    implements $ClientPatternsCopyWith<$Res> {
  _$ClientPatternsCopyWithImpl(this._self, this._then);

  final ClientPatterns _self;
  final $Res Function(ClientPatterns) _then;

/// Create a copy of ClientPatterns
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? businessId = null,Object? dayOfWeekNoshowRates = null,Object? hourOfDayNoshowRates = null,Object? providerNoshowRates = null,Object? providerCompletedCounts = null,Object? leadTimeNoshowRates = null,Object? totalAppointments = null,Object? totalNoshows = null,Object? totalCancellations = null,Object? overallNoshowRate = null,Object? preferredDaysOfWeek = null,Object? preferredHours = null,Object? preferredProviders = null,Object? calculatedAt = null,Object? sampleSize = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeekNoshowRates: null == dayOfWeekNoshowRates ? _self.dayOfWeekNoshowRates : dayOfWeekNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<int, double>,hourOfDayNoshowRates: null == hourOfDayNoshowRates ? _self.hourOfDayNoshowRates : hourOfDayNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<int, double>,providerNoshowRates: null == providerNoshowRates ? _self.providerNoshowRates : providerNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,providerCompletedCounts: null == providerCompletedCounts ? _self.providerCompletedCounts : providerCompletedCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,leadTimeNoshowRates: null == leadTimeNoshowRates ? _self.leadTimeNoshowRates : leadTimeNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,totalAppointments: null == totalAppointments ? _self.totalAppointments : totalAppointments // ignore: cast_nullable_to_non_nullable
as int,totalNoshows: null == totalNoshows ? _self.totalNoshows : totalNoshows // ignore: cast_nullable_to_non_nullable
as int,totalCancellations: null == totalCancellations ? _self.totalCancellations : totalCancellations // ignore: cast_nullable_to_non_nullable
as int,overallNoshowRate: null == overallNoshowRate ? _self.overallNoshowRate : overallNoshowRate // ignore: cast_nullable_to_non_nullable
as double,preferredDaysOfWeek: null == preferredDaysOfWeek ? _self.preferredDaysOfWeek : preferredDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,preferredHours: null == preferredHours ? _self.preferredHours : preferredHours // ignore: cast_nullable_to_non_nullable
as List<int>,preferredProviders: null == preferredProviders ? _self.preferredProviders : preferredProviders // ignore: cast_nullable_to_non_nullable
as List<String>,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientPatterns].
extension ClientPatternsPatterns on ClientPatterns {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientPatterns value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientPatterns() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientPatterns value)  $default,){
final _that = this;
switch (_that) {
case _ClientPatterns():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientPatterns value)?  $default,){
final _that = this;
switch (_that) {
case _ClientPatterns() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String businessId,  Map<int, double> dayOfWeekNoshowRates,  Map<int, double> hourOfDayNoshowRates,  Map<String, double> providerNoshowRates,  Map<String, int> providerCompletedCounts,  Map<String, double> leadTimeNoshowRates,  int totalAppointments,  int totalNoshows,  int totalCancellations,  double overallNoshowRate,  List<int> preferredDaysOfWeek,  List<int> preferredHours,  List<String> preferredProviders,  DateTime calculatedAt,  int sampleSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientPatterns() when $default != null:
return $default(_that.clientId,_that.businessId,_that.dayOfWeekNoshowRates,_that.hourOfDayNoshowRates,_that.providerNoshowRates,_that.providerCompletedCounts,_that.leadTimeNoshowRates,_that.totalAppointments,_that.totalNoshows,_that.totalCancellations,_that.overallNoshowRate,_that.preferredDaysOfWeek,_that.preferredHours,_that.preferredProviders,_that.calculatedAt,_that.sampleSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String businessId,  Map<int, double> dayOfWeekNoshowRates,  Map<int, double> hourOfDayNoshowRates,  Map<String, double> providerNoshowRates,  Map<String, int> providerCompletedCounts,  Map<String, double> leadTimeNoshowRates,  int totalAppointments,  int totalNoshows,  int totalCancellations,  double overallNoshowRate,  List<int> preferredDaysOfWeek,  List<int> preferredHours,  List<String> preferredProviders,  DateTime calculatedAt,  int sampleSize)  $default,) {final _that = this;
switch (_that) {
case _ClientPatterns():
return $default(_that.clientId,_that.businessId,_that.dayOfWeekNoshowRates,_that.hourOfDayNoshowRates,_that.providerNoshowRates,_that.providerCompletedCounts,_that.leadTimeNoshowRates,_that.totalAppointments,_that.totalNoshows,_that.totalCancellations,_that.overallNoshowRate,_that.preferredDaysOfWeek,_that.preferredHours,_that.preferredProviders,_that.calculatedAt,_that.sampleSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String businessId,  Map<int, double> dayOfWeekNoshowRates,  Map<int, double> hourOfDayNoshowRates,  Map<String, double> providerNoshowRates,  Map<String, int> providerCompletedCounts,  Map<String, double> leadTimeNoshowRates,  int totalAppointments,  int totalNoshows,  int totalCancellations,  double overallNoshowRate,  List<int> preferredDaysOfWeek,  List<int> preferredHours,  List<String> preferredProviders,  DateTime calculatedAt,  int sampleSize)?  $default,) {final _that = this;
switch (_that) {
case _ClientPatterns() when $default != null:
return $default(_that.clientId,_that.businessId,_that.dayOfWeekNoshowRates,_that.hourOfDayNoshowRates,_that.providerNoshowRates,_that.providerCompletedCounts,_that.leadTimeNoshowRates,_that.totalAppointments,_that.totalNoshows,_that.totalCancellations,_that.overallNoshowRate,_that.preferredDaysOfWeek,_that.preferredHours,_that.preferredProviders,_that.calculatedAt,_that.sampleSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientPatterns extends ClientPatterns {
  const _ClientPatterns({required this.clientId, required this.businessId, required final  Map<int, double> dayOfWeekNoshowRates, required final  Map<int, double> hourOfDayNoshowRates, required final  Map<String, double> providerNoshowRates, required final  Map<String, int> providerCompletedCounts, required final  Map<String, double> leadTimeNoshowRates, required this.totalAppointments, required this.totalNoshows, required this.totalCancellations, required this.overallNoshowRate, final  List<int> preferredDaysOfWeek = const [], final  List<int> preferredHours = const [], final  List<String> preferredProviders = const [], required this.calculatedAt, required this.sampleSize}): _dayOfWeekNoshowRates = dayOfWeekNoshowRates,_hourOfDayNoshowRates = hourOfDayNoshowRates,_providerNoshowRates = providerNoshowRates,_providerCompletedCounts = providerCompletedCounts,_leadTimeNoshowRates = leadTimeNoshowRates,_preferredDaysOfWeek = preferredDaysOfWeek,_preferredHours = preferredHours,_preferredProviders = preferredProviders,super._();
  factory _ClientPatterns.fromJson(Map<String, dynamic> json) => _$ClientPatternsFromJson(json);

/// Client ID these patterns belong to
@override final  String clientId;
/// Business ID for multi-tenant isolation
@override final  String businessId;
/// No-show rate by day of week (1=Monday, 7=Sunday)
/// Key: day number, Value: no-show rate (0.0-1.0)
 final  Map<int, double> _dayOfWeekNoshowRates;
/// No-show rate by day of week (1=Monday, 7=Sunday)
/// Key: day number, Value: no-show rate (0.0-1.0)
@override Map<int, double> get dayOfWeekNoshowRates {
  if (_dayOfWeekNoshowRates is EqualUnmodifiableMapView) return _dayOfWeekNoshowRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dayOfWeekNoshowRates);
}

/// No-show rate by hour of day (0-23)
/// Key: hour, Value: no-show rate (0.0-1.0)
 final  Map<int, double> _hourOfDayNoshowRates;
/// No-show rate by hour of day (0-23)
/// Key: hour, Value: no-show rate (0.0-1.0)
@override Map<int, double> get hourOfDayNoshowRates {
  if (_hourOfDayNoshowRates is EqualUnmodifiableMapView) return _hourOfDayNoshowRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hourOfDayNoshowRates);
}

/// No-show rate by provider ID
/// Key: provider ID, Value: no-show rate (0.0-1.0)
 final  Map<String, double> _providerNoshowRates;
/// No-show rate by provider ID
/// Key: provider ID, Value: no-show rate (0.0-1.0)
@override Map<String, double> get providerNoshowRates {
  if (_providerNoshowRates is EqualUnmodifiableMapView) return _providerNoshowRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_providerNoshowRates);
}

/// Completed appointment count by provider
/// Key: provider ID, Value: completed count
 final  Map<String, int> _providerCompletedCounts;
/// Completed appointment count by provider
/// Key: provider ID, Value: completed count
@override Map<String, int> get providerCompletedCounts {
  if (_providerCompletedCounts is EqualUnmodifiableMapView) return _providerCompletedCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_providerCompletedCounts);
}

/// No-show rate by booking lead time bucket
/// Key: bucket name ("same_day", "1-3_days", "4-7_days", "8-14_days", "15+_days")
/// Value: no-show rate (0.0-1.0)
 final  Map<String, double> _leadTimeNoshowRates;
/// No-show rate by booking lead time bucket
/// Key: bucket name ("same_day", "1-3_days", "4-7_days", "8-14_days", "15+_days")
/// Value: no-show rate (0.0-1.0)
@override Map<String, double> get leadTimeNoshowRates {
  if (_leadTimeNoshowRates is EqualUnmodifiableMapView) return _leadTimeNoshowRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_leadTimeNoshowRates);
}

/// Overall statistics
@override final  int totalAppointments;
@override final  int totalNoshows;
@override final  int totalCancellations;
@override final  double overallNoshowRate;
/// Preferred booking patterns (derived from successful appointments)
 final  List<int> _preferredDaysOfWeek;
/// Preferred booking patterns (derived from successful appointments)
@override@JsonKey() List<int> get preferredDaysOfWeek {
  if (_preferredDaysOfWeek is EqualUnmodifiableListView) return _preferredDaysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredDaysOfWeek);
}

 final  List<int> _preferredHours;
@override@JsonKey() List<int> get preferredHours {
  if (_preferredHours is EqualUnmodifiableListView) return _preferredHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredHours);
}

 final  List<String> _preferredProviders;
@override@JsonKey() List<String> get preferredProviders {
  if (_preferredProviders is EqualUnmodifiableListView) return _preferredProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredProviders);
}

/// When these patterns were last calculated
@override final  DateTime calculatedAt;
/// How many appointments were used to calculate these patterns
@override final  int sampleSize;

/// Create a copy of ClientPatterns
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientPatternsCopyWith<_ClientPatterns> get copyWith => __$ClientPatternsCopyWithImpl<_ClientPatterns>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientPatternsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientPatterns&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&const DeepCollectionEquality().equals(other._dayOfWeekNoshowRates, _dayOfWeekNoshowRates)&&const DeepCollectionEquality().equals(other._hourOfDayNoshowRates, _hourOfDayNoshowRates)&&const DeepCollectionEquality().equals(other._providerNoshowRates, _providerNoshowRates)&&const DeepCollectionEquality().equals(other._providerCompletedCounts, _providerCompletedCounts)&&const DeepCollectionEquality().equals(other._leadTimeNoshowRates, _leadTimeNoshowRates)&&(identical(other.totalAppointments, totalAppointments) || other.totalAppointments == totalAppointments)&&(identical(other.totalNoshows, totalNoshows) || other.totalNoshows == totalNoshows)&&(identical(other.totalCancellations, totalCancellations) || other.totalCancellations == totalCancellations)&&(identical(other.overallNoshowRate, overallNoshowRate) || other.overallNoshowRate == overallNoshowRate)&&const DeepCollectionEquality().equals(other._preferredDaysOfWeek, _preferredDaysOfWeek)&&const DeepCollectionEquality().equals(other._preferredHours, _preferredHours)&&const DeepCollectionEquality().equals(other._preferredProviders, _preferredProviders)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,businessId,const DeepCollectionEquality().hash(_dayOfWeekNoshowRates),const DeepCollectionEquality().hash(_hourOfDayNoshowRates),const DeepCollectionEquality().hash(_providerNoshowRates),const DeepCollectionEquality().hash(_providerCompletedCounts),const DeepCollectionEquality().hash(_leadTimeNoshowRates),totalAppointments,totalNoshows,totalCancellations,overallNoshowRate,const DeepCollectionEquality().hash(_preferredDaysOfWeek),const DeepCollectionEquality().hash(_preferredHours),const DeepCollectionEquality().hash(_preferredProviders),calculatedAt,sampleSize);

@override
String toString() {
  return 'ClientPatterns(clientId: $clientId, businessId: $businessId, dayOfWeekNoshowRates: $dayOfWeekNoshowRates, hourOfDayNoshowRates: $hourOfDayNoshowRates, providerNoshowRates: $providerNoshowRates, providerCompletedCounts: $providerCompletedCounts, leadTimeNoshowRates: $leadTimeNoshowRates, totalAppointments: $totalAppointments, totalNoshows: $totalNoshows, totalCancellations: $totalCancellations, overallNoshowRate: $overallNoshowRate, preferredDaysOfWeek: $preferredDaysOfWeek, preferredHours: $preferredHours, preferredProviders: $preferredProviders, calculatedAt: $calculatedAt, sampleSize: $sampleSize)';
}


}

/// @nodoc
abstract mixin class _$ClientPatternsCopyWith<$Res> implements $ClientPatternsCopyWith<$Res> {
  factory _$ClientPatternsCopyWith(_ClientPatterns value, $Res Function(_ClientPatterns) _then) = __$ClientPatternsCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String businessId, Map<int, double> dayOfWeekNoshowRates, Map<int, double> hourOfDayNoshowRates, Map<String, double> providerNoshowRates, Map<String, int> providerCompletedCounts, Map<String, double> leadTimeNoshowRates, int totalAppointments, int totalNoshows, int totalCancellations, double overallNoshowRate, List<int> preferredDaysOfWeek, List<int> preferredHours, List<String> preferredProviders, DateTime calculatedAt, int sampleSize
});




}
/// @nodoc
class __$ClientPatternsCopyWithImpl<$Res>
    implements _$ClientPatternsCopyWith<$Res> {
  __$ClientPatternsCopyWithImpl(this._self, this._then);

  final _ClientPatterns _self;
  final $Res Function(_ClientPatterns) _then;

/// Create a copy of ClientPatterns
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? businessId = null,Object? dayOfWeekNoshowRates = null,Object? hourOfDayNoshowRates = null,Object? providerNoshowRates = null,Object? providerCompletedCounts = null,Object? leadTimeNoshowRates = null,Object? totalAppointments = null,Object? totalNoshows = null,Object? totalCancellations = null,Object? overallNoshowRate = null,Object? preferredDaysOfWeek = null,Object? preferredHours = null,Object? preferredProviders = null,Object? calculatedAt = null,Object? sampleSize = null,}) {
  return _then(_ClientPatterns(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeekNoshowRates: null == dayOfWeekNoshowRates ? _self._dayOfWeekNoshowRates : dayOfWeekNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<int, double>,hourOfDayNoshowRates: null == hourOfDayNoshowRates ? _self._hourOfDayNoshowRates : hourOfDayNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<int, double>,providerNoshowRates: null == providerNoshowRates ? _self._providerNoshowRates : providerNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,providerCompletedCounts: null == providerCompletedCounts ? _self._providerCompletedCounts : providerCompletedCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,leadTimeNoshowRates: null == leadTimeNoshowRates ? _self._leadTimeNoshowRates : leadTimeNoshowRates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,totalAppointments: null == totalAppointments ? _self.totalAppointments : totalAppointments // ignore: cast_nullable_to_non_nullable
as int,totalNoshows: null == totalNoshows ? _self.totalNoshows : totalNoshows // ignore: cast_nullable_to_non_nullable
as int,totalCancellations: null == totalCancellations ? _self.totalCancellations : totalCancellations // ignore: cast_nullable_to_non_nullable
as int,overallNoshowRate: null == overallNoshowRate ? _self.overallNoshowRate : overallNoshowRate // ignore: cast_nullable_to_non_nullable
as double,preferredDaysOfWeek: null == preferredDaysOfWeek ? _self._preferredDaysOfWeek : preferredDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,preferredHours: null == preferredHours ? _self._preferredHours : preferredHours // ignore: cast_nullable_to_non_nullable
as List<int>,preferredProviders: null == preferredProviders ? _self._preferredProviders : preferredProviders // ignore: cast_nullable_to_non_nullable
as List<String>,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DayOfWeekStats {

 int get dayOfWeek; String get dayName; int get appointmentCount; int get noshowCount; double get noshowRate; bool get isPreferred;
/// Create a copy of DayOfWeekStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayOfWeekStatsCopyWith<DayOfWeekStats> get copyWith => _$DayOfWeekStatsCopyWithImpl<DayOfWeekStats>(this as DayOfWeekStats, _$identity);

  /// Serializes this DayOfWeekStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayOfWeekStats&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.appointmentCount, appointmentCount) || other.appointmentCount == appointmentCount)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.isPreferred, isPreferred) || other.isPreferred == isPreferred));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,dayName,appointmentCount,noshowCount,noshowRate,isPreferred);

@override
String toString() {
  return 'DayOfWeekStats(dayOfWeek: $dayOfWeek, dayName: $dayName, appointmentCount: $appointmentCount, noshowCount: $noshowCount, noshowRate: $noshowRate, isPreferred: $isPreferred)';
}


}

/// @nodoc
abstract mixin class $DayOfWeekStatsCopyWith<$Res>  {
  factory $DayOfWeekStatsCopyWith(DayOfWeekStats value, $Res Function(DayOfWeekStats) _then) = _$DayOfWeekStatsCopyWithImpl;
@useResult
$Res call({
 int dayOfWeek, String dayName, int appointmentCount, int noshowCount, double noshowRate, bool isPreferred
});




}
/// @nodoc
class _$DayOfWeekStatsCopyWithImpl<$Res>
    implements $DayOfWeekStatsCopyWith<$Res> {
  _$DayOfWeekStatsCopyWithImpl(this._self, this._then);

  final DayOfWeekStats _self;
  final $Res Function(DayOfWeekStats) _then;

/// Create a copy of DayOfWeekStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayOfWeek = null,Object? dayName = null,Object? appointmentCount = null,Object? noshowCount = null,Object? noshowRate = null,Object? isPreferred = null,}) {
  return _then(_self.copyWith(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,dayName: null == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String,appointmentCount: null == appointmentCount ? _self.appointmentCount : appointmentCount // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,isPreferred: null == isPreferred ? _self.isPreferred : isPreferred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DayOfWeekStats].
extension DayOfWeekStatsPatterns on DayOfWeekStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayOfWeekStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayOfWeekStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayOfWeekStats value)  $default,){
final _that = this;
switch (_that) {
case _DayOfWeekStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayOfWeekStats value)?  $default,){
final _that = this;
switch (_that) {
case _DayOfWeekStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayOfWeek,  String dayName,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayOfWeekStats() when $default != null:
return $default(_that.dayOfWeek,_that.dayName,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayOfWeek,  String dayName,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)  $default,) {final _that = this;
switch (_that) {
case _DayOfWeekStats():
return $default(_that.dayOfWeek,_that.dayName,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayOfWeek,  String dayName,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)?  $default,) {final _that = this;
switch (_that) {
case _DayOfWeekStats() when $default != null:
return $default(_that.dayOfWeek,_that.dayName,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayOfWeekStats implements DayOfWeekStats {
  const _DayOfWeekStats({required this.dayOfWeek, required this.dayName, required this.appointmentCount, required this.noshowCount, required this.noshowRate, required this.isPreferred});
  factory _DayOfWeekStats.fromJson(Map<String, dynamic> json) => _$DayOfWeekStatsFromJson(json);

@override final  int dayOfWeek;
@override final  String dayName;
@override final  int appointmentCount;
@override final  int noshowCount;
@override final  double noshowRate;
@override final  bool isPreferred;

/// Create a copy of DayOfWeekStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayOfWeekStatsCopyWith<_DayOfWeekStats> get copyWith => __$DayOfWeekStatsCopyWithImpl<_DayOfWeekStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayOfWeekStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayOfWeekStats&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.appointmentCount, appointmentCount) || other.appointmentCount == appointmentCount)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.isPreferred, isPreferred) || other.isPreferred == isPreferred));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,dayName,appointmentCount,noshowCount,noshowRate,isPreferred);

@override
String toString() {
  return 'DayOfWeekStats(dayOfWeek: $dayOfWeek, dayName: $dayName, appointmentCount: $appointmentCount, noshowCount: $noshowCount, noshowRate: $noshowRate, isPreferred: $isPreferred)';
}


}

/// @nodoc
abstract mixin class _$DayOfWeekStatsCopyWith<$Res> implements $DayOfWeekStatsCopyWith<$Res> {
  factory _$DayOfWeekStatsCopyWith(_DayOfWeekStats value, $Res Function(_DayOfWeekStats) _then) = __$DayOfWeekStatsCopyWithImpl;
@override @useResult
$Res call({
 int dayOfWeek, String dayName, int appointmentCount, int noshowCount, double noshowRate, bool isPreferred
});




}
/// @nodoc
class __$DayOfWeekStatsCopyWithImpl<$Res>
    implements _$DayOfWeekStatsCopyWith<$Res> {
  __$DayOfWeekStatsCopyWithImpl(this._self, this._then);

  final _DayOfWeekStats _self;
  final $Res Function(_DayOfWeekStats) _then;

/// Create a copy of DayOfWeekStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayOfWeek = null,Object? dayName = null,Object? appointmentCount = null,Object? noshowCount = null,Object? noshowRate = null,Object? isPreferred = null,}) {
  return _then(_DayOfWeekStats(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,dayName: null == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String,appointmentCount: null == appointmentCount ? _self.appointmentCount : appointmentCount // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,isPreferred: null == isPreferred ? _self.isPreferred : isPreferred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$HourOfDayStats {

 int get hour; String get timeLabel; int get appointmentCount; int get noshowCount; double get noshowRate; bool get isPreferred;
/// Create a copy of HourOfDayStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HourOfDayStatsCopyWith<HourOfDayStats> get copyWith => _$HourOfDayStatsCopyWithImpl<HourOfDayStats>(this as HourOfDayStats, _$identity);

  /// Serializes this HourOfDayStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HourOfDayStats&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.timeLabel, timeLabel) || other.timeLabel == timeLabel)&&(identical(other.appointmentCount, appointmentCount) || other.appointmentCount == appointmentCount)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.isPreferred, isPreferred) || other.isPreferred == isPreferred));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,timeLabel,appointmentCount,noshowCount,noshowRate,isPreferred);

@override
String toString() {
  return 'HourOfDayStats(hour: $hour, timeLabel: $timeLabel, appointmentCount: $appointmentCount, noshowCount: $noshowCount, noshowRate: $noshowRate, isPreferred: $isPreferred)';
}


}

/// @nodoc
abstract mixin class $HourOfDayStatsCopyWith<$Res>  {
  factory $HourOfDayStatsCopyWith(HourOfDayStats value, $Res Function(HourOfDayStats) _then) = _$HourOfDayStatsCopyWithImpl;
@useResult
$Res call({
 int hour, String timeLabel, int appointmentCount, int noshowCount, double noshowRate, bool isPreferred
});




}
/// @nodoc
class _$HourOfDayStatsCopyWithImpl<$Res>
    implements $HourOfDayStatsCopyWith<$Res> {
  _$HourOfDayStatsCopyWithImpl(this._self, this._then);

  final HourOfDayStats _self;
  final $Res Function(HourOfDayStats) _then;

/// Create a copy of HourOfDayStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hour = null,Object? timeLabel = null,Object? appointmentCount = null,Object? noshowCount = null,Object? noshowRate = null,Object? isPreferred = null,}) {
  return _then(_self.copyWith(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,timeLabel: null == timeLabel ? _self.timeLabel : timeLabel // ignore: cast_nullable_to_non_nullable
as String,appointmentCount: null == appointmentCount ? _self.appointmentCount : appointmentCount // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,isPreferred: null == isPreferred ? _self.isPreferred : isPreferred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HourOfDayStats].
extension HourOfDayStatsPatterns on HourOfDayStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HourOfDayStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HourOfDayStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HourOfDayStats value)  $default,){
final _that = this;
switch (_that) {
case _HourOfDayStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HourOfDayStats value)?  $default,){
final _that = this;
switch (_that) {
case _HourOfDayStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int hour,  String timeLabel,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HourOfDayStats() when $default != null:
return $default(_that.hour,_that.timeLabel,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int hour,  String timeLabel,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)  $default,) {final _that = this;
switch (_that) {
case _HourOfDayStats():
return $default(_that.hour,_that.timeLabel,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int hour,  String timeLabel,  int appointmentCount,  int noshowCount,  double noshowRate,  bool isPreferred)?  $default,) {final _that = this;
switch (_that) {
case _HourOfDayStats() when $default != null:
return $default(_that.hour,_that.timeLabel,_that.appointmentCount,_that.noshowCount,_that.noshowRate,_that.isPreferred);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HourOfDayStats implements HourOfDayStats {
  const _HourOfDayStats({required this.hour, required this.timeLabel, required this.appointmentCount, required this.noshowCount, required this.noshowRate, required this.isPreferred});
  factory _HourOfDayStats.fromJson(Map<String, dynamic> json) => _$HourOfDayStatsFromJson(json);

@override final  int hour;
@override final  String timeLabel;
@override final  int appointmentCount;
@override final  int noshowCount;
@override final  double noshowRate;
@override final  bool isPreferred;

/// Create a copy of HourOfDayStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HourOfDayStatsCopyWith<_HourOfDayStats> get copyWith => __$HourOfDayStatsCopyWithImpl<_HourOfDayStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HourOfDayStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HourOfDayStats&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.timeLabel, timeLabel) || other.timeLabel == timeLabel)&&(identical(other.appointmentCount, appointmentCount) || other.appointmentCount == appointmentCount)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.isPreferred, isPreferred) || other.isPreferred == isPreferred));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,timeLabel,appointmentCount,noshowCount,noshowRate,isPreferred);

@override
String toString() {
  return 'HourOfDayStats(hour: $hour, timeLabel: $timeLabel, appointmentCount: $appointmentCount, noshowCount: $noshowCount, noshowRate: $noshowRate, isPreferred: $isPreferred)';
}


}

/// @nodoc
abstract mixin class _$HourOfDayStatsCopyWith<$Res> implements $HourOfDayStatsCopyWith<$Res> {
  factory _$HourOfDayStatsCopyWith(_HourOfDayStats value, $Res Function(_HourOfDayStats) _then) = __$HourOfDayStatsCopyWithImpl;
@override @useResult
$Res call({
 int hour, String timeLabel, int appointmentCount, int noshowCount, double noshowRate, bool isPreferred
});




}
/// @nodoc
class __$HourOfDayStatsCopyWithImpl<$Res>
    implements _$HourOfDayStatsCopyWith<$Res> {
  __$HourOfDayStatsCopyWithImpl(this._self, this._then);

  final _HourOfDayStats _self;
  final $Res Function(_HourOfDayStats) _then;

/// Create a copy of HourOfDayStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hour = null,Object? timeLabel = null,Object? appointmentCount = null,Object? noshowCount = null,Object? noshowRate = null,Object? isPreferred = null,}) {
  return _then(_HourOfDayStats(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,timeLabel: null == timeLabel ? _self.timeLabel : timeLabel // ignore: cast_nullable_to_non_nullable
as String,appointmentCount: null == appointmentCount ? _self.appointmentCount : appointmentCount // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,isPreferred: null == isPreferred ? _self.isPreferred : isPreferred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderClientHistory {

 String get providerId; String get providerName; int get completedAppointments; int get noshowCount; int get cancellationCount; double get noshowRate; double get satisfactionScore; DateTime? get lastAppointment;
/// Create a copy of ProviderClientHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderClientHistoryCopyWith<ProviderClientHistory> get copyWith => _$ProviderClientHistoryCopyWithImpl<ProviderClientHistory>(this as ProviderClientHistory, _$identity);

  /// Serializes this ProviderClientHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderClientHistory&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.cancellationCount, cancellationCount) || other.cancellationCount == cancellationCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.satisfactionScore, satisfactionScore) || other.satisfactionScore == satisfactionScore)&&(identical(other.lastAppointment, lastAppointment) || other.lastAppointment == lastAppointment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,completedAppointments,noshowCount,cancellationCount,noshowRate,satisfactionScore,lastAppointment);

@override
String toString() {
  return 'ProviderClientHistory(providerId: $providerId, providerName: $providerName, completedAppointments: $completedAppointments, noshowCount: $noshowCount, cancellationCount: $cancellationCount, noshowRate: $noshowRate, satisfactionScore: $satisfactionScore, lastAppointment: $lastAppointment)';
}


}

/// @nodoc
abstract mixin class $ProviderClientHistoryCopyWith<$Res>  {
  factory $ProviderClientHistoryCopyWith(ProviderClientHistory value, $Res Function(ProviderClientHistory) _then) = _$ProviderClientHistoryCopyWithImpl;
@useResult
$Res call({
 String providerId, String providerName, int completedAppointments, int noshowCount, int cancellationCount, double noshowRate, double satisfactionScore, DateTime? lastAppointment
});




}
/// @nodoc
class _$ProviderClientHistoryCopyWithImpl<$Res>
    implements $ProviderClientHistoryCopyWith<$Res> {
  _$ProviderClientHistoryCopyWithImpl(this._self, this._then);

  final ProviderClientHistory _self;
  final $Res Function(ProviderClientHistory) _then;

/// Create a copy of ProviderClientHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? providerName = null,Object? completedAppointments = null,Object? noshowCount = null,Object? cancellationCount = null,Object? noshowRate = null,Object? satisfactionScore = null,Object? lastAppointment = freezed,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,cancellationCount: null == cancellationCount ? _self.cancellationCount : cancellationCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,satisfactionScore: null == satisfactionScore ? _self.satisfactionScore : satisfactionScore // ignore: cast_nullable_to_non_nullable
as double,lastAppointment: freezed == lastAppointment ? _self.lastAppointment : lastAppointment // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderClientHistory].
extension ProviderClientHistoryPatterns on ProviderClientHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderClientHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderClientHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderClientHistory value)  $default,){
final _that = this;
switch (_that) {
case _ProviderClientHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderClientHistory value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderClientHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String providerName,  int completedAppointments,  int noshowCount,  int cancellationCount,  double noshowRate,  double satisfactionScore,  DateTime? lastAppointment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderClientHistory() when $default != null:
return $default(_that.providerId,_that.providerName,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.noshowRate,_that.satisfactionScore,_that.lastAppointment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String providerName,  int completedAppointments,  int noshowCount,  int cancellationCount,  double noshowRate,  double satisfactionScore,  DateTime? lastAppointment)  $default,) {final _that = this;
switch (_that) {
case _ProviderClientHistory():
return $default(_that.providerId,_that.providerName,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.noshowRate,_that.satisfactionScore,_that.lastAppointment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String providerName,  int completedAppointments,  int noshowCount,  int cancellationCount,  double noshowRate,  double satisfactionScore,  DateTime? lastAppointment)?  $default,) {final _that = this;
switch (_that) {
case _ProviderClientHistory() when $default != null:
return $default(_that.providerId,_that.providerName,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.noshowRate,_that.satisfactionScore,_that.lastAppointment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderClientHistory extends ProviderClientHistory {
  const _ProviderClientHistory({required this.providerId, required this.providerName, required this.completedAppointments, required this.noshowCount, required this.cancellationCount, required this.noshowRate, required this.satisfactionScore, this.lastAppointment}): super._();
  factory _ProviderClientHistory.fromJson(Map<String, dynamic> json) => _$ProviderClientHistoryFromJson(json);

@override final  String providerId;
@override final  String providerName;
@override final  int completedAppointments;
@override final  int noshowCount;
@override final  int cancellationCount;
@override final  double noshowRate;
@override final  double satisfactionScore;
@override final  DateTime? lastAppointment;

/// Create a copy of ProviderClientHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderClientHistoryCopyWith<_ProviderClientHistory> get copyWith => __$ProviderClientHistoryCopyWithImpl<_ProviderClientHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderClientHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderClientHistory&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.cancellationCount, cancellationCount) || other.cancellationCount == cancellationCount)&&(identical(other.noshowRate, noshowRate) || other.noshowRate == noshowRate)&&(identical(other.satisfactionScore, satisfactionScore) || other.satisfactionScore == satisfactionScore)&&(identical(other.lastAppointment, lastAppointment) || other.lastAppointment == lastAppointment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,completedAppointments,noshowCount,cancellationCount,noshowRate,satisfactionScore,lastAppointment);

@override
String toString() {
  return 'ProviderClientHistory(providerId: $providerId, providerName: $providerName, completedAppointments: $completedAppointments, noshowCount: $noshowCount, cancellationCount: $cancellationCount, noshowRate: $noshowRate, satisfactionScore: $satisfactionScore, lastAppointment: $lastAppointment)';
}


}

/// @nodoc
abstract mixin class _$ProviderClientHistoryCopyWith<$Res> implements $ProviderClientHistoryCopyWith<$Res> {
  factory _$ProviderClientHistoryCopyWith(_ProviderClientHistory value, $Res Function(_ProviderClientHistory) _then) = __$ProviderClientHistoryCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String providerName, int completedAppointments, int noshowCount, int cancellationCount, double noshowRate, double satisfactionScore, DateTime? lastAppointment
});




}
/// @nodoc
class __$ProviderClientHistoryCopyWithImpl<$Res>
    implements _$ProviderClientHistoryCopyWith<$Res> {
  __$ProviderClientHistoryCopyWithImpl(this._self, this._then);

  final _ProviderClientHistory _self;
  final $Res Function(_ProviderClientHistory) _then;

/// Create a copy of ProviderClientHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? providerName = null,Object? completedAppointments = null,Object? noshowCount = null,Object? cancellationCount = null,Object? noshowRate = null,Object? satisfactionScore = null,Object? lastAppointment = freezed,}) {
  return _then(_ProviderClientHistory(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,cancellationCount: null == cancellationCount ? _self.cancellationCount : cancellationCount // ignore: cast_nullable_to_non_nullable
as int,noshowRate: null == noshowRate ? _self.noshowRate : noshowRate // ignore: cast_nullable_to_non_nullable
as double,satisfactionScore: null == satisfactionScore ? _self.satisfactionScore : satisfactionScore // ignore: cast_nullable_to_non_nullable
as double,lastAppointment: freezed == lastAppointment ? _self.lastAppointment : lastAppointment // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
