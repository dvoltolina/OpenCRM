// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TimesheetSummary _$TimesheetSummaryFromJson(Map<String, dynamic> json) {
  return _TimesheetSummary.fromJson(json);
}

/// @nodoc
mixin _$TimesheetSummary {
  String get staffId => throw _privateConstructorUsedError;
  String get staffName => throw _privateConstructorUsedError;
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;

  /// Total minutes worked across all entries
  int get totalWorkedMinutes => throw _privateConstructorUsedError;

  /// Total break minutes across all entries
  int get totalBreakMinutes => throw _privateConstructorUsedError;

  /// Number of shifts (clock-in/clock-out cycles) in period
  int get totalShifts => throw _privateConstructorUsedError;

  /// Regular hours (up to 8 hrs/day or 40 hrs/week)
  int get regularMinutes => throw _privateConstructorUsedError;

  /// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
  int get overtimeMinutes => throw _privateConstructorUsedError;

  /// Estimated pay based on hourly rate
  double get estimatedPayAmount => throw _privateConstructorUsedError;

  /// All time entries in this period
  List<TimeEntry> get entries => throw _privateConstructorUsedError;

  /// Current approval status
  TimesheetStatus get status => throw _privateConstructorUsedError;

  /// Serializes this TimesheetSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimesheetSummaryCopyWith<TimesheetSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimesheetSummaryCopyWith<$Res> {
  factory $TimesheetSummaryCopyWith(
          TimesheetSummary value, $Res Function(TimesheetSummary) then) =
      _$TimesheetSummaryCopyWithImpl<$Res, TimesheetSummary>;
  @useResult
  $Res call(
      {String staffId,
      String staffName,
      DateTime periodStart,
      DateTime periodEnd,
      int totalWorkedMinutes,
      int totalBreakMinutes,
      int totalShifts,
      int regularMinutes,
      int overtimeMinutes,
      double estimatedPayAmount,
      List<TimeEntry> entries,
      TimesheetStatus status});
}

/// @nodoc
class _$TimesheetSummaryCopyWithImpl<$Res, $Val extends TimesheetSummary>
    implements $TimesheetSummaryCopyWith<$Res> {
  _$TimesheetSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? staffId = null,
    Object? staffName = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? totalWorkedMinutes = null,
    Object? totalBreakMinutes = null,
    Object? totalShifts = null,
    Object? regularMinutes = null,
    Object? overtimeMinutes = null,
    Object? estimatedPayAmount = null,
    Object? entries = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      staffId: null == staffId
          ? _value.staffId
          : staffId // ignore: cast_nullable_to_non_nullable
              as String,
      staffName: null == staffName
          ? _value.staffName
          : staffName // ignore: cast_nullable_to_non_nullable
              as String,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalWorkedMinutes: null == totalWorkedMinutes
          ? _value.totalWorkedMinutes
          : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      totalBreakMinutes: null == totalBreakMinutes
          ? _value.totalBreakMinutes
          : totalBreakMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      totalShifts: null == totalShifts
          ? _value.totalShifts
          : totalShifts // ignore: cast_nullable_to_non_nullable
              as int,
      regularMinutes: null == regularMinutes
          ? _value.regularMinutes
          : regularMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      overtimeMinutes: null == overtimeMinutes
          ? _value.overtimeMinutes
          : overtimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedPayAmount: null == estimatedPayAmount
          ? _value.estimatedPayAmount
          : estimatedPayAmount // ignore: cast_nullable_to_non_nullable
              as double,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<TimeEntry>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TimesheetStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimesheetSummaryImplCopyWith<$Res>
    implements $TimesheetSummaryCopyWith<$Res> {
  factory _$$TimesheetSummaryImplCopyWith(_$TimesheetSummaryImpl value,
          $Res Function(_$TimesheetSummaryImpl) then) =
      __$$TimesheetSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String staffId,
      String staffName,
      DateTime periodStart,
      DateTime periodEnd,
      int totalWorkedMinutes,
      int totalBreakMinutes,
      int totalShifts,
      int regularMinutes,
      int overtimeMinutes,
      double estimatedPayAmount,
      List<TimeEntry> entries,
      TimesheetStatus status});
}

