// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prediction_features.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PredictionFeatures {

// ============ Metadata ============
/// Unique identifier of the appointment being predicted
 String get appointmentId;/// Business ID for multi-tenant isolation
 String get businessId;/// Timestamp when features were extracted
 DateTime get extractedAt;/// Schema version for compatibility tracking with ML model
 int get featureSchemaVersion;// ============ Client Behavioral Features ============
/// Client's historical no-show rate (0.0-1.0)
/// Source: Past appointments where status == noShow / total past appointments
/// Range: 0.0 to 1.0
/// Weight: Very High
 double get clientHistoricalNoshowRate;/// Client's historical cancellation rate (0.0-1.0)
/// Source: Past appointments where status == cancelled / total past appointments
/// Range: 0.0 to 1.0
/// Weight: High
 double get clientHistoricalCancelRate;/// Total number of past appointments for this client
/// Source: Count of all past appointments (before now)
/// Range: 0 to infinity
/// Weight: Medium (new clients have higher uncertainty)
 int get clientTotalAppointments;/// Days since client's last completed visit
/// Source: DateTime.now - last completed appointment start time
/// Range: 0 to infinity (9999 for first-time clients)
/// Weight: Medium
 int get clientDaysSinceLastVisit;/// Client's total lifetime payment value in cents
/// Source: Sum of completed payments for this client
/// Range: 0 to infinity
/// Weight: Medium (higher value = more invested)
 int get clientLifetimeValueCents;/// Client's current lifecycle stage
/// Source: Client.lifecycle enum as string
/// Values: 'newClient', 'active', 'inactive', 'churned'
/// Weight: Low
 String get clientLifecycleStage;/// Whether client has a payment method on file
/// Source: Client.hasPaymentMethod
/// Weight: Medium (trust indicator)
 bool get clientHasPaymentMethod;// ============ Appointment Context Features ============
/// Number of days between booking creation and appointment start
/// Source: appointment.startTime - appointment.createdAt (in days)
/// Range: 0 to 365 (capped)
/// Weight: Very High (longer lead = higher no-show risk)
 int get bookingLeadDays;/// Day of week (1=Monday, 7=Sunday)
/// Source: appointment.startTime.weekday
/// Range: 1 to 7
/// Weight: Medium
 int get dayOfWeek;/// Hour of day (24-hour format)
/// Source: appointment.startTime.hour
/// Range: 0 to 23
/// Weight: Medium (early morning/late evening may have higher no-shows)
 int get hourOfDay;/// Whether this is a recurring appointment
/// Source: Appointment.isRecurring
/// Weight: Medium (recurring = more committed)
 bool get isRecurring;/// Whether this is a group session/class
/// Source: Appointment.isGroupSession
/// Weight: Low
 bool get isGroupSession;/// Service duration in minutes
/// Source: Service.durationMinutes
/// Range: 15 to 480
/// Weight: Low
 int get serviceDurationMinutes;/// Service price in cents
/// Source: Service.price (converted to cents)
/// Range: 0 to infinity
/// Weight: Low (higher price = more committed)
 int get servicePriceCents;/// Whether appointment requires payment
/// Source: Appointment.requiresPayment
/// Weight: High (payment required = lower no-show)
 bool get requiresPayment;/// Whether payment has been collected
/// Source: Appointment.paymentStatus == completed
/// Weight: Very High (collected = much lower no-show)
 bool get paymentCollected;/// Whether client submitted an intake form for this appointment
/// Source: IntakeFormSubmission exists for client + appointment
/// Weight: Low (engagement indicator)
 bool get hasIntakeForm;// ============ Provider Features ============
/// Provider's historical no-show rate (0.0-1.0)
/// Source: Past appointments for this provider where status == noShow
/// Range: 0.0 to 1.0
/// Weight: Medium (some providers may have higher no-show rates)
 double get providerHistoricalNoshowRate;/// Total appointments for this provider
/// Source: Count of past appointments for this provider
/// Range: 0 to infinity
/// Weight: Low
 int get providerTotalAppointments;// ============ Time Slot Features ============
/// Historical no-show rate for this day/hour combination (0.0-1.0)
/// Source: Past appointments at same weekday + hour
/// Range: 0.0 to 1.0
/// Weight: Medium
 double get slotHistoricalNoshowRate;/// Whether this is the first appointment of the provider's day
/// Source: Comparison with other appointments on same day
/// Weight: Low (first appointments may have different patterns)
 bool get isFirstAppointmentOfDay;/// Whether this is the last appointment of the provider's day
