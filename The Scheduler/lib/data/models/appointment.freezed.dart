// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Appointment {

 String get id; String get businessId; String get clientId; String get providerId; String get serviceId; String? get serviceType;// Cached service name for display
 String get locationId;@TimestampConverter() DateTime get startTime;@TimestampConverter() DateTime get endTime;@TimestampConverter() DateTime get date; AppointmentStatus get status; String? get notes;@TimestampConverter() DateTime get createdAt; bool get requiresPayment; PaymentType get paymentType; int? get paymentAmountCents; PaymentStatus get paymentStatus; String? get paymentId; bool get refundEligible; PaymentStatus? get refundStatus; int? get refundAmountCents;@NullableTimestampConverter() DateTime? get refundRequestedAt;@NullableTimestampConverter() DateTime? get refundProcessedAt; String? get refundPaymentId; bool get rescheduleFeeRequired; int? get rescheduleFeeCents; PaymentStatus get rescheduleFeeStatus; String? get reschedulePaymentId; bool get cancellationFeeRequired; int? get cancellationFeeCents; PaymentStatus get cancellationFeeStatus; String? get cancellationPaymentId; String? get cancellationReason; String? get cancellationCode;@NullableTimestampConverter() DateTime? get cancelledAt;// Recurrence fields
/// Whether this is a recurring appointment
 bool get isRecurring;/// ID linking all appointments in the same recurrence series
 String? get recurrenceId;/// The recurrence pattern (only set on parent/first appointment in series)
 RecurrencePattern? get recurrencePattern;/// Whether this instance is an exception (modified) from the series
 bool get isRecurrenceException;/// Original date/time before modification (for exceptions)
@NullableTimestampConverter() DateTime? get originalStartTime;/// For group appointments/classes
 bool get isGroupSession; int? get capacity; List<String> get attendeeIds; bool get publicVisibility;@NullableTimestampConverter() DateTime? get registrationDeadline;
/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentCopyWith<Appointment> get copyWith => _$AppointmentCopyWithImpl<Appointment>(this as Appointment, _$identity);

  /// Serializes this Appointment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.paymentAmountCents, paymentAmountCents) || other.paymentAmountCents == paymentAmountCents)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.refundEligible, refundEligible) || other.refundEligible == refundEligible)&&(identical(other.refundStatus, refundStatus) || other.refundStatus == refundStatus)&&(identical(other.refundAmountCents, refundAmountCents) || other.refundAmountCents == refundAmountCents)&&(identical(other.refundRequestedAt, refundRequestedAt) || other.refundRequestedAt == refundRequestedAt)&&(identical(other.refundProcessedAt, refundProcessedAt) || other.refundProcessedAt == refundProcessedAt)&&(identical(other.refundPaymentId, refundPaymentId) || other.refundPaymentId == refundPaymentId)&&(identical(other.rescheduleFeeRequired, rescheduleFeeRequired) || other.rescheduleFeeRequired == rescheduleFeeRequired)&&(identical(other.rescheduleFeeCents, rescheduleFeeCents) || other.rescheduleFeeCents == rescheduleFeeCents)&&(identical(other.rescheduleFeeStatus, rescheduleFeeStatus) || other.rescheduleFeeStatus == rescheduleFeeStatus)&&(identical(other.reschedulePaymentId, reschedulePaymentId) || other.reschedulePaymentId == reschedulePaymentId)&&(identical(other.cancellationFeeRequired, cancellationFeeRequired) || other.cancellationFeeRequired == cancellationFeeRequired)&&(identical(other.cancellationFeeCents, cancellationFeeCents) || other.cancellationFeeCents == cancellationFeeCents)&&(identical(other.cancellationFeeStatus, cancellationFeeStatus) || other.cancellationFeeStatus == cancellationFeeStatus)&&(identical(other.cancellationPaymentId, cancellationPaymentId) || other.cancellationPaymentId == cancellationPaymentId)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.cancellationCode, cancellationCode) || other.cancellationCode == cancellationCode)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.recurrenceId, recurrenceId) || other.recurrenceId == recurrenceId)&&(identical(other.recurrencePattern, recurrencePattern) || other.recurrencePattern == recurrencePattern)&&(identical(other.isRecurrenceException, isRecurrenceException) || other.isRecurrenceException == isRecurrenceException)&&(identical(other.originalStartTime, originalStartTime) || other.originalStartTime == originalStartTime)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other.attendeeIds, attendeeIds)&&(identical(other.publicVisibility, publicVisibility) || other.publicVisibility == publicVisibility)&&(identical(other.registrationDeadline, registrationDeadline) || other.registrationDeadline == registrationDeadline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,clientId,providerId,serviceId,serviceType,locationId,startTime,endTime,date,status,notes,createdAt,requiresPayment,paymentType,paymentAmountCents,paymentStatus,paymentId,refundEligible,refundStatus,refundAmountCents,refundRequestedAt,refundProcessedAt,refundPaymentId,rescheduleFeeRequired,rescheduleFeeCents,rescheduleFeeStatus,reschedulePaymentId,cancellationFeeRequired,cancellationFeeCents,cancellationFeeStatus,cancellationPaymentId,cancellationReason,cancellationCode,cancelledAt,isRecurring,recurrenceId,recurrencePattern,isRecurrenceException,originalStartTime,isGroupSession,capacity,const DeepCollectionEquality().hash(attendeeIds),publicVisibility,registrationDeadline]);

