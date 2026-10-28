// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyticsMetrics {

 String get businessId;@TimestampConverter() DateTime get startDate;@TimestampConverter() DateTime get endDate;// Appointment Metrics
 int get totalAppointments; int get confirmedAppointments; int get canceledAppointments; int get completedAppointments; int get pendingAppointments; int get noShowAppointments;// Revenue Metrics (in cents)
 int get totalRevenueCents; int get paidRevenueCents; int get pendingRevenueCents; int get refundedRevenueCents;// Client Metrics
 int get totalClients; int get newClients; int get returningClients; int get activeClients; int get inactiveClients;// Provider Metrics
 Map<String, int> get appointmentsByProvider; Map<String, int> get revenueByProvider;// in cents
// Service Metrics
 Map<String, int> get appointmentsByService; Map<String, int> get revenueByService;// in cents
// Time-based Metrics
 Map<String, int> get appointmentsByDayOfWeek;// Monday: 5, etc
 Map<int, int> get appointmentsByHourOfDay;// 9: 12, 14: 8, etc
 Map<String, int> get appointmentsByDate;// 2025-11-22: 8, etc
// Performance Metrics
 double get averageBookingLeadDays; double get cancellationRate; double get noShowRate; double get utilizationRate;// Group Session Metrics
 int get totalGroupSessions; int get totalGroupSessionAttendees; int get totalGroupSessionCapacity; double get groupSessionUtilizationRate; Map<String, int> get groupSessionsByService; Map<String, int> get attendeesByGroupSession;
/// Create a copy of AnalyticsMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsMetricsCopyWith<AnalyticsMetrics> get copyWith => _$AnalyticsMetricsCopyWithImpl<AnalyticsMetrics>(this as AnalyticsMetrics, _$identity);

  /// Serializes this AnalyticsMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsMetrics&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.totalAppointments, totalAppointments) || other.totalAppointments == totalAppointments)&&(identical(other.confirmedAppointments, confirmedAppointments) || other.confirmedAppointments == confirmedAppointments)&&(identical(other.canceledAppointments, canceledAppointments) || other.canceledAppointments == canceledAppointments)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.pendingAppointments, pendingAppointments) || other.pendingAppointments == pendingAppointments)&&(identical(other.noShowAppointments, noShowAppointments) || other.noShowAppointments == noShowAppointments)&&(identical(other.totalRevenueCents, totalRevenueCents) || other.totalRevenueCents == totalRevenueCents)&&(identical(other.paidRevenueCents, paidRevenueCents) || other.paidRevenueCents == paidRevenueCents)&&(identical(other.pendingRevenueCents, pendingRevenueCents) || other.pendingRevenueCents == pendingRevenueCents)&&(identical(other.refundedRevenueCents, refundedRevenueCents) || other.refundedRevenueCents == refundedRevenueCents)&&(identical(other.totalClients, totalClients) || other.totalClients == totalClients)&&(identical(other.newClients, newClients) || other.newClients == newClients)&&(identical(other.returningClients, returningClients) || other.returningClients == returningClients)&&(identical(other.activeClients, activeClients) || other.activeClients == activeClients)&&(identical(other.inactiveClients, inactiveClients) || other.inactiveClients == inactiveClients)&&const DeepCollectionEquality().equals(other.appointmentsByProvider, appointmentsByProvider)&&const DeepCollectionEquality().equals(other.revenueByProvider, revenueByProvider)&&const DeepCollectionEquality().equals(other.appointmentsByService, appointmentsByService)&&const DeepCollectionEquality().equals(other.revenueByService, revenueByService)&&const DeepCollectionEquality().equals(other.appointmentsByDayOfWeek, appointmentsByDayOfWeek)&&const DeepCollectionEquality().equals(other.appointmentsByHourOfDay, appointmentsByHourOfDay)&&const DeepCollectionEquality().equals(other.appointmentsByDate, appointmentsByDate)&&(identical(other.averageBookingLeadDays, averageBookingLeadDays) || other.averageBookingLeadDays == averageBookingLeadDays)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.noShowRate, noShowRate) || other.noShowRate == noShowRate)&&(identical(other.utilizationRate, utilizationRate) || other.utilizationRate == utilizationRate)&&(identical(other.totalGroupSessions, totalGroupSessions) || other.totalGroupSessions == totalGroupSessions)&&(identical(other.totalGroupSessionAttendees, totalGroupSessionAttendees) || other.totalGroupSessionAttendees == totalGroupSessionAttendees)&&(identical(other.totalGroupSessionCapacity, totalGroupSessionCapacity) || other.totalGroupSessionCapacity == totalGroupSessionCapacity)&&(identical(other.groupSessionUtilizationRate, groupSessionUtilizationRate) || other.groupSessionUtilizationRate == groupSessionUtilizationRate)&&const DeepCollectionEquality().equals(other.groupSessionsByService, groupSessionsByService)&&const DeepCollectionEquality().equals(other.attendeesByGroupSession, attendeesByGroupSession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,businessId,startDate,endDate,totalAppointments,confirmedAppointments,canceledAppointments,completedAppointments,pendingAppointments,noShowAppointments,totalRevenueCents,paidRevenueCents,pendingRevenueCents,refundedRevenueCents,totalClients,newClients,returningClients,activeClients,inactiveClients,const DeepCollectionEquality().hash(appointmentsByProvider),const DeepCollectionEquality().hash(revenueByProvider),const DeepCollectionEquality().hash(appointmentsByService),const DeepCollectionEquality().hash(revenueByService),const DeepCollectionEquality().hash(appointmentsByDayOfWeek),const DeepCollectionEquality().hash(appointmentsByHourOfDay),const DeepCollectionEquality().hash(appointmentsByDate),averageBookingLeadDays,cancellationRate,noShowRate,utilizationRate,totalGroupSessions,totalGroupSessionAttendees,totalGroupSessionCapacity,groupSessionUtilizationRate,const DeepCollectionEquality().hash(groupSessionsByService),const DeepCollectionEquality().hash(attendeesByGroupSession)]);

