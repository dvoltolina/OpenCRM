// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LocalAppointment _$LocalAppointmentFromJson(Map<String, dynamic> json) {
  return _LocalAppointment.fromJson(json);
}

/// @nodoc
mixin _$LocalAppointment {
// Required identifiers
  String get id => throw _privateConstructorUsedError;
  String get businessId => throw _privateConstructorUsedError;
  String get clientId => throw _privateConstructorUsedError;
  String get serviceId => throw _privateConstructorUsedError;
  String get locationId =>
      throw _privateConstructorUsedError; // Denormalized client info (for offline display)
  String? get clientName => throw _privateConstructorUsedError;
  String? get clientPhone => throw _privateConstructorUsedError;
  String? get clientEmail => throw _privateConstructorUsedError;
  String? get clientAddress =>
      throw _privateConstructorUsedError; // Denormalized service/location info (for offline display)
  String? get serviceName => throw _privateConstructorUsedError;
  String? get locationName => throw _privateConstructorUsedError;
  int? get serviceDurationMinutes =>
      throw _privateConstructorUsedError; // Time fields
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime get endTime =>
      throw _privateConstructorUsedError; // Appointment status
  String get status => throw _privateConstructorUsedError; // Notes
  /// Admin/booking notes (read-only for staff)
  String? get notes => throw _privateConstructorUsedError;

  /// Staff-entered notes (editable)
  String? get staffNotes => throw _privateConstructorUsedError; // Payment info
  bool get requiresPayment => throw _privateConstructorUsedError;
  String? get paymentStatus =>
      throw _privateConstructorUsedError; // Offline sync fields
  /// When this record was last updated locally
  DateTime? get localUpdatedAt => throw _privateConstructorUsedError;

  /// True if this record has pending changes to sync
  bool get pendingSync => throw _privateConstructorUsedError;

  /// Action to perform on sync: 'update', 'check_in', 'complete', 'no_show'
  String? get syncAction =>
      throw _privateConstructorUsedError; // Check-in tracking
  /// When the client was checked in
  DateTime? get checkedInAt => throw _privateConstructorUsedError;

  /// Staff member who checked in the client
  String? get checkedInByStaffId =>
      throw _privateConstructorUsedError; // Completion tracking
  /// When the appointment was completed
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Staff member who completed the appointment
  String? get completedByStaffId => throw _privateConstructorUsedError;

  /// Serializes this LocalAppointment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocalAppointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalAppointmentCopyWith<LocalAppointment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalAppointmentCopyWith<$Res> {
  factory $LocalAppointmentCopyWith(
          LocalAppointment value, $Res Function(LocalAppointment) then) =
      _$LocalAppointmentCopyWithImpl<$Res, LocalAppointment>;
  @useResult
  $Res call(
      {String id,
      String businessId,
      String clientId,
      String serviceId,
      String locationId,
      String? clientName,
      String? clientPhone,
      String? clientEmail,
      String? clientAddress,
      String? serviceName,
      String? locationName,
      int? serviceDurationMinutes,
      DateTime startTime,
      DateTime endTime,
      String status,
      String? notes,
      String? staffNotes,
      bool requiresPayment,
      String? paymentStatus,
      DateTime? localUpdatedAt,
      bool pendingSync,
      String? syncAction,
      DateTime? checkedInAt,
      String? checkedInByStaffId,
      DateTime? completedAt,
      String? completedByStaffId});
}

