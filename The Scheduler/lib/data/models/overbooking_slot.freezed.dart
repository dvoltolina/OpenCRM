// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overbooking_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OverbookingSlot {

/// Unique identifier for this overbooking slot record
 String get id;/// Business this slot belongs to
 String get businessId;/// Provider for this slot
 String get providerId;/// Location for this slot (if applicable)
 String? get locationId;/// Date of the slot
@TimestampConverter() DateTime get slotDate;/// Start time of the slot
@TimestampConverter() DateTime get slotStartTime;/// End time of the slot
@TimestampConverter() DateTime get slotEndTime;/// Service ID (if slot is service-specific)
 String? get serviceId;/// Current number of bookings in this slot
 int get currentBookings;/// Maximum capacity for this slot (before overbooking)
 int get baseCapacity;/// Calculated safe overbooking count
 int get safeOverbookCount;/// Number of accepted overbooks
 int get acceptedOverbooks;/// Weighted average no-show probability for appointments in slot
 double get weightedNoshowProbability;/// Average confidence of predictions
 double get averageConfidence;/// Historical no-show rate for this slot pattern
 double? get historicalNoshowRate;/// Current status of this overbooking slot
 OverbookingStatus get status;/// Outcome after slot time passed (for model improvement)
 OverbookingOutcome get outcome;/// Expected revenue if all show (cents)
 int get expectedRevenueCents;/// Expected revenue with overbooking strategy (cents)
 int get projectedRevenueCents;/// Potential revenue at risk if double-book occurs (cents)
 int get riskRevenueCents;/// IDs of appointments in this slot
 List<String> get appointmentIds;/// IDs of overbooked appointments (if any)
 List<String> get overbookedAppointmentIds;/// Whether this slot contains VIP clients (excluded from overbooking)
 bool get hasVipClients;/// Whether this is a group session (never overbook)
 bool get isGroupSession;/// Provider opted out of overbooking
 bool get providerOptedOut;/// Reason if overbooking not recommended
 String? get exclusionReason;/// When this analysis was calculated
@TimestampConverter() DateTime get calculatedAt;/// When this record was last updated
@NullableTimestampConverter() DateTime? get updatedAt;/// Version of the yield algorithm used
 String get algorithmVersion;
/// Create a copy of OverbookingSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookingSlotCopyWith<OverbookingSlot> get copyWith => _$OverbookingSlotCopyWithImpl<OverbookingSlot>(this as OverbookingSlot, _$identity);

  /// Serializes this OverbookingSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookingSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.slotDate, slotDate) || other.slotDate == slotDate)&&(identical(other.slotStartTime, slotStartTime) || other.slotStartTime == slotStartTime)&&(identical(other.slotEndTime, slotEndTime) || other.slotEndTime == slotEndTime)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.currentBookings, currentBookings) || other.currentBookings == currentBookings)&&(identical(other.baseCapacity, baseCapacity) || other.baseCapacity == baseCapacity)&&(identical(other.safeOverbookCount, safeOverbookCount) || other.safeOverbookCount == safeOverbookCount)&&(identical(other.acceptedOverbooks, acceptedOverbooks) || other.acceptedOverbooks == acceptedOverbooks)&&(identical(other.weightedNoshowProbability, weightedNoshowProbability) || other.weightedNoshowProbability == weightedNoshowProbability)&&(identical(other.averageConfidence, averageConfidence) || other.averageConfidence == averageConfidence)&&(identical(other.historicalNoshowRate, historicalNoshowRate) || other.historicalNoshowRate == historicalNoshowRate)&&(identical(other.status, status) || other.status == status)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.expectedRevenueCents, expectedRevenueCents) || other.expectedRevenueCents == expectedRevenueCents)&&(identical(other.projectedRevenueCents, projectedRevenueCents) || other.projectedRevenueCents == projectedRevenueCents)&&(identical(other.riskRevenueCents, riskRevenueCents) || other.riskRevenueCents == riskRevenueCents)&&const DeepCollectionEquality().equals(other.appointmentIds, appointmentIds)&&const DeepCollectionEquality().equals(other.overbookedAppointmentIds, overbookedAppointmentIds)&&(identical(other.hasVipClients, hasVipClients) || other.hasVipClients == hasVipClients)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.providerOptedOut, providerOptedOut) || other.providerOptedOut == providerOptedOut)&&(identical(other.exclusionReason, exclusionReason) || other.exclusionReason == exclusionReason)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.algorithmVersion, algorithmVersion) || other.algorithmVersion == algorithmVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,providerId,locationId,slotDate,slotStartTime,slotEndTime,serviceId,currentBookings,baseCapacity,safeOverbookCount,acceptedOverbooks,weightedNoshowProbability,averageConfidence,historicalNoshowRate,status,outcome,expectedRevenueCents,projectedRevenueCents,riskRevenueCents,const DeepCollectionEquality().hash(appointmentIds),const DeepCollectionEquality().hash(overbookedAppointmentIds),hasVipClients,isGroupSession,providerOptedOut,exclusionReason,calculatedAt,updatedAt,algorithmVersion]);

@override
String toString() {
  return 'OverbookingSlot(id: $id, businessId: $businessId, providerId: $providerId, locationId: $locationId, slotDate: $slotDate, slotStartTime: $slotStartTime, slotEndTime: $slotEndTime, serviceId: $serviceId, currentBookings: $currentBookings, baseCapacity: $baseCapacity, safeOverbookCount: $safeOverbookCount, acceptedOverbooks: $acceptedOverbooks, weightedNoshowProbability: $weightedNoshowProbability, averageConfidence: $averageConfidence, historicalNoshowRate: $historicalNoshowRate, status: $status, outcome: $outcome, expectedRevenueCents: $expectedRevenueCents, projectedRevenueCents: $projectedRevenueCents, riskRevenueCents: $riskRevenueCents, appointmentIds: $appointmentIds, overbookedAppointmentIds: $overbookedAppointmentIds, hasVipClients: $hasVipClients, isGroupSession: $isGroupSession, providerOptedOut: $providerOptedOut, exclusionReason: $exclusionReason, calculatedAt: $calculatedAt, updatedAt: $updatedAt, algorithmVersion: $algorithmVersion)';
}


}