@override
String toString() {
  return 'AnalyticsMetrics(businessId: $businessId, startDate: $startDate, endDate: $endDate, totalAppointments: $totalAppointments, confirmedAppointments: $confirmedAppointments, canceledAppointments: $canceledAppointments, completedAppointments: $completedAppointments, pendingAppointments: $pendingAppointments, noShowAppointments: $noShowAppointments, totalRevenueCents: $totalRevenueCents, paidRevenueCents: $paidRevenueCents, pendingRevenueCents: $pendingRevenueCents, refundedRevenueCents: $refundedRevenueCents, totalClients: $totalClients, newClients: $newClients, returningClients: $returningClients, activeClients: $activeClients, inactiveClients: $inactiveClients, appointmentsByProvider: $appointmentsByProvider, revenueByProvider: $revenueByProvider, appointmentsByService: $appointmentsByService, revenueByService: $revenueByService, appointmentsByDayOfWeek: $appointmentsByDayOfWeek, appointmentsByHourOfDay: $appointmentsByHourOfDay, appointmentsByDate: $appointmentsByDate, averageBookingLeadDays: $averageBookingLeadDays, cancellationRate: $cancellationRate, noShowRate: $noShowRate, utilizationRate: $utilizationRate, totalGroupSessions: $totalGroupSessions, totalGroupSessionAttendees: $totalGroupSessionAttendees, totalGroupSessionCapacity: $totalGroupSessionCapacity, groupSessionUtilizationRate: $groupSessionUtilizationRate, groupSessionsByService: $groupSessionsByService, attendeesByGroupSession: $attendeesByGroupSession)';
}


}

