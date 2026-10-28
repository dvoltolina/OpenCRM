// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sentiment_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SentimentResult {

/// Unique identifier for this analysis
 String get id;/// Business ID (multi-tenant)
 String get businessId;/// Client ID this text belongs to
 String get clientId;/// Source of the analyzed text
 SentimentSource get source;/// Reference to source document
 String? get sourceDocumentId;/// The text that was analyzed (truncated for storage)
 String get analyzedText;/// Overall sentiment score (-1.0 = very negative, 1.0 = very positive)
 double get sentimentScore;/// Confidence in the sentiment score (0.0-1.0)
 double get confidence;/// Detected risk indicators
 List<RiskIndicator> get riskIndicators;/// Detected VIP indicators
 List<RiskIndicator> get vipIndicators;/// AI-generated summary of the text sentiment
 String? get summary;/// Suggested action based on analysis
 String? get recommendedAction;/// Model version used for analysis
 String get modelVersion;/// When the analysis was performed
 DateTime get analyzedAt;/// When this result expires (for caching)
 DateTime get expiresAt;/// Processing time in milliseconds
 int? get processingTimeMs;
/// Create a copy of SentimentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SentimentResultCopyWith<SentimentResult> get copyWith => _$SentimentResultCopyWithImpl<SentimentResult>(this as SentimentResult, _$identity);

  /// Serializes this SentimentResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SentimentResult&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.analyzedText, analyzedText) || other.analyzedText == analyzedText)&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other.riskIndicators, riskIndicators)&&const DeepCollectionEquality().equals(other.vipIndicators, vipIndicators)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.recommendedAction, recommendedAction) || other.recommendedAction == recommendedAction)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.analyzedAt, analyzedAt) || other.analyzedAt == analyzedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,clientId,source,sourceDocumentId,analyzedText,sentimentScore,confidence,const DeepCollectionEquality().hash(riskIndicators),const DeepCollectionEquality().hash(vipIndicators),summary,recommendedAction,modelVersion,analyzedAt,expiresAt,processingTimeMs);

@override
String toString() {
  return 'SentimentResult(id: $id, businessId: $businessId, clientId: $clientId, source: $source, sourceDocumentId: $sourceDocumentId, analyzedText: $analyzedText, sentimentScore: $sentimentScore, confidence: $confidence, riskIndicators: $riskIndicators, vipIndicators: $vipIndicators, summary: $summary, recommendedAction: $recommendedAction, modelVersion: $modelVersion, analyzedAt: $analyzedAt, expiresAt: $expiresAt, processingTimeMs: $processingTimeMs)';
}


}