@override
String toString() {
  return 'Appointment(id: $id, businessId: $businessId, clientId: $clientId, providerId: $providerId, serviceId: $serviceId, serviceType: $serviceType, locationId: $locationId, startTime: $startTime, endTime: $endTime, date: $date, status: $status, notes: $notes, createdAt: $createdAt, requiresPayment: $requiresPayment, paymentType: $paymentType, paymentAmountCents: $paymentAmountCents, paymentStatus: $paymentStatus, paymentId: $paymentId, refundEligible: $refundEligible, refundStatus: $refundStatus, refundAmountCents: $refundAmountCents, refundRequestedAt: $refundRequestedAt, refundProcessedAt: $refundProcessedAt, refundPaymentId: $refundPaymentId, rescheduleFeeRequired: $rescheduleFeeRequired, rescheduleFeeCents: $rescheduleFeeCents, rescheduleFeeStatus: $rescheduleFeeStatus, reschedulePaymentId: $reschedulePaymentId, cancellationFeeRequired: $cancellationFeeRequired, cancellationFeeCents: $cancellationFeeCents, cancellationFeeStatus: $cancellationFeeStatus, cancellationPaymentId: $cancellationPaymentId, cancellationReason: $cancellationReason, cancellationCode: $cancellationCode, cancelledAt: $cancelledAt, isRecurring: $isRecurring, recurrenceId: $recurrenceId, recurrencePattern: $recurrencePattern, isRecurrenceException: $isRecurrenceException, originalStartTime: $originalStartTime, isGroupSession: $isGroupSession, capacity: $capacity, attendeeIds: $attendeeIds, publicVisibility: $publicVisibility, registrationDeadline: $registrationDeadline)';
}


}

/// @nodoc
abstract mixin class $AppointmentCopyWith<$Res>  {
  factory $AppointmentCopyWith(Appointment value, $Res Function(Appointment) _then) = _$AppointmentCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String clientId, String providerId, String serviceId, String? serviceType, String locationId,@TimestampConverter() DateTime startTime,@TimestampConverter() DateTime endTime,@TimestampConverter() DateTime date, AppointmentStatus status, String? notes,@TimestampConverter() DateTime createdAt, bool requiresPayment, PaymentType paymentType, int? paymentAmountCents, PaymentStatus paymentStatus, String? paymentId, bool refundEligible, PaymentStatus? refundStatus, int? refundAmountCents,@NullableTimestampConverter() DateTime? refundRequestedAt,@NullableTimestampConverter() DateTime? refundProcessedAt, String? refundPaymentId, bool rescheduleFeeRequired, int? rescheduleFeeCents, PaymentStatus rescheduleFeeStatus, String? reschedulePaymentId, bool cancellationFeeRequired, int? cancellationFeeCents, PaymentStatus cancellationFeeStatus, String? cancellationPaymentId, String? cancellationReason, String? cancellationCode,@NullableTimestampConverter() DateTime? cancelledAt, bool isRecurring, String? recurrenceId, RecurrencePattern? recurrencePattern, bool isRecurrenceException,@NullableTimestampConverter() DateTime? originalStartTime, bool isGroupSession, int? capacity, List<String> attendeeIds, bool publicVisibility,@NullableTimestampConverter() DateTime? registrationDeadline
});