/// @nodoc
abstract mixin class $AnalyticsMetricsCopyWith<$Res>  {
  factory $AnalyticsMetricsCopyWith(AnalyticsMetrics value, $Res Function(AnalyticsMetrics) _then) = _$AnalyticsMetricsCopyWithImpl;
@useResult
$Res call({
 String businessId,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, int totalAppointments, int confirmedAppointments, int canceledAppointments, int completedAppointments, int pendingAppointments, int noShowAppointments, int totalRevenueCents, int paidRevenueCents, int pendingRevenueCents, int refundedRevenueCents, int totalClients, int newClients, int returningClients, int activeClients, int inactiveClients, Map<String, int> appointmentsByProvider, Map<String, int> revenueByProvider, Map<String, int> appointmentsByService, Map<String, int> revenueByService, Map<String, int> appointmentsByDayOfWeek, Map<int, int> appointmentsByHourOfDay, Map<String, int> appointmentsByDate, double averageBookingLeadDays, double cancellationRate, double noShowRate, double utilizationRate, int totalGroupSessions, int totalGroupSessionAttendees, int totalGroupSessionCapacity, double groupSessionUtilizationRate, Map<String, int> groupSessionsByService, Map<String, int> attendeesByGroupSession
});




}
/// @nodoc
class _$AnalyticsMetricsCopyWithImpl<$Res>
    implements $AnalyticsMetricsCopyWith<$Res> {
  _$AnalyticsMetricsCopyWithImpl(this._self, this._then);

  final AnalyticsMetrics _self;
  final $Res Function(AnalyticsMetrics) _then;

/// Create a copy of AnalyticsMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessId = null,Object? startDate = null,Object? endDate = null,Object? totalAppointments = null,Object? confirmedAppointments = null,Object? canceledAppointments = null,Object? completedAppointments = null,Object? pendingAppointments = null,Object? noShowAppointments = null,Object? totalRevenueCents = null,Object? paidRevenueCents = null,Object? pendingRevenueCents = null,Object? refundedRevenueCents = null,Object? totalClients = null,Object? newClients = null,Object? returningClients = null,Object? activeClients = null,Object? inactiveClients = null,Object? appointmentsByProvider = null,Object? revenueByProvider = null,Object? appointmentsByService = null,Object? revenueByService = null,Object? appointmentsByDayOfWeek = null,Object? appointmentsByHourOfDay = null,Object? appointmentsByDate = null,Object? averageBookingLeadDays = null,Object? cancellationRate = null,Object? noShowRate = null,Object? utilizationRate = null,Object? totalGroupSessions = null,Object? totalGroupSessionAttendees = null,Object? totalGroupSessionCapacity = null,Object? groupSessionUtilizationRate = null,Object? groupSessionsByService = null,Object? attendeesByGroupSession = null,}) {
  return _then(_self.copyWith(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalAppointments: null == totalAppointments ? _self.totalAppointments : totalAppointments // ignore: cast_nullable_to_non_nullable
as int,confirmedAppointments: null == confirmedAppointments ? _self.confirmedAppointments : confirmedAppointments // ignore: cast_nullable_to_non_nullable
as int,canceledAppointments: null == canceledAppointments ? _self.canceledAppointments : canceledAppointments // ignore: cast_nullable_to_non_nullable
as int,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,pendingAppointments: null == pendingAppointments ? _self.pendingAppointments : pendingAppointments // ignore: cast_nullable_to_non_nullable
as int,noShowAppointments: null == noShowAppointments ? _self.noShowAppointments : noShowAppointments // ignore: cast_nullable_to_non_nullable
as int,totalRevenueCents: null == totalRevenueCents ? _self.totalRevenueCents : totalRevenueCents // ignore: cast_nullable_to_non_nullable
as int,paidRevenueCents: null == paidRevenueCents ? _self.paidRevenueCents : paidRevenueCents // ignore: cast_nullable_to_non_nullable
as int,pendingRevenueCents: null == pendingRevenueCents ? _self.pendingRevenueCents : pendingRevenueCents // ignore: cast_nullable_to_non_nullable
as int,refundedRevenueCents: null == refundedRevenueCents ? _self.refundedRevenueCents : refundedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,totalClients: null == totalClients ? _self.totalClients : totalClients // ignore: cast_nullable_to_non_nullable
as int,newClients: null == newClients ? _self.newClients : newClients // ignore: cast_nullable_to_non_nullable
as int,returningClients: null == returningClients ? _self.returningClients : returningClients // ignore: cast_nullable_to_non_nullable
as int,activeClients: null == activeClients ? _self.activeClients : activeClients // ignore: cast_nullable_to_non_nullable
as int,inactiveClients: null == inactiveClients ? _self.inactiveClients : inactiveClients // ignore: cast_nullable_to_non_nullable
as int,appointmentsByProvider: null == appointmentsByProvider ? _self.appointmentsByProvider : appointmentsByProvider // ignore: cast_nullable_to_non_nullable
as Map<String, int>,revenueByProvider: null == revenueByProvider ? _self.revenueByProvider : revenueByProvider // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByService: null == appointmentsByService ? _self.appointmentsByService : appointmentsByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,revenueByService: null == revenueByService ? _self.revenueByService : revenueByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByDayOfWeek: null == appointmentsByDayOfWeek ? _self.appointmentsByDayOfWeek : appointmentsByDayOfWeek // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByHourOfDay: null == appointmentsByHourOfDay ? _self.appointmentsByHourOfDay : appointmentsByHourOfDay // ignore: cast_nullable_to_non_nullable
as Map<int, int>,appointmentsByDate: null == appointmentsByDate ? _self.appointmentsByDate : appointmentsByDate // ignore: cast_nullable_to_non_nullable
as Map<String, int>,averageBookingLeadDays: null == averageBookingLeadDays ? _self.averageBookingLeadDays : averageBookingLeadDays // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,noShowRate: null == noShowRate ? _self.noShowRate : noShowRate // ignore: cast_nullable_to_non_nullable
as double,utilizationRate: null == utilizationRate ? _self.utilizationRate : utilizationRate // ignore: cast_nullable_to_non_nullable
as double,totalGroupSessions: null == totalGroupSessions ? _self.totalGroupSessions : totalGroupSessions // ignore: cast_nullable_to_non_nullable
as int,totalGroupSessionAttendees: null == totalGroupSessionAttendees ? _self.totalGroupSessionAttendees : totalGroupSessionAttendees // ignore: cast_nullable_to_non_nullable
as int,totalGroupSessionCapacity: null == totalGroupSessionCapacity ? _self.totalGroupSessionCapacity : totalGroupSessionCapacity // ignore: cast_nullable_to_non_nullable
as int,groupSessionUtilizationRate: null == groupSessionUtilizationRate ? _self.groupSessionUtilizationRate : groupSessionUtilizationRate // ignore: cast_nullable_to_non_nullable
as double,groupSessionsByService: null == groupSessionsByService ? _self.groupSessionsByService : groupSessionsByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,attendeesByGroupSession: null == attendeesByGroupSession ? _self.attendeesByGroupSession : attendeesByGroupSession // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsMetrics].
extension AnalyticsMetricsPatterns on AnalyticsMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsMetrics value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessId, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  int totalAppointments,  int confirmedAppointments,  int canceledAppointments,  int completedAppointments,  int pendingAppointments,  int noShowAppointments,  int totalRevenueCents,  int paidRevenueCents,  int pendingRevenueCents,  int refundedRevenueCents,  int totalClients,  int newClients,  int returningClients,  int activeClients,  int inactiveClients,  Map<String, int> appointmentsByProvider,  Map<String, int> revenueByProvider,  Map<String, int> appointmentsByService,  Map<String, int> revenueByService,  Map<String, int> appointmentsByDayOfWeek,  Map<int, int> appointmentsByHourOfDay,  Map<String, int> appointmentsByDate,  double averageBookingLeadDays,  double cancellationRate,  double noShowRate,  double utilizationRate,  int totalGroupSessions,  int totalGroupSessionAttendees,  int totalGroupSessionCapacity,  double groupSessionUtilizationRate,  Map<String, int> groupSessionsByService,  Map<String, int> attendeesByGroupSession)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsMetrics() when $default != null:
return $default(_that.businessId,_that.startDate,_that.endDate,_that.totalAppointments,_that.confirmedAppointments,_that.canceledAppointments,_that.completedAppointments,_that.pendingAppointments,_that.noShowAppointments,_that.totalRevenueCents,_that.paidRevenueCents,_that.pendingRevenueCents,_that.refundedRevenueCents,_that.totalClients,_that.newClients,_that.returningClients,_that.activeClients,_that.inactiveClients,_that.appointmentsByProvider,_that.revenueByProvider,_that.appointmentsByService,_that.revenueByService,_that.appointmentsByDayOfWeek,_that.appointmentsByHourOfDay,_that.appointmentsByDate,_that.averageBookingLeadDays,_that.cancellationRate,_that.noShowRate,_that.utilizationRate,_that.totalGroupSessions,_that.totalGroupSessionAttendees,_that.totalGroupSessionCapacity,_that.groupSessionUtilizationRate,_that.groupSessionsByService,_that.attendeesByGroupSession);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessId, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  int totalAppointments,  int confirmedAppointments,  int canceledAppointments,  int completedAppointments,  int pendingAppointments,  int noShowAppointments,  int totalRevenueCents,  int paidRevenueCents,  int pendingRevenueCents,  int refundedRevenueCents,  int totalClients,  int newClients,  int returningClients,  int activeClients,  int inactiveClients,  Map<String, int> appointmentsByProvider,  Map<String, int> revenueByProvider,  Map<String, int> appointmentsByService,  Map<String, int> revenueByService,  Map<String, int> appointmentsByDayOfWeek,  Map<int, int> appointmentsByHourOfDay,  Map<String, int> appointmentsByDate,  double averageBookingLeadDays,  double cancellationRate,  double noShowRate,  double utilizationRate,  int totalGroupSessions,  int totalGroupSessionAttendees,  int totalGroupSessionCapacity,  double groupSessionUtilizationRate,  Map<String, int> groupSessionsByService,  Map<String, int> attendeesByGroupSession)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsMetrics():
return $default(_that.businessId,_that.startDate,_that.endDate,_that.totalAppointments,_that.confirmedAppointments,_that.canceledAppointments,_that.completedAppointments,_that.pendingAppointments,_that.noShowAppointments,_that.totalRevenueCents,_that.paidRevenueCents,_that.pendingRevenueCents,_that.refundedRevenueCents,_that.totalClients,_that.newClients,_that.returningClients,_that.activeClients,_that.inactiveClients,_that.appointmentsByProvider,_that.revenueByProvider,_that.appointmentsByService,_that.revenueByService,_that.appointmentsByDayOfWeek,_that.appointmentsByHourOfDay,_that.appointmentsByDate,_that.averageBookingLeadDays,_that.cancellationRate,_that.noShowRate,_that.utilizationRate,_that.totalGroupSessions,_that.totalGroupSessionAttendees,_that.totalGroupSessionCapacity,_that.groupSessionUtilizationRate,_that.groupSessionsByService,_that.attendeesByGroupSession);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessId, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  int totalAppointments,  int confirmedAppointments,  int canceledAppointments,  int completedAppointments,  int pendingAppointments,  int noShowAppointments,  int totalRevenueCents,  int paidRevenueCents,  int pendingRevenueCents,  int refundedRevenueCents,  int totalClients,  int newClients,  int returningClients,  int activeClients,  int inactiveClients,  Map<String, int> appointmentsByProvider,  Map<String, int> revenueByProvider,  Map<String, int> appointmentsByService,  Map<String, int> revenueByService,  Map<String, int> appointmentsByDayOfWeek,  Map<int, int> appointmentsByHourOfDay,  Map<String, int> appointmentsByDate,  double averageBookingLeadDays,  double cancellationRate,  double noShowRate,  double utilizationRate,  int totalGroupSessions,  int totalGroupSessionAttendees,  int totalGroupSessionCapacity,  double groupSessionUtilizationRate,  Map<String, int> groupSessionsByService,  Map<String, int> attendeesByGroupSession)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsMetrics() when $default != null:
return $default(_that.businessId,_that.startDate,_that.endDate,_that.totalAppointments,_that.confirmedAppointments,_that.canceledAppointments,_that.completedAppointments,_that.pendingAppointments,_that.noShowAppointments,_that.totalRevenueCents,_that.paidRevenueCents,_that.pendingRevenueCents,_that.refundedRevenueCents,_that.totalClients,_that.newClients,_that.returningClients,_that.activeClients,_that.inactiveClients,_that.appointmentsByProvider,_that.revenueByProvider,_that.appointmentsByService,_that.revenueByService,_that.appointmentsByDayOfWeek,_that.appointmentsByHourOfDay,_that.appointmentsByDate,_that.averageBookingLeadDays,_that.cancellationRate,_that.noShowRate,_that.utilizationRate,_that.totalGroupSessions,_that.totalGroupSessionAttendees,_that.totalGroupSessionCapacity,_that.groupSessionUtilizationRate,_that.groupSessionsByService,_that.attendeesByGroupSession);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsMetrics extends AnalyticsMetrics {
  const _AnalyticsMetrics({required this.businessId, @TimestampConverter() required this.startDate, @TimestampConverter() required this.endDate, required this.totalAppointments, required this.confirmedAppointments, required this.canceledAppointments, required this.completedAppointments, required this.pendingAppointments, required this.noShowAppointments, required this.totalRevenueCents, required this.paidRevenueCents, required this.pendingRevenueCents, required this.refundedRevenueCents, required this.totalClients, required this.newClients, required this.returningClients, required this.activeClients, required this.inactiveClients, required final  Map<String, int> appointmentsByProvider, required final  Map<String, int> revenueByProvider, required final  Map<String, int> appointmentsByService, required final  Map<String, int> revenueByService, required final  Map<String, int> appointmentsByDayOfWeek, required final  Map<int, int> appointmentsByHourOfDay, required final  Map<String, int> appointmentsByDate, required this.averageBookingLeadDays, required this.cancellationRate, required this.noShowRate, required this.utilizationRate, this.totalGroupSessions = 0, this.totalGroupSessionAttendees = 0, this.totalGroupSessionCapacity = 0, this.groupSessionUtilizationRate = 0.0, final  Map<String, int> groupSessionsByService = const {}, final  Map<String, int> attendeesByGroupSession = const {}}): _appointmentsByProvider = appointmentsByProvider,_revenueByProvider = revenueByProvider,_appointmentsByService = appointmentsByService,_revenueByService = revenueByService,_appointmentsByDayOfWeek = appointmentsByDayOfWeek,_appointmentsByHourOfDay = appointmentsByHourOfDay,_appointmentsByDate = appointmentsByDate,_groupSessionsByService = groupSessionsByService,_attendeesByGroupSession = attendeesByGroupSession,super._();
  factory _AnalyticsMetrics.fromJson(Map<String, dynamic> json) => _$AnalyticsMetricsFromJson(json);

@override final  String businessId;
@override@TimestampConverter() final  DateTime startDate;
@override@TimestampConverter() final  DateTime endDate;
// Appointment Metrics
@override final  int totalAppointments;
@override final  int confirmedAppointments;
@override final  int canceledAppointments;
@override final  int completedAppointments;
@override final  int pendingAppointments;
@override final  int noShowAppointments;
// Revenue Metrics (in cents)
@override final  int totalRevenueCents;
@override final  int paidRevenueCents;
@override final  int pendingRevenueCents;
@override final  int refundedRevenueCents;
// Client Metrics
@override final  int totalClients;
@override final  int newClients;
@override final  int returningClients;
@override final  int activeClients;
@override final  int inactiveClients;
// Provider Metrics
 final  Map<String, int> _appointmentsByProvider;
// Provider Metrics
@override Map<String, int> get appointmentsByProvider {
  if (_appointmentsByProvider is EqualUnmodifiableMapView) return _appointmentsByProvider;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appointmentsByProvider);
}

 final  Map<String, int> _revenueByProvider;