/// @nodoc
class _$LocalAppointmentCopyWithImpl<$Res, $Val extends LocalAppointment>
    implements $LocalAppointmentCopyWith<$Res> {
  _$LocalAppointmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalAppointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? clientId = null,
    Object? serviceId = null,
    Object? locationId = null,
    Object? clientName = freezed,
    Object? clientPhone = freezed,
    Object? clientEmail = freezed,
    Object? clientAddress = freezed,
    Object? serviceName = freezed,
    Object? locationName = freezed,
    Object? serviceDurationMinutes = freezed,
    Object? startTime = null,
    Object? endTime = null,
    Object? status = null,
    Object? notes = freezed,
    Object? staffNotes = freezed,
    Object? requiresPayment = null,
    Object? paymentStatus = freezed,
    Object? localUpdatedAt = freezed,
    Object? pendingSync = null,
    Object? syncAction = freezed,
    Object? checkedInAt = freezed,
    Object? checkedInByStaffId = freezed,
    Object? completedAt = freezed,
    Object? completedByStaffId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      serviceId: null == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String,
      locationId: null == locationId
          ? _value.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      clientPhone: freezed == clientPhone
          ? _value.clientPhone
          : clientPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      clientEmail: freezed == clientEmail
          ? _value.clientEmail
          : clientEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      clientAddress: freezed == clientAddress
          ? _value.clientAddress
          : clientAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceName: freezed == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceDurationMinutes: freezed == serviceDurationMinutes
          ? _value.serviceDurationMinutes
          : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      staffNotes: freezed == staffNotes
          ? _value.staffNotes
          : staffNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresPayment: null == requiresPayment
          ? _value.requiresPayment
          : requiresPayment // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      localUpdatedAt: freezed == localUpdatedAt
          ? _value.localUpdatedAt
          : localUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pendingSync: null == pendingSync
          ? _value.pendingSync
          : pendingSync // ignore: cast_nullable_to_non_nullable
              as bool,
      syncAction: freezed == syncAction
          ? _value.syncAction
          : syncAction // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedInAt: freezed == checkedInAt
          ? _value.checkedInAt
          : checkedInAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkedInByStaffId: freezed == checkedInByStaffId
          ? _value.checkedInByStaffId
          : checkedInByStaffId // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedByStaffId: freezed == completedByStaffId
          ? _value.completedByStaffId
          : completedByStaffId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocalAppointmentImplCopyWith<$Res>
    implements $LocalAppointmentCopyWith<$Res> {
  factory _$$LocalAppointmentImplCopyWith(_$LocalAppointmentImpl value,
          $Res Function(_$LocalAppointmentImpl) then) =
      __$$LocalAppointmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String businessId,
      String clientId,
      String serviceId,
      String locationId,
      String? clientName,
      String? clientPhone,
      String? clientEmail,
      String? clientAddress,
      String? serviceName,
      String? locationName,
      int? serviceDurationMinutes,
      DateTime startTime,
      DateTime endTime,
      String status,
      String? notes,
      String? staffNotes,
      bool requiresPayment,
      String? paymentStatus,
      DateTime? localUpdatedAt,
      bool pendingSync,
      String? syncAction,
      DateTime? checkedInAt,
      String? checkedInByStaffId,
      DateTime? completedAt,
      String? completedByStaffId});
}