$RecurrencePatternCopyWith<$Res>? get recurrencePattern;

}
/// @nodoc
class _$AppointmentCopyWithImpl<$Res>
    implements $AppointmentCopyWith<$Res> {
  _$AppointmentCopyWithImpl(this._self, this._then);

  final Appointment _self;
  final $Res Function(Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? providerId = null,Object? serviceId = null,Object? serviceType = freezed,Object? locationId = null,Object? startTime = null,Object? endTime = null,Object? date = null,Object? status = null,Object? notes = freezed,Object? createdAt = null,Object? requiresPayment = null,Object? paymentType = null,Object? paymentAmountCents = freezed,Object? paymentStatus = null,Object? paymentId = freezed,Object? refundEligible = null,Object? refundStatus = freezed,Object? refundAmountCents = freezed,Object? refundRequestedAt = freezed,Object? refundProcessedAt = freezed,Object? refundPaymentId = freezed,Object? rescheduleFeeRequired = null,Object? rescheduleFeeCents = freezed,Object? rescheduleFeeStatus = null,Object? reschedulePaymentId = freezed,Object? cancellationFeeRequired = null,Object? cancellationFeeCents = freezed,Object? cancellationFeeStatus = null,Object? cancellationPaymentId = freezed,Object? cancellationReason = freezed,Object? cancellationCode = freezed,Object? cancelledAt = freezed,Object? isRecurring = null,Object? recurrenceId = freezed,Object? recurrencePattern = freezed,Object? isRecurrenceException = null,Object? originalStartTime = freezed,Object? isGroupSession = null,Object? capacity = freezed,Object? attendeeIds = null,Object? publicVisibility = null,Object? registrationDeadline = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceType: freezed == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as String?,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as PaymentType,paymentAmountCents: freezed == paymentAmountCents ? _self.paymentAmountCents : paymentAmountCents // ignore: cast_nullable_to_non_nullable
as int?,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,refundEligible: null == refundEligible ? _self.refundEligible : refundEligible // ignore: cast_nullable_to_non_nullable
as bool,refundStatus: freezed == refundStatus ? _self.refundStatus : refundStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus?,refundAmountCents: freezed == refundAmountCents ? _self.refundAmountCents : refundAmountCents // ignore: cast_nullable_to_non_nullable
as int?,refundRequestedAt: freezed == refundRequestedAt ? _self.refundRequestedAt : refundRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundProcessedAt: freezed == refundProcessedAt ? _self.refundProcessedAt : refundProcessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundPaymentId: freezed == refundPaymentId ? _self.refundPaymentId : refundPaymentId // ignore: cast_nullable_to_non_nullable
as String?,rescheduleFeeRequired: null == rescheduleFeeRequired ? _self.rescheduleFeeRequired : rescheduleFeeRequired // ignore: cast_nullable_to_non_nullable
as bool,rescheduleFeeCents: freezed == rescheduleFeeCents ? _self.rescheduleFeeCents : rescheduleFeeCents // ignore: cast_nullable_to_non_nullable
as int?,rescheduleFeeStatus: null == rescheduleFeeStatus ? _self.rescheduleFeeStatus : rescheduleFeeStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,reschedulePaymentId: freezed == reschedulePaymentId ? _self.reschedulePaymentId : reschedulePaymentId // ignore: cast_nullable_to_non_nullable
as String?,cancellationFeeRequired: null == cancellationFeeRequired ? _self.cancellationFeeRequired : cancellationFeeRequired // ignore: cast_nullable_to_non_nullable
as bool,cancellationFeeCents: freezed == cancellationFeeCents ? _self.cancellationFeeCents : cancellationFeeCents // ignore: cast_nullable_to_non_nullable
as int?,cancellationFeeStatus: null == cancellationFeeStatus ? _self.cancellationFeeStatus : cancellationFeeStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,cancellationPaymentId: freezed == cancellationPaymentId ? _self.cancellationPaymentId : cancellationPaymentId // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,cancellationCode: freezed == cancellationCode ? _self.cancellationCode : cancellationCode // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,recurrencePattern: freezed == recurrencePattern ? _self.recurrencePattern : recurrencePattern // ignore: cast_nullable_to_non_nullable
as RecurrencePattern?,isRecurrenceException: null == isRecurrenceException ? _self.isRecurrenceException : isRecurrenceException // ignore: cast_nullable_to_non_nullable
as bool,originalStartTime: freezed == originalStartTime ? _self.originalStartTime : originalStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,attendeeIds: null == attendeeIds ? _self.attendeeIds : attendeeIds // ignore: cast_nullable_to_non_nullable
as List<String>,publicVisibility: null == publicVisibility ? _self.publicVisibility : publicVisibility // ignore: cast_nullable_to_non_nullable
as bool,registrationDeadline: freezed == registrationDeadline ? _self.registrationDeadline : registrationDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrencePatternCopyWith<$Res>? get recurrencePattern {
    if (_self.recurrencePattern == null) {
    return null;
  }

  return $RecurrencePatternCopyWith<$Res>(_self.recurrencePattern!, (value) {
    return _then(_self.copyWith(recurrencePattern: value));
  });
}
}


/// Adds pattern-matching-related methods to [Appointment].
extension AppointmentPatterns on Appointment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Appointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Appointment value)  $default,){
final _that = this;
switch (_that) {
case _Appointment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Appointment value)?  $default,){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  String providerId,  String serviceId,  String? serviceType,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime, @TimestampConverter()  DateTime date,  AppointmentStatus status,  String? notes, @TimestampConverter()  DateTime createdAt,  bool requiresPayment,  PaymentType paymentType,  int? paymentAmountCents,  PaymentStatus paymentStatus,  String? paymentId,  bool refundEligible,  PaymentStatus? refundStatus,  int? refundAmountCents, @NullableTimestampConverter()  DateTime? refundRequestedAt, @NullableTimestampConverter()  DateTime? refundProcessedAt,  String? refundPaymentId,  bool rescheduleFeeRequired,  int? rescheduleFeeCents,  PaymentStatus rescheduleFeeStatus,  String? reschedulePaymentId,  bool cancellationFeeRequired,  int? cancellationFeeCents,  PaymentStatus cancellationFeeStatus,  String? cancellationPaymentId,  String? cancellationReason,  String? cancellationCode, @NullableTimestampConverter()  DateTime? cancelledAt,  bool isRecurring,  String? recurrenceId,  RecurrencePattern? recurrencePattern,  bool isRecurrenceException, @NullableTimestampConverter()  DateTime? originalStartTime,  bool isGroupSession,  int? capacity,  List<String> attendeeIds,  bool publicVisibility, @NullableTimestampConverter()  DateTime? registrationDeadline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.providerId,_that.serviceId,_that.serviceType,_that.locationId,_that.startTime,_that.endTime,_that.date,_that.status,_that.notes,_that.createdAt,_that.requiresPayment,_that.paymentType,_that.paymentAmountCents,_that.paymentStatus,_that.paymentId,_that.refundEligible,_that.refundStatus,_that.refundAmountCents,_that.refundRequestedAt,_that.refundProcessedAt,_that.refundPaymentId,_that.rescheduleFeeRequired,_that.rescheduleFeeCents,_that.rescheduleFeeStatus,_that.reschedulePaymentId,_that.cancellationFeeRequired,_that.cancellationFeeCents,_that.cancellationFeeStatus,_that.cancellationPaymentId,_that.cancellationReason,_that.cancellationCode,_that.cancelledAt,_that.isRecurring,_that.recurrenceId,_that.recurrencePattern,_that.isRecurrenceException,_that.originalStartTime,_that.isGroupSession,_that.capacity,_that.attendeeIds,_that.publicVisibility,_that.registrationDeadline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  String providerId,  String serviceId,  String? serviceType,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime, @TimestampConverter()  DateTime date,  AppointmentStatus status,  String? notes, @TimestampConverter()  DateTime createdAt,  bool requiresPayment,  PaymentType paymentType,  int? paymentAmountCents,  PaymentStatus paymentStatus,  String? paymentId,  bool refundEligible,  PaymentStatus? refundStatus,  int? refundAmountCents, @NullableTimestampConverter()  DateTime? refundRequestedAt, @NullableTimestampConverter()  DateTime? refundProcessedAt,  String? refundPaymentId,  bool rescheduleFeeRequired,  int? rescheduleFeeCents,  PaymentStatus rescheduleFeeStatus,  String? reschedulePaymentId,  bool cancellationFeeRequired,  int? cancellationFeeCents,  PaymentStatus cancellationFeeStatus,  String? cancellationPaymentId,  String? cancellationReason,  String? cancellationCode, @NullableTimestampConverter()  DateTime? cancelledAt,  bool isRecurring,  String? recurrenceId,  RecurrencePattern? recurrencePattern,  bool isRecurrenceException, @NullableTimestampConverter()  DateTime? originalStartTime,  bool isGroupSession,  int? capacity,  List<String> attendeeIds,  bool publicVisibility, @NullableTimestampConverter()  DateTime? registrationDeadline)  $default,) {final _that = this;
switch (_that) {
case _Appointment():
return $default(_that.id,_that.businessId,_that.clientId,_that.providerId,_that.serviceId,_that.serviceType,_that.locationId,_that.startTime,_that.endTime,_that.date,_that.status,_that.notes,_that.createdAt,_that.requiresPayment,_that.paymentType,_that.paymentAmountCents,_that.paymentStatus,_that.paymentId,_that.refundEligible,_that.refundStatus,_that.refundAmountCents,_that.refundRequestedAt,_that.refundProcessedAt,_that.refundPaymentId,_that.rescheduleFeeRequired,_that.rescheduleFeeCents,_that.rescheduleFeeStatus,_that.reschedulePaymentId,_that.cancellationFeeRequired,_that.cancellationFeeCents,_that.cancellationFeeStatus,_that.cancellationPaymentId,_that.cancellationReason,_that.cancellationCode,_that.cancelledAt,_that.isRecurring,_that.recurrenceId,_that.recurrencePattern,_that.isRecurrenceException,_that.originalStartTime,_that.isGroupSession,_that.capacity,_that.attendeeIds,_that.publicVisibility,_that.registrationDeadline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String clientId,  String providerId,  String serviceId,  String? serviceType,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime, @TimestampConverter()  DateTime date,  AppointmentStatus status,  String? notes, @TimestampConverter()  DateTime createdAt,  bool requiresPayment,  PaymentType paymentType,  int? paymentAmountCents,  PaymentStatus paymentStatus,  String? paymentId,  bool refundEligible,  PaymentStatus? refundStatus,  int? refundAmountCents, @NullableTimestampConverter()  DateTime? refundRequestedAt, @NullableTimestampConverter()  DateTime? refundProcessedAt,  String? refundPaymentId,  bool rescheduleFeeRequired,  int? rescheduleFeeCents,  PaymentStatus rescheduleFeeStatus,  String? reschedulePaymentId,  bool cancellationFeeRequired,  int? cancellationFeeCents,  PaymentStatus cancellationFeeStatus,  String? cancellationPaymentId,  String? cancellationReason,  String? cancellationCode, @NullableTimestampConverter()  DateTime? cancelledAt,  bool isRecurring,  String? recurrenceId,  RecurrencePattern? recurrencePattern,  bool isRecurrenceException, @NullableTimestampConverter()  DateTime? originalStartTime,  bool isGroupSession,  int? capacity,  List<String> attendeeIds,  bool publicVisibility, @NullableTimestampConverter()  DateTime? registrationDeadline)?  $default,) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.providerId,_that.serviceId,_that.serviceType,_that.locationId,_that.startTime,_that.endTime,_that.date,_that.status,_that.notes,_that.createdAt,_that.requiresPayment,_that.paymentType,_that.paymentAmountCents,_that.paymentStatus,_that.paymentId,_that.refundEligible,_that.refundStatus,_that.refundAmountCents,_that.refundRequestedAt,_that.refundProcessedAt,_that.refundPaymentId,_that.rescheduleFeeRequired,_that.rescheduleFeeCents,_that.rescheduleFeeStatus,_that.reschedulePaymentId,_that.cancellationFeeRequired,_that.cancellationFeeCents,_that.cancellationFeeStatus,_that.cancellationPaymentId,_that.cancellationReason,_that.cancellationCode,_that.cancelledAt,_that.isRecurring,_that.recurrenceId,_that.recurrencePattern,_that.isRecurrenceException,_that.originalStartTime,_that.isGroupSession,_that.capacity,_that.attendeeIds,_that.publicVisibility,_that.registrationDeadline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Appointment implements Appointment {
  const _Appointment({required this.id, required this.businessId, required this.clientId, required this.providerId, required this.serviceId, this.serviceType, required this.locationId, @TimestampConverter() required this.startTime, @TimestampConverter() required this.endTime, @TimestampConverter() required this.date, required this.status, this.notes, @TimestampConverter() required this.createdAt, this.requiresPayment = false, this.paymentType = PaymentType.full, this.paymentAmountCents, this.paymentStatus = PaymentStatus.none, this.paymentId, this.refundEligible = false, this.refundStatus, this.refundAmountCents, @NullableTimestampConverter() this.refundRequestedAt, @NullableTimestampConverter() this.refundProcessedAt, this.refundPaymentId, this.rescheduleFeeRequired = false, this.rescheduleFeeCents, this.rescheduleFeeStatus = PaymentStatus.none, this.reschedulePaymentId, this.cancellationFeeRequired = false, this.cancellationFeeCents, this.cancellationFeeStatus = PaymentStatus.none, this.cancellationPaymentId, this.cancellationReason, this.cancellationCode, @NullableTimestampConverter() this.cancelledAt, this.isRecurring = false, this.recurrenceId, this.recurrencePattern, this.isRecurrenceException = false, @NullableTimestampConverter() this.originalStartTime, this.isGroupSession = false, this.capacity, final  List<String> attendeeIds = const [], this.publicVisibility = false, @NullableTimestampConverter() this.registrationDeadline}): _attendeeIds = attendeeIds;
  factory _Appointment.fromJson(Map<String, dynamic> json) => _$AppointmentFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String clientId;
@override final  String providerId;
@override final  String serviceId;
@override final  String? serviceType;
// Cached service name for display
@override final  String locationId;
@override@TimestampConverter() final  DateTime startTime;
@override@TimestampConverter() final  DateTime endTime;
@override@TimestampConverter() final  DateTime date;
@override final  AppointmentStatus status;
@override final  String? notes;
@override@TimestampConverter() final  DateTime createdAt;
@override@JsonKey() final  bool requiresPayment;
@override@JsonKey() final  PaymentType paymentType;
@override final  int? paymentAmountCents;
@override@JsonKey() final  PaymentStatus paymentStatus;
@override final  String? paymentId;
@override@JsonKey() final  bool refundEligible;
@override final  PaymentStatus? refundStatus;
@override final  int? refundAmountCents;
@override@NullableTimestampConverter() final  DateTime? refundRequestedAt;
@override@NullableTimestampConverter() final  DateTime? refundProcessedAt;
@override final  String? refundPaymentId;
@override@JsonKey() final  bool rescheduleFeeRequired;
@override final  int? rescheduleFeeCents;
@override@JsonKey() final  PaymentStatus rescheduleFeeStatus;
@override final  String? reschedulePaymentId;
@override@JsonKey() final  bool cancellationFeeRequired;
@override final  int? cancellationFeeCents;
@override@JsonKey() final  PaymentStatus cancellationFeeStatus;
@override final  String? cancellationPaymentId;
@override final  String? cancellationReason;
@override final  String? cancellationCode;
@override@NullableTimestampConverter() final  DateTime? cancelledAt;
// Recurrence fields
/// Whether this is a recurring appointment
@override@JsonKey() final  bool isRecurring;
/// ID linking all appointments in the same recurrence series
@override final  String? recurrenceId;
/// The recurrence pattern (only set on parent/first appointment in series)
@override final  RecurrencePattern? recurrencePattern;
/// Whether this instance is an exception (modified) from the series
@override@JsonKey() final  bool isRecurrenceException;
/// Original date/time before modification (for exceptions)
@override@NullableTimestampConverter() final  DateTime? originalStartTime;
/// For group appointments/classes
@override@JsonKey() final  bool isGroupSession;
@override final  int? capacity;
 final  List<String> _attendeeIds;
@override@JsonKey() List<String> get attendeeIds {
  if (_attendeeIds is EqualUnmodifiableListView) return _attendeeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attendeeIds);
}

@override@JsonKey() final  bool publicVisibility;
@override@NullableTimestampConverter() final  DateTime? registrationDeadline;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppointmentCopyWith<_Appointment> get copyWith => __$AppointmentCopyWithImpl<_Appointment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppointmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.paymentAmountCents, paymentAmountCents) || other.paymentAmountCents == paymentAmountCents)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.refundEligible, refundEligible) || other.refundEligible == refundEligible)&&(identical(other.refundStatus, refundStatus) || other.refundStatus == refundStatus)&&(identical(other.refundAmountCents, refundAmountCents) || other.refundAmountCents == refundAmountCents)&&(identical(other.refundRequestedAt, refundRequestedAt) || other.refundRequestedAt == refundRequestedAt)&&(identical(other.refundProcessedAt, refundProcessedAt) || other.refundProcessedAt == refundProcessedAt)&&(identical(other.refundPaymentId, refundPaymentId) || other.refundPaymentId == refundPaymentId)&&(identical(other.rescheduleFeeRequired, rescheduleFeeRequired) || other.rescheduleFeeRequired == rescheduleFeeRequired)&&(identical(other.rescheduleFeeCents, rescheduleFeeCents) || other.rescheduleFeeCents == rescheduleFeeCents)&&(identical(other.rescheduleFeeStatus, rescheduleFeeStatus) || other.rescheduleFeeStatus == rescheduleFeeStatus)&&(identical(other.reschedulePaymentId, reschedulePaymentId) || other.reschedulePaymentId == reschedulePaymentId)&&(identical(other.cancellationFeeRequired, cancellationFeeRequired) || other.cancellationFeeRequired == cancellationFeeRequired)&&(identical(other.cancellationFeeCents, cancellationFeeCents) || other.cancellationFeeCents == cancellationFeeCents)&&(identical(other.cancellationFeeStatus, cancellationFeeStatus) || other.cancellationFeeStatus == cancellationFeeStatus)&&(identical(other.cancellationPaymentId, cancellationPaymentId) || other.cancellationPaymentId == cancellationPaymentId)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.cancellationCode, cancellationCode) || other.cancellationCode == cancellationCode)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.recurrenceId, recurrenceId) || other.recurrenceId == recurrenceId)&&(identical(other.recurrencePattern, recurrencePattern) || other.recurrencePattern == recurrencePattern)&&(identical(other.isRecurrenceException, isRecurrenceException) || other.isRecurrenceException == isRecurrenceException)&&(identical(other.originalStartTime, originalStartTime) || other.originalStartTime == originalStartTime)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other._attendeeIds, _attendeeIds)&&(identical(other.publicVisibility, publicVisibility) || other.publicVisibility == publicVisibility)&&(identical(other.registrationDeadline, registrationDeadline) || other.registrationDeadline == registrationDeadline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,clientId,providerId,serviceId,serviceType,locationId,startTime,endTime,date,status,notes,createdAt,requiresPayment,paymentType,paymentAmountCents,paymentStatus,paymentId,refundEligible,refundStatus,refundAmountCents,refundRequestedAt,refundProcessedAt,refundPaymentId,rescheduleFeeRequired,rescheduleFeeCents,rescheduleFeeStatus,reschedulePaymentId,cancellationFeeRequired,cancellationFeeCents,cancellationFeeStatus,cancellationPaymentId,cancellationReason,cancellationCode,cancelledAt,isRecurring,recurrenceId,recurrencePattern,isRecurrenceException,originalStartTime,isGroupSession,capacity,const DeepCollectionEquality().hash(_attendeeIds),publicVisibility,registrationDeadline]);