/// Source: Comparison with other appointments on same day
/// Weight: Low
 bool get isLastAppointmentOfDay;
/// Create a copy of PredictionFeatures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionFeaturesCopyWith<PredictionFeatures> get copyWith => _$PredictionFeaturesCopyWithImpl<PredictionFeatures>(this as PredictionFeatures, _$identity);

  /// Serializes this PredictionFeatures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionFeatures&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.extractedAt, extractedAt) || other.extractedAt == extractedAt)&&(identical(other.featureSchemaVersion, featureSchemaVersion) || other.featureSchemaVersion == featureSchemaVersion)&&(identical(other.clientHistoricalNoshowRate, clientHistoricalNoshowRate) || other.clientHistoricalNoshowRate == clientHistoricalNoshowRate)&&(identical(other.clientHistoricalCancelRate, clientHistoricalCancelRate) || other.clientHistoricalCancelRate == clientHistoricalCancelRate)&&(identical(other.clientTotalAppointments, clientTotalAppointments) || other.clientTotalAppointments == clientTotalAppointments)&&(identical(other.clientDaysSinceLastVisit, clientDaysSinceLastVisit) || other.clientDaysSinceLastVisit == clientDaysSinceLastVisit)&&(identical(other.clientLifetimeValueCents, clientLifetimeValueCents) || other.clientLifetimeValueCents == clientLifetimeValueCents)&&(identical(other.clientLifecycleStage, clientLifecycleStage) || other.clientLifecycleStage == clientLifecycleStage)&&(identical(other.clientHasPaymentMethod, clientHasPaymentMethod) || other.clientHasPaymentMethod == clientHasPaymentMethod)&&(identical(other.bookingLeadDays, bookingLeadDays) || other.bookingLeadDays == bookingLeadDays)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.hourOfDay, hourOfDay) || other.hourOfDay == hourOfDay)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.servicePriceCents, servicePriceCents) || other.servicePriceCents == servicePriceCents)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.paymentCollected, paymentCollected) || other.paymentCollected == paymentCollected)&&(identical(other.hasIntakeForm, hasIntakeForm) || other.hasIntakeForm == hasIntakeForm)&&(identical(other.providerHistoricalNoshowRate, providerHistoricalNoshowRate) || other.providerHistoricalNoshowRate == providerHistoricalNoshowRate)&&(identical(other.providerTotalAppointments, providerTotalAppointments) || other.providerTotalAppointments == providerTotalAppointments)&&(identical(other.slotHistoricalNoshowRate, slotHistoricalNoshowRate) || other.slotHistoricalNoshowRate == slotHistoricalNoshowRate)&&(identical(other.isFirstAppointmentOfDay, isFirstAppointmentOfDay) || other.isFirstAppointmentOfDay == isFirstAppointmentOfDay)&&(identical(other.isLastAppointmentOfDay, isLastAppointmentOfDay) || other.isLastAppointmentOfDay == isLastAppointmentOfDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appointmentId,businessId,extractedAt,featureSchemaVersion,clientHistoricalNoshowRate,clientHistoricalCancelRate,clientTotalAppointments,clientDaysSinceLastVisit,clientLifetimeValueCents,clientLifecycleStage,clientHasPaymentMethod,bookingLeadDays,dayOfWeek,hourOfDay,isRecurring,isGroupSession,serviceDurationMinutes,servicePriceCents,requiresPayment,paymentCollected,hasIntakeForm,providerHistoricalNoshowRate,providerTotalAppointments,slotHistoricalNoshowRate,isFirstAppointmentOfDay,isLastAppointmentOfDay]);

@override
String toString() {
  return 'PredictionFeatures(appointmentId: $appointmentId, businessId: $businessId, extractedAt: $extractedAt, featureSchemaVersion: $featureSchemaVersion, clientHistoricalNoshowRate: $clientHistoricalNoshowRate, clientHistoricalCancelRate: $clientHistoricalCancelRate, clientTotalAppointments: $clientTotalAppointments, clientDaysSinceLastVisit: $clientDaysSinceLastVisit, clientLifetimeValueCents: $clientLifetimeValueCents, clientLifecycleStage: $clientLifecycleStage, clientHasPaymentMethod: $clientHasPaymentMethod, bookingLeadDays: $bookingLeadDays, dayOfWeek: $dayOfWeek, hourOfDay: $hourOfDay, isRecurring: $isRecurring, isGroupSession: $isGroupSession, serviceDurationMinutes: $serviceDurationMinutes, servicePriceCents: $servicePriceCents, requiresPayment: $requiresPayment, paymentCollected: $paymentCollected, hasIntakeForm: $hasIntakeForm, providerHistoricalNoshowRate: $providerHistoricalNoshowRate, providerTotalAppointments: $providerTotalAppointments, slotHistoricalNoshowRate: $slotHistoricalNoshowRate, isFirstAppointmentOfDay: $isFirstAppointmentOfDay, isLastAppointmentOfDay: $isLastAppointmentOfDay)';
}


}

