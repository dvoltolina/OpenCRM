// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'risk_indicator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RiskIndicator {

/// Unique identifier
 String get id;/// Type of indicator (risk, vip, neutral)
 IndicatorType get type;/// Severity level
 IndicatorSeverity get severity;/// Category of the indicator
 String get category;/// Human-readable description
 String get description;/// Confidence score from AI (0.0-1.0)
 double get confidence;/// Source that triggered this indicator
 SentimentSource get source;/// Reference to source document ID
 String? get sourceDocumentId;/// Snippet of text that triggered this indicator
 String? get triggerText;/// When this indicator was detected
 DateTime get detectedAt;/// Suggested action to take
 String? get suggestedAction;/// Whether this indicator has been acknowledged by staff
 bool get acknowledged;/// Staff member who acknowledged (if any)
 String? get acknowledgedBy;/// When acknowledged
 DateTime? get acknowledgedAt;
/// Create a copy of RiskIndicator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskIndicatorCopyWith<RiskIndicator> get copyWith => _$RiskIndicatorCopyWithImpl<RiskIndicator>(this as RiskIndicator, _$identity);

  /// Serializes this RiskIndicator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskIndicator&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.triggerText, triggerText) || other.triggerText == triggerText)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&(identical(other.acknowledged, acknowledged) || other.acknowledged == acknowledged)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,severity,category,description,confidence,source,sourceDocumentId,triggerText,detectedAt,suggestedAction,acknowledged,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'RiskIndicator(id: $id, type: $type, severity: $severity, category: $category, description: $description, confidence: $confidence, source: $source, sourceDocumentId: $sourceDocumentId, triggerText: $triggerText, detectedAt: $detectedAt, suggestedAction: $suggestedAction, acknowledged: $acknowledged, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class $RiskIndicatorCopyWith<$Res>  {
  factory $RiskIndicatorCopyWith(RiskIndicator value, $Res Function(RiskIndicator) _then) = _$RiskIndicatorCopyWithImpl;
