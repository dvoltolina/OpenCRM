// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scored_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScoredProvider {

/// Provider ID
 String get providerId;/// Provider display name
 String get providerName;/// Provider profile image URL (optional)
 String? get profileImageUrl;/// Overall match score (0-100, higher is better)
 double get matchScore;/// No-show rate for this client with this provider
 double get noshowRateWithClient;/// Number of completed appointments together
 int get completedAppointments;/// Number of no-shows with this provider
 int get noshowCount;/// Number of cancellations with this provider
 int get cancellationCount;/// Whether this provider is recommended for the client
 bool get isRecommended;/// Match quality classification
 ProviderMatchQuality get matchQuality;/// Factors contributing to match score
 List<ProviderMatchFactor> get matchFactors;/// Human-readable recommendation text
 String? get recommendationText;/// Provider's overall no-show rate (across all clients)
 double? get providerOverallNoshowRate;/// How this client's rate compares to provider average
 double? get clientVsAveragePercent;/// Last appointment date with this provider
 DateTime? get lastAppointmentDate;/// Provider's specialties (if relevant)
 List<String> get specialties;/// Whether provider is currently accepting new appointments
 bool get isAcceptingAppointments;
/// Create a copy of ScoredProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoredProviderCopyWith<ScoredProvider> get copyWith => _$ScoredProviderCopyWithImpl<ScoredProvider>(this as ScoredProvider, _$identity);

  /// Serializes this ScoredProvider to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoredProvider&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore)&&(identical(other.noshowRateWithClient, noshowRateWithClient) || other.noshowRateWithClient == noshowRateWithClient)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.cancellationCount, cancellationCount) || other.cancellationCount == cancellationCount)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.matchQuality, matchQuality) || other.matchQuality == matchQuality)&&const DeepCollectionEquality().equals(other.matchFactors, matchFactors)&&(identical(other.recommendationText, recommendationText) || other.recommendationText == recommendationText)&&(identical(other.providerOverallNoshowRate, providerOverallNoshowRate) || other.providerOverallNoshowRate == providerOverallNoshowRate)&&(identical(other.clientVsAveragePercent, clientVsAveragePercent) || other.clientVsAveragePercent == clientVsAveragePercent)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate)&&const DeepCollectionEquality().equals(other.specialties, specialties)&&(identical(other.isAcceptingAppointments, isAcceptingAppointments) || other.isAcceptingAppointments == isAcceptingAppointments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,profileImageUrl,matchScore,noshowRateWithClient,completedAppointments,noshowCount,cancellationCount,isRecommended,matchQuality,const DeepCollectionEquality().hash(matchFactors),recommendationText,providerOverallNoshowRate,clientVsAveragePercent,lastAppointmentDate,const DeepCollectionEquality().hash(specialties),isAcceptingAppointments);

@override
String toString() {
  return 'ScoredProvider(providerId: $providerId, providerName: $providerName, profileImageUrl: $profileImageUrl, matchScore: $matchScore, noshowRateWithClient: $noshowRateWithClient, completedAppointments: $completedAppointments, noshowCount: $noshowCount, cancellationCount: $cancellationCount, isRecommended: $isRecommended, matchQuality: $matchQuality, matchFactors: $matchFactors, recommendationText: $recommendationText, providerOverallNoshowRate: $providerOverallNoshowRate, clientVsAveragePercent: $clientVsAveragePercent, lastAppointmentDate: $lastAppointmentDate, specialties: $specialties, isAcceptingAppointments: $isAcceptingAppointments)';
}


}