@override
String toString() {
  return 'Appointment(id: $id, businessId: $businessId, clientId: $clientId, providerId: $providerId, serviceId: $serviceId, serviceType: $serviceType, locationId: $locationId, startTime: $startTime, endTime: $endTime, date: $date, status: $status, notes: $notes, createdAt: $createdAt, requiresPayment: $requiresPayment, paymentType: $paymentType, paymentAmountCents: $paymentAmountCents, paymentStatus: $paymentStatus, paymentId: $paymentId, refundEligible: $refundEligible, refundStatus: $refundStatus, refundAmountCents: $refundAmountCents, refundRequestedAt: $refundRequestedAt, refundProcessedAt: $refundProcessedAt, refundPaymentId: $refundPaymentId, rescheduleFeeRequired: $rescheduleFeeRequired, rescheduleFeeCents: $rescheduleFeeCents, rescheduleFeeStatus: $rescheduleFeeStatus, reschedulePaymentId: $reschedulePaymentId, cancellationFeeRequired: $cancellationFeeRequired, cancellationFeeCents: $cancellationFeeCents, cancellationFeeStatus: $cancellationFeeStatus, cancellationPaymentId: $cancellationPaymentId, cancellationReason: $cancellationReason, cancellationCode: $cancellationCode, cancelledAt: $cancelledAt, isRecurring: $isRecurring, recurrenceId: $recurrenceId, recurrencePattern: $recurrencePattern, isRecurrenceException: $isRecurrenceException, originalStartTime: $originalStartTime, isGroupSession: $isGroupSession, capacity: $capacity, attendeeIds: $attendeeIds, publicVisibility: $publicVisibility, registrationDeadline: $registrationDeadline)';
}


}