@useResult
$Res call({
 String id, IndicatorType type, IndicatorSeverity severity, String category, String description, double confidence, SentimentSource source, String? sourceDocumentId, String? triggerText, DateTime detectedAt, String? suggestedAction, bool acknowledged, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class _$RiskIndicatorCopyWithImpl<$Res>
    implements $RiskIndicatorCopyWith<$Res> {
  _$RiskIndicatorCopyWithImpl(this._self, this._then);

  final RiskIndicator _self;
  final $Res Function(RiskIndicator) _then;

/// Create a copy of RiskIndicator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? severity = null,Object? category = null,Object? description = null,Object? confidence = null,Object? source = null,Object? sourceDocumentId = freezed,Object? triggerText = freezed,Object? detectedAt = null,Object? suggestedAction = freezed,Object? acknowledged = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IndicatorType,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as IndicatorSeverity,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SentimentSource,sourceDocumentId: freezed == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as String?,triggerText: freezed == triggerText ? _self.triggerText : triggerText // ignore: cast_nullable_to_non_nullable
as String?,detectedAt: null == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedAction: freezed == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String?,acknowledged: null == acknowledged ? _self.acknowledged : acknowledged // ignore: cast_nullable_to_non_nullable
as bool,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskIndicator].
extension RiskIndicatorPatterns on RiskIndicator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskIndicator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskIndicator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskIndicator value)  $default,){
final _that = this;
switch (_that) {
case _RiskIndicator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskIndicator value)?  $default,){
final _that = this;
switch (_that) {
case _RiskIndicator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  IndicatorType type,  IndicatorSeverity severity,  String category,  String description,  double confidence,  SentimentSource source,  String? sourceDocumentId,  String? triggerText,  DateTime detectedAt,  String? suggestedAction,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskIndicator() when $default != null:
return $default(_that.id,_that.type,_that.severity,_that.category,_that.description,_that.confidence,_that.source,_that.sourceDocumentId,_that.triggerText,_that.detectedAt,_that.suggestedAction,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  IndicatorType type,  IndicatorSeverity severity,  String category,  String description,  double confidence,  SentimentSource source,  String? sourceDocumentId,  String? triggerText,  DateTime detectedAt,  String? suggestedAction,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)  $default,) {final _that = this;
switch (_that) {
case _RiskIndicator():
return $default(_that.id,_that.type,_that.severity,_that.category,_that.description,_that.confidence,_that.source,_that.sourceDocumentId,_that.triggerText,_that.detectedAt,_that.suggestedAction,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  IndicatorType type,  IndicatorSeverity severity,  String category,  String description,  double confidence,  SentimentSource source,  String? sourceDocumentId,  String? triggerText,  DateTime detectedAt,  String? suggestedAction,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,) {final _that = this;
switch (_that) {
case _RiskIndicator() when $default != null:
return $default(_that.id,_that.type,_that.severity,_that.category,_that.description,_that.confidence,_that.source,_that.sourceDocumentId,_that.triggerText,_that.detectedAt,_that.suggestedAction,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiskIndicator implements RiskIndicator {
  const _RiskIndicator({required this.id, required this.type, required this.severity, required this.category, required this.description, required this.confidence, required this.source, this.sourceDocumentId, this.triggerText, required this.detectedAt, this.suggestedAction, this.acknowledged = false, this.acknowledgedBy, this.acknowledgedAt});
  factory _RiskIndicator.fromJson(Map<String, dynamic> json) => _$RiskIndicatorFromJson(json);

/// Unique identifier
@override final  String id;
/// Type of indicator (risk, vip, neutral)
@override final  IndicatorType type;
/// Severity level
@override final  IndicatorSeverity severity;
/// Category of the indicator
@override final  String category;
/// Human-readable description
@override final  String description;
/// Confidence score from AI (0.0-1.0)
@override final  double confidence;
/// Source that triggered this indicator
@override final  SentimentSource source;
/// Reference to source document ID
@override final  String? sourceDocumentId;
/// Snippet of text that triggered this indicator
@override final  String? triggerText;
/// When this indicator was detected
@override final  DateTime detectedAt;
/// Suggested action to take
@override final  String? suggestedAction;
/// Whether this indicator has been acknowledged by staff
@override@JsonKey() final  bool acknowledged;
/// Staff member who acknowledged (if any)
@override final  String? acknowledgedBy;
/// When acknowledged
@override final  DateTime? acknowledgedAt;

/// Create a copy of RiskIndicator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskIndicatorCopyWith<_RiskIndicator> get copyWith => __$RiskIndicatorCopyWithImpl<_RiskIndicator>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiskIndicatorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskIndicator&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.triggerText, triggerText) || other.triggerText == triggerText)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&(identical(other.acknowledged, acknowledged) || other.acknowledged == acknowledged)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,severity,category,description,confidence,source,sourceDocumentId,triggerText,detectedAt,suggestedAction,acknowledged,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'RiskIndicator(id: $id, type: $type, severity: $severity, category: $category, description: $description, confidence: $confidence, source: $source, sourceDocumentId: $sourceDocumentId, triggerText: $triggerText, detectedAt: $detectedAt, suggestedAction: $suggestedAction, acknowledged: $acknowledged, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class _$RiskIndicatorCopyWith<$Res> implements $RiskIndicatorCopyWith<$Res> {
  factory _$RiskIndicatorCopyWith(_RiskIndicator value, $Res Function(_RiskIndicator) _then) = __$RiskIndicatorCopyWithImpl;
@override @useResult
$Res call({
 String id, IndicatorType type, IndicatorSeverity severity, String category, String description, double confidence, SentimentSource source, String? sourceDocumentId, String? triggerText, DateTime detectedAt, String? suggestedAction, bool acknowledged, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class __$RiskIndicatorCopyWithImpl<$Res>
    implements _$RiskIndicatorCopyWith<$Res> {
  __$RiskIndicatorCopyWithImpl(this._self, this._then);

  final _RiskIndicator _self;
  final $Res Function(_RiskIndicator) _then;

/// Create a copy of RiskIndicator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? severity = null,Object? category = null,Object? description = null,Object? confidence = null,Object? source = null,Object? sourceDocumentId = freezed,Object? triggerText = freezed,Object? detectedAt = null,Object? suggestedAction = freezed,Object? acknowledged = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_RiskIndicator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IndicatorType,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as IndicatorSeverity,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SentimentSource,sourceDocumentId: freezed == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as String?,triggerText: freezed == triggerText ? _self.triggerText : triggerText // ignore: cast_nullable_to_non_nullable
as String?,detectedAt: null == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,suggestedAction: freezed == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String?,acknowledged: null == acknowledged ? _self.acknowledged : acknowledged // ignore: cast_nullable_to_non_nullable
as bool,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