/// @nodoc
abstract mixin class $ScoredProviderCopyWith<$Res>  {
  factory $ScoredProviderCopyWith(ScoredProvider value, $Res Function(ScoredProvider) _then) = _$ScoredProviderCopyWithImpl;
@useResult
$Res call({
 String providerId, String providerName, String? profileImageUrl, double matchScore, double noshowRateWithClient, int completedAppointments, int noshowCount, int cancellationCount, bool isRecommended, ProviderMatchQuality matchQuality, List<ProviderMatchFactor> matchFactors, String? recommendationText, double? providerOverallNoshowRate, double? clientVsAveragePercent, DateTime? lastAppointmentDate, List<String> specialties, bool isAcceptingAppointments
});




}
/// @nodoc
class _$ScoredProviderCopyWithImpl<$Res>
    implements $ScoredProviderCopyWith<$Res> {
  _$ScoredProviderCopyWithImpl(this._self, this._then);

  final ScoredProvider _self;
  final $Res Function(ScoredProvider) _then;

/// Create a copy of ScoredProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? providerName = null,Object? profileImageUrl = freezed,Object? matchScore = null,Object? noshowRateWithClient = null,Object? completedAppointments = null,Object? noshowCount = null,Object? cancellationCount = null,Object? isRecommended = null,Object? matchQuality = null,Object? matchFactors = null,Object? recommendationText = freezed,Object? providerOverallNoshowRate = freezed,Object? clientVsAveragePercent = freezed,Object? lastAppointmentDate = freezed,Object? specialties = null,Object? isAcceptingAppointments = null,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,matchScore: null == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double,noshowRateWithClient: null == noshowRateWithClient ? _self.noshowRateWithClient : noshowRateWithClient // ignore: cast_nullable_to_non_nullable
as double,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,cancellationCount: null == cancellationCount ? _self.cancellationCount : cancellationCount // ignore: cast_nullable_to_non_nullable
as int,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,matchQuality: null == matchQuality ? _self.matchQuality : matchQuality // ignore: cast_nullable_to_non_nullable
as ProviderMatchQuality,matchFactors: null == matchFactors ? _self.matchFactors : matchFactors // ignore: cast_nullable_to_non_nullable
as List<ProviderMatchFactor>,recommendationText: freezed == recommendationText ? _self.recommendationText : recommendationText // ignore: cast_nullable_to_non_nullable
as String?,providerOverallNoshowRate: freezed == providerOverallNoshowRate ? _self.providerOverallNoshowRate : providerOverallNoshowRate // ignore: cast_nullable_to_non_nullable
as double?,clientVsAveragePercent: freezed == clientVsAveragePercent ? _self.clientVsAveragePercent : clientVsAveragePercent // ignore: cast_nullable_to_non_nullable
as double?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,specialties: null == specialties ? _self.specialties : specialties // ignore: cast_nullable_to_non_nullable
as List<String>,isAcceptingAppointments: null == isAcceptingAppointments ? _self.isAcceptingAppointments : isAcceptingAppointments // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoredProvider].
extension ScoredProviderPatterns on ScoredProvider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoredProvider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoredProvider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoredProvider value)  $default,){
final _that = this;
switch (_that) {
case _ScoredProvider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoredProvider value)?  $default,){
final _that = this;
switch (_that) {
case _ScoredProvider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String providerName,  String? profileImageUrl,  double matchScore,  double noshowRateWithClient,  int completedAppointments,  int noshowCount,  int cancellationCount,  bool isRecommended,  ProviderMatchQuality matchQuality,  List<ProviderMatchFactor> matchFactors,  String? recommendationText,  double? providerOverallNoshowRate,  double? clientVsAveragePercent,  DateTime? lastAppointmentDate,  List<String> specialties,  bool isAcceptingAppointments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoredProvider() when $default != null:
return $default(_that.providerId,_that.providerName,_that.profileImageUrl,_that.matchScore,_that.noshowRateWithClient,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.isRecommended,_that.matchQuality,_that.matchFactors,_that.recommendationText,_that.providerOverallNoshowRate,_that.clientVsAveragePercent,_that.lastAppointmentDate,_that.specialties,_that.isAcceptingAppointments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String providerName,  String? profileImageUrl,  double matchScore,  double noshowRateWithClient,  int completedAppointments,  int noshowCount,  int cancellationCount,  bool isRecommended,  ProviderMatchQuality matchQuality,  List<ProviderMatchFactor> matchFactors,  String? recommendationText,  double? providerOverallNoshowRate,  double? clientVsAveragePercent,  DateTime? lastAppointmentDate,  List<String> specialties,  bool isAcceptingAppointments)  $default,) {final _that = this;
switch (_that) {
case _ScoredProvider():
return $default(_that.providerId,_that.providerName,_that.profileImageUrl,_that.matchScore,_that.noshowRateWithClient,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.isRecommended,_that.matchQuality,_that.matchFactors,_that.recommendationText,_that.providerOverallNoshowRate,_that.clientVsAveragePercent,_that.lastAppointmentDate,_that.specialties,_that.isAcceptingAppointments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String providerName,  String? profileImageUrl,  double matchScore,  double noshowRateWithClient,  int completedAppointments,  int noshowCount,  int cancellationCount,  bool isRecommended,  ProviderMatchQuality matchQuality,  List<ProviderMatchFactor> matchFactors,  String? recommendationText,  double? providerOverallNoshowRate,  double? clientVsAveragePercent,  DateTime? lastAppointmentDate,  List<String> specialties,  bool isAcceptingAppointments)?  $default,) {final _that = this;
switch (_that) {
case _ScoredProvider() when $default != null:
return $default(_that.providerId,_that.providerName,_that.profileImageUrl,_that.matchScore,_that.noshowRateWithClient,_that.completedAppointments,_that.noshowCount,_that.cancellationCount,_that.isRecommended,_that.matchQuality,_that.matchFactors,_that.recommendationText,_that.providerOverallNoshowRate,_that.clientVsAveragePercent,_that.lastAppointmentDate,_that.specialties,_that.isAcceptingAppointments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoredProvider extends ScoredProvider {
  const _ScoredProvider({required this.providerId, required this.providerName, this.profileImageUrl, required this.matchScore, required this.noshowRateWithClient, required this.completedAppointments, required this.noshowCount, required this.cancellationCount, required this.isRecommended, required this.matchQuality, required final  List<ProviderMatchFactor> matchFactors, this.recommendationText, this.providerOverallNoshowRate, this.clientVsAveragePercent, this.lastAppointmentDate, final  List<String> specialties = const [], this.isAcceptingAppointments = true}): _matchFactors = matchFactors,_specialties = specialties,super._();
  factory _ScoredProvider.fromJson(Map<String, dynamic> json) => _$ScoredProviderFromJson(json);

/// Provider ID
@override final  String providerId;
/// Provider display name
@override final  String providerName;
/// Provider profile image URL (optional)
@override final  String? profileImageUrl;
/// Overall match score (0-100, higher is better)
@override final  double matchScore;
/// No-show rate for this client with this provider
@override final  double noshowRateWithClient;
/// Number of completed appointments together
@override final  int completedAppointments;
/// Number of no-shows with this provider
@override final  int noshowCount;
/// Number of cancellations with this provider
@override final  int cancellationCount;
/// Whether this provider is recommended for the client
@override final  bool isRecommended;
/// Match quality classification
@override final  ProviderMatchQuality matchQuality;
/// Factors contributing to match score
 final  List<ProviderMatchFactor> _matchFactors;
/// Factors contributing to match score
@override List<ProviderMatchFactor> get matchFactors {
  if (_matchFactors is EqualUnmodifiableListView) return _matchFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matchFactors);
}

/// Human-readable recommendation text
@override final  String? recommendationText;
/// Provider's overall no-show rate (across all clients)
@override final  double? providerOverallNoshowRate;
/// How this client's rate compares to provider average
@override final  double? clientVsAveragePercent;
/// Last appointment date with this provider
@override final  DateTime? lastAppointmentDate;
/// Provider's specialties (if relevant)
 final  List<String> _specialties;
/// Provider's specialties (if relevant)
@override@JsonKey() List<String> get specialties {
  if (_specialties is EqualUnmodifiableListView) return _specialties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_specialties);
}

/// Whether provider is currently accepting new appointments
@override@JsonKey() final  bool isAcceptingAppointments;

/// Create a copy of ScoredProvider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoredProviderCopyWith<_ScoredProvider> get copyWith => __$ScoredProviderCopyWithImpl<_ScoredProvider>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoredProviderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoredProvider&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore)&&(identical(other.noshowRateWithClient, noshowRateWithClient) || other.noshowRateWithClient == noshowRateWithClient)&&(identical(other.completedAppointments, completedAppointments) || other.completedAppointments == completedAppointments)&&(identical(other.noshowCount, noshowCount) || other.noshowCount == noshowCount)&&(identical(other.cancellationCount, cancellationCount) || other.cancellationCount == cancellationCount)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.matchQuality, matchQuality) || other.matchQuality == matchQuality)&&const DeepCollectionEquality().equals(other._matchFactors, _matchFactors)&&(identical(other.recommendationText, recommendationText) || other.recommendationText == recommendationText)&&(identical(other.providerOverallNoshowRate, providerOverallNoshowRate) || other.providerOverallNoshowRate == providerOverallNoshowRate)&&(identical(other.clientVsAveragePercent, clientVsAveragePercent) || other.clientVsAveragePercent == clientVsAveragePercent)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate)&&const DeepCollectionEquality().equals(other._specialties, _specialties)&&(identical(other.isAcceptingAppointments, isAcceptingAppointments) || other.isAcceptingAppointments == isAcceptingAppointments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,profileImageUrl,matchScore,noshowRateWithClient,completedAppointments,noshowCount,cancellationCount,isRecommended,matchQuality,const DeepCollectionEquality().hash(_matchFactors),recommendationText,providerOverallNoshowRate,clientVsAveragePercent,lastAppointmentDate,const DeepCollectionEquality().hash(_specialties),isAcceptingAppointments);

@override
String toString() {
  return 'ScoredProvider(providerId: $providerId, providerName: $providerName, profileImageUrl: $profileImageUrl, matchScore: $matchScore, noshowRateWithClient: $noshowRateWithClient, completedAppointments: $completedAppointments, noshowCount: $noshowCount, cancellationCount: $cancellationCount, isRecommended: $isRecommended, matchQuality: $matchQuality, matchFactors: $matchFactors, recommendationText: $recommendationText, providerOverallNoshowRate: $providerOverallNoshowRate, clientVsAveragePercent: $clientVsAveragePercent, lastAppointmentDate: $lastAppointmentDate, specialties: $specialties, isAcceptingAppointments: $isAcceptingAppointments)';
}


}

/// @nodoc
abstract mixin class _$ScoredProviderCopyWith<$Res> implements $ScoredProviderCopyWith<$Res> {
  factory _$ScoredProviderCopyWith(_ScoredProvider value, $Res Function(_ScoredProvider) _then) = __$ScoredProviderCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String providerName, String? profileImageUrl, double matchScore, double noshowRateWithClient, int completedAppointments, int noshowCount, int cancellationCount, bool isRecommended, ProviderMatchQuality matchQuality, List<ProviderMatchFactor> matchFactors, String? recommendationText, double? providerOverallNoshowRate, double? clientVsAveragePercent, DateTime? lastAppointmentDate, List<String> specialties, bool isAcceptingAppointments
});




}
/// @nodoc
class __$ScoredProviderCopyWithImpl<$Res>
    implements _$ScoredProviderCopyWith<$Res> {
  __$ScoredProviderCopyWithImpl(this._self, this._then);

  final _ScoredProvider _self;
  final $Res Function(_ScoredProvider) _then;

/// Create a copy of ScoredProvider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? providerName = null,Object? profileImageUrl = freezed,Object? matchScore = null,Object? noshowRateWithClient = null,Object? completedAppointments = null,Object? noshowCount = null,Object? cancellationCount = null,Object? isRecommended = null,Object? matchQuality = null,Object? matchFactors = null,Object? recommendationText = freezed,Object? providerOverallNoshowRate = freezed,Object? clientVsAveragePercent = freezed,Object? lastAppointmentDate = freezed,Object? specialties = null,Object? isAcceptingAppointments = null,}) {
  return _then(_ScoredProvider(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,matchScore: null == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double,noshowRateWithClient: null == noshowRateWithClient ? _self.noshowRateWithClient : noshowRateWithClient // ignore: cast_nullable_to_non_nullable
as double,completedAppointments: null == completedAppointments ? _self.completedAppointments : completedAppointments // ignore: cast_nullable_to_non_nullable
as int,noshowCount: null == noshowCount ? _self.noshowCount : noshowCount // ignore: cast_nullable_to_non_nullable
as int,cancellationCount: null == cancellationCount ? _self.cancellationCount : cancellationCount // ignore: cast_nullable_to_non_nullable
as int,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,matchQuality: null == matchQuality ? _self.matchQuality : matchQuality // ignore: cast_nullable_to_non_nullable
as ProviderMatchQuality,matchFactors: null == matchFactors ? _self._matchFactors : matchFactors // ignore: cast_nullable_to_non_nullable
as List<ProviderMatchFactor>,recommendationText: freezed == recommendationText ? _self.recommendationText : recommendationText // ignore: cast_nullable_to_non_nullable
as String?,providerOverallNoshowRate: freezed == providerOverallNoshowRate ? _self.providerOverallNoshowRate : providerOverallNoshowRate // ignore: cast_nullable_to_non_nullable
as double?,clientVsAveragePercent: freezed == clientVsAveragePercent ? _self.clientVsAveragePercent : clientVsAveragePercent // ignore: cast_nullable_to_non_nullable
as double?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,specialties: null == specialties ? _self._specialties : specialties // ignore: cast_nullable_to_non_nullable
as List<String>,isAcceptingAppointments: null == isAcceptingAppointments ? _self.isAcceptingAppointments : isAcceptingAppointments // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderMatchFactor {

/// Factor type
 ProviderFactorType get factorType;/// Human-readable description
 String get description;/// Impact on score (-100 to 100)
 double get impact;/// Weight of this factor (0.0-1.0)
 double get weight;/// Icon name for UI
 String? get iconName;
/// Create a copy of ProviderMatchFactor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderMatchFactorCopyWith<ProviderMatchFactor> get copyWith => _$ProviderMatchFactorCopyWithImpl<ProviderMatchFactor>(this as ProviderMatchFactor, _$identity);

  /// Serializes this ProviderMatchFactor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderMatchFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,weight,iconName);

@override
String toString() {
  return 'ProviderMatchFactor(factorType: $factorType, description: $description, impact: $impact, weight: $weight, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $ProviderMatchFactorCopyWith<$Res>  {
  factory $ProviderMatchFactorCopyWith(ProviderMatchFactor value, $Res Function(ProviderMatchFactor) _then) = _$ProviderMatchFactorCopyWithImpl;
@useResult
$Res call({
 ProviderFactorType factorType, String description, double impact, double weight, String? iconName
});




}
/// @nodoc
class _$ProviderMatchFactorCopyWithImpl<$Res>
    implements $ProviderMatchFactorCopyWith<$Res> {
  _$ProviderMatchFactorCopyWithImpl(this._self, this._then);

  final ProviderMatchFactor _self;
  final $Res Function(ProviderMatchFactor) _then;

/// Create a copy of ProviderMatchFactor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? weight = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as ProviderFactorType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderMatchFactor].
extension ProviderMatchFactorPatterns on ProviderMatchFactor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderMatchFactor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderMatchFactor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderMatchFactor value)  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchFactor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderMatchFactor value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchFactor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderFactorType factorType,  String description,  double impact,  double weight,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderMatchFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderFactorType factorType,  String description,  double impact,  double weight,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchFactor():
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderFactorType factorType,  String description,  double impact,  double weight,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderMatchFactor implements ProviderMatchFactor {
  const _ProviderMatchFactor({required this.factorType, required this.description, required this.impact, required this.weight, this.iconName});
  factory _ProviderMatchFactor.fromJson(Map<String, dynamic> json) => _$ProviderMatchFactorFromJson(json);

/// Factor type
@override final  ProviderFactorType factorType;
/// Human-readable description
@override final  String description;
/// Impact on score (-100 to 100)
@override final  double impact;
/// Weight of this factor (0.0-1.0)
@override final  double weight;
/// Icon name for UI
@override final  String? iconName;

/// Create a copy of ProviderMatchFactor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderMatchFactorCopyWith<_ProviderMatchFactor> get copyWith => __$ProviderMatchFactorCopyWithImpl<_ProviderMatchFactor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderMatchFactorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderMatchFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,weight,iconName);

@override
String toString() {
  return 'ProviderMatchFactor(factorType: $factorType, description: $description, impact: $impact, weight: $weight, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$ProviderMatchFactorCopyWith<$Res> implements $ProviderMatchFactorCopyWith<$Res> {
  factory _$ProviderMatchFactorCopyWith(_ProviderMatchFactor value, $Res Function(_ProviderMatchFactor) _then) = __$ProviderMatchFactorCopyWithImpl;
@override @useResult
$Res call({
 ProviderFactorType factorType, String description, double impact, double weight, String? iconName
});




}
/// @nodoc
class __$ProviderMatchFactorCopyWithImpl<$Res>
    implements _$ProviderMatchFactorCopyWith<$Res> {
  __$ProviderMatchFactorCopyWithImpl(this._self, this._then);

  final _ProviderMatchFactor _self;
  final $Res Function(_ProviderMatchFactor) _then;

/// Create a copy of ProviderMatchFactor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? weight = null,Object? iconName = freezed,}) {
  return _then(_ProviderMatchFactor(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as ProviderFactorType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProviderMatchResult {

/// Client ID
 String get clientId;/// Service being booked
 String get serviceId;/// All providers scored, sorted by match score
 List<ScoredProvider> get scoredProviders;/// Top recommended providers
 List<ScoredProvider> get recommendedProviders;/// Best matching provider
 ScoredProvider? get bestMatch;/// Client's preferred provider (if they have one)
 ScoredProvider? get preferredProvider;/// Whether client has history with any providers
 bool get hasProviderHistory;/// When this result was generated
 DateTime get generatedAt;/// Message for clients with no history
 String? get noHistoryMessage;
/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderMatchResultCopyWith<ProviderMatchResult> get copyWith => _$ProviderMatchResultCopyWithImpl<ProviderMatchResult>(this as ProviderMatchResult, _$identity);

  /// Serializes this ProviderMatchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderMatchResult&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&const DeepCollectionEquality().equals(other.scoredProviders, scoredProviders)&&const DeepCollectionEquality().equals(other.recommendedProviders, recommendedProviders)&&(identical(other.bestMatch, bestMatch) || other.bestMatch == bestMatch)&&(identical(other.preferredProvider, preferredProvider) || other.preferredProvider == preferredProvider)&&(identical(other.hasProviderHistory, hasProviderHistory) || other.hasProviderHistory == hasProviderHistory)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.noHistoryMessage, noHistoryMessage) || other.noHistoryMessage == noHistoryMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,const DeepCollectionEquality().hash(scoredProviders),const DeepCollectionEquality().hash(recommendedProviders),bestMatch,preferredProvider,hasProviderHistory,generatedAt,noHistoryMessage);

@override
String toString() {
  return 'ProviderMatchResult(clientId: $clientId, serviceId: $serviceId, scoredProviders: $scoredProviders, recommendedProviders: $recommendedProviders, bestMatch: $bestMatch, preferredProvider: $preferredProvider, hasProviderHistory: $hasProviderHistory, generatedAt: $generatedAt, noHistoryMessage: $noHistoryMessage)';
}


}

/// @nodoc
abstract mixin class $ProviderMatchResultCopyWith<$Res>  {
  factory $ProviderMatchResultCopyWith(ProviderMatchResult value, $Res Function(ProviderMatchResult) _then) = _$ProviderMatchResultCopyWithImpl;
@useResult
$Res call({
 String clientId, String serviceId, List<ScoredProvider> scoredProviders, List<ScoredProvider> recommendedProviders, ScoredProvider? bestMatch, ScoredProvider? preferredProvider, bool hasProviderHistory, DateTime generatedAt, String? noHistoryMessage
});


$ScoredProviderCopyWith<$Res>? get bestMatch;$ScoredProviderCopyWith<$Res>? get preferredProvider;

}
/// @nodoc
class _$ProviderMatchResultCopyWithImpl<$Res>
    implements $ProviderMatchResultCopyWith<$Res> {
  _$ProviderMatchResultCopyWithImpl(this._self, this._then);

  final ProviderMatchResult _self;
  final $Res Function(ProviderMatchResult) _then;

/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? serviceId = null,Object? scoredProviders = null,Object? recommendedProviders = null,Object? bestMatch = freezed,Object? preferredProvider = freezed,Object? hasProviderHistory = null,Object? generatedAt = null,Object? noHistoryMessage = freezed,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,scoredProviders: null == scoredProviders ? _self.scoredProviders : scoredProviders // ignore: cast_nullable_to_non_nullable
as List<ScoredProvider>,recommendedProviders: null == recommendedProviders ? _self.recommendedProviders : recommendedProviders // ignore: cast_nullable_to_non_nullable
as List<ScoredProvider>,bestMatch: freezed == bestMatch ? _self.bestMatch : bestMatch // ignore: cast_nullable_to_non_nullable
as ScoredProvider?,preferredProvider: freezed == preferredProvider ? _self.preferredProvider : preferredProvider // ignore: cast_nullable_to_non_nullable
as ScoredProvider?,hasProviderHistory: null == hasProviderHistory ? _self.hasProviderHistory : hasProviderHistory // ignore: cast_nullable_to_non_nullable
as bool,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,noHistoryMessage: freezed == noHistoryMessage ? _self.noHistoryMessage : noHistoryMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredProviderCopyWith<$Res>? get bestMatch {
    if (_self.bestMatch == null) {
    return null;
  }

  return $ScoredProviderCopyWith<$Res>(_self.bestMatch!, (value) {
    return _then(_self.copyWith(bestMatch: value));
  });
}/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredProviderCopyWith<$Res>? get preferredProvider {
    if (_self.preferredProvider == null) {
    return null;
  }

  return $ScoredProviderCopyWith<$Res>(_self.preferredProvider!, (value) {
    return _then(_self.copyWith(preferredProvider: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderMatchResult].
extension ProviderMatchResultPatterns on ProviderMatchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderMatchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderMatchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderMatchResult value)  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderMatchResult value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  List<ScoredProvider> scoredProviders,  List<ScoredProvider> recommendedProviders,  ScoredProvider? bestMatch,  ScoredProvider? preferredProvider,  bool hasProviderHistory,  DateTime generatedAt,  String? noHistoryMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderMatchResult() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.scoredProviders,_that.recommendedProviders,_that.bestMatch,_that.preferredProvider,_that.hasProviderHistory,_that.generatedAt,_that.noHistoryMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  List<ScoredProvider> scoredProviders,  List<ScoredProvider> recommendedProviders,  ScoredProvider? bestMatch,  ScoredProvider? preferredProvider,  bool hasProviderHistory,  DateTime generatedAt,  String? noHistoryMessage)  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchResult():
return $default(_that.clientId,_that.serviceId,_that.scoredProviders,_that.recommendedProviders,_that.bestMatch,_that.preferredProvider,_that.hasProviderHistory,_that.generatedAt,_that.noHistoryMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String serviceId,  List<ScoredProvider> scoredProviders,  List<ScoredProvider> recommendedProviders,  ScoredProvider? bestMatch,  ScoredProvider? preferredProvider,  bool hasProviderHistory,  DateTime generatedAt,  String? noHistoryMessage)?  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchResult() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.scoredProviders,_that.recommendedProviders,_that.bestMatch,_that.preferredProvider,_that.hasProviderHistory,_that.generatedAt,_that.noHistoryMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderMatchResult extends ProviderMatchResult {
  const _ProviderMatchResult({required this.clientId, required this.serviceId, required final  List<ScoredProvider> scoredProviders, required final  List<ScoredProvider> recommendedProviders, this.bestMatch, this.preferredProvider, required this.hasProviderHistory, required this.generatedAt, this.noHistoryMessage}): _scoredProviders = scoredProviders,_recommendedProviders = recommendedProviders,super._();
  factory _ProviderMatchResult.fromJson(Map<String, dynamic> json) => _$ProviderMatchResultFromJson(json);

/// Client ID
@override final  String clientId;
/// Service being booked
@override final  String serviceId;
/// All providers scored, sorted by match score
 final  List<ScoredProvider> _scoredProviders;
/// All providers scored, sorted by match score
@override List<ScoredProvider> get scoredProviders {
  if (_scoredProviders is EqualUnmodifiableListView) return _scoredProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scoredProviders);
}

/// Top recommended providers
 final  List<ScoredProvider> _recommendedProviders;
/// Top recommended providers
@override List<ScoredProvider> get recommendedProviders {
  if (_recommendedProviders is EqualUnmodifiableListView) return _recommendedProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendedProviders);
}

/// Best matching provider
@override final  ScoredProvider? bestMatch;
/// Client's preferred provider (if they have one)
@override final  ScoredProvider? preferredProvider;
/// Whether client has history with any providers
@override final  bool hasProviderHistory;
/// When this result was generated
@override final  DateTime generatedAt;
/// Message for clients with no history
@override final  String? noHistoryMessage;

/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderMatchResultCopyWith<_ProviderMatchResult> get copyWith => __$ProviderMatchResultCopyWithImpl<_ProviderMatchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderMatchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderMatchResult&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&const DeepCollectionEquality().equals(other._scoredProviders, _scoredProviders)&&const DeepCollectionEquality().equals(other._recommendedProviders, _recommendedProviders)&&(identical(other.bestMatch, bestMatch) || other.bestMatch == bestMatch)&&(identical(other.preferredProvider, preferredProvider) || other.preferredProvider == preferredProvider)&&(identical(other.hasProviderHistory, hasProviderHistory) || other.hasProviderHistory == hasProviderHistory)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.noHistoryMessage, noHistoryMessage) || other.noHistoryMessage == noHistoryMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,const DeepCollectionEquality().hash(_scoredProviders),const DeepCollectionEquality().hash(_recommendedProviders),bestMatch,preferredProvider,hasProviderHistory,generatedAt,noHistoryMessage);

@override
String toString() {
  return 'ProviderMatchResult(clientId: $clientId, serviceId: $serviceId, scoredProviders: $scoredProviders, recommendedProviders: $recommendedProviders, bestMatch: $bestMatch, preferredProvider: $preferredProvider, hasProviderHistory: $hasProviderHistory, generatedAt: $generatedAt, noHistoryMessage: $noHistoryMessage)';
}


}

/// @nodoc
abstract mixin class _$ProviderMatchResultCopyWith<$Res> implements $ProviderMatchResultCopyWith<$Res> {
  factory _$ProviderMatchResultCopyWith(_ProviderMatchResult value, $Res Function(_ProviderMatchResult) _then) = __$ProviderMatchResultCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String serviceId, List<ScoredProvider> scoredProviders, List<ScoredProvider> recommendedProviders, ScoredProvider? bestMatch, ScoredProvider? preferredProvider, bool hasProviderHistory, DateTime generatedAt, String? noHistoryMessage
});


@override $ScoredProviderCopyWith<$Res>? get bestMatch;@override $ScoredProviderCopyWith<$Res>? get preferredProvider;

}
/// @nodoc
class __$ProviderMatchResultCopyWithImpl<$Res>
    implements _$ProviderMatchResultCopyWith<$Res> {
  __$ProviderMatchResultCopyWithImpl(this._self, this._then);

  final _ProviderMatchResult _self;
  final $Res Function(_ProviderMatchResult) _then;

/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? serviceId = null,Object? scoredProviders = null,Object? recommendedProviders = null,Object? bestMatch = freezed,Object? preferredProvider = freezed,Object? hasProviderHistory = null,Object? generatedAt = null,Object? noHistoryMessage = freezed,}) {
  return _then(_ProviderMatchResult(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,scoredProviders: null == scoredProviders ? _self._scoredProviders : scoredProviders // ignore: cast_nullable_to_non_nullable
as List<ScoredProvider>,recommendedProviders: null == recommendedProviders ? _self._recommendedProviders : recommendedProviders // ignore: cast_nullable_to_non_nullable
as List<ScoredProvider>,bestMatch: freezed == bestMatch ? _self.bestMatch : bestMatch // ignore: cast_nullable_to_non_nullable
as ScoredProvider?,preferredProvider: freezed == preferredProvider ? _self.preferredProvider : preferredProvider // ignore: cast_nullable_to_non_nullable
as ScoredProvider?,hasProviderHistory: null == hasProviderHistory ? _self.hasProviderHistory : hasProviderHistory // ignore: cast_nullable_to_non_nullable
as bool,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,noHistoryMessage: freezed == noHistoryMessage ? _self.noHistoryMessage : noHistoryMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredProviderCopyWith<$Res>? get bestMatch {
    if (_self.bestMatch == null) {
    return null;
  }

  return $ScoredProviderCopyWith<$Res>(_self.bestMatch!, (value) {
    return _then(_self.copyWith(bestMatch: value));
  });
}/// Create a copy of ProviderMatchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredProviderCopyWith<$Res>? get preferredProvider {
    if (_self.preferredProvider == null) {
    return null;
  }

  return $ScoredProviderCopyWith<$Res>(_self.preferredProvider!, (value) {
    return _then(_self.copyWith(preferredProvider: value));
  });
}
}


/// @nodoc
mixin _$ProviderMatchRequest {

/// Client to match providers for
 String get clientId;/// Service being booked
 String get serviceId;/// Location filter (optional)
 String? get locationId;/// Date for availability check (optional)
 DateTime? get date;/// Maximum number of results
 int get maxResults;/// Minimum appointments for reliable score
 int get minAppointmentsForReliability;
/// Create a copy of ProviderMatchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderMatchRequestCopyWith<ProviderMatchRequest> get copyWith => _$ProviderMatchRequestCopyWithImpl<ProviderMatchRequest>(this as ProviderMatchRequest, _$identity);

  /// Serializes this ProviderMatchRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderMatchRequest&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.date, date) || other.date == date)&&(identical(other.maxResults, maxResults) || other.maxResults == maxResults)&&(identical(other.minAppointmentsForReliability, minAppointmentsForReliability) || other.minAppointmentsForReliability == minAppointmentsForReliability));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,locationId,date,maxResults,minAppointmentsForReliability);

@override
String toString() {
  return 'ProviderMatchRequest(clientId: $clientId, serviceId: $serviceId, locationId: $locationId, date: $date, maxResults: $maxResults, minAppointmentsForReliability: $minAppointmentsForReliability)';
}


}

/// @nodoc
abstract mixin class $ProviderMatchRequestCopyWith<$Res>  {
  factory $ProviderMatchRequestCopyWith(ProviderMatchRequest value, $Res Function(ProviderMatchRequest) _then) = _$ProviderMatchRequestCopyWithImpl;
@useResult
$Res call({
 String clientId, String serviceId, String? locationId, DateTime? date, int maxResults, int minAppointmentsForReliability
});




}
/// @nodoc
class _$ProviderMatchRequestCopyWithImpl<$Res>
    implements $ProviderMatchRequestCopyWith<$Res> {
  _$ProviderMatchRequestCopyWithImpl(this._self, this._then);

  final ProviderMatchRequest _self;
  final $Res Function(ProviderMatchRequest) _then;

/// Create a copy of ProviderMatchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? serviceId = null,Object? locationId = freezed,Object? date = freezed,Object? maxResults = null,Object? minAppointmentsForReliability = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,maxResults: null == maxResults ? _self.maxResults : maxResults // ignore: cast_nullable_to_non_nullable
as int,minAppointmentsForReliability: null == minAppointmentsForReliability ? _self.minAppointmentsForReliability : minAppointmentsForReliability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderMatchRequest].
extension ProviderMatchRequestPatterns on ProviderMatchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderMatchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderMatchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderMatchRequest value)  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderMatchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderMatchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  String? locationId,  DateTime? date,  int maxResults,  int minAppointmentsForReliability)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderMatchRequest() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.locationId,_that.date,_that.maxResults,_that.minAppointmentsForReliability);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  String? locationId,  DateTime? date,  int maxResults,  int minAppointmentsForReliability)  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchRequest():
return $default(_that.clientId,_that.serviceId,_that.locationId,_that.date,_that.maxResults,_that.minAppointmentsForReliability);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String serviceId,  String? locationId,  DateTime? date,  int maxResults,  int minAppointmentsForReliability)?  $default,) {final _that = this;
switch (_that) {
case _ProviderMatchRequest() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.locationId,_that.date,_that.maxResults,_that.minAppointmentsForReliability);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderMatchRequest implements ProviderMatchRequest {
  const _ProviderMatchRequest({required this.clientId, required this.serviceId, this.locationId, this.date, this.maxResults = 10, this.minAppointmentsForReliability = 2});
  factory _ProviderMatchRequest.fromJson(Map<String, dynamic> json) => _$ProviderMatchRequestFromJson(json);

/// Client to match providers for
@override final  String clientId;
/// Service being booked
@override final  String serviceId;
/// Location filter (optional)
@override final  String? locationId;
/// Date for availability check (optional)
@override final  DateTime? date;
/// Maximum number of results
@override@JsonKey() final  int maxResults;
/// Minimum appointments for reliable score
@override@JsonKey() final  int minAppointmentsForReliability;

/// Create a copy of ProviderMatchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderMatchRequestCopyWith<_ProviderMatchRequest> get copyWith => __$ProviderMatchRequestCopyWithImpl<_ProviderMatchRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderMatchRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderMatchRequest&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.date, date) || other.date == date)&&(identical(other.maxResults, maxResults) || other.maxResults == maxResults)&&(identical(other.minAppointmentsForReliability, minAppointmentsForReliability) || other.minAppointmentsForReliability == minAppointmentsForReliability));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,locationId,date,maxResults,minAppointmentsForReliability);

@override
String toString() {
  return 'ProviderMatchRequest(clientId: $clientId, serviceId: $serviceId, locationId: $locationId, date: $date, maxResults: $maxResults, minAppointmentsForReliability: $minAppointmentsForReliability)';
}


}

/// @nodoc
abstract mixin class _$ProviderMatchRequestCopyWith<$Res> implements $ProviderMatchRequestCopyWith<$Res> {
  factory _$ProviderMatchRequestCopyWith(_ProviderMatchRequest value, $Res Function(_ProviderMatchRequest) _then) = __$ProviderMatchRequestCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String serviceId, String? locationId, DateTime? date, int maxResults, int minAppointmentsForReliability
});




}
/// @nodoc
class __$ProviderMatchRequestCopyWithImpl<$Res>
    implements _$ProviderMatchRequestCopyWith<$Res> {
  __$ProviderMatchRequestCopyWithImpl(this._self, this._then);

  final _ProviderMatchRequest _self;
  final $Res Function(_ProviderMatchRequest) _then;

/// Create a copy of ProviderMatchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? serviceId = null,Object? locationId = freezed,Object? date = freezed,Object? maxResults = null,Object? minAppointmentsForReliability = null,}) {
  return _then(_ProviderMatchRequest(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,maxResults: null == maxResults ? _self.maxResults : maxResults // ignore: cast_nullable_to_non_nullable
as int,minAppointmentsForReliability: null == minAppointmentsForReliability ? _self.minAppointmentsForReliability : minAppointmentsForReliability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