/// @nodoc
abstract mixin class _$AppointmentCopyWith<$Res> implements $AppointmentCopyWith<$Res> {
  factory _$AppointmentCopyWith(_Appointment value, $Res Function(_Appointment) _then) = __$AppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String clientId, String providerId, String serviceId, String? serviceType, String locationId,@TimestampConverter() DateTime startTime,@TimestampConverter() DateTime endTime,@TimestampConverter() DateTime date, AppointmentStatus status, String? notes,@TimestampConverter() DateTime createdAt, bool requiresPayment, PaymentType paymentType, int? paymentAmountCents, PaymentStatus paymentStatus, String? paymentId, bool refundEligible, PaymentStatus? refundStatus, int? refundAmountCents,@NullableTimestampConverter() DateTime? refundRequestedAt,@NullableTimestampConverter() DateTime? refundProcessedAt, String? refundPaymentId, bool rescheduleFeeRequired, int? rescheduleFeeCents, PaymentStatus rescheduleFeeStatus, String? reschedulePaymentId, bool cancellationFeeRequired, int? cancellationFeeCents, PaymentStatus cancellationFeeStatus, String? cancellationPaymentId, String? cancellationReason, String? cancellationCode,@NullableTimestampConverter() DateTime? cancelledAt, bool isRecurring, String? recurrenceId, RecurrencePattern? recurrencePattern, bool isRecurrenceException,@NullableTimestampConverter() DateTime? originalStartTime, bool isGroupSession, int? capacity, List<String> attendeeIds, bool publicVisibility,@NullableTimestampConverter() DateTime? registrationDeadline
});