@override Map<String, int> get revenueByProvider {
  if (_revenueByProvider is EqualUnmodifiableMapView) return _revenueByProvider;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_revenueByProvider);
}

// in cents
// Service Metrics
 final  Map<String, int> _appointmentsByService;
// in cents
// Service Metrics
@override Map<String, int> get appointmentsByService {
  if (_appointmentsByService is EqualUnmodifiableMapView) return _appointmentsByService;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appointmentsByService);
}

 final  Map<String, int> _revenueByService;
@override Map<String, int> get revenueByService {
  if (_revenueByService is EqualUnmodifiableMapView) return _revenueByService;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_revenueByService);
}

// in cents
// Time-based Metrics
 final  Map<String, int> _appointmentsByDayOfWeek;
// in cents
// Time-based Metrics
@override Map<String, int> get appointmentsByDayOfWeek {
  if (_appointmentsByDayOfWeek is EqualUnmodifiableMapView) return _appointmentsByDayOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appointmentsByDayOfWeek);
}

// Monday: 5, etc
 final  Map<int, int> _appointmentsByHourOfDay;
// Monday: 5, etc
@override Map<int, int> get appointmentsByHourOfDay {
  if (_appointmentsByHourOfDay is EqualUnmodifiableMapView) return _appointmentsByHourOfDay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appointmentsByHourOfDay);
}