/// @nodoc
abstract mixin class $PredictionFeaturesCopyWith<$Res>  {
  factory $PredictionFeaturesCopyWith(PredictionFeatures value, $Res Function(PredictionFeatures) _then) = _$PredictionFeaturesCopyWithImpl;
@useResult
$Res call({
 String appointmentId, String businessId, DateTime extractedAt, int featureSchemaVersion, double clientHistoricalNoshowRate, double clientHistoricalCancelRate, int clientTotalAppointments, int clientDaysSinceLastVisit, int clientLifetimeValueCents, String clientLifecycleStage, bool clientHasPaymentMethod, int bookingLeadDays, int dayOfWeek, int hourOfDay, bool isRecurring, bool isGroupSession, int serviceDurationMinutes, int servicePriceCents, bool requiresPayment, bool paymentCollected, bool hasIntakeForm, double providerHistoricalNoshowRate, int providerTotalAppointments, double slotHistoricalNoshowRate, bool isFirstAppointmentOfDay, bool isLastAppointmentOfDay
});




}
/// @nodoc
class _$PredictionFeaturesCopyWithImpl<$Res>
    implements $PredictionFeaturesCopyWith<$Res> {
  _$PredictionFeaturesCopyWithImpl(this._self, this._then);

  final PredictionFeatures _self;
  final $Res Function(PredictionFeatures) _then;

/// Create a copy of PredictionFeatures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointmentId = null,Object? businessId = null,Object? extractedAt = null,Object? featureSchemaVersion = null,Object? clientHistoricalNoshowRate = null,Object? clientHistoricalCancelRate = null,Object? clientTotalAppointments = null,Object? clientDaysSinceLastVisit = null,Object? clientLifetimeValueCents = null,Object? clientLifecycleStage = null,Object? clientHasPaymentMethod = null,Object? bookingLeadDays = null,Object? dayOfWeek = null,Object? hourOfDay = null,Object? isRecurring = null,Object? isGroupSession = null,Object? serviceDurationMinutes = null,Object? servicePriceCents = null,Object? requiresPayment = null,Object? paymentCollected = null,Object? hasIntakeForm = null,Object? providerHistoricalNoshowRate = null,Object? providerTotalAppointments = null,Object? slotHistoricalNoshowRate = null,Object? isFirstAppointmentOfDay = null,Object? isLastAppointmentOfDay = null,}) {
  return _then(_self.copyWith(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,extractedAt: null == extractedAt ? _self.extractedAt : extractedAt // ignore: cast_nullable_to_non_nullable
as DateTime,featureSchemaVersion: null == featureSchemaVersion ? _self.featureSchemaVersion : featureSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,clientHistoricalNoshowRate: null == clientHistoricalNoshowRate ? _self.clientHistoricalNoshowRate : clientHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,clientHistoricalCancelRate: null == clientHistoricalCancelRate ? _self.clientHistoricalCancelRate : clientHistoricalCancelRate // ignore: cast_nullable_to_non_nullable
as double,clientTotalAppointments: null == clientTotalAppointments ? _self.clientTotalAppointments : clientTotalAppointments // ignore: cast_nullable_to_non_nullable
as int,clientDaysSinceLastVisit: null == clientDaysSinceLastVisit ? _self.clientDaysSinceLastVisit : clientDaysSinceLastVisit // ignore: cast_nullable_to_non_nullable
as int,clientLifetimeValueCents: null == clientLifetimeValueCents ? _self.clientLifetimeValueCents : clientLifetimeValueCents // ignore: cast_nullable_to_non_nullable
as int,clientLifecycleStage: null == clientLifecycleStage ? _self.clientLifecycleStage : clientLifecycleStage // ignore: cast_nullable_to_non_nullable
as String,clientHasPaymentMethod: null == clientHasPaymentMethod ? _self.clientHasPaymentMethod : clientHasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,bookingLeadDays: null == bookingLeadDays ? _self.bookingLeadDays : bookingLeadDays // ignore: cast_nullable_to_non_nullable
as int,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,hourOfDay: null == hourOfDay ? _self.hourOfDay : hourOfDay // ignore: cast_nullable_to_non_nullable
as int,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,servicePriceCents: null == servicePriceCents ? _self.servicePriceCents : servicePriceCents // ignore: cast_nullable_to_non_nullable
as int,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,paymentCollected: null == paymentCollected ? _self.paymentCollected : paymentCollected // ignore: cast_nullable_to_non_nullable
as bool,hasIntakeForm: null == hasIntakeForm ? _self.hasIntakeForm : hasIntakeForm // ignore: cast_nullable_to_non_nullable
as bool,providerHistoricalNoshowRate: null == providerHistoricalNoshowRate ? _self.providerHistoricalNoshowRate : providerHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,providerTotalAppointments: null == providerTotalAppointments ? _self.providerTotalAppointments : providerTotalAppointments // ignore: cast_nullable_to_non_nullable
as int,slotHistoricalNoshowRate: null == slotHistoricalNoshowRate ? _self.slotHistoricalNoshowRate : slotHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,isFirstAppointmentOfDay: null == isFirstAppointmentOfDay ? _self.isFirstAppointmentOfDay : isFirstAppointmentOfDay // ignore: cast_nullable_to_non_nullable
as bool,isLastAppointmentOfDay: null == isLastAppointmentOfDay ? _self.isLastAppointmentOfDay : isLastAppointmentOfDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionFeatures].
extension PredictionFeaturesPatterns on PredictionFeatures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionFeatures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionFeatures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionFeatures value)  $default,){
final _that = this;
switch (_that) {
case _PredictionFeatures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionFeatures value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionFeatures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appointmentId,  String businessId,  DateTime extractedAt,  int featureSchemaVersion,  double clientHistoricalNoshowRate,  double clientHistoricalCancelRate,  int clientTotalAppointments,  int clientDaysSinceLastVisit,  int clientLifetimeValueCents,  String clientLifecycleStage,  bool clientHasPaymentMethod,  int bookingLeadDays,  int dayOfWeek,  int hourOfDay,  bool isRecurring,  bool isGroupSession,  int serviceDurationMinutes,  int servicePriceCents,  bool requiresPayment,  bool paymentCollected,  bool hasIntakeForm,  double providerHistoricalNoshowRate,  int providerTotalAppointments,  double slotHistoricalNoshowRate,  bool isFirstAppointmentOfDay,  bool isLastAppointmentOfDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionFeatures() when $default != null:
return $default(_that.appointmentId,_that.businessId,_that.extractedAt,_that.featureSchemaVersion,_that.clientHistoricalNoshowRate,_that.clientHistoricalCancelRate,_that.clientTotalAppointments,_that.clientDaysSinceLastVisit,_that.clientLifetimeValueCents,_that.clientLifecycleStage,_that.clientHasPaymentMethod,_that.bookingLeadDays,_that.dayOfWeek,_that.hourOfDay,_that.isRecurring,_that.isGroupSession,_that.serviceDurationMinutes,_that.servicePriceCents,_that.requiresPayment,_that.paymentCollected,_that.hasIntakeForm,_that.providerHistoricalNoshowRate,_that.providerTotalAppointments,_that.slotHistoricalNoshowRate,_that.isFirstAppointmentOfDay,_that.isLastAppointmentOfDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appointmentId,  String businessId,  DateTime extractedAt,  int featureSchemaVersion,  double clientHistoricalNoshowRate,  double clientHistoricalCancelRate,  int clientTotalAppointments,  int clientDaysSinceLastVisit,  int clientLifetimeValueCents,  String clientLifecycleStage,  bool clientHasPaymentMethod,  int bookingLeadDays,  int dayOfWeek,  int hourOfDay,  bool isRecurring,  bool isGroupSession,  int serviceDurationMinutes,  int servicePriceCents,  bool requiresPayment,  bool paymentCollected,  bool hasIntakeForm,  double providerHistoricalNoshowRate,  int providerTotalAppointments,  double slotHistoricalNoshowRate,  bool isFirstAppointmentOfDay,  bool isLastAppointmentOfDay)  $default,) {final _that = this;
switch (_that) {
case _PredictionFeatures():
return $default(_that.appointmentId,_that.businessId,_that.extractedAt,_that.featureSchemaVersion,_that.clientHistoricalNoshowRate,_that.clientHistoricalCancelRate,_that.clientTotalAppointments,_that.clientDaysSinceLastVisit,_that.clientLifetimeValueCents,_that.clientLifecycleStage,_that.clientHasPaymentMethod,_that.bookingLeadDays,_that.dayOfWeek,_that.hourOfDay,_that.isRecurring,_that.isGroupSession,_that.serviceDurationMinutes,_that.servicePriceCents,_that.requiresPayment,_that.paymentCollected,_that.hasIntakeForm,_that.providerHistoricalNoshowRate,_that.providerTotalAppointments,_that.slotHistoricalNoshowRate,_that.isFirstAppointmentOfDay,_that.isLastAppointmentOfDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appointmentId,  String businessId,  DateTime extractedAt,  int featureSchemaVersion,  double clientHistoricalNoshowRate,  double clientHistoricalCancelRate,  int clientTotalAppointments,  int clientDaysSinceLastVisit,  int clientLifetimeValueCents,  String clientLifecycleStage,  bool clientHasPaymentMethod,  int bookingLeadDays,  int dayOfWeek,  int hourOfDay,  bool isRecurring,  bool isGroupSession,  int serviceDurationMinutes,  int servicePriceCents,  bool requiresPayment,  bool paymentCollected,  bool hasIntakeForm,  double providerHistoricalNoshowRate,  int providerTotalAppointments,  double slotHistoricalNoshowRate,  bool isFirstAppointmentOfDay,  bool isLastAppointmentOfDay)?  $default,) {final _that = this;
switch (_that) {
case _PredictionFeatures() when $default != null:
return $default(_that.appointmentId,_that.businessId,_that.extractedAt,_that.featureSchemaVersion,_that.clientHistoricalNoshowRate,_that.clientHistoricalCancelRate,_that.clientTotalAppointments,_that.clientDaysSinceLastVisit,_that.clientLifetimeValueCents,_that.clientLifecycleStage,_that.clientHasPaymentMethod,_that.bookingLeadDays,_that.dayOfWeek,_that.hourOfDay,_that.isRecurring,_that.isGroupSession,_that.serviceDurationMinutes,_that.servicePriceCents,_that.requiresPayment,_that.paymentCollected,_that.hasIntakeForm,_that.providerHistoricalNoshowRate,_that.providerTotalAppointments,_that.slotHistoricalNoshowRate,_that.isFirstAppointmentOfDay,_that.isLastAppointmentOfDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionFeatures extends PredictionFeatures {
  const _PredictionFeatures({required this.appointmentId, required this.businessId, required this.extractedAt, required this.featureSchemaVersion, required this.clientHistoricalNoshowRate, required this.clientHistoricalCancelRate, required this.clientTotalAppointments, required this.clientDaysSinceLastVisit, required this.clientLifetimeValueCents, required this.clientLifecycleStage, required this.clientHasPaymentMethod, required this.bookingLeadDays, required this.dayOfWeek, required this.hourOfDay, required this.isRecurring, required this.isGroupSession, required this.serviceDurationMinutes, required this.servicePriceCents, required this.requiresPayment, required this.paymentCollected, required this.hasIntakeForm, required this.providerHistoricalNoshowRate, required this.providerTotalAppointments, required this.slotHistoricalNoshowRate, required this.isFirstAppointmentOfDay, required this.isLastAppointmentOfDay}): super._();
  factory _PredictionFeatures.fromJson(Map<String, dynamic> json) => _$PredictionFeaturesFromJson(json);

// ============ Metadata ============
/// Unique identifier of the appointment being predicted
@override final  String appointmentId;
/// Business ID for multi-tenant isolation
@override final  String businessId;
/// Timestamp when features were extracted
@override final  DateTime extractedAt;
/// Schema version for compatibility tracking with ML model
@override final  int featureSchemaVersion;
// ============ Client Behavioral Features ============
/// Client's historical no-show rate (0.0-1.0)
/// Source: Past appointments where status == noShow / total past appointments
/// Range: 0.0 to 1.0
/// Weight: Very High
@override final  double clientHistoricalNoshowRate;
/// Client's historical cancellation rate (0.0-1.0)
/// Source: Past appointments where status == cancelled / total past appointments
/// Range: 0.0 to 1.0
/// Weight: High
@override final  double clientHistoricalCancelRate;
/// Total number of past appointments for this client
/// Source: Count of all past appointments (before now)
/// Range: 0 to infinity
/// Weight: Medium (new clients have higher uncertainty)
@override final  int clientTotalAppointments;
/// Days since client's last completed visit
/// Source: DateTime.now - last completed appointment start time
/// Range: 0 to infinity (9999 for first-time clients)
/// Weight: Medium
@override final  int clientDaysSinceLastVisit;
/// Client's total lifetime payment value in cents
/// Source: Sum of completed payments for this client
/// Range: 0 to infinity
/// Weight: Medium (higher value = more invested)
@override final  int clientLifetimeValueCents;
/// Client's current lifecycle stage
/// Source: Client.lifecycle enum as string
/// Values: 'newClient', 'active', 'inactive', 'churned'
/// Weight: Low
@override final  String clientLifecycleStage;
/// Whether client has a payment method on file
/// Source: Client.hasPaymentMethod
/// Weight: Medium (trust indicator)
@override final  bool clientHasPaymentMethod;
// ============ Appointment Context Features ============
/// Number of days between booking creation and appointment start
/// Source: appointment.startTime - appointment.createdAt (in days)
/// Range: 0 to 365 (capped)
/// Weight: Very High (longer lead = higher no-show risk)
@override final  int bookingLeadDays;
/// Day of week (1=Monday, 7=Sunday)
/// Source: appointment.startTime.weekday
/// Range: 1 to 7
/// Weight: Medium
@override final  int dayOfWeek;
/// Hour of day (24-hour format)
/// Source: appointment.startTime.hour
/// Range: 0 to 23
/// Weight: Medium (early morning/late evening may have higher no-shows)
@override final  int hourOfDay;
/// Whether this is a recurring appointment
/// Source: Appointment.isRecurring
/// Weight: Medium (recurring = more committed)
@override final  bool isRecurring;
/// Whether this is a group session/class
/// Source: Appointment.isGroupSession
/// Weight: Low
@override final  bool isGroupSession;
/// Service duration in minutes
/// Source: Service.durationMinutes
/// Range: 15 to 480
/// Weight: Low
@override final  int serviceDurationMinutes;
/// Service price in cents
/// Source: Service.price (converted to cents)
/// Range: 0 to infinity
/// Weight: Low (higher price = more committed)
@override final  int servicePriceCents;
/// Whether appointment requires payment
/// Source: Appointment.requiresPayment
/// Weight: High (payment required = lower no-show)
@override final  bool requiresPayment;
/// Whether payment has been collected
/// Source: Appointment.paymentStatus == completed
/// Weight: Very High (collected = much lower no-show)
@override final  bool paymentCollected;
/// Whether client submitted an intake form for this appointment
/// Source: IntakeFormSubmission exists for client + appointment
/// Weight: Low (engagement indicator)
@override final  bool hasIntakeForm;
// ============ Provider Features ============
/// Provider's historical no-show rate (0.0-1.0)
/// Source: Past appointments for this provider where status == noShow
/// Range: 0.0 to 1.0
/// Weight: Medium (some providers may have higher no-show rates)
@override final  double providerHistoricalNoshowRate;
/// Total appointments for this provider
/// Source: Count of past appointments for this provider
/// Range: 0 to infinity
/// Weight: Low
@override final  int providerTotalAppointments;
// ============ Time Slot Features ============
/// Historical no-show rate for this day/hour combination (0.0-1.0)
/// Source: Past appointments at same weekday + hour
/// Range: 0.0 to 1.0
/// Weight: Medium
@override final  double slotHistoricalNoshowRate;
/// Whether this is the first appointment of the provider's day
/// Source: Comparison with other appointments on same day
/// Weight: Low (first appointments may have different patterns)
@override final  bool isFirstAppointmentOfDay;
/// Whether this is the last appointment of the provider's day
/// Source: Comparison with other appointments on same day
/// Weight: Low
@override final  bool isLastAppointmentOfDay;

/// Create a copy of PredictionFeatures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionFeaturesCopyWith<_PredictionFeatures> get copyWith => __$PredictionFeaturesCopyWithImpl<_PredictionFeatures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionFeaturesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionFeatures&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.extractedAt, extractedAt) || other.extractedAt == extractedAt)&&(identical(other.featureSchemaVersion, featureSchemaVersion) || other.featureSchemaVersion == featureSchemaVersion)&&(identical(other.clientHistoricalNoshowRate, clientHistoricalNoshowRate) || other.clientHistoricalNoshowRate == clientHistoricalNoshowRate)&&(identical(other.clientHistoricalCancelRate, clientHistoricalCancelRate) || other.clientHistoricalCancelRate == clientHistoricalCancelRate)&&(identical(other.clientTotalAppointments, clientTotalAppointments) || other.clientTotalAppointments == clientTotalAppointments)&&(identical(other.clientDaysSinceLastVisit, clientDaysSinceLastVisit) || other.clientDaysSinceLastVisit == clientDaysSinceLastVisit)&&(identical(other.clientLifetimeValueCents, clientLifetimeValueCents) || other.clientLifetimeValueCents == clientLifetimeValueCents)&&(identical(other.clientLifecycleStage, clientLifecycleStage) || other.clientLifecycleStage == clientLifecycleStage)&&(identical(other.clientHasPaymentMethod, clientHasPaymentMethod) || other.clientHasPaymentMethod == clientHasPaymentMethod)&&(identical(other.bookingLeadDays, bookingLeadDays) || other.bookingLeadDays == bookingLeadDays)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.hourOfDay, hourOfDay) || other.hourOfDay == hourOfDay)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.servicePriceCents, servicePriceCents) || other.servicePriceCents == servicePriceCents)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.paymentCollected, paymentCollected) || other.paymentCollected == paymentCollected)&&(identical(other.hasIntakeForm, hasIntakeForm) || other.hasIntakeForm == hasIntakeForm)&&(identical(other.providerHistoricalNoshowRate, providerHistoricalNoshowRate) || other.providerHistoricalNoshowRate == providerHistoricalNoshowRate)&&(identical(other.providerTotalAppointments, providerTotalAppointments) || other.providerTotalAppointments == providerTotalAppointments)&&(identical(other.slotHistoricalNoshowRate, slotHistoricalNoshowRate) || other.slotHistoricalNoshowRate == slotHistoricalNoshowRate)&&(identical(other.isFirstAppointmentOfDay, isFirstAppointmentOfDay) || other.isFirstAppointmentOfDay == isFirstAppointmentOfDay)&&(identical(other.isLastAppointmentOfDay, isLastAppointmentOfDay) || other.isLastAppointmentOfDay == isLastAppointmentOfDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appointmentId,businessId,extractedAt,featureSchemaVersion,clientHistoricalNoshowRate,clientHistoricalCancelRate,clientTotalAppointments,clientDaysSinceLastVisit,clientLifetimeValueCents,clientLifecycleStage,clientHasPaymentMethod,bookingLeadDays,dayOfWeek,hourOfDay,isRecurring,isGroupSession,serviceDurationMinutes,servicePriceCents,requiresPayment,paymentCollected,hasIntakeForm,providerHistoricalNoshowRate,providerTotalAppointments,slotHistoricalNoshowRate,isFirstAppointmentOfDay,isLastAppointmentOfDay]);

@override
String toString() {
  return 'PredictionFeatures(appointmentId: $appointmentId, businessId: $businessId, extractedAt: $extractedAt, featureSchemaVersion: $featureSchemaVersion, clientHistoricalNoshowRate: $clientHistoricalNoshowRate, clientHistoricalCancelRate: $clientHistoricalCancelRate, clientTotalAppointments: $clientTotalAppointments, clientDaysSinceLastVisit: $clientDaysSinceLastVisit, clientLifetimeValueCents: $clientLifetimeValueCents, clientLifecycleStage: $clientLifecycleStage, clientHasPaymentMethod: $clientHasPaymentMethod, bookingLeadDays: $bookingLeadDays, dayOfWeek: $dayOfWeek, hourOfDay: $hourOfDay, isRecurring: $isRecurring, isGroupSession: $isGroupSession, serviceDurationMinutes: $serviceDurationMinutes, servicePriceCents: $servicePriceCents, requiresPayment: $requiresPayment, paymentCollected: $paymentCollected, hasIntakeForm: $hasIntakeForm, providerHistoricalNoshowRate: $providerHistoricalNoshowRate, providerTotalAppointments: $providerTotalAppointments, slotHistoricalNoshowRate: $slotHistoricalNoshowRate, isFirstAppointmentOfDay: $isFirstAppointmentOfDay, isLastAppointmentOfDay: $isLastAppointmentOfDay)';
}


}

/// @nodoc
abstract mixin class _$PredictionFeaturesCopyWith<$Res> implements $PredictionFeaturesCopyWith<$Res> {
  factory _$PredictionFeaturesCopyWith(_PredictionFeatures value, $Res Function(_PredictionFeatures) _then) = __$PredictionFeaturesCopyWithImpl;
@override @useResult
$Res call({
 String appointmentId, String businessId, DateTime extractedAt, int featureSchemaVersion, double clientHistoricalNoshowRate, double clientHistoricalCancelRate, int clientTotalAppointments, int clientDaysSinceLastVisit, int clientLifetimeValueCents, String clientLifecycleStage, bool clientHasPaymentMethod, int bookingLeadDays, int dayOfWeek, int hourOfDay, bool isRecurring, bool isGroupSession, int serviceDurationMinutes, int servicePriceCents, bool requiresPayment, bool paymentCollected, bool hasIntakeForm, double providerHistoricalNoshowRate, int providerTotalAppointments, double slotHistoricalNoshowRate, bool isFirstAppointmentOfDay, bool isLastAppointmentOfDay
});




}
/// @nodoc
class __$PredictionFeaturesCopyWithImpl<$Res>
    implements _$PredictionFeaturesCopyWith<$Res> {
  __$PredictionFeaturesCopyWithImpl(this._self, this._then);

  final _PredictionFeatures _self;
  final $Res Function(_PredictionFeatures) _then;

/// Create a copy of PredictionFeatures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointmentId = null,Object? businessId = null,Object? extractedAt = null,Object? featureSchemaVersion = null,Object? clientHistoricalNoshowRate = null,Object? clientHistoricalCancelRate = null,Object? clientTotalAppointments = null,Object? clientDaysSinceLastVisit = null,Object? clientLifetimeValueCents = null,Object? clientLifecycleStage = null,Object? clientHasPaymentMethod = null,Object? bookingLeadDays = null,Object? dayOfWeek = null,Object? hourOfDay = null,Object? isRecurring = null,Object? isGroupSession = null,Object? serviceDurationMinutes = null,Object? servicePriceCents = null,Object? requiresPayment = null,Object? paymentCollected = null,Object? hasIntakeForm = null,Object? providerHistoricalNoshowRate = null,Object? providerTotalAppointments = null,Object? slotHistoricalNoshowRate = null,Object? isFirstAppointmentOfDay = null,Object? isLastAppointmentOfDay = null,}) {
  return _then(_PredictionFeatures(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,extractedAt: null == extractedAt ? _self.extractedAt : extractedAt // ignore: cast_nullable_to_non_nullable
as DateTime,featureSchemaVersion: null == featureSchemaVersion ? _self.featureSchemaVersion : featureSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,clientHistoricalNoshowRate: null == clientHistoricalNoshowRate ? _self.clientHistoricalNoshowRate : clientHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,clientHistoricalCancelRate: null == clientHistoricalCancelRate ? _self.clientHistoricalCancelRate : clientHistoricalCancelRate // ignore: cast_nullable_to_non_nullable
as double,clientTotalAppointments: null == clientTotalAppointments ? _self.clientTotalAppointments : clientTotalAppointments // ignore: cast_nullable_to_non_nullable
as int,clientDaysSinceLastVisit: null == clientDaysSinceLastVisit ? _self.clientDaysSinceLastVisit : clientDaysSinceLastVisit // ignore: cast_nullable_to_non_nullable
as int,clientLifetimeValueCents: null == clientLifetimeValueCents ? _self.clientLifetimeValueCents : clientLifetimeValueCents // ignore: cast_nullable_to_non_nullable
as int,clientLifecycleStage: null == clientLifecycleStage ? _self.clientLifecycleStage : clientLifecycleStage // ignore: cast_nullable_to_non_nullable
as String,clientHasPaymentMethod: null == clientHasPaymentMethod ? _self.clientHasPaymentMethod : clientHasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,bookingLeadDays: null == bookingLeadDays ? _self.bookingLeadDays : bookingLeadDays // ignore: cast_nullable_to_non_nullable
as int,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,hourOfDay: null == hourOfDay ? _self.hourOfDay : hourOfDay // ignore: cast_nullable_to_non_nullable
as int,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,servicePriceCents: null == servicePriceCents ? _self.servicePriceCents : servicePriceCents // ignore: cast_nullable_to_non_nullable
as int,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,paymentCollected: null == paymentCollected ? _self.paymentCollected : paymentCollected // ignore: cast_nullable_to_non_nullable
as bool,hasIntakeForm: null == hasIntakeForm ? _self.hasIntakeForm : hasIntakeForm // ignore: cast_nullable_to_non_nullable
as bool,providerHistoricalNoshowRate: null == providerHistoricalNoshowRate ? _self.providerHistoricalNoshowRate : providerHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,providerTotalAppointments: null == providerTotalAppointments ? _self.providerTotalAppointments : providerTotalAppointments // ignore: cast_nullable_to_non_nullable
as int,slotHistoricalNoshowRate: null == slotHistoricalNoshowRate ? _self.slotHistoricalNoshowRate : slotHistoricalNoshowRate // ignore: cast_nullable_to_non_nullable
as double,isFirstAppointmentOfDay: null == isFirstAppointmentOfDay ? _self.isFirstAppointmentOfDay : isFirstAppointmentOfDay // ignore: cast_nullable_to_non_nullable
as bool,isLastAppointmentOfDay: null == isLastAppointmentOfDay ? _self.isLastAppointmentOfDay : isLastAppointmentOfDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