@override $RecurrencePatternCopyWith<$Res>? get recurrencePattern;

}
/// @nodoc
class __$AppointmentCopyWithImpl<$Res>
    implements _$AppointmentCopyWith<$Res> {
  __$AppointmentCopyWithImpl(this._self, this._then);

  final _Appointment _self;
  final $Res Function(_Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? providerId = null,Object? serviceId = null,Object? serviceType = freezed,Object? locationId = null,Object? startTime = null,Object? endTime = null,Object? date = null,Object? status = null,Object? notes = freezed,Object? createdAt = null,Object? requiresPayment = null,Object? paymentType = null,Object? paymentAmountCents = freezed,Object? paymentStatus = null,Object? paymentId = freezed,Object? refundEligible = null,Object? refundStatus = freezed,Object? refundAmountCents = freezed,Object? refundRequestedAt = freezed,Object? refundProcessedAt = freezed,Object? refundPaymentId = freezed,Object? rescheduleFeeRequired = null,Object? rescheduleFeeCents = freezed,Object? rescheduleFeeStatus = null,Object? reschedulePaymentId = freezed,Object? cancellationFeeRequired = null,Object? cancellationFeeCents = freezed,Object? cancellationFeeStatus = null,Object? cancellationPaymentId = freezed,Object? cancellationReason = freezed,Object? cancellationCode = freezed,Object? cancelledAt = freezed,Object? isRecurring = null,Object? recurrenceId = freezed,Object? recurrencePattern = freezed,Object? isRecurrenceException = null,Object? originalStartTime = freezed,Object? isGroupSession = null,Object? capacity = freezed,Object? attendeeIds = null,Object? publicVisibility = null,Object? registrationDeadline = freezed,}) {
  return _then(_Appointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceType: freezed == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as String?,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as PaymentType,paymentAmountCents: freezed == paymentAmountCents ? _self.paymentAmountCents : paymentAmountCents // ignore: cast_nullable_to_non_nullable
as int?,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,refundEligible: null == refundEligible ? _self.refundEligible : refundEligible // ignore: cast_nullable_to_non_nullable
as bool,refundStatus: freezed == refundStatus ? _self.refundStatus : refundStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus?,refundAmountCents: freezed == refundAmountCents ? _self.refundAmountCents : refundAmountCents // ignore: cast_nullable_to_non_nullable
as int?,refundRequestedAt: freezed == refundRequestedAt ? _self.refundRequestedAt : refundRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundProcessedAt: freezed == refundProcessedAt ? _self.refundProcessedAt : refundProcessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundPaymentId: freezed == refundPaymentId ? _self.refundPaymentId : refundPaymentId // ignore: cast_nullable_to_non_nullable
as String?,rescheduleFeeRequired: null == rescheduleFeeRequired ? _self.rescheduleFeeRequired : rescheduleFeeRequired // ignore: cast_nullable_to_non_nullable
as bool,rescheduleFeeCents: freezed == rescheduleFeeCents ? _self.rescheduleFeeCents : rescheduleFeeCents // ignore: cast_nullable_to_non_nullable
as int?,rescheduleFeeStatus: null == rescheduleFeeStatus ? _self.rescheduleFeeStatus : rescheduleFeeStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,reschedulePaymentId: freezed == reschedulePaymentId ? _self.reschedulePaymentId : reschedulePaymentId // ignore: cast_nullable_to_non_nullable
as String?,cancellationFeeRequired: null == cancellationFeeRequired ? _self.cancellationFeeRequired : cancellationFeeRequired // ignore: cast_nullable_to_non_nullable
as bool,cancellationFeeCents: freezed == cancellationFeeCents ? _self.cancellationFeeCents : cancellationFeeCents // ignore: cast_nullable_to_non_nullable
as int?,cancellationFeeStatus: null == cancellationFeeStatus ? _self.cancellationFeeStatus : cancellationFeeStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,cancellationPaymentId: freezed == cancellationPaymentId ? _self.cancellationPaymentId : cancellationPaymentId // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,cancellationCode: freezed == cancellationCode ? _self.cancellationCode : cancellationCode // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,recurrencePattern: freezed == recurrencePattern ? _self.recurrencePattern : recurrencePattern // ignore: cast_nullable_to_non_nullable
as RecurrencePattern?,isRecurrenceException: null == isRecurrenceException ? _self.isRecurrenceException : isRecurrenceException // ignore: cast_nullable_to_non_nullable
as bool,originalStartTime: freezed == originalStartTime ? _self.originalStartTime : originalStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,attendeeIds: null == attendeeIds ? _self._attendeeIds : attendeeIds // ignore: cast_nullable_to_non_nullable
as List<String>,publicVisibility: null == publicVisibility ? _self.publicVisibility : publicVisibility // ignore: cast_nullable_to_non_nullable
as bool,registrationDeadline: freezed == registrationDeadline ? _self.registrationDeadline : registrationDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrencePatternCopyWith<$Res>? get recurrencePattern {
    if (_self.recurrencePattern == null) {
    return null;
  }

  return $RecurrencePatternCopyWith<$Res>(_self.recurrencePattern!, (value) {
    return _then(_self.copyWith(recurrencePattern: value));
  });
}
}

// dart format on