/// @nodoc
class __$$TimesheetSummaryImplCopyWithImpl<$Res>
    extends _$TimesheetSummaryCopyWithImpl<$Res, _$TimesheetSummaryImpl>
    implements _$$TimesheetSummaryImplCopyWith<$Res> {
  __$$TimesheetSummaryImplCopyWithImpl(_$TimesheetSummaryImpl _value,
      $Res Function(_$TimesheetSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? staffId = null,
    Object? staffName = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? totalWorkedMinutes = null,
    Object? totalBreakMinutes = null,
    Object? totalShifts = null,
    Object? regularMinutes = null,
    Object? overtimeMinutes = null,
    Object? estimatedPayAmount = null,
    Object? entries = null,
    Object? status = null,
  }) {
    return _then(_$TimesheetSummaryImpl(
      staffId: null == staffId
          ? _value.staffId
          : staffId // ignore: cast_nullable_to_non_nullable
              as String,
      staffName: null == staffName
          ? _value.staffName
          : staffName // ignore: cast_nullable_to_non_nullable
              as String,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalWorkedMinutes: null == totalWorkedMinutes
          ? _value.totalWorkedMinutes
          : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      totalBreakMinutes: null == totalBreakMinutes
          ? _value.totalBreakMinutes
          : totalBreakMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      totalShifts: null == totalShifts
          ? _value.totalShifts
          : totalShifts // ignore: cast_nullable_to_non_nullable
              as int,
      regularMinutes: null == regularMinutes
          ? _value.regularMinutes
          : regularMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      overtimeMinutes: null == overtimeMinutes
          ? _value.overtimeMinutes
          : overtimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedPayAmount: null == estimatedPayAmount
          ? _value.estimatedPayAmount
          : estimatedPayAmount // ignore: cast_nullable_to_non_nullable
              as double,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<TimeEntry>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TimesheetStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimesheetSummaryImpl extends _TimesheetSummary {
  const _$TimesheetSummaryImpl(
      {required this.staffId,
      required this.staffName,
      required this.periodStart,
      required this.periodEnd,
      required this.totalWorkedMinutes,
      required this.totalBreakMinutes,
      required this.totalShifts,
      required this.regularMinutes,
      required this.overtimeMinutes,
      required this.estimatedPayAmount,
      required final List<TimeEntry> entries,
      required this.status})
      : _entries = entries,
        super._();

  factory _$TimesheetSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimesheetSummaryImplFromJson(json);

  @override
  final String staffId;
  @override
  final String staffName;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;

  /// Total minutes worked across all entries
  @override
  final int totalWorkedMinutes;

  /// Total break minutes across all entries
  @override
  final int totalBreakMinutes;

  /// Number of shifts (clock-in/clock-out cycles) in period
  @override
  final int totalShifts;

  /// Regular hours (up to 8 hrs/day or 40 hrs/week)
  @override
  final int regularMinutes;

  /// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
  @override
  final int overtimeMinutes;

  /// Estimated pay based on hourly rate
  @override
  final double estimatedPayAmount;

  /// All time entries in this period
  final List<TimeEntry> _entries;

  /// All time entries in this period
  @override
  List<TimeEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  /// Current approval status
  @override
  final TimesheetStatus status;

  @override
  String toString() {
    return 'TimesheetSummary(staffId: $staffId, staffName: $staffName, periodStart: $periodStart, periodEnd: $periodEnd, totalWorkedMinutes: $totalWorkedMinutes, totalBreakMinutes: $totalBreakMinutes, totalShifts: $totalShifts, regularMinutes: $regularMinutes, overtimeMinutes: $overtimeMinutes, estimatedPayAmount: $estimatedPayAmount, entries: $entries, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimesheetSummaryImpl &&
            (identical(other.staffId, staffId) || other.staffId == staffId) &&
            (identical(other.staffName, staffName) ||
                other.staffName == staffName) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.totalWorkedMinutes, totalWorkedMinutes) ||
                other.totalWorkedMinutes == totalWorkedMinutes) &&
            (identical(other.totalBreakMinutes, totalBreakMinutes) ||
                other.totalBreakMinutes == totalBreakMinutes) &&
            (identical(other.totalShifts, totalShifts) ||
                other.totalShifts == totalShifts) &&
            (identical(other.regularMinutes, regularMinutes) ||
                other.regularMinutes == regularMinutes) &&
            (identical(other.overtimeMinutes, overtimeMinutes) ||
                other.overtimeMinutes == overtimeMinutes) &&
            (identical(other.estimatedPayAmount, estimatedPayAmount) ||
                other.estimatedPayAmount == estimatedPayAmount) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      staffId,
      staffName,
      periodStart,
      periodEnd,
      totalWorkedMinutes,
      totalBreakMinutes,
      totalShifts,
      regularMinutes,
      overtimeMinutes,
      estimatedPayAmount,
      const DeepCollectionEquality().hash(_entries),
      status);

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimesheetSummaryImplCopyWith<_$TimesheetSummaryImpl> get copyWith =>
      __$$TimesheetSummaryImplCopyWithImpl<_$TimesheetSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimesheetSummaryImplToJson(
      this,
    );
  }
}

abstract class _TimesheetSummary extends TimesheetSummary {
  const factory _TimesheetSummary(
      {required final String staffId,
      required final String staffName,
      required final DateTime periodStart,
      required final DateTime periodEnd,
      required final int totalWorkedMinutes,
      required final int totalBreakMinutes,
      required final int totalShifts,
      required final int regularMinutes,
      required final int overtimeMinutes,
      required final double estimatedPayAmount,
      required final List<TimeEntry> entries,
      required final TimesheetStatus status}) = _$TimesheetSummaryImpl;
  const _TimesheetSummary._() : super._();

  factory _TimesheetSummary.fromJson(Map<String, dynamic> json) =
      _$TimesheetSummaryImpl.fromJson;

  @override
  String get staffId;
  @override
  String get staffName;
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;

  /// Total minutes worked across all entries
  @override
  int get totalWorkedMinutes;

  /// Total break minutes across all entries
  @override
  int get totalBreakMinutes;

  /// Number of shifts (clock-in/clock-out cycles) in period
  @override
  int get totalShifts;

  /// Regular hours (up to 8 hrs/day or 40 hrs/week)
  @override
  int get regularMinutes;

  /// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
  @override
  int get overtimeMinutes;

  /// Estimated pay based on hourly rate
  @override
  double get estimatedPayAmount;

  /// All time entries in this period
  @override
  List<TimeEntry> get entries;

  /// Current approval status
  @override
  TimesheetStatus get status;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimesheetSummaryImplCopyWith<_$TimesheetSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