/// @nodoc
class __$$LocalAppointmentImplCopyWithImpl<$Res>
    extends _$LocalAppointmentCopyWithImpl<$Res, _$LocalAppointmentImpl>
    implements _$$LocalAppointmentImplCopyWith<$Res> {
  __$$LocalAppointmentImplCopyWithImpl(_$LocalAppointmentImpl _value,
      $Res Function(_$LocalAppointmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of LocalAppointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? clientId = null,
    Object? serviceId = null,
    Object? locationId = null,
    Object? clientName = freezed,
    Object? clientPhone = freezed,
    Object? clientEmail = freezed,
    Object? clientAddress = freezed,
    Object? serviceName = freezed,
    Object? locationName = freezed,
    Object? serviceDurationMinutes = freezed,
    Object? startTime = null,
    Object? endTime = null,
    Object? status = null,
    Object? notes = freezed,
    Object? staffNotes = freezed,
    Object? requiresPayment = null,
    Object? paymentStatus = freezed,
    Object? localUpdatedAt = freezed,
    Object? pendingSync = null,
    Object? syncAction = freezed,
    Object? checkedInAt = freezed,
    Object? checkedInByStaffId = freezed,
    Object? completedAt = freezed,
    Object? completedByStaffId = freezed,
  }) {
    return _then(_$LocalAppointmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      serviceId: null == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String,
      locationId: null == locationId
          ? _value.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      clientPhone: freezed == clientPhone
          ? _value.clientPhone
          : clientPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      clientEmail: freezed == clientEmail
          ? _value.clientEmail
          : clientEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      clientAddress: freezed == clientAddress
          ? _value.clientAddress
          : clientAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceName: freezed == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceDurationMinutes: freezed == serviceDurationMinutes
          ? _value.serviceDurationMinutes
          : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      staffNotes: freezed == staffNotes
          ? _value.staffNotes
          : staffNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresPayment: null == requiresPayment
          ? _value.requiresPayment
          : requiresPayment // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      localUpdatedAt: freezed == localUpdatedAt
          ? _value.localUpdatedAt
          : localUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pendingSync: null == pendingSync
          ? _value.pendingSync
          : pendingSync // ignore: cast_nullable_to_non_nullable
              as bool,
      syncAction: freezed == syncAction
          ? _value.syncAction
          : syncAction // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedInAt: freezed == checkedInAt
          ? _value.checkedInAt
          : checkedInAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkedInByStaffId: freezed == checkedInByStaffId
          ? _value.checkedInByStaffId
          : checkedInByStaffId // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedByStaffId: freezed == completedByStaffId
          ? _value.completedByStaffId
          : completedByStaffId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocalAppointmentImpl extends _LocalAppointment {
  const _$LocalAppointmentImpl(
      {required this.id,
      required this.businessId,
      required this.clientId,
      required this.serviceId,
      required this.locationId,
      this.clientName,
      this.clientPhone,
      this.clientEmail,
      this.clientAddress,
      this.serviceName,
      this.locationName,
      this.serviceDurationMinutes,
      required this.startTime,
      required this.endTime,
      required this.status,
      this.notes,
      this.staffNotes,
      this.requiresPayment = false,
      this.paymentStatus,
      this.localUpdatedAt,
      this.pendingSync = false,
      this.syncAction,
      this.checkedInAt,
      this.checkedInByStaffId,
      this.completedAt,
      this.completedByStaffId})
      : super._();

  factory _$LocalAppointmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocalAppointmentImplFromJson(json);

// Required identifiers
  @override
  final String id;
  @override
  final String businessId;
  @override
  final String clientId;
  @override
  final String serviceId;
  @override
  final String locationId;
// Denormalized client info (for offline display)
  @override
  final String? clientName;
  @override
  final String? clientPhone;
  @override
  final String? clientEmail;
  @override
  final String? clientAddress;
// Denormalized service/location info (for offline display)
  @override
  final String? serviceName;
  @override
  final String? locationName;
  @override
  final int? serviceDurationMinutes;
// Time fields
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
// Appointment status
  @override
  final String status;
// Notes
  /// Admin/booking notes (read-only for staff)
  @override
  final String? notes;

  /// Staff-entered notes (editable)
  @override
  final String? staffNotes;
// Payment info
  @override
  @JsonKey()
  final bool requiresPayment;
  @override
  final String? paymentStatus;
// Offline sync fields
  /// When this record was last updated locally
  @override
  final DateTime? localUpdatedAt;

  /// True if this record has pending changes to sync
  @override
  @JsonKey()
  final bool pendingSync;

  /// Action to perform on sync: 'update', 'check_in', 'complete', 'no_show'
  @override
  final String? syncAction;
// Check-in tracking
  /// When the client was checked in
  @override
  final DateTime? checkedInAt;

  /// Staff member who checked in the client
  @override
  final String? checkedInByStaffId;
// Completion tracking
  /// When the appointment was completed
  @override
  final DateTime? completedAt;

  /// Staff member who completed the appointment
  @override
  final String? completedByStaffId;

  @override
  String toString() {
    return 'LocalAppointment(id: $id, businessId: $businessId, clientId: $clientId, serviceId: $serviceId, locationId: $locationId, clientName: $clientName, clientPhone: $clientPhone, clientEmail: $clientEmail, clientAddress: $clientAddress, serviceName: $serviceName, locationName: $locationName, serviceDurationMinutes: $serviceDurationMinutes, startTime: $startTime, endTime: $endTime, status: $status, notes: $notes, staffNotes: $staffNotes, requiresPayment: $requiresPayment, paymentStatus: $paymentStatus, localUpdatedAt: $localUpdatedAt, pendingSync: $pendingSync, syncAction: $syncAction, checkedInAt: $checkedInAt, checkedInByStaffId: $checkedInByStaffId, completedAt: $completedAt, completedByStaffId: $completedByStaffId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalAppointmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.locationId, locationId) ||
                other.locationId == locationId) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.clientPhone, clientPhone) ||
                other.clientPhone == clientPhone) &&
            (identical(other.clientEmail, clientEmail) ||
                other.clientEmail == clientEmail) &&
            (identical(other.clientAddress, clientAddress) ||
                other.clientAddress == clientAddress) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.serviceDurationMinutes, serviceDurationMinutes) ||
                other.serviceDurationMinutes == serviceDurationMinutes) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.staffNotes, staffNotes) ||
                other.staffNotes == staffNotes) &&
            (identical(other.requiresPayment, requiresPayment) ||
                other.requiresPayment == requiresPayment) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.localUpdatedAt, localUpdatedAt) ||
                other.localUpdatedAt == localUpdatedAt) &&
            (identical(other.pendingSync, pendingSync) ||
                other.pendingSync == pendingSync) &&
            (identical(other.syncAction, syncAction) ||
                other.syncAction == syncAction) &&
            (identical(other.checkedInAt, checkedInAt) ||
                other.checkedInAt == checkedInAt) &&
            (identical(other.checkedInByStaffId, checkedInByStaffId) ||
                other.checkedInByStaffId == checkedInByStaffId) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.completedByStaffId, completedByStaffId) ||
                other.completedByStaffId == completedByStaffId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        businessId,
        clientId,
        serviceId,
        locationId,
        clientName,
        clientPhone,
        clientEmail,
        clientAddress,
        serviceName,
        locationName,
        serviceDurationMinutes,
        startTime,
        endTime,
        status,
        notes,
        staffNotes,
        requiresPayment,
        paymentStatus,
        localUpdatedAt,
        pendingSync,
        syncAction,
        checkedInAt,
        checkedInByStaffId,
        completedAt,
        completedByStaffId
      ]);

  /// Create a copy of LocalAppointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalAppointmentImplCopyWith<_$LocalAppointmentImpl> get copyWith =>
      __$$LocalAppointmentImplCopyWithImpl<_$LocalAppointmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocalAppointmentImplToJson(
      this,
    );
  }
}