/// @nodoc
abstract mixin class $OverbookingSlotCopyWith<$Res>  {
  factory $OverbookingSlotCopyWith(OverbookingSlot value, $Res Function(OverbookingSlot) _then) = _$OverbookingSlotCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String providerId, String? locationId,@TimestampConverter() DateTime slotDate,@TimestampConverter() DateTime slotStartTime,@TimestampConverter() DateTime slotEndTime, String? serviceId, int currentBookings, int baseCapacity, int safeOverbookCount, int acceptedOverbooks, double weightedNoshowProbability, double averageConfidence, double? historicalNoshowRate, OverbookingStatus status, OverbookingOutcome outcome, int expectedRevenueCents, int projectedRevenueCents, int riskRevenueCents, List<String> appointmentIds, List<String> overbookedAppointmentIds, bool hasVipClients, bool isGroupSession, bool providerOptedOut, String? exclusionReason,@TimestampConverter() DateTime calculatedAt,@NullableTimestampConverter() DateTime? updatedAt, String algorithmVersion
});




}
/// @nodoc
class _$OverbookingSlotCopyWithImpl<$Res>
    implements $OverbookingSlotCopyWith<$Res> {
  _$OverbookingSlotCopyWithImpl(this._self, this._then);

  final OverbookingSlot _self;
  final $Res Function(OverbookingSlot) _then;

/// Create a copy of OverbookingSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? providerId = null,Object? locationId = freezed,Object? slotDate = null,Object? slotStartTime = null,Object? slotEndTime = null,Object? serviceId = freezed,Object? currentBookings = null,Object? baseCapacity = null,Object? safeOverbookCount = null,Object? acceptedOverbooks = null,Object? weightedNoshowProbability = null,Object? averageConfidence = null,Object? historicalNoshowRate = freezed,Object? status = null,Object? outcome = null,Object? expectedRevenueCents = null,Object? projectedRevenueCents = null,Object? riskRevenueCents = null,Object? appointmentIds = null,Object? overbookedAppointmentIds = null,Object? hasVipClients = null,Object? isGroupSession = null,Object? providerOptedOut = null,Object? exclusionReason = freezed,Object? calculatedAt = null,Object? updatedAt = freezed,Object? algorithmVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,slotDate: null == slotDate ? _self.slotDate : slotDate // ignore: cast_nullable_to_non_nullable
as DateTime,slotStartTime: null == slotStartTime ? _self.slotStartTime : slotStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,slotEndTime: null == slotEndTime ? _self.slotEndTime : slotEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,currentBookings: null == currentBookings ? _self.currentBookings : currentBookings // ignore: cast_nullable_to_non_nullable
as int,baseCapacity: null == baseCapacity ? _self.baseCapacity : baseCapacity // ignore: cast_nullable_to_non_nullable
as int,safeOverbookCount: null == safeOverbookCount ? _self.safeOverbookCount : safeOverbookCount // ignore: cast_nullable_to_non_nullable
as int,acceptedOverbooks: null == acceptedOverbooks ? _self.acceptedOverbooks : acceptedOverbooks // ignore: cast_nullable_to_non_nullable
as int,weightedNoshowProbability: null == weightedNoshowProbability ? _self.weightedNoshowProbability : weightedNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,averageConfidence: null == averageConfidence ? _self.averageConfidence : averageConfidence // ignore: cast_nullable_to_non_nullable
as double,historicalNoshowRate: freezed == historicalNoshowRate ? _self.historicalNoshowRate : historicalNoshowRate // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OverbookingStatus,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as OverbookingOutcome,expectedRevenueCents: null == expectedRevenueCents ? _self.expectedRevenueCents : expectedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,projectedRevenueCents: null == projectedRevenueCents ? _self.projectedRevenueCents : projectedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,riskRevenueCents: null == riskRevenueCents ? _self.riskRevenueCents : riskRevenueCents // ignore: cast_nullable_to_non_nullable
as int,appointmentIds: null == appointmentIds ? _self.appointmentIds : appointmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,overbookedAppointmentIds: null == overbookedAppointmentIds ? _self.overbookedAppointmentIds : overbookedAppointmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,hasVipClients: null == hasVipClients ? _self.hasVipClients : hasVipClients // ignore: cast_nullable_to_non_nullable
as bool,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,providerOptedOut: null == providerOptedOut ? _self.providerOptedOut : providerOptedOut // ignore: cast_nullable_to_non_nullable
as bool,exclusionReason: freezed == exclusionReason ? _self.exclusionReason : exclusionReason // ignore: cast_nullable_to_non_nullable
as String?,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,algorithmVersion: null == algorithmVersion ? _self.algorithmVersion : algorithmVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OverbookingSlot].
extension OverbookingSlotPatterns on OverbookingSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookingSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookingSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookingSlot value)  $default,){
final _that = this;
switch (_that) {
case _OverbookingSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookingSlot value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookingSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String providerId,  String? locationId, @TimestampConverter()  DateTime slotDate, @TimestampConverter()  DateTime slotStartTime, @TimestampConverter()  DateTime slotEndTime,  String? serviceId,  int currentBookings,  int baseCapacity,  int safeOverbookCount,  int acceptedOverbooks,  double weightedNoshowProbability,  double averageConfidence,  double? historicalNoshowRate,  OverbookingStatus status,  OverbookingOutcome outcome,  int expectedRevenueCents,  int projectedRevenueCents,  int riskRevenueCents,  List<String> appointmentIds,  List<String> overbookedAppointmentIds,  bool hasVipClients,  bool isGroupSession,  bool providerOptedOut,  String? exclusionReason, @TimestampConverter()  DateTime calculatedAt, @NullableTimestampConverter()  DateTime? updatedAt,  String algorithmVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverbookingSlot() when $default != null:
return $default(_that.id,_that.businessId,_that.providerId,_that.locationId,_that.slotDate,_that.slotStartTime,_that.slotEndTime,_that.serviceId,_that.currentBookings,_that.baseCapacity,_that.safeOverbookCount,_that.acceptedOverbooks,_that.weightedNoshowProbability,_that.averageConfidence,_that.historicalNoshowRate,_that.status,_that.outcome,_that.expectedRevenueCents,_that.projectedRevenueCents,_that.riskRevenueCents,_that.appointmentIds,_that.overbookedAppointmentIds,_that.hasVipClients,_that.isGroupSession,_that.providerOptedOut,_that.exclusionReason,_that.calculatedAt,_that.updatedAt,_that.algorithmVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String providerId,  String? locationId, @TimestampConverter()  DateTime slotDate, @TimestampConverter()  DateTime slotStartTime, @TimestampConverter()  DateTime slotEndTime,  String? serviceId,  int currentBookings,  int baseCapacity,  int safeOverbookCount,  int acceptedOverbooks,  double weightedNoshowProbability,  double averageConfidence,  double? historicalNoshowRate,  OverbookingStatus status,  OverbookingOutcome outcome,  int expectedRevenueCents,  int projectedRevenueCents,  int riskRevenueCents,  List<String> appointmentIds,  List<String> overbookedAppointmentIds,  bool hasVipClients,  bool isGroupSession,  bool providerOptedOut,  String? exclusionReason, @TimestampConverter()  DateTime calculatedAt, @NullableTimestampConverter()  DateTime? updatedAt,  String algorithmVersion)  $default,) {final _that = this;
switch (_that) {
case _OverbookingSlot():
return $default(_that.id,_that.businessId,_that.providerId,_that.locationId,_that.slotDate,_that.slotStartTime,_that.slotEndTime,_that.serviceId,_that.currentBookings,_that.baseCapacity,_that.safeOverbookCount,_that.acceptedOverbooks,_that.weightedNoshowProbability,_that.averageConfidence,_that.historicalNoshowRate,_that.status,_that.outcome,_that.expectedRevenueCents,_that.projectedRevenueCents,_that.riskRevenueCents,_that.appointmentIds,_that.overbookedAppointmentIds,_that.hasVipClients,_that.isGroupSession,_that.providerOptedOut,_that.exclusionReason,_that.calculatedAt,_that.updatedAt,_that.algorithmVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String providerId,  String? locationId, @TimestampConverter()  DateTime slotDate, @TimestampConverter()  DateTime slotStartTime, @TimestampConverter()  DateTime slotEndTime,  String? serviceId,  int currentBookings,  int baseCapacity,  int safeOverbookCount,  int acceptedOverbooks,  double weightedNoshowProbability,  double averageConfidence,  double? historicalNoshowRate,  OverbookingStatus status,  OverbookingOutcome outcome,  int expectedRevenueCents,  int projectedRevenueCents,  int riskRevenueCents,  List<String> appointmentIds,  List<String> overbookedAppointmentIds,  bool hasVipClients,  bool isGroupSession,  bool providerOptedOut,  String? exclusionReason, @TimestampConverter()  DateTime calculatedAt, @NullableTimestampConverter()  DateTime? updatedAt,  String algorithmVersion)?  $default,) {final _that = this;
switch (_that) {
case _OverbookingSlot() when $default != null:
return $default(_that.id,_that.businessId,_that.providerId,_that.locationId,_that.slotDate,_that.slotStartTime,_that.slotEndTime,_that.serviceId,_that.currentBookings,_that.baseCapacity,_that.safeOverbookCount,_that.acceptedOverbooks,_that.weightedNoshowProbability,_that.averageConfidence,_that.historicalNoshowRate,_that.status,_that.outcome,_that.expectedRevenueCents,_that.projectedRevenueCents,_that.riskRevenueCents,_that.appointmentIds,_that.overbookedAppointmentIds,_that.hasVipClients,_that.isGroupSession,_that.providerOptedOut,_that.exclusionReason,_that.calculatedAt,_that.updatedAt,_that.algorithmVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverbookingSlot extends OverbookingSlot {
  const _OverbookingSlot({required this.id, required this.businessId, required this.providerId, this.locationId, @TimestampConverter() required this.slotDate, @TimestampConverter() required this.slotStartTime, @TimestampConverter() required this.slotEndTime, this.serviceId, required this.currentBookings, required this.baseCapacity, required this.safeOverbookCount, this.acceptedOverbooks = 0, required this.weightedNoshowProbability, required this.averageConfidence, this.historicalNoshowRate, this.status = OverbookingStatus.available, this.outcome = OverbookingOutcome.pending, required this.expectedRevenueCents, required this.projectedRevenueCents, required this.riskRevenueCents, required final  List<String> appointmentIds, final  List<String> overbookedAppointmentIds = const [], this.hasVipClients = false, this.isGroupSession = false, this.providerOptedOut = false, this.exclusionReason, @TimestampConverter() required this.calculatedAt, @NullableTimestampConverter() this.updatedAt, this.algorithmVersion = '1.0.0'}): _appointmentIds = appointmentIds,_overbookedAppointmentIds = overbookedAppointmentIds,super._();
  factory _OverbookingSlot.fromJson(Map<String, dynamic> json) => _$OverbookingSlotFromJson(json);

/// Unique identifier for this overbooking slot record
@override final  String id;
/// Business this slot belongs to
@override final  String businessId;
/// Provider for this slot
@override final  String providerId;
/// Location for this slot (if applicable)
@override final  String? locationId;
/// Date of the slot
@override@TimestampConverter() final  DateTime slotDate;
/// Start time of the slot
@override@TimestampConverter() final  DateTime slotStartTime;
/// End time of the slot
@override@TimestampConverter() final  DateTime slotEndTime;
/// Service ID (if slot is service-specific)
@override final  String? serviceId;
/// Current number of bookings in this slot
@override final  int currentBookings;
/// Maximum capacity for this slot (before overbooking)
@override final  int baseCapacity;
/// Calculated safe overbooking count
@override final  int safeOverbookCount;
/// Number of accepted overbooks
@override@JsonKey() final  int acceptedOverbooks;
/// Weighted average no-show probability for appointments in slot
@override final  double weightedNoshowProbability;
/// Average confidence of predictions
@override final  double averageConfidence;
/// Historical no-show rate for this slot pattern
@override final  double? historicalNoshowRate;
/// Current status of this overbooking slot
@override@JsonKey() final  OverbookingStatus status;
/// Outcome after slot time passed (for model improvement)
@override@JsonKey() final  OverbookingOutcome outcome;
/// Expected revenue if all show (cents)
@override final  int expectedRevenueCents;
/// Expected revenue with overbooking strategy (cents)
@override final  int projectedRevenueCents;
/// Potential revenue at risk if double-book occurs (cents)
@override final  int riskRevenueCents;
/// IDs of appointments in this slot
 final  List<String> _appointmentIds;
/// IDs of appointments in this slot
@override List<String> get appointmentIds {
  if (_appointmentIds is EqualUnmodifiableListView) return _appointmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appointmentIds);
}

/// IDs of overbooked appointments (if any)
 final  List<String> _overbookedAppointmentIds;
/// IDs of overbooked appointments (if any)
@override@JsonKey() List<String> get overbookedAppointmentIds {
  if (_overbookedAppointmentIds is EqualUnmodifiableListView) return _overbookedAppointmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overbookedAppointmentIds);
}

/// Whether this slot contains VIP clients (excluded from overbooking)
@override@JsonKey() final  bool hasVipClients;
/// Whether this is a group session (never overbook)
@override@JsonKey() final  bool isGroupSession;
/// Provider opted out of overbooking
@override@JsonKey() final  bool providerOptedOut;
/// Reason if overbooking not recommended
@override final  String? exclusionReason;
/// When this analysis was calculated
@override@TimestampConverter() final  DateTime calculatedAt;
/// When this record was last updated
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// Version of the yield algorithm used
@override@JsonKey() final  String algorithmVersion;

/// Create a copy of OverbookingSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookingSlotCopyWith<_OverbookingSlot> get copyWith => __$OverbookingSlotCopyWithImpl<_OverbookingSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverbookingSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookingSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.slotDate, slotDate) || other.slotDate == slotDate)&&(identical(other.slotStartTime, slotStartTime) || other.slotStartTime == slotStartTime)&&(identical(other.slotEndTime, slotEndTime) || other.slotEndTime == slotEndTime)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.currentBookings, currentBookings) || other.currentBookings == currentBookings)&&(identical(other.baseCapacity, baseCapacity) || other.baseCapacity == baseCapacity)&&(identical(other.safeOverbookCount, safeOverbookCount) || other.safeOverbookCount == safeOverbookCount)&&(identical(other.acceptedOverbooks, acceptedOverbooks) || other.acceptedOverbooks == acceptedOverbooks)&&(identical(other.weightedNoshowProbability, weightedNoshowProbability) || other.weightedNoshowProbability == weightedNoshowProbability)&&(identical(other.averageConfidence, averageConfidence) || other.averageConfidence == averageConfidence)&&(identical(other.historicalNoshowRate, historicalNoshowRate) || other.historicalNoshowRate == historicalNoshowRate)&&(identical(other.status, status) || other.status == status)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.expectedRevenueCents, expectedRevenueCents) || other.expectedRevenueCents == expectedRevenueCents)&&(identical(other.projectedRevenueCents, projectedRevenueCents) || other.projectedRevenueCents == projectedRevenueCents)&&(identical(other.riskRevenueCents, riskRevenueCents) || other.riskRevenueCents == riskRevenueCents)&&const DeepCollectionEquality().equals(other._appointmentIds, _appointmentIds)&&const DeepCollectionEquality().equals(other._overbookedAppointmentIds, _overbookedAppointmentIds)&&(identical(other.hasVipClients, hasVipClients) || other.hasVipClients == hasVipClients)&&(identical(other.isGroupSession, isGroupSession) || other.isGroupSession == isGroupSession)&&(identical(other.providerOptedOut, providerOptedOut) || other.providerOptedOut == providerOptedOut)&&(identical(other.exclusionReason, exclusionReason) || other.exclusionReason == exclusionReason)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.algorithmVersion, algorithmVersion) || other.algorithmVersion == algorithmVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,providerId,locationId,slotDate,slotStartTime,slotEndTime,serviceId,currentBookings,baseCapacity,safeOverbookCount,acceptedOverbooks,weightedNoshowProbability,averageConfidence,historicalNoshowRate,status,outcome,expectedRevenueCents,projectedRevenueCents,riskRevenueCents,const DeepCollectionEquality().hash(_appointmentIds),const DeepCollectionEquality().hash(_overbookedAppointmentIds),hasVipClients,isGroupSession,providerOptedOut,exclusionReason,calculatedAt,updatedAt,algorithmVersion]);

@override
String toString() {
  return 'OverbookingSlot(id: $id, businessId: $businessId, providerId: $providerId, locationId: $locationId, slotDate: $slotDate, slotStartTime: $slotStartTime, slotEndTime: $slotEndTime, serviceId: $serviceId, currentBookings: $currentBookings, baseCapacity: $baseCapacity, safeOverbookCount: $safeOverbookCount, acceptedOverbooks: $acceptedOverbooks, weightedNoshowProbability: $weightedNoshowProbability, averageConfidence: $averageConfidence, historicalNoshowRate: $historicalNoshowRate, status: $status, outcome: $outcome, expectedRevenueCents: $expectedRevenueCents, projectedRevenueCents: $projectedRevenueCents, riskRevenueCents: $riskRevenueCents, appointmentIds: $appointmentIds, overbookedAppointmentIds: $overbookedAppointmentIds, hasVipClients: $hasVipClients, isGroupSession: $isGroupSession, providerOptedOut: $providerOptedOut, exclusionReason: $exclusionReason, calculatedAt: $calculatedAt, updatedAt: $updatedAt, algorithmVersion: $algorithmVersion)';
}


}

/// @nodoc
abstract mixin class _$OverbookingSlotCopyWith<$Res> implements $OverbookingSlotCopyWith<$Res> {
  factory _$OverbookingSlotCopyWith(_OverbookingSlot value, $Res Function(_OverbookingSlot) _then) = __$OverbookingSlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String providerId, String? locationId,@TimestampConverter() DateTime slotDate,@TimestampConverter() DateTime slotStartTime,@TimestampConverter() DateTime slotEndTime, String? serviceId, int currentBookings, int baseCapacity, int safeOverbookCount, int acceptedOverbooks, double weightedNoshowProbability, double averageConfidence, double? historicalNoshowRate, OverbookingStatus status, OverbookingOutcome outcome, int expectedRevenueCents, int projectedRevenueCents, int riskRevenueCents, List<String> appointmentIds, List<String> overbookedAppointmentIds, bool hasVipClients, bool isGroupSession, bool providerOptedOut, String? exclusionReason,@TimestampConverter() DateTime calculatedAt,@NullableTimestampConverter() DateTime? updatedAt, String algorithmVersion
});




}
/// @nodoc
class __$OverbookingSlotCopyWithImpl<$Res>
    implements _$OverbookingSlotCopyWith<$Res> {
  __$OverbookingSlotCopyWithImpl(this._self, this._then);

  final _OverbookingSlot _self;
  final $Res Function(_OverbookingSlot) _then;

/// Create a copy of OverbookingSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? providerId = null,Object? locationId = freezed,Object? slotDate = null,Object? slotStartTime = null,Object? slotEndTime = null,Object? serviceId = freezed,Object? currentBookings = null,Object? baseCapacity = null,Object? safeOverbookCount = null,Object? acceptedOverbooks = null,Object? weightedNoshowProbability = null,Object? averageConfidence = null,Object? historicalNoshowRate = freezed,Object? status = null,Object? outcome = null,Object? expectedRevenueCents = null,Object? projectedRevenueCents = null,Object? riskRevenueCents = null,Object? appointmentIds = null,Object? overbookedAppointmentIds = null,Object? hasVipClients = null,Object? isGroupSession = null,Object? providerOptedOut = null,Object? exclusionReason = freezed,Object? calculatedAt = null,Object? updatedAt = freezed,Object? algorithmVersion = null,}) {
  return _then(_OverbookingSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,slotDate: null == slotDate ? _self.slotDate : slotDate // ignore: cast_nullable_to_non_nullable
as DateTime,slotStartTime: null == slotStartTime ? _self.slotStartTime : slotStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,slotEndTime: null == slotEndTime ? _self.slotEndTime : slotEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,currentBookings: null == currentBookings ? _self.currentBookings : currentBookings // ignore: cast_nullable_to_non_nullable
as int,baseCapacity: null == baseCapacity ? _self.baseCapacity : baseCapacity // ignore: cast_nullable_to_non_nullable
as int,safeOverbookCount: null == safeOverbookCount ? _self.safeOverbookCount : safeOverbookCount // ignore: cast_nullable_to_non_nullable
as int,acceptedOverbooks: null == acceptedOverbooks ? _self.acceptedOverbooks : acceptedOverbooks // ignore: cast_nullable_to_non_nullable
as int,weightedNoshowProbability: null == weightedNoshowProbability ? _self.weightedNoshowProbability : weightedNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,averageConfidence: null == averageConfidence ? _self.averageConfidence : averageConfidence // ignore: cast_nullable_to_non_nullable
as double,historicalNoshowRate: freezed == historicalNoshowRate ? _self.historicalNoshowRate : historicalNoshowRate // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OverbookingStatus,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as OverbookingOutcome,expectedRevenueCents: null == expectedRevenueCents ? _self.expectedRevenueCents : expectedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,projectedRevenueCents: null == projectedRevenueCents ? _self.projectedRevenueCents : projectedRevenueCents // ignore: cast_nullable_to_non_nullable
as int,riskRevenueCents: null == riskRevenueCents ? _self.riskRevenueCents : riskRevenueCents // ignore: cast_nullable_to_non_nullable
as int,appointmentIds: null == appointmentIds ? _self._appointmentIds : appointmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,overbookedAppointmentIds: null == overbookedAppointmentIds ? _self._overbookedAppointmentIds : overbookedAppointmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,hasVipClients: null == hasVipClients ? _self.hasVipClients : hasVipClients // ignore: cast_nullable_to_non_nullable
as bool,isGroupSession: null == isGroupSession ? _self.isGroupSession : isGroupSession // ignore: cast_nullable_to_non_nullable
as bool,providerOptedOut: null == providerOptedOut ? _self.providerOptedOut : providerOptedOut // ignore: cast_nullable_to_non_nullable
as bool,exclusionReason: freezed == exclusionReason ? _self.exclusionReason : exclusionReason // ignore: cast_nullable_to_non_nullable
as String?,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,algorithmVersion: null == algorithmVersion ? _self.algorithmVersion : algorithmVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DailyOverbookingSummary {

/// Provider ID
 String get providerId;/// Business ID
 String get businessId;/// Date of the summary
@TimestampConverter() DateTime get date;/// Total slots analyzed
 int get totalSlots;/// Slots with overbooking opportunity
 int get slotsWithOpportunity;/// Total safe overbook capacity across all slots
 int get totalSafeOverbookCapacity;/// Total accepted overbooks
 int get totalAcceptedOverbooks;/// Expected additional revenue from overbooking (cents)
 int get expectedAdditionalRevenueCents;/// Average no-show probability across slots
 double get averageNoshowProbability;/// Slots excluded from overbooking
 int get excludedSlots;/// When this summary was calculated
@TimestampConverter() DateTime get calculatedAt;
/// Create a copy of DailyOverbookingSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyOverbookingSummaryCopyWith<DailyOverbookingSummary> get copyWith => _$DailyOverbookingSummaryCopyWithImpl<DailyOverbookingSummary>(this as DailyOverbookingSummary, _$identity);

  /// Serializes this DailyOverbookingSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyOverbookingSummary&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.date, date) || other.date == date)&&(identical(other.totalSlots, totalSlots) || other.totalSlots == totalSlots)&&(identical(other.slotsWithOpportunity, slotsWithOpportunity) || other.slotsWithOpportunity == slotsWithOpportunity)&&(identical(other.totalSafeOverbookCapacity, totalSafeOverbookCapacity) || other.totalSafeOverbookCapacity == totalSafeOverbookCapacity)&&(identical(other.totalAcceptedOverbooks, totalAcceptedOverbooks) || other.totalAcceptedOverbooks == totalAcceptedOverbooks)&&(identical(other.expectedAdditionalRevenueCents, expectedAdditionalRevenueCents) || other.expectedAdditionalRevenueCents == expectedAdditionalRevenueCents)&&(identical(other.averageNoshowProbability, averageNoshowProbability) || other.averageNoshowProbability == averageNoshowProbability)&&(identical(other.excludedSlots, excludedSlots) || other.excludedSlots == excludedSlots)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,businessId,date,totalSlots,slotsWithOpportunity,totalSafeOverbookCapacity,totalAcceptedOverbooks,expectedAdditionalRevenueCents,averageNoshowProbability,excludedSlots,calculatedAt);

@override
String toString() {
  return 'DailyOverbookingSummary(providerId: $providerId, businessId: $businessId, date: $date, totalSlots: $totalSlots, slotsWithOpportunity: $slotsWithOpportunity, totalSafeOverbookCapacity: $totalSafeOverbookCapacity, totalAcceptedOverbooks: $totalAcceptedOverbooks, expectedAdditionalRevenueCents: $expectedAdditionalRevenueCents, averageNoshowProbability: $averageNoshowProbability, excludedSlots: $excludedSlots, calculatedAt: $calculatedAt)';
}


}

/// @nodoc
abstract mixin class $DailyOverbookingSummaryCopyWith<$Res>  {
  factory $DailyOverbookingSummaryCopyWith(DailyOverbookingSummary value, $Res Function(DailyOverbookingSummary) _then) = _$DailyOverbookingSummaryCopyWithImpl;
@useResult
$Res call({
 String providerId, String businessId,@TimestampConverter() DateTime date, int totalSlots, int slotsWithOpportunity, int totalSafeOverbookCapacity, int totalAcceptedOverbooks, int expectedAdditionalRevenueCents, double averageNoshowProbability, int excludedSlots,@TimestampConverter() DateTime calculatedAt
});




}
/// @nodoc
class _$DailyOverbookingSummaryCopyWithImpl<$Res>
    implements $DailyOverbookingSummaryCopyWith<$Res> {
  _$DailyOverbookingSummaryCopyWithImpl(this._self, this._then);

  final DailyOverbookingSummary _self;
  final $Res Function(DailyOverbookingSummary) _then;

/// Create a copy of DailyOverbookingSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? businessId = null,Object? date = null,Object? totalSlots = null,Object? slotsWithOpportunity = null,Object? totalSafeOverbookCapacity = null,Object? totalAcceptedOverbooks = null,Object? expectedAdditionalRevenueCents = null,Object? averageNoshowProbability = null,Object? excludedSlots = null,Object? calculatedAt = null,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,slotsWithOpportunity: null == slotsWithOpportunity ? _self.slotsWithOpportunity : slotsWithOpportunity // ignore: cast_nullable_to_non_nullable
as int,totalSafeOverbookCapacity: null == totalSafeOverbookCapacity ? _self.totalSafeOverbookCapacity : totalSafeOverbookCapacity // ignore: cast_nullable_to_non_nullable
as int,totalAcceptedOverbooks: null == totalAcceptedOverbooks ? _self.totalAcceptedOverbooks : totalAcceptedOverbooks // ignore: cast_nullable_to_non_nullable
as int,expectedAdditionalRevenueCents: null == expectedAdditionalRevenueCents ? _self.expectedAdditionalRevenueCents : expectedAdditionalRevenueCents // ignore: cast_nullable_to_non_nullable
as int,averageNoshowProbability: null == averageNoshowProbability ? _self.averageNoshowProbability : averageNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,excludedSlots: null == excludedSlots ? _self.excludedSlots : excludedSlots // ignore: cast_nullable_to_non_nullable
as int,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyOverbookingSummary].
extension DailyOverbookingSummaryPatterns on DailyOverbookingSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyOverbookingSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyOverbookingSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyOverbookingSummary value)  $default,){
final _that = this;
switch (_that) {
case _DailyOverbookingSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyOverbookingSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DailyOverbookingSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String businessId, @TimestampConverter()  DateTime date,  int totalSlots,  int slotsWithOpportunity,  int totalSafeOverbookCapacity,  int totalAcceptedOverbooks,  int expectedAdditionalRevenueCents,  double averageNoshowProbability,  int excludedSlots, @TimestampConverter()  DateTime calculatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyOverbookingSummary() when $default != null:
return $default(_that.providerId,_that.businessId,_that.date,_that.totalSlots,_that.slotsWithOpportunity,_that.totalSafeOverbookCapacity,_that.totalAcceptedOverbooks,_that.expectedAdditionalRevenueCents,_that.averageNoshowProbability,_that.excludedSlots,_that.calculatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String businessId, @TimestampConverter()  DateTime date,  int totalSlots,  int slotsWithOpportunity,  int totalSafeOverbookCapacity,  int totalAcceptedOverbooks,  int expectedAdditionalRevenueCents,  double averageNoshowProbability,  int excludedSlots, @TimestampConverter()  DateTime calculatedAt)  $default,) {final _that = this;
switch (_that) {
case _DailyOverbookingSummary():
return $default(_that.providerId,_that.businessId,_that.date,_that.totalSlots,_that.slotsWithOpportunity,_that.totalSafeOverbookCapacity,_that.totalAcceptedOverbooks,_that.expectedAdditionalRevenueCents,_that.averageNoshowProbability,_that.excludedSlots,_that.calculatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String businessId, @TimestampConverter()  DateTime date,  int totalSlots,  int slotsWithOpportunity,  int totalSafeOverbookCapacity,  int totalAcceptedOverbooks,  int expectedAdditionalRevenueCents,  double averageNoshowProbability,  int excludedSlots, @TimestampConverter()  DateTime calculatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DailyOverbookingSummary() when $default != null:
return $default(_that.providerId,_that.businessId,_that.date,_that.totalSlots,_that.slotsWithOpportunity,_that.totalSafeOverbookCapacity,_that.totalAcceptedOverbooks,_that.expectedAdditionalRevenueCents,_that.averageNoshowProbability,_that.excludedSlots,_that.calculatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyOverbookingSummary extends DailyOverbookingSummary {
  const _DailyOverbookingSummary({required this.providerId, required this.businessId, @TimestampConverter() required this.date, required this.totalSlots, required this.slotsWithOpportunity, required this.totalSafeOverbookCapacity, required this.totalAcceptedOverbooks, required this.expectedAdditionalRevenueCents, required this.averageNoshowProbability, required this.excludedSlots, @TimestampConverter() required this.calculatedAt}): super._();
  factory _DailyOverbookingSummary.fromJson(Map<String, dynamic> json) => _$DailyOverbookingSummaryFromJson(json);

/// Provider ID
@override final  String providerId;
/// Business ID
@override final  String businessId;
/// Date of the summary
@override@TimestampConverter() final  DateTime date;
/// Total slots analyzed
@override final  int totalSlots;
/// Slots with overbooking opportunity
@override final  int slotsWithOpportunity;
/// Total safe overbook capacity across all slots
@override final  int totalSafeOverbookCapacity;
/// Total accepted overbooks
@override final  int totalAcceptedOverbooks;
/// Expected additional revenue from overbooking (cents)
@override final  int expectedAdditionalRevenueCents;
/// Average no-show probability across slots
@override final  double averageNoshowProbability;
/// Slots excluded from overbooking
@override final  int excludedSlots;
/// When this summary was calculated
@override@TimestampConverter() final  DateTime calculatedAt;

/// Create a copy of DailyOverbookingSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyOverbookingSummaryCopyWith<_DailyOverbookingSummary> get copyWith => __$DailyOverbookingSummaryCopyWithImpl<_DailyOverbookingSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyOverbookingSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyOverbookingSummary&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.date, date) || other.date == date)&&(identical(other.totalSlots, totalSlots) || other.totalSlots == totalSlots)&&(identical(other.slotsWithOpportunity, slotsWithOpportunity) || other.slotsWithOpportunity == slotsWithOpportunity)&&(identical(other.totalSafeOverbookCapacity, totalSafeOverbookCapacity) || other.totalSafeOverbookCapacity == totalSafeOverbookCapacity)&&(identical(other.totalAcceptedOverbooks, totalAcceptedOverbooks) || other.totalAcceptedOverbooks == totalAcceptedOverbooks)&&(identical(other.expectedAdditionalRevenueCents, expectedAdditionalRevenueCents) || other.expectedAdditionalRevenueCents == expectedAdditionalRevenueCents)&&(identical(other.averageNoshowProbability, averageNoshowProbability) || other.averageNoshowProbability == averageNoshowProbability)&&(identical(other.excludedSlots, excludedSlots) || other.excludedSlots == excludedSlots)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,businessId,date,totalSlots,slotsWithOpportunity,totalSafeOverbookCapacity,totalAcceptedOverbooks,expectedAdditionalRevenueCents,averageNoshowProbability,excludedSlots,calculatedAt);

@override
String toString() {
  return 'DailyOverbookingSummary(providerId: $providerId, businessId: $businessId, date: $date, totalSlots: $totalSlots, slotsWithOpportunity: $slotsWithOpportunity, totalSafeOverbookCapacity: $totalSafeOverbookCapacity, totalAcceptedOverbooks: $totalAcceptedOverbooks, expectedAdditionalRevenueCents: $expectedAdditionalRevenueCents, averageNoshowProbability: $averageNoshowProbability, excludedSlots: $excludedSlots, calculatedAt: $calculatedAt)';
}


}

/// @nodoc
abstract mixin class _$DailyOverbookingSummaryCopyWith<$Res> implements $DailyOverbookingSummaryCopyWith<$Res> {
  factory _$DailyOverbookingSummaryCopyWith(_DailyOverbookingSummary value, $Res Function(_DailyOverbookingSummary) _then) = __$DailyOverbookingSummaryCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String businessId,@TimestampConverter() DateTime date, int totalSlots, int slotsWithOpportunity, int totalSafeOverbookCapacity, int totalAcceptedOverbooks, int expectedAdditionalRevenueCents, double averageNoshowProbability, int excludedSlots,@TimestampConverter() DateTime calculatedAt
});




}
/// @nodoc
class __$DailyOverbookingSummaryCopyWithImpl<$Res>
    implements _$DailyOverbookingSummaryCopyWith<$Res> {
  __$DailyOverbookingSummaryCopyWithImpl(this._self, this._then);

  final _DailyOverbookingSummary _self;
  final $Res Function(_DailyOverbookingSummary) _then;

/// Create a copy of DailyOverbookingSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? businessId = null,Object? date = null,Object? totalSlots = null,Object? slotsWithOpportunity = null,Object? totalSafeOverbookCapacity = null,Object? totalAcceptedOverbooks = null,Object? expectedAdditionalRevenueCents = null,Object? averageNoshowProbability = null,Object? excludedSlots = null,Object? calculatedAt = null,}) {
  return _then(_DailyOverbookingSummary(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,slotsWithOpportunity: null == slotsWithOpportunity ? _self.slotsWithOpportunity : slotsWithOpportunity // ignore: cast_nullable_to_non_nullable
as int,totalSafeOverbookCapacity: null == totalSafeOverbookCapacity ? _self.totalSafeOverbookCapacity : totalSafeOverbookCapacity // ignore: cast_nullable_to_non_nullable
as int,totalAcceptedOverbooks: null == totalAcceptedOverbooks ? _self.totalAcceptedOverbooks : totalAcceptedOverbooks // ignore: cast_nullable_to_non_nullable
as int,expectedAdditionalRevenueCents: null == expectedAdditionalRevenueCents ? _self.expectedAdditionalRevenueCents : expectedAdditionalRevenueCents // ignore: cast_nullable_to_non_nullable
as int,averageNoshowProbability: null == averageNoshowProbability ? _self.averageNoshowProbability : averageNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,excludedSlots: null == excludedSlots ? _self.excludedSlots : excludedSlots // ignore: cast_nullable_to_non_nullable
as int,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$OverbookingOutcomeRecord {

/// Unique identifier
 String get id;/// Reference to the overbooking slot
 String get overbookingSlotId;/// Business ID
 String get businessId;/// Provider ID
 String get providerId;/// Slot date and time
@TimestampConverter() DateTime get slotDateTime;/// Predicted no-show probability at decision time
 double get predictedNoshowProbability;/// Actual outcome
 OverbookingOutcome get actualOutcome;/// Whether prediction was accurate (no-show occurred as predicted)
 bool get predictionAccurate;/// Revenue impact (positive = gained, negative = lost)
 int get revenueImpactCents;/// Number of appointments that were overbooked
 int get overbookedCount;/// Number that actually no-showed
 int get actualNoshowCount;/// Algorithm version used
 String get algorithmVersion;/// When the outcome was recorded
@TimestampConverter() DateTime get recordedAt;
/// Create a copy of OverbookingOutcomeRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookingOutcomeRecordCopyWith<OverbookingOutcomeRecord> get copyWith => _$OverbookingOutcomeRecordCopyWithImpl<OverbookingOutcomeRecord>(this as OverbookingOutcomeRecord, _$identity);

  /// Serializes this OverbookingOutcomeRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookingOutcomeRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.overbookingSlotId, overbookingSlotId) || other.overbookingSlotId == overbookingSlotId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&(identical(other.predictedNoshowProbability, predictedNoshowProbability) || other.predictedNoshowProbability == predictedNoshowProbability)&&(identical(other.actualOutcome, actualOutcome) || other.actualOutcome == actualOutcome)&&(identical(other.predictionAccurate, predictionAccurate) || other.predictionAccurate == predictionAccurate)&&(identical(other.revenueImpactCents, revenueImpactCents) || other.revenueImpactCents == revenueImpactCents)&&(identical(other.overbookedCount, overbookedCount) || other.overbookedCount == overbookedCount)&&(identical(other.actualNoshowCount, actualNoshowCount) || other.actualNoshowCount == actualNoshowCount)&&(identical(other.algorithmVersion, algorithmVersion) || other.algorithmVersion == algorithmVersion)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,overbookingSlotId,businessId,providerId,slotDateTime,predictedNoshowProbability,actualOutcome,predictionAccurate,revenueImpactCents,overbookedCount,actualNoshowCount,algorithmVersion,recordedAt);

@override
String toString() {
  return 'OverbookingOutcomeRecord(id: $id, overbookingSlotId: $overbookingSlotId, businessId: $businessId, providerId: $providerId, slotDateTime: $slotDateTime, predictedNoshowProbability: $predictedNoshowProbability, actualOutcome: $actualOutcome, predictionAccurate: $predictionAccurate, revenueImpactCents: $revenueImpactCents, overbookedCount: $overbookedCount, actualNoshowCount: $actualNoshowCount, algorithmVersion: $algorithmVersion, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $OverbookingOutcomeRecordCopyWith<$Res>  {
  factory $OverbookingOutcomeRecordCopyWith(OverbookingOutcomeRecord value, $Res Function(OverbookingOutcomeRecord) _then) = _$OverbookingOutcomeRecordCopyWithImpl;
@useResult
$Res call({
 String id, String overbookingSlotId, String businessId, String providerId,@TimestampConverter() DateTime slotDateTime, double predictedNoshowProbability, OverbookingOutcome actualOutcome, bool predictionAccurate, int revenueImpactCents, int overbookedCount, int actualNoshowCount, String algorithmVersion,@TimestampConverter() DateTime recordedAt
});




}
/// @nodoc
class _$OverbookingOutcomeRecordCopyWithImpl<$Res>
    implements $OverbookingOutcomeRecordCopyWith<$Res> {
  _$OverbookingOutcomeRecordCopyWithImpl(this._self, this._then);

  final OverbookingOutcomeRecord _self;
  final $Res Function(OverbookingOutcomeRecord) _then;

/// Create a copy of OverbookingOutcomeRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? overbookingSlotId = null,Object? businessId = null,Object? providerId = null,Object? slotDateTime = null,Object? predictedNoshowProbability = null,Object? actualOutcome = null,Object? predictionAccurate = null,Object? revenueImpactCents = null,Object? overbookedCount = null,Object? actualNoshowCount = null,Object? algorithmVersion = null,Object? recordedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,overbookingSlotId: null == overbookingSlotId ? _self.overbookingSlotId : overbookingSlotId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,predictedNoshowProbability: null == predictedNoshowProbability ? _self.predictedNoshowProbability : predictedNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,actualOutcome: null == actualOutcome ? _self.actualOutcome : actualOutcome // ignore: cast_nullable_to_non_nullable
as OverbookingOutcome,predictionAccurate: null == predictionAccurate ? _self.predictionAccurate : predictionAccurate // ignore: cast_nullable_to_non_nullable
as bool,revenueImpactCents: null == revenueImpactCents ? _self.revenueImpactCents : revenueImpactCents // ignore: cast_nullable_to_non_nullable
as int,overbookedCount: null == overbookedCount ? _self.overbookedCount : overbookedCount // ignore: cast_nullable_to_non_nullable
as int,actualNoshowCount: null == actualNoshowCount ? _self.actualNoshowCount : actualNoshowCount // ignore: cast_nullable_to_non_nullable
as int,algorithmVersion: null == algorithmVersion ? _self.algorithmVersion : algorithmVersion // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OverbookingOutcomeRecord].
extension OverbookingOutcomeRecordPatterns on OverbookingOutcomeRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookingOutcomeRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookingOutcomeRecord value)  $default,){
final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookingOutcomeRecord value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String overbookingSlotId,  String businessId,  String providerId, @TimestampConverter()  DateTime slotDateTime,  double predictedNoshowProbability,  OverbookingOutcome actualOutcome,  bool predictionAccurate,  int revenueImpactCents,  int overbookedCount,  int actualNoshowCount,  String algorithmVersion, @TimestampConverter()  DateTime recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord() when $default != null:
return $default(_that.id,_that.overbookingSlotId,_that.businessId,_that.providerId,_that.slotDateTime,_that.predictedNoshowProbability,_that.actualOutcome,_that.predictionAccurate,_that.revenueImpactCents,_that.overbookedCount,_that.actualNoshowCount,_that.algorithmVersion,_that.recordedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String overbookingSlotId,  String businessId,  String providerId, @TimestampConverter()  DateTime slotDateTime,  double predictedNoshowProbability,  OverbookingOutcome actualOutcome,  bool predictionAccurate,  int revenueImpactCents,  int overbookedCount,  int actualNoshowCount,  String algorithmVersion, @TimestampConverter()  DateTime recordedAt)  $default,) {final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord():
return $default(_that.id,_that.overbookingSlotId,_that.businessId,_that.providerId,_that.slotDateTime,_that.predictedNoshowProbability,_that.actualOutcome,_that.predictionAccurate,_that.revenueImpactCents,_that.overbookedCount,_that.actualNoshowCount,_that.algorithmVersion,_that.recordedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String overbookingSlotId,  String businessId,  String providerId, @TimestampConverter()  DateTime slotDateTime,  double predictedNoshowProbability,  OverbookingOutcome actualOutcome,  bool predictionAccurate,  int revenueImpactCents,  int overbookedCount,  int actualNoshowCount,  String algorithmVersion, @TimestampConverter()  DateTime recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _OverbookingOutcomeRecord() when $default != null:
return $default(_that.id,_that.overbookingSlotId,_that.businessId,_that.providerId,_that.slotDateTime,_that.predictedNoshowProbability,_that.actualOutcome,_that.predictionAccurate,_that.revenueImpactCents,_that.overbookedCount,_that.actualNoshowCount,_that.algorithmVersion,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverbookingOutcomeRecord implements OverbookingOutcomeRecord {
  const _OverbookingOutcomeRecord({required this.id, required this.overbookingSlotId, required this.businessId, required this.providerId, @TimestampConverter() required this.slotDateTime, required this.predictedNoshowProbability, required this.actualOutcome, required this.predictionAccurate, required this.revenueImpactCents, required this.overbookedCount, required this.actualNoshowCount, required this.algorithmVersion, @TimestampConverter() required this.recordedAt});
  factory _OverbookingOutcomeRecord.fromJson(Map<String, dynamic> json) => _$OverbookingOutcomeRecordFromJson(json);

/// Unique identifier
@override final  String id;
/// Reference to the overbooking slot
@override final  String overbookingSlotId;
/// Business ID
@override final  String businessId;
/// Provider ID
@override final  String providerId;
/// Slot date and time
@override@TimestampConverter() final  DateTime slotDateTime;
/// Predicted no-show probability at decision time
@override final  double predictedNoshowProbability;
/// Actual outcome
@override final  OverbookingOutcome actualOutcome;
/// Whether prediction was accurate (no-show occurred as predicted)
@override final  bool predictionAccurate;
/// Revenue impact (positive = gained, negative = lost)
@override final  int revenueImpactCents;
/// Number of appointments that were overbooked
@override final  int overbookedCount;
/// Number that actually no-showed
@override final  int actualNoshowCount;
/// Algorithm version used
@override final  String algorithmVersion;
/// When the outcome was recorded
@override@TimestampConverter() final  DateTime recordedAt;

/// Create a copy of OverbookingOutcomeRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookingOutcomeRecordCopyWith<_OverbookingOutcomeRecord> get copyWith => __$OverbookingOutcomeRecordCopyWithImpl<_OverbookingOutcomeRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverbookingOutcomeRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookingOutcomeRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.overbookingSlotId, overbookingSlotId) || other.overbookingSlotId == overbookingSlotId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&(identical(other.predictedNoshowProbability, predictedNoshowProbability) || other.predictedNoshowProbability == predictedNoshowProbability)&&(identical(other.actualOutcome, actualOutcome) || other.actualOutcome == actualOutcome)&&(identical(other.predictionAccurate, predictionAccurate) || other.predictionAccurate == predictionAccurate)&&(identical(other.revenueImpactCents, revenueImpactCents) || other.revenueImpactCents == revenueImpactCents)&&(identical(other.overbookedCount, overbookedCount) || other.overbookedCount == overbookedCount)&&(identical(other.actualNoshowCount, actualNoshowCount) || other.actualNoshowCount == actualNoshowCount)&&(identical(other.algorithmVersion, algorithmVersion) || other.algorithmVersion == algorithmVersion)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,overbookingSlotId,businessId,providerId,slotDateTime,predictedNoshowProbability,actualOutcome,predictionAccurate,revenueImpactCents,overbookedCount,actualNoshowCount,algorithmVersion,recordedAt);

@override
String toString() {
  return 'OverbookingOutcomeRecord(id: $id, overbookingSlotId: $overbookingSlotId, businessId: $businessId, providerId: $providerId, slotDateTime: $slotDateTime, predictedNoshowProbability: $predictedNoshowProbability, actualOutcome: $actualOutcome, predictionAccurate: $predictionAccurate, revenueImpactCents: $revenueImpactCents, overbookedCount: $overbookedCount, actualNoshowCount: $actualNoshowCount, algorithmVersion: $algorithmVersion, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$OverbookingOutcomeRecordCopyWith<$Res> implements $OverbookingOutcomeRecordCopyWith<$Res> {
  factory _$OverbookingOutcomeRecordCopyWith(_OverbookingOutcomeRecord value, $Res Function(_OverbookingOutcomeRecord) _then) = __$OverbookingOutcomeRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String overbookingSlotId, String businessId, String providerId,@TimestampConverter() DateTime slotDateTime, double predictedNoshowProbability, OverbookingOutcome actualOutcome, bool predictionAccurate, int revenueImpactCents, int overbookedCount, int actualNoshowCount, String algorithmVersion,@TimestampConverter() DateTime recordedAt
});




}
/// @nodoc
class __$OverbookingOutcomeRecordCopyWithImpl<$Res>
    implements _$OverbookingOutcomeRecordCopyWith<$Res> {
  __$OverbookingOutcomeRecordCopyWithImpl(this._self, this._then);

  final _OverbookingOutcomeRecord _self;
  final $Res Function(_OverbookingOutcomeRecord) _then;

/// Create a copy of OverbookingOutcomeRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? overbookingSlotId = null,Object? businessId = null,Object? providerId = null,Object? slotDateTime = null,Object? predictedNoshowProbability = null,Object? actualOutcome = null,Object? predictionAccurate = null,Object? revenueImpactCents = null,Object? overbookedCount = null,Object? actualNoshowCount = null,Object? algorithmVersion = null,Object? recordedAt = null,}) {
  return _then(_OverbookingOutcomeRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,overbookingSlotId: null == overbookingSlotId ? _self.overbookingSlotId : overbookingSlotId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,predictedNoshowProbability: null == predictedNoshowProbability ? _self.predictedNoshowProbability : predictedNoshowProbability // ignore: cast_nullable_to_non_nullable
as double,actualOutcome: null == actualOutcome ? _self.actualOutcome : actualOutcome // ignore: cast_nullable_to_non_nullable
as OverbookingOutcome,predictionAccurate: null == predictionAccurate ? _self.predictionAccurate : predictionAccurate // ignore: cast_nullable_to_non_nullable
as bool,revenueImpactCents: null == revenueImpactCents ? _self.revenueImpactCents : revenueImpactCents // ignore: cast_nullable_to_non_nullable
as int,overbookedCount: null == overbookedCount ? _self.overbookedCount : overbookedCount // ignore: cast_nullable_to_non_nullable
as int,actualNoshowCount: null == actualNoshowCount ? _self.actualNoshowCount : actualNoshowCount // ignore: cast_nullable_to_non_nullable
as int,algorithmVersion: null == algorithmVersion ? _self.algorithmVersion : algorithmVersion // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