// 9: 12, 14: 8, etc
 final  Map<String, int> _appointmentsByDate;
// 9: 12, 14: 8, etc
@override Map<String, int> get appointmentsByDate {
  if (_appointmentsByDate is EqualUnmodifiableMapView) return _appointmentsByDate;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appointmentsByDate);
}

// 2025-11-22: 8, etc
// Performance Metrics
@override final  double averageBookingLeadDays;
@override final  double cancellationRate;
@override final  double noShowRate;
@override final  double utilizationRate;
// Group Session Metrics
@override@JsonKey() final  int totalGroupSessions;
@override@JsonKey() final  int totalGroupSessionAttendees;
@override@JsonKey() final  int totalGroupSessionCapacity;
@override@JsonKey() final  double groupSessionUtilizationRate;
 final  Map<String, int> _groupSessionsByService;
@override@JsonKey() Map<String, int> get groupSessionsByService {
  if (_groupSessionsByService is EqualUnmodifiableMapView) return _groupSessionsByService;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groupSessionsByService);
}

 final  Map<String, int> _attendeesByGroupSession;
@override@JsonKey() Map<String, int> get attendeesByGroupSession {
  if (_attendeesByGroupSession is EqualUnmodifiableMapView) return _attendeesByGroupSession;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attendeesByGroupSession);
}