abstract class _LocalAppointment extends LocalAppointment {
  const factory _LocalAppointment(
      {required final String id,
      required final String businessId,
      required final String clientId,
      required final String serviceId,
      required final String locationId,
      final String? clientName,
      final String? clientPhone,
      final String? clientEmail,
      final String? clientAddress,
      final String? serviceName,
      final String? locationName,
      final int? serviceDurationMinutes,
      required final DateTime startTime,
      required final DateTime endTime,
      required final String status,
      final String? notes,
      final String? staffNotes,
      final bool requiresPayment,
      final String? paymentStatus,
      final DateTime? localUpdatedAt,
      final bool pendingSync,
      final String? syncAction,
      final DateTime? checkedInAt,
      final String? checkedInByStaffId,
      final DateTime? completedAt,
      final String? completedByStaffId}) = _$LocalAppointmentImpl;
  const _LocalAppointment._() : super._();

  factory _LocalAppointment.fromJson(Map<String, dynamic> json) =
      _$LocalAppointmentImpl.fromJson;

// Required identifiers
  @override
  String get id;
  @override
  String get businessId;
  @override
  String get clientId;
  @override
  String get serviceId;
  @override
  String get locationId; // Denormalized client info (for offline display)
  @override
  String? get clientName;
  @override
  String? get clientPhone;
  @override
  String? get clientEmail;
  @override
  String?
      get clientAddress; // Denormalized service/location info (for offline display)
  @override
  String? get serviceName;
  @override
  String? get locationName;
  @override
  int? get serviceDurationMinutes; // Time fields
  @override
  DateTime get startTime;
  @override
  DateTime get endTime; // Appointment status
  @override
  String get status; // Notes
  /// Admin/booking notes (read-only for staff)
  @override
  String? get notes;

  /// Staff-entered notes (editable)
  @override
  String? get staffNotes; // Payment info
  @override
  bool get requiresPayment;
  @override
  String? get paymentStatus; // Offline sync fields
  /// When this record was last updated locally
  @override
  DateTime? get localUpdatedAt;

  /// True if this record has pending changes to sync
  @override
  bool get pendingSync;

  /// Action to perform on sync: 'update', 'check_in', 'complete', 'no_show'
  @override
  String? get syncAction; // Check-in tracking
  /// When the client was checked in
  @override
  DateTime? get checkedInAt;

  /// Staff member who checked in the client
  @override
  String? get checkedInByStaffId; // Completion tracking
  /// When the appointment was completed
  @override
  DateTime? get completedAt;

  /// Staff member who completed the appointment
  @override
  String? get completedByStaffId;

  /// Create a copy of LocalAppointment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalAppointmentImplCopyWith<_$LocalAppointmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