/// @nodoc
abstract mixin class $SentimentResultCopyWith<$Res>  {
  factory $SentimentResultCopyWith(SentimentResult value, $Res Function(SentimentResult) _then) = _$SentimentResultCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String clientId, SentimentSource source, String? sourceDocumentId, String analyzedText, double sentimentScore, double confidence, List<RiskIndicator> riskIndicators, List<RiskIndicator> vipIndicators, String? summary, String? recommendedAction, String modelVersion, DateTime analyzedAt, DateTime expiresAt, int? processingTimeMs
});




}
/// @nodoc
class _$SentimentResultCopyWithImpl<$Res>
    implements $SentimentResultCopyWith<$Res> {
  _$SentimentResultCopyWithImpl(this._self, this._then);

  final SentimentResult _self;
  final $Res Function(SentimentResult) _then;

/// Create a copy of SentimentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? source = null,Object? sourceDocumentId = freezed,Object? analyzedText = null,Object? sentimentScore = null,Object? confidence = null,Object? riskIndicators = null,Object? vipIndicators = null,Object? summary = freezed,Object? recommendedAction = freezed,Object? modelVersion = null,Object? analyzedAt = null,Object? expiresAt = null,Object? processingTimeMs = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SentimentSource,sourceDocumentId: freezed == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as String?,analyzedText: null == analyzedText ? _self.analyzedText : analyzedText // ignore: cast_nullable_to_non_nullable
as String,sentimentScore: null == sentimentScore ? _self.sentimentScore : sentimentScore // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,riskIndicators: null == riskIndicators ? _self.riskIndicators : riskIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,vipIndicators: null == vipIndicators ? _self.vipIndicators : vipIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,recommendedAction: freezed == recommendedAction ? _self.recommendedAction : recommendedAction // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,analyzedAt: null == analyzedAt ? _self.analyzedAt : analyzedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,processingTimeMs: freezed == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SentimentResult].
extension SentimentResultPatterns on SentimentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SentimentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SentimentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SentimentResult value)  $default,){
final _that = this;
switch (_that) {
case _SentimentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SentimentResult value)?  $default,){
final _that = this;
switch (_that) {
case _SentimentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  SentimentSource source,  String? sourceDocumentId,  String analyzedText,  double sentimentScore,  double confidence,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  String? summary,  String? recommendedAction,  String modelVersion,  DateTime analyzedAt,  DateTime expiresAt,  int? processingTimeMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SentimentResult() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.source,_that.sourceDocumentId,_that.analyzedText,_that.sentimentScore,_that.confidence,_that.riskIndicators,_that.vipIndicators,_that.summary,_that.recommendedAction,_that.modelVersion,_that.analyzedAt,_that.expiresAt,_that.processingTimeMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  SentimentSource source,  String? sourceDocumentId,  String analyzedText,  double sentimentScore,  double confidence,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  String? summary,  String? recommendedAction,  String modelVersion,  DateTime analyzedAt,  DateTime expiresAt,  int? processingTimeMs)  $default,) {final _that = this;
switch (_that) {
case _SentimentResult():
return $default(_that.id,_that.businessId,_that.clientId,_that.source,_that.sourceDocumentId,_that.analyzedText,_that.sentimentScore,_that.confidence,_that.riskIndicators,_that.vipIndicators,_that.summary,_that.recommendedAction,_that.modelVersion,_that.analyzedAt,_that.expiresAt,_that.processingTimeMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String clientId,  SentimentSource source,  String? sourceDocumentId,  String analyzedText,  double sentimentScore,  double confidence,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  String? summary,  String? recommendedAction,  String modelVersion,  DateTime analyzedAt,  DateTime expiresAt,  int? processingTimeMs)?  $default,) {final _that = this;
switch (_that) {
case _SentimentResult() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.source,_that.sourceDocumentId,_that.analyzedText,_that.sentimentScore,_that.confidence,_that.riskIndicators,_that.vipIndicators,_that.summary,_that.recommendedAction,_that.modelVersion,_that.analyzedAt,_that.expiresAt,_that.processingTimeMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SentimentResult implements SentimentResult {
  const _SentimentResult({required this.id, required this.businessId, required this.clientId, required this.source, this.sourceDocumentId, required this.analyzedText, required this.sentimentScore, required this.confidence, required final  List<RiskIndicator> riskIndicators, required final  List<RiskIndicator> vipIndicators, this.summary, this.recommendedAction, required this.modelVersion, required this.analyzedAt, required this.expiresAt, this.processingTimeMs}): _riskIndicators = riskIndicators,_vipIndicators = vipIndicators;
  factory _SentimentResult.fromJson(Map<String, dynamic> json) => _$SentimentResultFromJson(json);

/// Unique identifier for this analysis
@override final  String id;
/// Business ID (multi-tenant)
@override final  String businessId;
/// Client ID this text belongs to
@override final  String clientId;
/// Source of the analyzed text
@override final  SentimentSource source;
/// Reference to source document
@override final  String? sourceDocumentId;
/// The text that was analyzed (truncated for storage)
@override final  String analyzedText;
/// Overall sentiment score (-1.0 = very negative, 1.0 = very positive)
@override final  double sentimentScore;
/// Confidence in the sentiment score (0.0-1.0)
@override final  double confidence;
/// Detected risk indicators
 final  List<RiskIndicator> _riskIndicators;
/// Detected risk indicators
@override List<RiskIndicator> get riskIndicators {
  if (_riskIndicators is EqualUnmodifiableListView) return _riskIndicators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_riskIndicators);
}

/// Detected VIP indicators
 final  List<RiskIndicator> _vipIndicators;
/// Detected VIP indicators
@override List<RiskIndicator> get vipIndicators {
  if (_vipIndicators is EqualUnmodifiableListView) return _vipIndicators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vipIndicators);
}

/// AI-generated summary of the text sentiment
@override final  String? summary;
/// Suggested action based on analysis
@override final  String? recommendedAction;
/// Model version used for analysis
@override final  String modelVersion;
/// When the analysis was performed
@override final  DateTime analyzedAt;
/// When this result expires (for caching)
@override final  DateTime expiresAt;
/// Processing time in milliseconds
@override final  int? processingTimeMs;

/// Create a copy of SentimentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SentimentResultCopyWith<_SentimentResult> get copyWith => __$SentimentResultCopyWithImpl<_SentimentResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SentimentResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SentimentResult&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.analyzedText, analyzedText) || other.analyzedText == analyzedText)&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other._riskIndicators, _riskIndicators)&&const DeepCollectionEquality().equals(other._vipIndicators, _vipIndicators)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.recommendedAction, recommendedAction) || other.recommendedAction == recommendedAction)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.analyzedAt, analyzedAt) || other.analyzedAt == analyzedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,clientId,source,sourceDocumentId,analyzedText,sentimentScore,confidence,const DeepCollectionEquality().hash(_riskIndicators),const DeepCollectionEquality().hash(_vipIndicators),summary,recommendedAction,modelVersion,analyzedAt,expiresAt,processingTimeMs);

@override
String toString() {
  return 'SentimentResult(id: $id, businessId: $businessId, clientId: $clientId, source: $source, sourceDocumentId: $sourceDocumentId, analyzedText: $analyzedText, sentimentScore: $sentimentScore, confidence: $confidence, riskIndicators: $riskIndicators, vipIndicators: $vipIndicators, summary: $summary, recommendedAction: $recommendedAction, modelVersion: $modelVersion, analyzedAt: $analyzedAt, expiresAt: $expiresAt, processingTimeMs: $processingTimeMs)';
}


}

/// @nodoc
abstract mixin class _$SentimentResultCopyWith<$Res> implements $SentimentResultCopyWith<$Res> {
  factory _$SentimentResultCopyWith(_SentimentResult value, $Res Function(_SentimentResult) _then) = __$SentimentResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String clientId, SentimentSource source, String? sourceDocumentId, String analyzedText, double sentimentScore, double confidence, List<RiskIndicator> riskIndicators, List<RiskIndicator> vipIndicators, String? summary, String? recommendedAction, String modelVersion, DateTime analyzedAt, DateTime expiresAt, int? processingTimeMs
});




}
/// @nodoc
class __$SentimentResultCopyWithImpl<$Res>
    implements _$SentimentResultCopyWith<$Res> {
  __$SentimentResultCopyWithImpl(this._self, this._then);

  final _SentimentResult _self;
  final $Res Function(_SentimentResult) _then;

/// Create a copy of SentimentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? source = null,Object? sourceDocumentId = freezed,Object? analyzedText = null,Object? sentimentScore = null,Object? confidence = null,Object? riskIndicators = null,Object? vipIndicators = null,Object? summary = freezed,Object? recommendedAction = freezed,Object? modelVersion = null,Object? analyzedAt = null,Object? expiresAt = null,Object? processingTimeMs = freezed,}) {
  return _then(_SentimentResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SentimentSource,sourceDocumentId: freezed == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as String?,analyzedText: null == analyzedText ? _self.analyzedText : analyzedText // ignore: cast_nullable_to_non_nullable
as String,sentimentScore: null == sentimentScore ? _self.sentimentScore : sentimentScore // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,riskIndicators: null == riskIndicators ? _self._riskIndicators : riskIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,vipIndicators: null == vipIndicators ? _self._vipIndicators : vipIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,recommendedAction: freezed == recommendedAction ? _self.recommendedAction : recommendedAction // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,analyzedAt: null == analyzedAt ? _self.analyzedAt : analyzedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,processingTimeMs: freezed == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