/// Create a copy of AnalyticsMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsMetricsCopyWith<_AnalyticsMetrics> get copyWith => __$AnalyticsMetricsCopyWithImpl<_AnalyticsMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsMetrics&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.totalAppointments, totalAppointments) || other.totalAppointments == totalAppointments)&&(identical(other.confirmedAppointments, confirmedAppointments) || other.confirmedAppointments == confirmedAppointments)&&(identical(other.canceledAppointments, canceledAppointments) || other.canceledAppointments == canceledAppointments)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.pendingAppointments, pendingAppointments) || other.pendingAppointments == pendingAppointments)&&(identical(other.noShowAppointments, noShowAppointments) || other.noShowAppointments == noShowAppointments)&&(identical(other.totalRevenueCents, totalRevenueCents) || other.totalRevenueCents == totalRevenueCents)&&(identical(other.paidRevenueCents, paidRevenueCents) || other.paidRevenueCents == paidRevenueCents)&&(identical(other.pendingRevenueCents, pendingRevenueCents) || other.pendingRevenueCents == pendingRevenueCents)&&(identical(other.refundedRevenueCents, refundedRevenueCents) || other.refundedRevenueCents == refundedRevenueCents)&&(identical(other.totalClients, totalClients) || other.totalClients == totalClients)&&(identical(other.newClients, newClients) || other.newClients == newClients)&&(identical(other.returningClients, returningClients) || other.returningClients == returningClients)&&(identical(other.activeClients, activeClients) || other.activeClients == activeClients)&&(identical(other.inactiveClients, inactiveClients) || other.inactiveClients == inactiveClients)&&const DeepCollectionEquality().equals(other._appointmentsByProvider, _appointmentsByProvider)&&const DeepCollectionEquality().equals(other._revenueByProvider, _revenueByProvider)&&const DeepCollectionEquality().equals(other._appointmentsByService, _appointmentsByService)&&const DeepCollectionEquality().equals(other._revenueByService, _revenueByService)&&const DeepCollectionEquality().equals(other._appointmentsByDayOfWeek, _appointmentsByDayOfWeek)&&const DeepCollectionEquality().equals(other._appointmentsByHourOfDay, _appointmentsByHourOfDay)&&const DeepCollectionEquality().equals(other._appointmentsByDate, _appointmentsByDate)&&(identical(other.averageBookingLeadDays, averageBookingLeadDays) || other.averageBookingLeadDays == averageBookingLeadDays)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.noShowRate, noShowRate) || other.noShowRate == noShowRate)&&(identical(other.utilizationRate, utilizationRate) || other.utilizationRate == utilizationRate)&&(identical(other.totalGroupSessions, totalGroupSessions) || other.totalGroupSessions == totalGroupSessions)&&(identical(other.totalGroupSessionAttendees, totalGroupSessionAttendees) || other.totalGroupSessionAttendees == totalGroupSessionAttendees)&&(identical(other.totalGroupSessionCapacity, totalGroupSessionCapacity) || other.totalGroupSessionCapacity == totalGroupSessionCapacity)&&(identical(other.groupSessionUtilizationRate, groupSessionUtilizationRate) || other.groupSessionUtilizationRate == groupSessionUtilizationRate)&&const DeepCollectionEquality().equals(other._groupSessionsByService, _groupSessionsByService)&&const DeepCollectionEquality().equals(other._attendeesByGroupSession, _attendeesByGroupSession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,businessId,startDate,endDate,totalAppointments,confirmedAppointments,canceledAppointments,completedAppointments,pendingAppointments,noShowAppointments,totalRevenueCents,paidRevenueCents,pendingRevenueCents,refundedRevenueCents,totalClients,newClients,returningClients,activeClients,inactiveClients,const DeepCollectionEquality().hash(_appointmentsByProvider),const DeepCollectionEquality().hash(_revenueByProvider),const DeepCollectionEquality().hash(_appointmentsByService),const DeepCollectionEquality().hash(_revenueByService),const DeepCollectionEquality().hash(_appointmentsByDayOfWeek),const DeepCollectionEquality().hash(_appointmentsByHourOfDay),const DeepCollectionEquality().hash(_appointmentsByDate),averageBookingLeadDays,cancellationRate,noShowRate,utilizationRate,totalGroupSessions,totalGroupSessionAttendees,totalGroupSessionCapacity,groupSessionUtilizationRate,const DeepCollectionEquality().hash(_groupSessionsByService),const DeepCollectionEquality().hash(_attendeesByGroupSession)]);

