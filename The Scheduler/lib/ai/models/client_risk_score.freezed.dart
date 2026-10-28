// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_risk_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecommendedClientAction {

 String get actionId; String get title; String get description; ClientActionPriority get priority; String get reasoning; bool get automatable; String? get automationRuleId;
/// Create a copy of RecommendedClientAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendedClientActionCopyWith<RecommendedClientAction> get copyWith => _$RecommendedClientActionCopyWithImpl<RecommendedClientAction>(this as RecommendedClientAction, _$identity);

  /// Serializes this RecommendedClientAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendedClientAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.automatable, automatable) || other.automatable == automatable)&&(identical(other.automationRuleId, automationRuleId) || other.automationRuleId == automationRuleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,title,description,priority,reasoning,automatable,automationRuleId);

@override
String toString() {
  return 'RecommendedClientAction(actionId: $actionId, title: $title, description: $description, priority: $priority, reasoning: $reasoning, automatable: $automatable, automationRuleId: $automationRuleId)';
}


}

/// @nodoc
abstract mixin class $RecommendedClientActionCopyWith<$Res>  {
  factory $RecommendedClientActionCopyWith(RecommendedClientAction value, $Res Function(RecommendedClientAction) _then) = _$RecommendedClientActionCopyWithImpl;
@useResult
$Res call({
 String actionId, String title, String description, ClientActionPriority priority, String reasoning, bool automatable, String? automationRuleId
});




}
/// @nodoc
class _$RecommendedClientActionCopyWithImpl<$Res>
    implements $RecommendedClientActionCopyWith<$Res> {
  _$RecommendedClientActionCopyWithImpl(this._self, this._then);

  final RecommendedClientAction _self;
  final $Res Function(RecommendedClientAction) _then;

/// Create a copy of RecommendedClientAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionId = null,Object? title = null,Object? description = null,Object? priority = null,Object? reasoning = null,Object? automatable = null,Object? automationRuleId = freezed,}) {
  return _then(_self.copyWith(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as ClientActionPriority,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,automatable: null == automatable ? _self.automatable : automatable // ignore: cast_nullable_to_non_nullable
as bool,automationRuleId: freezed == automationRuleId ? _self.automationRuleId : automationRuleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendedClientAction].
extension RecommendedClientActionPatterns on RecommendedClientAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendedClientAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendedClientAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendedClientAction value)  $default,){
final _that = this;
switch (_that) {
case _RecommendedClientAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendedClientAction value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendedClientAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String actionId,  String title,  String description,  ClientActionPriority priority,  String reasoning,  bool automatable,  String? automationRuleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendedClientAction() when $default != null:
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.reasoning,_that.automatable,_that.automationRuleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String actionId,  String title,  String description,  ClientActionPriority priority,  String reasoning,  bool automatable,  String? automationRuleId)  $default,) {final _that = this;
switch (_that) {
case _RecommendedClientAction():
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.reasoning,_that.automatable,_that.automationRuleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String actionId,  String title,  String description,  ClientActionPriority priority,  String reasoning,  bool automatable,  String? automationRuleId)?  $default,) {final _that = this;
switch (_that) {
case _RecommendedClientAction() when $default != null:
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.reasoning,_that.automatable,_that.automationRuleId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendedClientAction implements RecommendedClientAction {
  const _RecommendedClientAction({required this.actionId, required this.title, required this.description, required this.priority, required this.reasoning, required this.automatable, this.automationRuleId});
  factory _RecommendedClientAction.fromJson(Map<String, dynamic> json) => _$RecommendedClientActionFromJson(json);

@override final  String actionId;
@override final  String title;
@override final  String description;
@override final  ClientActionPriority priority;
@override final  String reasoning;
@override final  bool automatable;
@override final  String? automationRuleId;

/// Create a copy of RecommendedClientAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendedClientActionCopyWith<_RecommendedClientAction> get copyWith => __$RecommendedClientActionCopyWithImpl<_RecommendedClientAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendedClientActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendedClientAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.automatable, automatable) || other.automatable == automatable)&&(identical(other.automationRuleId, automationRuleId) || other.automationRuleId == automationRuleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,title,description,priority,reasoning,automatable,automationRuleId);

@override
String toString() {
  return 'RecommendedClientAction(actionId: $actionId, title: $title, description: $description, priority: $priority, reasoning: $reasoning, automatable: $automatable, automationRuleId: $automationRuleId)';
}


}

/// @nodoc
abstract mixin class _$RecommendedClientActionCopyWith<$Res> implements $RecommendedClientActionCopyWith<$Res> {
  factory _$RecommendedClientActionCopyWith(_RecommendedClientAction value, $Res Function(_RecommendedClientAction) _then) = __$RecommendedClientActionCopyWithImpl;
@override @useResult
$Res call({
 String actionId, String title, String description, ClientActionPriority priority, String reasoning, bool automatable, String? automationRuleId
});




}
/// @nodoc
class __$RecommendedClientActionCopyWithImpl<$Res>
    implements _$RecommendedClientActionCopyWith<$Res> {
  __$RecommendedClientActionCopyWithImpl(this._self, this._then);

  final _RecommendedClientAction _self;
  final $Res Function(_RecommendedClientAction) _then;

/// Create a copy of RecommendedClientAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionId = null,Object? title = null,Object? description = null,Object? priority = null,Object? reasoning = null,Object? automatable = null,Object? automationRuleId = freezed,}) {
  return _then(_RecommendedClientAction(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as ClientActionPriority,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,automatable: null == automatable ? _self.automatable : automatable // ignore: cast_nullable_to_non_nullable
as bool,automationRuleId: freezed == automationRuleId ? _self.automationRuleId : automationRuleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ClientRiskScore {

/// Unique identifier
 String get id;/// Client this score belongs to
 String get clientId;/// Business ID (multi-tenant)
 String get businessId;/// When this score was calculated
 DateTime get calculatedAt;// ============ Core Scores (0-100) ============
/// Churn risk score (0 = no risk, 100 = high risk)
 int get churnRiskScore;/// Satisfaction score (0 = unsatisfied, 100 = very satisfied)
 int get satisfactionScore;/// VIP score (0 = regular, 100 = high-value advocate)
 int get vipScore;/// Overall health score (composite)
 int get overallHealthScore;// ============ Trends ============
/// Trend for churn risk
 ScoreTrend get churnTrend;/// Trend for satisfaction
 ScoreTrend get satisfactionTrend;/// Trend for VIP score
 ScoreTrend get vipTrend;/// Change in churn score from last calculation
 int get churnScoreChange;/// Change in satisfaction score from last calculation
 int get satisfactionScoreChange;// ============ Indicators ============
/// All risk indicators contributing to score
 List<RiskIndicator> get riskIndicators;/// All VIP indicators contributing to score
 List<RiskIndicator> get vipIndicators;/// Top risk factors (most impactful)
 List<String> get topRiskFactors;/// Top VIP factors (most impactful)
 List<String> get topVipFactors;// ============ Analysis Metadata ============
/// Number of texts analyzed for this score
 int get textsAnalyzed;/// Date range of analyzed communications
 DateTime get analysisStartDate; DateTime get analysisEndDate;/// Average sentiment across all analyzed texts
 double get averageSentiment;/// Sentiment standard deviation (consistency)
 double get sentimentStdDev;// ============ Recommendations ============
/// Recommended actions based on analysis
 List<RecommendedClientAction> get recommendedActions;// ============ Behavioral Signals ============
/// Recent no-show count (factored into churn risk)
 int get recentNoshowCount;/// Recent cancellation count
 int get recentCancellationCount;/// Days since last visit
 int get daysSinceLastVisit;/// Visit frequency trend (increasing, stable, decreasing)
 ScoreTrend? get visitFrequencyTrend;// ============ Model Info ============
/// Version of scoring algorithm used
 String get scoringVersion;/// When this score expires
 DateTime get expiresAt;
/// Create a copy of ClientRiskScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientRiskScoreCopyWith<ClientRiskScore> get copyWith => _$ClientRiskScoreCopyWithImpl<ClientRiskScore>(this as ClientRiskScore, _$identity);

  /// Serializes this ClientRiskScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientRiskScore&&(identical(other.id, id) || other.id == id)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.churnRiskScore, churnRiskScore) || other.churnRiskScore == churnRiskScore)&&(identical(other.satisfactionScore, satisfactionScore) || other.satisfactionScore == satisfactionScore)&&(identical(other.vipScore, vipScore) || other.vipScore == vipScore)&&(identical(other.overallHealthScore, overallHealthScore) || other.overallHealthScore == overallHealthScore)&&(identical(other.churnTrend, churnTrend) || other.churnTrend == churnTrend)&&(identical(other.satisfactionTrend, satisfactionTrend) || other.satisfactionTrend == satisfactionTrend)&&(identical(other.vipTrend, vipTrend) || other.vipTrend == vipTrend)&&(identical(other.churnScoreChange, churnScoreChange) || other.churnScoreChange == churnScoreChange)&&(identical(other.satisfactionScoreChange, satisfactionScoreChange) || other.satisfactionScoreChange == satisfactionScoreChange)&&const DeepCollectionEquality().equals(other.riskIndicators, riskIndicators)&&const DeepCollectionEquality().equals(other.vipIndicators, vipIndicators)&&const DeepCollectionEquality().equals(other.topRiskFactors, topRiskFactors)&&const DeepCollectionEquality().equals(other.topVipFactors, topVipFactors)&&(identical(other.textsAnalyzed, textsAnalyzed) || other.textsAnalyzed == textsAnalyzed)&&(identical(other.analysisStartDate, analysisStartDate) || other.analysisStartDate == analysisStartDate)&&(identical(other.analysisEndDate, analysisEndDate) || other.analysisEndDate == analysisEndDate)&&(identical(other.averageSentiment, averageSentiment) || other.averageSentiment == averageSentiment)&&(identical(other.sentimentStdDev, sentimentStdDev) || other.sentimentStdDev == sentimentStdDev)&&const DeepCollectionEquality().equals(other.recommendedActions, recommendedActions)&&(identical(other.recentNoshowCount, recentNoshowCount) || other.recentNoshowCount == recentNoshowCount)&&(identical(other.recentCancellationCount, recentCancellationCount) || other.recentCancellationCount == recentCancellationCount)&&(identical(other.daysSinceLastVisit, daysSinceLastVisit) || other.daysSinceLastVisit == daysSinceLastVisit)&&(identical(other.visitFrequencyTrend, visitFrequencyTrend) || other.visitFrequencyTrend == visitFrequencyTrend)&&(identical(other.scoringVersion, scoringVersion) || other.scoringVersion == scoringVersion)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,clientId,businessId,calculatedAt,churnRiskScore,satisfactionScore,vipScore,overallHealthScore,churnTrend,satisfactionTrend,vipTrend,churnScoreChange,satisfactionScoreChange,const DeepCollectionEquality().hash(riskIndicators),const DeepCollectionEquality().hash(vipIndicators),const DeepCollectionEquality().hash(topRiskFactors),const DeepCollectionEquality().hash(topVipFactors),textsAnalyzed,analysisStartDate,analysisEndDate,averageSentiment,sentimentStdDev,const DeepCollectionEquality().hash(recommendedActions),recentNoshowCount,recentCancellationCount,daysSinceLastVisit,visitFrequencyTrend,scoringVersion,expiresAt]);

@override
String toString() {
  return 'ClientRiskScore(id: $id, clientId: $clientId, businessId: $businessId, calculatedAt: $calculatedAt, churnRiskScore: $churnRiskScore, satisfactionScore: $satisfactionScore, vipScore: $vipScore, overallHealthScore: $overallHealthScore, churnTrend: $churnTrend, satisfactionTrend: $satisfactionTrend, vipTrend: $vipTrend, churnScoreChange: $churnScoreChange, satisfactionScoreChange: $satisfactionScoreChange, riskIndicators: $riskIndicators, vipIndicators: $vipIndicators, topRiskFactors: $topRiskFactors, topVipFactors: $topVipFactors, textsAnalyzed: $textsAnalyzed, analysisStartDate: $analysisStartDate, analysisEndDate: $analysisEndDate, averageSentiment: $averageSentiment, sentimentStdDev: $sentimentStdDev, recommendedActions: $recommendedActions, recentNoshowCount: $recentNoshowCount, recentCancellationCount: $recentCancellationCount, daysSinceLastVisit: $daysSinceLastVisit, visitFrequencyTrend: $visitFrequencyTrend, scoringVersion: $scoringVersion, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ClientRiskScoreCopyWith<$Res>  {
  factory $ClientRiskScoreCopyWith(ClientRiskScore value, $Res Function(ClientRiskScore) _then) = _$ClientRiskScoreCopyWithImpl;
@useResult
$Res call({
 String id, String clientId, String businessId, DateTime calculatedAt, int churnRiskScore, int satisfactionScore, int vipScore, int overallHealthScore, ScoreTrend churnTrend, ScoreTrend satisfactionTrend, ScoreTrend vipTrend, int churnScoreChange, int satisfactionScoreChange, List<RiskIndicator> riskIndicators, List<RiskIndicator> vipIndicators, List<String> topRiskFactors, List<String> topVipFactors, int textsAnalyzed, DateTime analysisStartDate, DateTime analysisEndDate, double averageSentiment, double sentimentStdDev, List<RecommendedClientAction> recommendedActions, int recentNoshowCount, int recentCancellationCount, int daysSinceLastVisit, ScoreTrend? visitFrequencyTrend, String scoringVersion, DateTime expiresAt
});




}
/// @nodoc
class _$ClientRiskScoreCopyWithImpl<$Res>
    implements $ClientRiskScoreCopyWith<$Res> {
  _$ClientRiskScoreCopyWithImpl(this._self, this._then);

  final ClientRiskScore _self;
  final $Res Function(ClientRiskScore) _then;

/// Create a copy of ClientRiskScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clientId = null,Object? businessId = null,Object? calculatedAt = null,Object? churnRiskScore = null,Object? satisfactionScore = null,Object? vipScore = null,Object? overallHealthScore = null,Object? churnTrend = null,Object? satisfactionTrend = null,Object? vipTrend = null,Object? churnScoreChange = null,Object? satisfactionScoreChange = null,Object? riskIndicators = null,Object? vipIndicators = null,Object? topRiskFactors = null,Object? topVipFactors = null,Object? textsAnalyzed = null,Object? analysisStartDate = null,Object? analysisEndDate = null,Object? averageSentiment = null,Object? sentimentStdDev = null,Object? recommendedActions = null,Object? recentNoshowCount = null,Object? recentCancellationCount = null,Object? daysSinceLastVisit = null,Object? visitFrequencyTrend = freezed,Object? scoringVersion = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,churnRiskScore: null == churnRiskScore ? _self.churnRiskScore : churnRiskScore // ignore: cast_nullable_to_non_nullable
as int,satisfactionScore: null == satisfactionScore ? _self.satisfactionScore : satisfactionScore // ignore: cast_nullable_to_non_nullable
as int,vipScore: null == vipScore ? _self.vipScore : vipScore // ignore: cast_nullable_to_non_nullable
as int,overallHealthScore: null == overallHealthScore ? _self.overallHealthScore : overallHealthScore // ignore: cast_nullable_to_non_nullable
as int,churnTrend: null == churnTrend ? _self.churnTrend : churnTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,satisfactionTrend: null == satisfactionTrend ? _self.satisfactionTrend : satisfactionTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,vipTrend: null == vipTrend ? _self.vipTrend : vipTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,churnScoreChange: null == churnScoreChange ? _self.churnScoreChange : churnScoreChange // ignore: cast_nullable_to_non_nullable
as int,satisfactionScoreChange: null == satisfactionScoreChange ? _self.satisfactionScoreChange : satisfactionScoreChange // ignore: cast_nullable_to_non_nullable
as int,riskIndicators: null == riskIndicators ? _self.riskIndicators : riskIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,vipIndicators: null == vipIndicators ? _self.vipIndicators : vipIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,topRiskFactors: null == topRiskFactors ? _self.topRiskFactors : topRiskFactors // ignore: cast_nullable_to_non_nullable
as List<String>,topVipFactors: null == topVipFactors ? _self.topVipFactors : topVipFactors // ignore: cast_nullable_to_non_nullable
as List<String>,textsAnalyzed: null == textsAnalyzed ? _self.textsAnalyzed : textsAnalyzed // ignore: cast_nullable_to_non_nullable
as int,analysisStartDate: null == analysisStartDate ? _self.analysisStartDate : analysisStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,analysisEndDate: null == analysisEndDate ? _self.analysisEndDate : analysisEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,averageSentiment: null == averageSentiment ? _self.averageSentiment : averageSentiment // ignore: cast_nullable_to_non_nullable
as double,sentimentStdDev: null == sentimentStdDev ? _self.sentimentStdDev : sentimentStdDev // ignore: cast_nullable_to_non_nullable
as double,recommendedActions: null == recommendedActions ? _self.recommendedActions : recommendedActions // ignore: cast_nullable_to_non_nullable
as List<RecommendedClientAction>,recentNoshowCount: null == recentNoshowCount ? _self.recentNoshowCount : recentNoshowCount // ignore: cast_nullable_to_non_nullable
as int,recentCancellationCount: null == recentCancellationCount ? _self.recentCancellationCount : recentCancellationCount // ignore: cast_nullable_to_non_nullable
as int,daysSinceLastVisit: null == daysSinceLastVisit ? _self.daysSinceLastVisit : daysSinceLastVisit // ignore: cast_nullable_to_non_nullable
as int,visitFrequencyTrend: freezed == visitFrequencyTrend ? _self.visitFrequencyTrend : visitFrequencyTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend?,scoringVersion: null == scoringVersion ? _self.scoringVersion : scoringVersion // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientRiskScore].
extension ClientRiskScorePatterns on ClientRiskScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientRiskScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientRiskScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientRiskScore value)  $default,){
final _that = this;
switch (_that) {
case _ClientRiskScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientRiskScore value)?  $default,){
final _that = this;
switch (_that) {
case _ClientRiskScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clientId,  String businessId,  DateTime calculatedAt,  int churnRiskScore,  int satisfactionScore,  int vipScore,  int overallHealthScore,  ScoreTrend churnTrend,  ScoreTrend satisfactionTrend,  ScoreTrend vipTrend,  int churnScoreChange,  int satisfactionScoreChange,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  List<String> topRiskFactors,  List<String> topVipFactors,  int textsAnalyzed,  DateTime analysisStartDate,  DateTime analysisEndDate,  double averageSentiment,  double sentimentStdDev,  List<RecommendedClientAction> recommendedActions,  int recentNoshowCount,  int recentCancellationCount,  int daysSinceLastVisit,  ScoreTrend? visitFrequencyTrend,  String scoringVersion,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientRiskScore() when $default != null:
return $default(_that.id,_that.clientId,_that.businessId,_that.calculatedAt,_that.churnRiskScore,_that.satisfactionScore,_that.vipScore,_that.overallHealthScore,_that.churnTrend,_that.satisfactionTrend,_that.vipTrend,_that.churnScoreChange,_that.satisfactionScoreChange,_that.riskIndicators,_that.vipIndicators,_that.topRiskFactors,_that.topVipFactors,_that.textsAnalyzed,_that.analysisStartDate,_that.analysisEndDate,_that.averageSentiment,_that.sentimentStdDev,_that.recommendedActions,_that.recentNoshowCount,_that.recentCancellationCount,_that.daysSinceLastVisit,_that.visitFrequencyTrend,_that.scoringVersion,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clientId,  String businessId,  DateTime calculatedAt,  int churnRiskScore,  int satisfactionScore,  int vipScore,  int overallHealthScore,  ScoreTrend churnTrend,  ScoreTrend satisfactionTrend,  ScoreTrend vipTrend,  int churnScoreChange,  int satisfactionScoreChange,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  List<String> topRiskFactors,  List<String> topVipFactors,  int textsAnalyzed,  DateTime analysisStartDate,  DateTime analysisEndDate,  double averageSentiment,  double sentimentStdDev,  List<RecommendedClientAction> recommendedActions,  int recentNoshowCount,  int recentCancellationCount,  int daysSinceLastVisit,  ScoreTrend? visitFrequencyTrend,  String scoringVersion,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ClientRiskScore():
return $default(_that.id,_that.clientId,_that.businessId,_that.calculatedAt,_that.churnRiskScore,_that.satisfactionScore,_that.vipScore,_that.overallHealthScore,_that.churnTrend,_that.satisfactionTrend,_that.vipTrend,_that.churnScoreChange,_that.satisfactionScoreChange,_that.riskIndicators,_that.vipIndicators,_that.topRiskFactors,_that.topVipFactors,_that.textsAnalyzed,_that.analysisStartDate,_that.analysisEndDate,_that.averageSentiment,_that.sentimentStdDev,_that.recommendedActions,_that.recentNoshowCount,_that.recentCancellationCount,_that.daysSinceLastVisit,_that.visitFrequencyTrend,_that.scoringVersion,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clientId,  String businessId,  DateTime calculatedAt,  int churnRiskScore,  int satisfactionScore,  int vipScore,  int overallHealthScore,  ScoreTrend churnTrend,  ScoreTrend satisfactionTrend,  ScoreTrend vipTrend,  int churnScoreChange,  int satisfactionScoreChange,  List<RiskIndicator> riskIndicators,  List<RiskIndicator> vipIndicators,  List<String> topRiskFactors,  List<String> topVipFactors,  int textsAnalyzed,  DateTime analysisStartDate,  DateTime analysisEndDate,  double averageSentiment,  double sentimentStdDev,  List<RecommendedClientAction> recommendedActions,  int recentNoshowCount,  int recentCancellationCount,  int daysSinceLastVisit,  ScoreTrend? visitFrequencyTrend,  String scoringVersion,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ClientRiskScore() when $default != null:
return $default(_that.id,_that.clientId,_that.businessId,_that.calculatedAt,_that.churnRiskScore,_that.satisfactionScore,_that.vipScore,_that.overallHealthScore,_that.churnTrend,_that.satisfactionTrend,_that.vipTrend,_that.churnScoreChange,_that.satisfactionScoreChange,_that.riskIndicators,_that.vipIndicators,_that.topRiskFactors,_that.topVipFactors,_that.textsAnalyzed,_that.analysisStartDate,_that.analysisEndDate,_that.averageSentiment,_that.sentimentStdDev,_that.recommendedActions,_that.recentNoshowCount,_that.recentCancellationCount,_that.daysSinceLastVisit,_that.visitFrequencyTrend,_that.scoringVersion,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientRiskScore implements ClientRiskScore {
  const _ClientRiskScore({required this.id, required this.clientId, required this.businessId, required this.calculatedAt, required this.churnRiskScore, required this.satisfactionScore, required this.vipScore, required this.overallHealthScore, required this.churnTrend, required this.satisfactionTrend, required this.vipTrend, this.churnScoreChange = 0, this.satisfactionScoreChange = 0, required final  List<RiskIndicator> riskIndicators, required final  List<RiskIndicator> vipIndicators, final  List<String> topRiskFactors = const [], final  List<String> topVipFactors = const [], required this.textsAnalyzed, required this.analysisStartDate, required this.analysisEndDate, required this.averageSentiment, required this.sentimentStdDev, final  List<RecommendedClientAction> recommendedActions = const [], this.recentNoshowCount = 0, this.recentCancellationCount = 0, this.daysSinceLastVisit = 0, this.visitFrequencyTrend, required this.scoringVersion, required this.expiresAt}): _riskIndicators = riskIndicators,_vipIndicators = vipIndicators,_topRiskFactors = topRiskFactors,_topVipFactors = topVipFactors,_recommendedActions = recommendedActions;
  factory _ClientRiskScore.fromJson(Map<String, dynamic> json) => _$ClientRiskScoreFromJson(json);

/// Unique identifier
@override final  String id;
/// Client this score belongs to
@override final  String clientId;
/// Business ID (multi-tenant)
@override final  String businessId;
/// When this score was calculated
@override final  DateTime calculatedAt;
// ============ Core Scores (0-100) ============
/// Churn risk score (0 = no risk, 100 = high risk)
@override final  int churnRiskScore;
/// Satisfaction score (0 = unsatisfied, 100 = very satisfied)
@override final  int satisfactionScore;
/// VIP score (0 = regular, 100 = high-value advocate)
@override final  int vipScore;
/// Overall health score (composite)
@override final  int overallHealthScore;
// ============ Trends ============
/// Trend for churn risk
@override final  ScoreTrend churnTrend;
/// Trend for satisfaction
@override final  ScoreTrend satisfactionTrend;
/// Trend for VIP score
@override final  ScoreTrend vipTrend;
/// Change in churn score from last calculation
@override@JsonKey() final  int churnScoreChange;
/// Change in satisfaction score from last calculation
@override@JsonKey() final  int satisfactionScoreChange;
// ============ Indicators ============
/// All risk indicators contributing to score
 final  List<RiskIndicator> _riskIndicators;
// ============ Indicators ============
/// All risk indicators contributing to score
@override List<RiskIndicator> get riskIndicators {
  if (_riskIndicators is EqualUnmodifiableListView) return _riskIndicators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_riskIndicators);
}

/// All VIP indicators contributing to score
 final  List<RiskIndicator> _vipIndicators;
/// All VIP indicators contributing to score
@override List<RiskIndicator> get vipIndicators {
  if (_vipIndicators is EqualUnmodifiableListView) return _vipIndicators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vipIndicators);
}

/// Top risk factors (most impactful)
 final  List<String> _topRiskFactors;
/// Top risk factors (most impactful)
@override@JsonKey() List<String> get topRiskFactors {
  if (_topRiskFactors is EqualUnmodifiableListView) return _topRiskFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topRiskFactors);
}

/// Top VIP factors (most impactful)
 final  List<String> _topVipFactors;
/// Top VIP factors (most impactful)
@override@JsonKey() List<String> get topVipFactors {
  if (_topVipFactors is EqualUnmodifiableListView) return _topVipFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topVipFactors);
}

// ============ Analysis Metadata ============
/// Number of texts analyzed for this score
@override final  int textsAnalyzed;
/// Date range of analyzed communications
@override final  DateTime analysisStartDate;
@override final  DateTime analysisEndDate;
/// Average sentiment across all analyzed texts
@override final  double averageSentiment;
/// Sentiment standard deviation (consistency)
@override final  double sentimentStdDev;
// ============ Recommendations ============
/// Recommended actions based on analysis
 final  List<RecommendedClientAction> _recommendedActions;
// ============ Recommendations ============
/// Recommended actions based on analysis
@override@JsonKey() List<RecommendedClientAction> get recommendedActions {
  if (_recommendedActions is EqualUnmodifiableListView) return _recommendedActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendedActions);
}

// ============ Behavioral Signals ============
/// Recent no-show count (factored into churn risk)
@override@JsonKey() final  int recentNoshowCount;
/// Recent cancellation count
@override@JsonKey() final  int recentCancellationCount;
/// Days since last visit
@override@JsonKey() final  int daysSinceLastVisit;
/// Visit frequency trend (increasing, stable, decreasing)
@override final  ScoreTrend? visitFrequencyTrend;
// ============ Model Info ============
/// Version of scoring algorithm used
@override final  String scoringVersion;
/// When this score expires
@override final  DateTime expiresAt;

/// Create a copy of ClientRiskScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientRiskScoreCopyWith<_ClientRiskScore> get copyWith => __$ClientRiskScoreCopyWithImpl<_ClientRiskScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientRiskScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientRiskScore&&(identical(other.id, id) || other.id == id)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.churnRiskScore, churnRiskScore) || other.churnRiskScore == churnRiskScore)&&(identical(other.satisfactionScore, satisfactionScore) || other.satisfactionScore == satisfactionScore)&&(identical(other.vipScore, vipScore) || other.vipScore == vipScore)&&(identical(other.overallHealthScore, overallHealthScore) || other.overallHealthScore == overallHealthScore)&&(identical(other.churnTrend, churnTrend) || other.churnTrend == churnTrend)&&(identical(other.satisfactionTrend, satisfactionTrend) || other.satisfactionTrend == satisfactionTrend)&&(identical(other.vipTrend, vipTrend) || other.vipTrend == vipTrend)&&(identical(other.churnScoreChange, churnScoreChange) || other.churnScoreChange == churnScoreChange)&&(identical(other.satisfactionScoreChange, satisfactionScoreChange) || other.satisfactionScoreChange == satisfactionScoreChange)&&const DeepCollectionEquality().equals(other._riskIndicators, _riskIndicators)&&const DeepCollectionEquality().equals(other._vipIndicators, _vipIndicators)&&const DeepCollectionEquality().equals(other._topRiskFactors, _topRiskFactors)&&const DeepCollectionEquality().equals(other._topVipFactors, _topVipFactors)&&(identical(other.textsAnalyzed, textsAnalyzed) || other.textsAnalyzed == textsAnalyzed)&&(identical(other.analysisStartDate, analysisStartDate) || other.analysisStartDate == analysisStartDate)&&(identical(other.analysisEndDate, analysisEndDate) || other.analysisEndDate == analysisEndDate)&&(identical(other.averageSentiment, averageSentiment) || other.averageSentiment == averageSentiment)&&(identical(other.sentimentStdDev, sentimentStdDev) || other.sentimentStdDev == sentimentStdDev)&&const DeepCollectionEquality().equals(other._recommendedActions, _recommendedActions)&&(identical(other.recentNoshowCount, recentNoshowCount) || other.recentNoshowCount == recentNoshowCount)&&(identical(other.recentCancellationCount, recentCancellationCount) || other.recentCancellationCount == recentCancellationCount)&&(identical(other.daysSinceLastVisit, daysSinceLastVisit) || other.daysSinceLastVisit == daysSinceLastVisit)&&(identical(other.visitFrequencyTrend, visitFrequencyTrend) || other.visitFrequencyTrend == visitFrequencyTrend)&&(identical(other.scoringVersion, scoringVersion) || other.scoringVersion == scoringVersion)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,clientId,businessId,calculatedAt,churnRiskScore,satisfactionScore,vipScore,overallHealthScore,churnTrend,satisfactionTrend,vipTrend,churnScoreChange,satisfactionScoreChange,const DeepCollectionEquality().hash(_riskIndicators),const DeepCollectionEquality().hash(_vipIndicators),const DeepCollectionEquality().hash(_topRiskFactors),const DeepCollectionEquality().hash(_topVipFactors),textsAnalyzed,analysisStartDate,analysisEndDate,averageSentiment,sentimentStdDev,const DeepCollectionEquality().hash(_recommendedActions),recentNoshowCount,recentCancellationCount,daysSinceLastVisit,visitFrequencyTrend,scoringVersion,expiresAt]);

@override
String toString() {
  return 'ClientRiskScore(id: $id, clientId: $clientId, businessId: $businessId, calculatedAt: $calculatedAt, churnRiskScore: $churnRiskScore, satisfactionScore: $satisfactionScore, vipScore: $vipScore, overallHealthScore: $overallHealthScore, churnTrend: $churnTrend, satisfactionTrend: $satisfactionTrend, vipTrend: $vipTrend, churnScoreChange: $churnScoreChange, satisfactionScoreChange: $satisfactionScoreChange, riskIndicators: $riskIndicators, vipIndicators: $vipIndicators, topRiskFactors: $topRiskFactors, topVipFactors: $topVipFactors, textsAnalyzed: $textsAnalyzed, analysisStartDate: $analysisStartDate, analysisEndDate: $analysisEndDate, averageSentiment: $averageSentiment, sentimentStdDev: $sentimentStdDev, recommendedActions: $recommendedActions, recentNoshowCount: $recentNoshowCount, recentCancellationCount: $recentCancellationCount, daysSinceLastVisit: $daysSinceLastVisit, visitFrequencyTrend: $visitFrequencyTrend, scoringVersion: $scoringVersion, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ClientRiskScoreCopyWith<$Res> implements $ClientRiskScoreCopyWith<$Res> {
  factory _$ClientRiskScoreCopyWith(_ClientRiskScore value, $Res Function(_ClientRiskScore) _then) = __$ClientRiskScoreCopyWithImpl;
@override @useResult
$Res call({
 String id, String clientId, String businessId, DateTime calculatedAt, int churnRiskScore, int satisfactionScore, int vipScore, int overallHealthScore, ScoreTrend churnTrend, ScoreTrend satisfactionTrend, ScoreTrend vipTrend, int churnScoreChange, int satisfactionScoreChange, List<RiskIndicator> riskIndicators, List<RiskIndicator> vipIndicators, List<String> topRiskFactors, List<String> topVipFactors, int textsAnalyzed, DateTime analysisStartDate, DateTime analysisEndDate, double averageSentiment, double sentimentStdDev, List<RecommendedClientAction> recommendedActions, int recentNoshowCount, int recentCancellationCount, int daysSinceLastVisit, ScoreTrend? visitFrequencyTrend, String scoringVersion, DateTime expiresAt
});




}
/// @nodoc
class __$ClientRiskScoreCopyWithImpl<$Res>
    implements _$ClientRiskScoreCopyWith<$Res> {
  __$ClientRiskScoreCopyWithImpl(this._self, this._then);

  final _ClientRiskScore _self;
  final $Res Function(_ClientRiskScore) _then;

/// Create a copy of ClientRiskScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clientId = null,Object? businessId = null,Object? calculatedAt = null,Object? churnRiskScore = null,Object? satisfactionScore = null,Object? vipScore = null,Object? overallHealthScore = null,Object? churnTrend = null,Object? satisfactionTrend = null,Object? vipTrend = null,Object? churnScoreChange = null,Object? satisfactionScoreChange = null,Object? riskIndicators = null,Object? vipIndicators = null,Object? topRiskFactors = null,Object? topVipFactors = null,Object? textsAnalyzed = null,Object? analysisStartDate = null,Object? analysisEndDate = null,Object? averageSentiment = null,Object? sentimentStdDev = null,Object? recommendedActions = null,Object? recentNoshowCount = null,Object? recentCancellationCount = null,Object? daysSinceLastVisit = null,Object? visitFrequencyTrend = freezed,Object? scoringVersion = null,Object? expiresAt = null,}) {
  return _then(_ClientRiskScore(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,churnRiskScore: null == churnRiskScore ? _self.churnRiskScore : churnRiskScore // ignore: cast_nullable_to_non_nullable
as int,satisfactionScore: null == satisfactionScore ? _self.satisfactionScore : satisfactionScore // ignore: cast_nullable_to_non_nullable
as int,vipScore: null == vipScore ? _self.vipScore : vipScore // ignore: cast_nullable_to_non_nullable
as int,overallHealthScore: null == overallHealthScore ? _self.overallHealthScore : overallHealthScore // ignore: cast_nullable_to_non_nullable
as int,churnTrend: null == churnTrend ? _self.churnTrend : churnTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,satisfactionTrend: null == satisfactionTrend ? _self.satisfactionTrend : satisfactionTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,vipTrend: null == vipTrend ? _self.vipTrend : vipTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend,churnScoreChange: null == churnScoreChange ? _self.churnScoreChange : churnScoreChange // ignore: cast_nullable_to_non_nullable
as int,satisfactionScoreChange: null == satisfactionScoreChange ? _self.satisfactionScoreChange : satisfactionScoreChange // ignore: cast_nullable_to_non_nullable
as int,riskIndicators: null == riskIndicators ? _self._riskIndicators : riskIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,vipIndicators: null == vipIndicators ? _self._vipIndicators : vipIndicators // ignore: cast_nullable_to_non_nullable
as List<RiskIndicator>,topRiskFactors: null == topRiskFactors ? _self._topRiskFactors : topRiskFactors // ignore: cast_nullable_to_non_nullable
as List<String>,topVipFactors: null == topVipFactors ? _self._topVipFactors : topVipFactors // ignore: cast_nullable_to_non_nullable
as List<String>,textsAnalyzed: null == textsAnalyzed ? _self.textsAnalyzed : textsAnalyzed // ignore: cast_nullable_to_non_nullable
as int,analysisStartDate: null == analysisStartDate ? _self.analysisStartDate : analysisStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,analysisEndDate: null == analysisEndDate ? _self.analysisEndDate : analysisEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,averageSentiment: null == averageSentiment ? _self.averageSentiment : averageSentiment // ignore: cast_nullable_to_non_nullable
as double,sentimentStdDev: null == sentimentStdDev ? _self.sentimentStdDev : sentimentStdDev // ignore: cast_nullable_to_non_nullable
as double,recommendedActions: null == recommendedActions ? _self._recommendedActions : recommendedActions // ignore: cast_nullable_to_non_nullable
as List<RecommendedClientAction>,recentNoshowCount: null == recentNoshowCount ? _self.recentNoshowCount : recentNoshowCount // ignore: cast_nullable_to_non_nullable
as int,recentCancellationCount: null == recentCancellationCount ? _self.recentCancellationCount : recentCancellationCount // ignore: cast_nullable_to_non_nullable
as int,daysSinceLastVisit: null == daysSinceLastVisit ? _self.daysSinceLastVisit : daysSinceLastVisit // ignore: cast_nullable_to_non_nullable
as int,visitFrequencyTrend: freezed == visitFrequencyTrend ? _self.visitFrequencyTrend : visitFrequencyTrend // ignore: cast_nullable_to_non_nullable
as ScoreTrend?,scoringVersion: null == scoringVersion ? _self.scoringVersion : scoringVersion // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
