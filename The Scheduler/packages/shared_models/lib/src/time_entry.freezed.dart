// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BreakPeriod _$BreakPeriodFromJson(Map<String, dynamic> json) {
  return _BreakPeriod.fromJson(json);
}

/// @nodoc
mixin _$BreakPeriod {
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  BreakType get type => throw _privateConstructorUsedError;

  /// Serializes this BreakPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BreakPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BreakPeriodCopyWith<BreakPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BreakPeriodCopyWith<$Res> {
  factory $BreakPeriodCopyWith(
          BreakPeriod value, $Res Function(BreakPeriod) then) =
      _$BreakPeriodCopyWithImpl<$Res, BreakPeriod>;
  @useResult
  $Res call({DateTime startTime, DateTime? endTime, BreakType type});
}

/// @nodoc
class _$BreakPeriodCopyWithImpl<$Res, $Val extends BreakPeriod>
    implements $BreakPeriodCopyWith<$Res> {
  _$BreakPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BreakPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = freezed,
    Object? type = null,
  }) {
    return _then(_value.copyWith(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BreakType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BreakPeriodImplCopyWith<$Res>
    implements $BreakPeriodCopyWith<$Res> {
  factory _$$BreakPeriodImplCopyWith(
          _$BreakPeriodImpl value, $Res Function(_$BreakPeriodImpl) then) =
      __$$BreakPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime startTime, DateTime? endTime, BreakType type});
}

/// @nodoc
class __$$BreakPeriodImplCopyWithImpl<$Res>
    extends _$BreakPeriodCopyWithImpl<$Res, _$BreakPeriodImpl>
    implements _$$BreakPeriodImplCopyWith<$Res> {
  __$$BreakPeriodImplCopyWithImpl(
      _$BreakPeriodImpl _value, $Res Function(_$BreakPeriodImpl) _then)
      : super(_value, _then);

  /// Create a copy of BreakPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = freezed,
    Object? type = null,
  }) {
    return _then(_$BreakPeriodImpl(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BreakType,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BreakPeriodImpl implements _BreakPeriod {
  const _$BreakPeriodImpl(
      {required this.startTime, this.endTime, required this.type});

  factory _$BreakPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$BreakPeriodImplFromJson(json);

  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  @override
  final BreakType type;

  @override
  String toString() {
    return 'BreakPeriod(startTime: $startTime, endTime: $endTime, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BreakPeriodImpl &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startTime, endTime, type);

  /// Create a copy of BreakPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BreakPeriodImplCopyWith<_$BreakPeriodImpl> get copyWith =>
      __$$BreakPeriodImplCopyWithImpl<_$BreakPeriodImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BreakPeriodImplToJson(
      this,
    );
  }
}

abstract class _BreakPeriod implements BreakPeriod {
  const factory _BreakPeriod(
      {required final DateTime startTime,
      final DateTime? endTime,
      required final BreakType type}) = _$BreakPeriodImpl;

  factory _BreakPeriod.fromJson(Map<String, dynamic> json) =
      _$BreakPeriodImpl.fromJson;

  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  BreakType get type;

  /// Create a copy of BreakPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BreakPeriodImplCopyWith<_$BreakPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimeEntry _$TimeEntryFromJson(Map<String, dynamic> json) {
  return _TimeEntry.fromJson(json);
}

/// @nodoc
mixin _$TimeEntry {
  String get id => throw _privateConstructorUsedError;
  String get businessId => throw _privateConstructorUsedError;
  String get staffId =>
      throw _privateConstructorUsedError; // Clock in/out times
  DateTime get clockInTime => throw _privateConstructorUsedError;
  DateTime? get clockOutTime =>
      throw _privateConstructorUsedError; // Clock-in location tracking (GPS)
  double? get clockInLatitude => throw _privateConstructorUsedError;
  double? get clockInLongitude => throw _privateConstructorUsedError;
  String? get clockInAddress =>
      throw _privateConstructorUsedError; // Clock-out location tracking (GPS)
  double? get clockOutLatitude => throw _privateConstructorUsedError;
  double? get clockOutLongitude => throw _privateConstructorUsedError;
  String? get clockOutAddress =>
      throw _privateConstructorUsedError; // Geo-fence validation
  /// Business location ID if clocked in at a known location
  String? get clockInLocationId => throw _privateConstructorUsedError;

  /// Business location ID if clocked out at a known location
  String? get clockOutLocationId => throw _privateConstructorUsedError;

  /// True if clock-in was outside the geo-fence radius
  bool get clockInOutsideGeofence => throw _privateConstructorUsedError;

  /// True if clock-out was outside the geo-fence radius
  bool get clockOutOutsideGeofence =>
      throw _privateConstructorUsedError; // Breaks
  List<BreakPeriod> get breaks =>
      throw _privateConstructorUsedError; // Calculated fields (set on clock out)
  /// Total minutes between clock-in and clock-out
  int? get totalMinutes => throw _privateConstructorUsedError;

  /// Total break time in minutes
  int? get breakMinutes => throw _privateConstructorUsedError;

  /// Worked minutes (totalMinutes - breakMinutes)
  int? get workedMinutes =>
      throw _privateConstructorUsedError; // Status & approval
  TimeEntryStatus get status => throw _privateConstructorUsedError;

  /// User ID of manager who approved/rejected
  String? get approvedByUserId => throw _privateConstructorUsedError;

  /// When the entry was approved/rejected
  DateTime? get approvedAt => throw _privateConstructorUsedError;

  /// Reason for rejection (if status is rejected)
  String? get rejectionReason => throw _privateConstructorUsedError; // Notes
  /// Notes added by staff member
  String? get staffNotes => throw _privateConstructorUsedError;

  /// Notes added by manager
  String? get managerNotes =>
      throw _privateConstructorUsedError; // Audit fields
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TimeEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimeEntryCopyWith<TimeEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeEntryCopyWith<$Res> {
  factory $TimeEntryCopyWith(TimeEntry value, $Res Function(TimeEntry) then) =
      _$TimeEntryCopyWithImpl<$Res, TimeEntry>;
  @useResult
  $Res call(
      {String id,
      String businessId,
      String staffId,
      DateTime clockInTime,
      DateTime? clockOutTime,
      double? clockInLatitude,
      double? clockInLongitude,
      String? clockInAddress,
      double? clockOutLatitude,
      double? clockOutLongitude,
      String? clockOutAddress,
      String? clockInLocationId,
      String? clockOutLocationId,
      bool clockInOutsideGeofence,
      bool clockOutOutsideGeofence,
      List<BreakPeriod> breaks,
      int? totalMinutes,
      int? breakMinutes,
      int? workedMinutes,
      TimeEntryStatus status,
      String? approvedByUserId,
      DateTime? approvedAt,
      String? rejectionReason,
      String? staffNotes,
      String? managerNotes,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$TimeEntryCopyWithImpl<$Res, $Val extends TimeEntry>
    implements $TimeEntryCopyWith<$Res> {
  _$TimeEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? staffId = null,
    Object? clockInTime = null,
    Object? clockOutTime = freezed,
    Object? clockInLatitude = freezed,
    Object? clockInLongitude = freezed,
    Object? clockInAddress = freezed,
    Object? clockOutLatitude = freezed,
    Object? clockOutLongitude = freezed,
    Object? clockOutAddress = freezed,
    Object? clockInLocationId = freezed,
    Object? clockOutLocationId = freezed,
    Object? clockInOutsideGeofence = null,
    Object? clockOutOutsideGeofence = null,
    Object? breaks = null,
    Object? totalMinutes = freezed,
    Object? breakMinutes = freezed,
    Object? workedMinutes = freezed,
    Object? status = null,
    Object? approvedByUserId = freezed,
    Object? approvedAt = freezed,
    Object? rejectionReason = freezed,
    Object? staffNotes = freezed,
    Object? managerNotes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      staffId: null == staffId
          ? _value.staffId
          : staffId // ignore: cast_nullable_to_non_nullable
              as String,
      clockInTime: null == clockInTime
          ? _value.clockInTime
          : clockInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      clockOutTime: freezed == clockOutTime
          ? _value.clockOutTime
          : clockOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clockInLatitude: freezed == clockInLatitude
          ? _value.clockInLatitude
          : clockInLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockInLongitude: freezed == clockInLongitude
          ? _value.clockInLongitude
          : clockInLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockInAddress: freezed == clockInAddress
          ? _value.clockInAddress
          : clockInAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      clockOutLatitude: freezed == clockOutLatitude
          ? _value.clockOutLatitude
          : clockOutLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockOutLongitude: freezed == clockOutLongitude
          ? _value.clockOutLongitude
          : clockOutLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockOutAddress: freezed == clockOutAddress
          ? _value.clockOutAddress
          : clockOutAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      clockInLocationId: freezed == clockInLocationId
          ? _value.clockInLocationId
          : clockInLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      clockOutLocationId: freezed == clockOutLocationId
          ? _value.clockOutLocationId
          : clockOutLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      clockInOutsideGeofence: null == clockInOutsideGeofence
          ? _value.clockInOutsideGeofence
          : clockInOutsideGeofence // ignore: cast_nullable_to_non_nullable
              as bool,
      clockOutOutsideGeofence: null == clockOutOutsideGeofence
          ? _value.clockOutOutsideGeofence
          : clockOutOutsideGeofence // ignore: cast_nullable_to_non_nullable
              as bool,
      breaks: null == breaks
          ? _value.breaks
          : breaks // ignore: cast_nullable_to_non_nullable
              as List<BreakPeriod>,
      totalMinutes: freezed == totalMinutes
          ? _value.totalMinutes
          : totalMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      breakMinutes: freezed == breakMinutes
          ? _value.breakMinutes
          : breakMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      workedMinutes: freezed == workedMinutes
          ? _value.workedMinutes
          : workedMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TimeEntryStatus,
      approvedByUserId: freezed == approvedByUserId
          ? _value.approvedByUserId
          : approvedByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      staffNotes: freezed == staffNotes
          ? _value.staffNotes
          : staffNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      managerNotes: freezed == managerNotes
          ? _value.managerNotes
          : managerNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimeEntryImplCopyWith<$Res>
    implements $TimeEntryCopyWith<$Res> {
  factory _$$TimeEntryImplCopyWith(
          _$TimeEntryImpl value, $Res Function(_$TimeEntryImpl) then) =
      __$$TimeEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String businessId,
      String staffId,
      DateTime clockInTime,
      DateTime? clockOutTime,
      double? clockInLatitude,
      double? clockInLongitude,
      String? clockInAddress,
      double? clockOutLatitude,
      double? clockOutLongitude,
      String? clockOutAddress,
      String? clockInLocationId,
      String? clockOutLocationId,
      bool clockInOutsideGeofence,
      bool clockOutOutsideGeofence,
      List<BreakPeriod> breaks,
      int? totalMinutes,
      int? breakMinutes,
      int? workedMinutes,
      TimeEntryStatus status,
      String? approvedByUserId,
      DateTime? approvedAt,
      String? rejectionReason,
      String? staffNotes,
      String? managerNotes,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$TimeEntryImplCopyWithImpl<$Res>
    extends _$TimeEntryCopyWithImpl<$Res, _$TimeEntryImpl>
    implements _$$TimeEntryImplCopyWith<$Res> {
  __$$TimeEntryImplCopyWithImpl(
      _$TimeEntryImpl _value, $Res Function(_$TimeEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? staffId = null,
    Object? clockInTime = null,
    Object? clockOutTime = freezed,
    Object? clockInLatitude = freezed,
    Object? clockInLongitude = freezed,
    Object? clockInAddress = freezed,
    Object? clockOutLatitude = freezed,
    Object? clockOutLongitude = freezed,
    Object? clockOutAddress = freezed,
    Object? clockInLocationId = freezed,
    Object? clockOutLocationId = freezed,
    Object? clockInOutsideGeofence = null,
    Object? clockOutOutsideGeofence = null,
    Object? breaks = null,
    Object? totalMinutes = freezed,
    Object? breakMinutes = freezed,
    Object? workedMinutes = freezed,
    Object? status = null,
    Object? approvedByUserId = freezed,
    Object? approvedAt = freezed,
    Object? rejectionReason = freezed,
    Object? staffNotes = freezed,
    Object? managerNotes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TimeEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      staffId: null == staffId
          ? _value.staffId
          : staffId // ignore: cast_nullable_to_non_nullable
              as String,
      clockInTime: null == clockInTime
          ? _value.clockInTime
          : clockInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      clockOutTime: freezed == clockOutTime
          ? _value.clockOutTime
          : clockOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clockInLatitude: freezed == clockInLatitude
          ? _value.clockInLatitude
          : clockInLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockInLongitude: freezed == clockInLongitude
          ? _value.clockInLongitude
          : clockInLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockInAddress: freezed == clockInAddress
          ? _value.clockInAddress
          : clockInAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      clockOutLatitude: freezed == clockOutLatitude
          ? _value.clockOutLatitude
          : clockOutLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockOutLongitude: freezed == clockOutLongitude
          ? _value.clockOutLongitude
          : clockOutLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      clockOutAddress: freezed == clockOutAddress
          ? _value.clockOutAddress
          : clockOutAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      clockInLocationId: freezed == clockInLocationId
          ? _value.clockInLocationId
          : clockInLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      clockOutLocationId: freezed == clockOutLocationId
          ? _value.clockOutLocationId
          : clockOutLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      clockInOutsideGeofence: null == clockInOutsideGeofence
          ? _value.clockInOutsideGeofence
          : clockInOutsideGeofence // ignore: cast_nullable_to_non_nullable
              as bool,
      clockOutOutsideGeofence: null == clockOutOutsideGeofence
          ? _value.clockOutOutsideGeofence
          : clockOutOutsideGeofence // ignore: cast_nullable_to_non_nullable
              as bool,
      breaks: null == breaks
          ? _value._breaks
          : breaks // ignore: cast_nullable_to_non_nullable
              as List<BreakPeriod>,
      totalMinutes: freezed == totalMinutes
          ? _value.totalMinutes
          : totalMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      breakMinutes: freezed == breakMinutes
          ? _value.breakMinutes
          : breakMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      workedMinutes: freezed == workedMinutes
          ? _value.workedMinutes
          : workedMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TimeEntryStatus,
      approvedByUserId: freezed == approvedByUserId
          ? _value.approvedByUserId
          : approvedByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      staffNotes: freezed == staffNotes
          ? _value.staffNotes
          : staffNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      managerNotes: freezed == managerNotes
          ? _value.managerNotes
          : managerNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimeEntryImpl implements _TimeEntry {
  const _$TimeEntryImpl(
      {required this.id,
      required this.businessId,
      required this.staffId,
      required this.clockInTime,
      this.clockOutTime,
      this.clockInLatitude,
      this.clockInLongitude,
      this.clockInAddress,
      this.clockOutLatitude,
      this.clockOutLongitude,
      this.clockOutAddress,
      this.clockInLocationId,
      this.clockOutLocationId,
      this.clockInOutsideGeofence = false,
      this.clockOutOutsideGeofence = false,
      final List<BreakPeriod> breaks = const [],
      this.totalMinutes,
      this.breakMinutes,
      this.workedMinutes,
      required this.status,
      this.approvedByUserId,
      this.approvedAt,
      this.rejectionReason,
      this.staffNotes,
      this.managerNotes,
      required this.createdAt,
      required this.updatedAt})
      : _breaks = breaks;

  factory _$TimeEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimeEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String businessId;
  @override
  final String staffId;
// Clock in/out times
  @override
  final DateTime clockInTime;
  @override
  final DateTime? clockOutTime;
// Clock-in location tracking (GPS)
  @override
  final double? clockInLatitude;
  @override
  final double? clockInLongitude;
  @override
  final String? clockInAddress;
// Clock-out location tracking (GPS)
  @override
  final double? clockOutLatitude;
  @override
  final double? clockOutLongitude;
  @override
  final String? clockOutAddress;
// Geo-fence validation
  /// Business location ID if clocked in at a known location
  @override
  final String? clockInLocationId;

  /// Business location ID if clocked out at a known location
  @override
  final String? clockOutLocationId;

  /// True if clock-in was outside the geo-fence radius
  @override
  @JsonKey()
  final bool clockInOutsideGeofence;

  /// True if clock-out was outside the geo-fence radius
  @override
  @JsonKey()
  final bool clockOutOutsideGeofence;
// Breaks
  final List<BreakPeriod> _breaks;
// Breaks
  @override
  @JsonKey()
  List<BreakPeriod> get breaks {
    if (_breaks is EqualUnmodifiableListView) return _breaks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_breaks);
  }

// Calculated fields (set on clock out)
  /// Total minutes between clock-in and clock-out
  @override
  final int? totalMinutes;

  /// Total break time in minutes
  @override
  final int? breakMinutes;

  /// Worked minutes (totalMinutes - breakMinutes)
  @override
  final int? workedMinutes;
// Status & approval
  @override
  final TimeEntryStatus status;

  /// User ID of manager who approved/rejected
  @override
  final String? approvedByUserId;

  /// When the entry was approved/rejected
  @override
  final DateTime? approvedAt;

  /// Reason for rejection (if status is rejected)
  @override
  final String? rejectionReason;
// Notes
  /// Notes added by staff member
  @override
  final String? staffNotes;

  /// Notes added by manager
  @override
  final String? managerNotes;
// Audit fields
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TimeEntry(id: $id, businessId: $businessId, staffId: $staffId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockInAddress: $clockInAddress, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, clockOutAddress: $clockOutAddress, clockInLocationId: $clockInLocationId, clockOutLocationId: $clockOutLocationId, clockInOutsideGeofence: $clockInOutsideGeofence, clockOutOutsideGeofence: $clockOutOutsideGeofence, breaks: $breaks, totalMinutes: $totalMinutes, breakMinutes: $breakMinutes, workedMinutes: $workedMinutes, status: $status, approvedByUserId: $approvedByUserId, approvedAt: $approvedAt, rejectionReason: $rejectionReason, staffNotes: $staffNotes, managerNotes: $managerNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.staffId, staffId) || other.staffId == staffId) &&
            (identical(other.clockInTime, clockInTime) ||
                other.clockInTime == clockInTime) &&
            (identical(other.clockOutTime, clockOutTime) ||
                other.clockOutTime == clockOutTime) &&
            (identical(other.clockInLatitude, clockInLatitude) ||
                other.clockInLatitude == clockInLatitude) &&
            (identical(other.clockInLongitude, clockInLongitude) ||
                other.clockInLongitude == clockInLongitude) &&
            (identical(other.clockInAddress, clockInAddress) ||
                other.clockInAddress == clockInAddress) &&
            (identical(other.clockOutLatitude, clockOutLatitude) ||
                other.clockOutLatitude == clockOutLatitude) &&
            (identical(other.clockOutLongitude, clockOutLongitude) ||
                other.clockOutLongitude == clockOutLongitude) &&
            (identical(other.clockOutAddress, clockOutAddress) ||
                other.clockOutAddress == clockOutAddress) &&
            (identical(other.clockInLocationId, clockInLocationId) ||
                other.clockInLocationId == clockInLocationId) &&
            (identical(other.clockOutLocationId, clockOutLocationId) ||
                other.clockOutLocationId == clockOutLocationId) &&
            (identical(other.clockInOutsideGeofence, clockInOutsideGeofence) ||
                other.clockInOutsideGeofence == clockInOutsideGeofence) &&
            (identical(
                    other.clockOutOutsideGeofence, clockOutOutsideGeofence) ||
                other.clockOutOutsideGeofence == clockOutOutsideGeofence) &&
            const DeepCollectionEquality().equals(other._breaks, _breaks) &&
            (identical(other.totalMinutes, totalMinutes) ||
                other.totalMinutes == totalMinutes) &&
            (identical(other.breakMinutes, breakMinutes) ||
                other.breakMinutes == breakMinutes) &&
            (identical(other.workedMinutes, workedMinutes) ||
                other.workedMinutes == workedMinutes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.approvedByUserId, approvedByUserId) ||
                other.approvedByUserId == approvedByUserId) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.staffNotes, staffNotes) ||
                other.staffNotes == staffNotes) &&
            (identical(other.managerNotes, managerNotes) ||
                other.managerNotes == managerNotes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        businessId,
        staffId,
        clockInTime,
        clockOutTime,
        clockInLatitude,
        clockInLongitude,
        clockInAddress,
        clockOutLatitude,
        clockOutLongitude,
        clockOutAddress,
        clockInLocationId,
        clockOutLocationId,
        clockInOutsideGeofence,
        clockOutOutsideGeofence,
        const DeepCollectionEquality().hash(_breaks),
        totalMinutes,
        breakMinutes,
        workedMinutes,
        status,
        approvedByUserId,
        approvedAt,
        rejectionReason,
        staffNotes,
        managerNotes,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeEntryImplCopyWith<_$TimeEntryImpl> get copyWith =>
      __$$TimeEntryImplCopyWithImpl<_$TimeEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimeEntryImplToJson(
      this,
    );
  }
}

abstract class _TimeEntry implements TimeEntry {
  const factory _TimeEntry(
      {required final String id,
      required final String businessId,
      required final String staffId,
      required final DateTime clockInTime,
      final DateTime? clockOutTime,
      final double? clockInLatitude,
      final double? clockInLongitude,
      final String? clockInAddress,
      final double? clockOutLatitude,
      final double? clockOutLongitude,
      final String? clockOutAddress,
      final String? clockInLocationId,
      final String? clockOutLocationId,
      final bool clockInOutsideGeofence,
      final bool clockOutOutsideGeofence,
      final List<BreakPeriod> breaks,
      final int? totalMinutes,
      final int? breakMinutes,
      final int? workedMinutes,
      required final TimeEntryStatus status,
      final String? approvedByUserId,
      final DateTime? approvedAt,
      final String? rejectionReason,
      final String? staffNotes,
      final String? managerNotes,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$TimeEntryImpl;

  factory _TimeEntry.fromJson(Map<String, dynamic> json) =
      _$TimeEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get businessId;
  @override
  String get staffId; // Clock in/out times
  @override
  DateTime get clockInTime;
  @override
  DateTime? get clockOutTime; // Clock-in location tracking (GPS)
  @override
  double? get clockInLatitude;
  @override
  double? get clockInLongitude;
  @override
  String? get clockInAddress; // Clock-out location tracking (GPS)
  @override
  double? get clockOutLatitude;
  @override
  double? get clockOutLongitude;
  @override
  String? get clockOutAddress; // Geo-fence validation
  /// Business location ID if clocked in at a known location
  @override
  String? get clockInLocationId;

  /// Business location ID if clocked out at a known location
  @override
  String? get clockOutLocationId;

  /// True if clock-in was outside the geo-fence radius
  @override
  bool get clockInOutsideGeofence;

  /// True if clock-out was outside the geo-fence radius
  @override
  bool get clockOutOutsideGeofence; // Breaks
  @override
  List<BreakPeriod> get breaks; // Calculated fields (set on clock out)
  /// Total minutes between clock-in and clock-out
  @override
  int? get totalMinutes;

  /// Total break time in minutes
  @override
  int? get breakMinutes;

  /// Worked minutes (totalMinutes - breakMinutes)
  @override
  int? get workedMinutes; // Status & approval
  @override
  TimeEntryStatus get status;

  /// User ID of manager who approved/rejected
  @override
  String? get approvedByUserId;

  /// When the entry was approved/rejected
  @override
  DateTime? get approvedAt;

  /// Reason for rejection (if status is rejected)
  @override
  String? get rejectionReason; // Notes
  /// Notes added by staff member
  @override
  String? get staffNotes;

  /// Notes added by manager
  @override
  String? get managerNotes; // Audit fields
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimeEntryImplCopyWith<_$TimeEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