@override
String toString() {
  return 'AnalyticsMetrics(businessId: $businessId, startDate: $startDate, endDate: $endDate, totalAppointments: $totalAppointments, confirmedAppointments: $confirmedAppointments, canceledAppointments: $canceledAppointments, completedAppointments: $completedAppointments, pendingAppointments: $pendingAppointments, noShowAppointments: $noShowAppointments, totalRevenueCents: $totalRevenueCents, paidRevenueCents: $paidRevenueCents, pendingRevenueCents: $pendingRevenueCents, refundedRevenueCents: $refundedRevenueCents, totalClients: $totalClients, newClients: $newClients, returningClients: $returningClients, activeClients: $activeClients, inactiveClients: $inactiveClients, appointmentsByProvider: $appointmentsByProvider, revenueByProvider: $revenueByProvider, appointmentsByService: $appointmentsByService, revenueByService: $revenueByService, appointmentsByDayOfWeek: $appointmentsByDayOfWeek, appointmentsByHourOfDay: $appointmentsByHourOfDay, appointmentsByDate: $appointmentsByDate, averageBookingLeadDays: $averageBookingLeadDays, cancellationRate: $cancellationRate, noShowRate: $noShowRate, utilizationRate: $utilizationRate, totalGroupSessions: $totalGroupSessions, totalGroupSessionAttendees: $totalGroupSessionAttendees, totalGroupSessionCapacity: $totalGroupSessionCapacity, groupSessionUtilizationRate: $groupSessionUtilizationRate, groupSessionsByService: $groupSessionsByService, attendeesByGroupSession: $attendeesByGroupSession)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsMetricsCopyWith<$Res> implements $AnalyticsMetricsCopyWith<$Res> {
  factory _$AnalyticsMetricsCopyWith(_AnalyticsMetrics value, $Res Function(_AnalyticsMetrics) _then) = __$AnalyticsMetricsCopyWithImpl;
@override @useResult
$Res call({
 String businessId,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, int totalAppointments, int confirmedAppointments, int canceledAppointments, int completedAppointments, int pendingAppointments, int noShowAppointments, int totalRevenueCents, int paidRevenueCents, int pendingRevenueCents, int refundedRevenueCents, int totalClients, int newClients, int returningClients, int activeClients, int inactiveClients, Map<String, int> appointmentsByProvider, Map<String, int> revenueByProvider, Map<String, int> appointmentsByService, Map<String, int> revenueByService, Map<String, int> appointmentsByDayOfWeek, Map<int, int> appointmentsByHourOfDay, Map<String, int> appointmentsByDate, double averageBookingLeadDays, double cancellationRate, double noShowRate, double utilizationRate, int totalGroupSessions, int totalGroupSessionAttendees, int totalGroupSessionCapacity, double groupSessionUtilizationRate, Map<String, int> groupSessionsByService, Map<String, int> attendeesByGroupSession
});




}
/// @nodoc
class __$AnalyticsMetricsCopyWithImpl<$Res>
    implements _$AnalyticsMetricsCopyWith<$Res> {
  __$AnalyticsMetricsCopyWithImpl(this._self, this._then);

  final _AnalyticsMetrics _self;
  final $Res Function(_AnalyticsMetrics) _then;

/// Create a copy of AnalyticsMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessId = null,Object? startDate = null,Object? endDate = null,Object? totalAppointments = null,Object? confirmedAppointments = null,Object? canceledAppointments = null,Object? completedAppointments = null,Object? pendingAppointments = null,Object? noShowAppointments = null,Object? totalRevenueCents = null,Object? paidRevenueCents = null,Object? pendingRevenueCents = null,Object? refundedRevenueCents = null,Object? totalClients = null,Object? newClients = null,Object? returningClients = null,Object? activeClients = null,Object? inactiveClients = null,Object? appointmentsByProvider = null,Object? revenueByProvider = null,Object? appointmentsByService = null,Object? revenueByService = null,Object? appointmentsByDayOfWeek = null,Object? appointmentsByHourOfDay = null,Object? appointmentsByDate = null,Object? averageBookingLeadDays = null,Object? cancellationRate = null,Object? noShowRate = null,Object? utilizationRate = null,Object? totalGroupSessions = null,Object? totalGroupSessionAttendees = null,Object? totalGroupSessionCapacity = null,Object? groupSessionUtilizationRate = null,Object? groupSessionsByService = null,Object? attendeesByGroupSession = null,}) {
  return _then(_AnalyticsMetrics(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalAppointments: null == totalAppointments ? _self.totalAppointments : totalAppointments // ignore: cast_nullable_to_non_nullable
as int,confirmedAppointments: null == confirmedAppointments ? _self.confirmedAppointments : confirmedAppointments // ignore: cast_nullable_to_non_nullable
as int,canceledAppointments: null == canceledAppointments ? _self.canceledAppointments : canceledAppointments // ignore: cast_nullable_to_non_nullable
as int,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,pendingAppointments: null == pendingAppointments ? _self.pendingAppointments : pendingAppointments // ignore: cast_nullable_to_non_nullable
as int,noShowAppointments: null == noShowAppointments ? _self.noShowAppointments : noShowAppointments // ignore: cast_nullable_to_non_nullable
as int,totalRevenueCents: null == totalRevenueCents ? _self.totalRevenueCents : totalRevenueCents // ignore: cast_nullable_to_non_nullable
as int,paidRevenueCents: null == paidRevenueCents ? _self.paidRevenueCents : paidRevenueCents // ignore: cast_nullable_to_non_nullable
as int,pendingRevenueCents: null == pendingRevenueCents ? _self.pendingRevenueCents : pendingRevenueCents // ignore: cast_nullable_to_non_nullable
as int,refundedRevenueCents: null == refundedRevenueCents ? _self.refundedRevenueCents : refundedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,totalClients: null == totalClients ? _self.totalClients : totalClients // ignore: cast_nullable_to_non_nullable
as int,newClients: null == newClients ? _self.newClients : newClients // ignore: cast_nullable_to_non_nullable
as int,returningClients: null == returningClients ? _self.returningClients : returningClients // ignore: cast_nullable_to_non_nullable
as int,activeClients: null == activeClients ? _self.activeClients : activeClients // ignore: cast_nullable_to_non_nullable
as int,inactiveClients: null == inactiveClients ? _self.inactiveClients : inactiveClients // ignore: cast_nullable_to_non_nullable
as int,appointmentsByProvider: null == appointmentsByProvider ? _self._appointmentsByProvider : appointmentsByProvider // ignore: cast_nullable_to_non_nullable
as Map<String, int>,revenueByProvider: null == revenueByProvider ? _self._revenueByProvider : revenueByProvider // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByService: null == appointmentsByService ? _self._appointmentsByService : appointmentsByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,revenueByService: null == revenueByService ? _self._revenueByService : revenueByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByDayOfWeek: null == appointmentsByDayOfWeek ? _self._appointmentsByDayOfWeek : appointmentsByDayOfWeek // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appointmentsByHourOfDay: null == appointmentsByHourOfDay ? _self._appointmentsByHourOfDay : appointmentsByHourOfDay // ignore: cast_nullable_to_non_nullable
as Map<int, int>,appointmentsByDate: null == appointmentsByDate ? _self._appointmentsByDate : appointmentsByDate // ignore: cast_nullable_to_non_nullable
as Map<String, int>,averageBookingLeadDays: null == averageBookingLeadDays ? _self.averageBookingLeadDays : averageBookingLeadDays // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,noShowRate: null == noShowRate ? _self.noShowRate : noShowRate // ignore: cast_nullable_to_non_nullable
as double,utilizationRate: null == utilizationRate ? _self.utilizationRate : utilizationRate // ignore: cast_nullable_to_non_nullable
as double,totalGroupSessions: null == totalGroupSessions ? _self.totalGroupSessions : totalGroupSessions // ignore: cast_nullable_to_non_nullable
as int,totalGroupSessionAttendees: null == totalGroupSessionAttendees ? _self.totalGroupSessionAttendees : totalGroupSessionAttendees // ignore: cast_nullable_to_non_nullable
as int,totalGroupSessionCapacity: null == totalGroupSessionCapacity ? _self.totalGroupSessionCapacity : totalGroupSessionCapacity // ignore: cast_nullable_to_non_nullable
as int,groupSessionUtilizationRate: null == groupSessionUtilizationRate ? _self.groupSessionUtilizationRate : groupSessionUtilizationRate // ignore: cast_nullable_to_non_nullable
as double,groupSessionsByService: null == groupSessionsByService ? _self._groupSessionsByService : groupSessionsByService // ignore: cast_nullable_to_non_nullable
as Map<String, int>,attendeesByGroupSession: null == attendeesByGroupSession ? _self._attendeesByGroupSession : attendeesByGroupSession // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$DateRangeFilter {

@TimestampConverter() DateTime get startDate;@TimestampConverter() DateTime get endDate; DateRangePeriod get period;
/// Create a copy of DateRangeFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DateRangeFilterCopyWith<DateRangeFilter> get copyWith => _$DateRangeFilterCopyWithImpl<DateRangeFilter>(this as DateRangeFilter, _$identity);

  /// Serializes this DateRangeFilter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DateRangeFilter&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,period);

@override
String toString() {
  return 'DateRangeFilter(startDate: $startDate, endDate: $endDate, period: $period)';
}


}

/// @nodoc
abstract mixin class $DateRangeFilterCopyWith<$Res>  {
  factory $DateRangeFilterCopyWith(DateRangeFilter value, $Res Function(DateRangeFilter) _then) = _$DateRangeFilterCopyWithImpl;
@useResult
$Res call({
@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, DateRangePeriod period
});




}
/// @nodoc
class _$DateRangeFilterCopyWithImpl<$Res>
    implements $DateRangeFilterCopyWith<$Res> {
  _$DateRangeFilterCopyWithImpl(this._self, this._then);

  final DateRangeFilter _self;
  final $Res Function(DateRangeFilter) _then;

/// Create a copy of DateRangeFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,Object? period = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateRangePeriod,
  ));
}

}


/// Adds pattern-matching-related methods to [DateRangeFilter].
extension DateRangeFilterPatterns on DateRangeFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DateRangeFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DateRangeFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DateRangeFilter value)  $default,){
final _that = this;
switch (_that) {
case _DateRangeFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DateRangeFilter value)?  $default,){
final _that = this;
switch (_that) {
case _DateRangeFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  DateRangePeriod period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DateRangeFilter() when $default != null:
return $default(_that.startDate,_that.endDate,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  DateRangePeriod period)  $default,) {final _that = this;
switch (_that) {
case _DateRangeFilter():
return $default(_that.startDate,_that.endDate,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  DateRangePeriod period)?  $default,) {final _that = this;
switch (_that) {
case _DateRangeFilter() when $default != null:
return $default(_that.startDate,_that.endDate,_that.period);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DateRangeFilter implements DateRangeFilter {
  const _DateRangeFilter({@TimestampConverter() required this.startDate, @TimestampConverter() required this.endDate, required this.period});
  factory _DateRangeFilter.fromJson(Map<String, dynamic> json) => _$DateRangeFilterFromJson(json);

@override@TimestampConverter() final  DateTime startDate;
@override@TimestampConverter() final  DateTime endDate;
@override final  DateRangePeriod period;

/// Create a copy of DateRangeFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DateRangeFilterCopyWith<_DateRangeFilter> get copyWith => __$DateRangeFilterCopyWithImpl<_DateRangeFilter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DateRangeFilterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DateRangeFilter&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,period);

@override
String toString() {
  return 'DateRangeFilter(startDate: $startDate, endDate: $endDate, period: $period)';
}


}

/// @nodoc
abstract mixin class _$DateRangeFilterCopyWith<$Res> implements $DateRangeFilterCopyWith<$Res> {
  factory _$DateRangeFilterCopyWith(_DateRangeFilter value, $Res Function(_DateRangeFilter) _then) = __$DateRangeFilterCopyWithImpl;
@override @useResult
$Res call({
@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, DateRangePeriod period
});




}
/// @nodoc
class __$DateRangeFilterCopyWithImpl<$Res>
    implements _$DateRangeFilterCopyWith<$Res> {
  __$DateRangeFilterCopyWithImpl(this._self, this._then);

  final _DateRangeFilter _self;
  final $Res Function(_DateRangeFilter) _then;

/// Create a copy of DateRangeFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,Object? period = null,}) {
  return _then(_DateRangeFilter(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateRangePeriod,
  ));
}


}

// dart format on
