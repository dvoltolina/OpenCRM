// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessSearchResult {

 String get id; String get name; String get businessCode; String? get logoUrl; String? get city; String? get state; List<String> get serviceCategories; double? get rating; int? get reviewCount;
/// Create a copy of BusinessSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessSearchResultCopyWith<BusinessSearchResult> get copyWith => _$BusinessSearchResultCopyWithImpl<BusinessSearchResult>(this as BusinessSearchResult, _$identity);

  /// Serializes this BusinessSearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessSearchResult&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.businessCode, businessCode) || other.businessCode == businessCode)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.serviceCategories, serviceCategories)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,businessCode,logoUrl,city,state,const DeepCollectionEquality().hash(serviceCategories),rating,reviewCount);

@override
String toString() {
  return 'BusinessSearchResult(id: $id, name: $name, businessCode: $businessCode, logoUrl: $logoUrl, city: $city, state: $state, serviceCategories: $serviceCategories, rating: $rating, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class $BusinessSearchResultCopyWith<$Res>  {
  factory $BusinessSearchResultCopyWith(BusinessSearchResult value, $Res Function(BusinessSearchResult) _then) = _$BusinessSearchResultCopyWithImpl;
@useResult
$Res call({
 String id, String name, String businessCode, String? logoUrl, String? city, String? state, List<String> serviceCategories, double? rating, int? reviewCount
});




}
/// @nodoc
class _$BusinessSearchResultCopyWithImpl<$Res>
    implements $BusinessSearchResultCopyWith<$Res> {
  _$BusinessSearchResultCopyWithImpl(this._self, this._then);

  final BusinessSearchResult _self;
  final $Res Function(BusinessSearchResult) _then;

/// Create a copy of BusinessSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? businessCode = null,Object? logoUrl = freezed,Object? city = freezed,Object? state = freezed,Object? serviceCategories = null,Object? rating = freezed,Object? reviewCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,businessCode: null == businessCode ? _self.businessCode : businessCode // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,serviceCategories: null == serviceCategories ? _self.serviceCategories : serviceCategories // ignore: cast_nullable_to_non_nullable
as List<String>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessSearchResult].
extension BusinessSearchResultPatterns on BusinessSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _BusinessSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String businessCode,  String? logoUrl,  String? city,  String? state,  List<String> serviceCategories,  double? rating,  int? reviewCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessSearchResult() when $default != null:
return $default(_that.id,_that.name,_that.businessCode,_that.logoUrl,_that.city,_that.state,_that.serviceCategories,_that.rating,_that.reviewCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String businessCode,  String? logoUrl,  String? city,  String? state,  List<String> serviceCategories,  double? rating,  int? reviewCount)  $default,) {final _that = this;
switch (_that) {
case _BusinessSearchResult():
return $default(_that.id,_that.name,_that.businessCode,_that.logoUrl,_that.city,_that.state,_that.serviceCategories,_that.rating,_that.reviewCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String businessCode,  String? logoUrl,  String? city,  String? state,  List<String> serviceCategories,  double? rating,  int? reviewCount)?  $default,) {final _that = this;
switch (_that) {
case _BusinessSearchResult() when $default != null:
return $default(_that.id,_that.name,_that.businessCode,_that.logoUrl,_that.city,_that.state,_that.serviceCategories,_that.rating,_that.reviewCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessSearchResult implements BusinessSearchResult {
  const _BusinessSearchResult({required this.id, required this.name, required this.businessCode, this.logoUrl, this.city, this.state, final  List<String> serviceCategories = const [], this.rating, this.reviewCount}): _serviceCategories = serviceCategories;
  factory _BusinessSearchResult.fromJson(Map<String, dynamic> json) => _$BusinessSearchResultFromJson(json);

@override final  String id;
@override final  String name;
@override final  String businessCode;
@override final  String? logoUrl;
@override final  String? city;
@override final  String? state;
 final  List<String> _serviceCategories;
@override@JsonKey() List<String> get serviceCategories {
  if (_serviceCategories is EqualUnmodifiableListView) return _serviceCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceCategories);
}

@override final  double? rating;
@override final  int? reviewCount;

/// Create a copy of BusinessSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessSearchResultCopyWith<_BusinessSearchResult> get copyWith => __$BusinessSearchResultCopyWithImpl<_BusinessSearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessSearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessSearchResult&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.businessCode, businessCode) || other.businessCode == businessCode)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other._serviceCategories, _serviceCategories)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,businessCode,logoUrl,city,state,const DeepCollectionEquality().hash(_serviceCategories),rating,reviewCount);

@override
String toString() {
  return 'BusinessSearchResult(id: $id, name: $name, businessCode: $businessCode, logoUrl: $logoUrl, city: $city, state: $state, serviceCategories: $serviceCategories, rating: $rating, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class _$BusinessSearchResultCopyWith<$Res> implements $BusinessSearchResultCopyWith<$Res> {
  factory _$BusinessSearchResultCopyWith(_BusinessSearchResult value, $Res Function(_BusinessSearchResult) _then) = __$BusinessSearchResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String businessCode, String? logoUrl, String? city, String? state, List<String> serviceCategories, double? rating, int? reviewCount
});




}
/// @nodoc
class __$BusinessSearchResultCopyWithImpl<$Res>
    implements _$BusinessSearchResultCopyWith<$Res> {
  __$BusinessSearchResultCopyWithImpl(this._self, this._then);

  final _BusinessSearchResult _self;
  final $Res Function(_BusinessSearchResult) _then;

/// Create a copy of BusinessSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? businessCode = null,Object? logoUrl = freezed,Object? city = freezed,Object? state = freezed,Object? serviceCategories = null,Object? rating = freezed,Object? reviewCount = freezed,}) {
  return _then(_BusinessSearchResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,businessCode: null == businessCode ? _self.businessCode : businessCode // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,serviceCategories: null == serviceCategories ? _self._serviceCategories : serviceCategories // ignore: cast_nullable_to_non_nullable
as List<String>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$BusinessDetails {

 String get id; String get name; String get businessCode; String? get description; String? get logoUrl; List<BusinessLocation> get locations; List<String> get serviceCategories; BusinessHours? get hours; String? get phone; String? get email; String? get website; double? get rating; int? get reviewCount;
/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessDetailsCopyWith<BusinessDetails> get copyWith => _$BusinessDetailsCopyWithImpl<BusinessDetails>(this as BusinessDetails, _$identity);

  /// Serializes this BusinessDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.businessCode, businessCode) || other.businessCode == businessCode)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&const DeepCollectionEquality().equals(other.locations, locations)&&const DeepCollectionEquality().equals(other.serviceCategories, serviceCategories)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,businessCode,description,logoUrl,const DeepCollectionEquality().hash(locations),const DeepCollectionEquality().hash(serviceCategories),hours,phone,email,website,rating,reviewCount);

@override
String toString() {
  return 'BusinessDetails(id: $id, name: $name, businessCode: $businessCode, description: $description, logoUrl: $logoUrl, locations: $locations, serviceCategories: $serviceCategories, hours: $hours, phone: $phone, email: $email, website: $website, rating: $rating, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class $BusinessDetailsCopyWith<$Res>  {
  factory $BusinessDetailsCopyWith(BusinessDetails value, $Res Function(BusinessDetails) _then) = _$BusinessDetailsCopyWithImpl;
@useResult
$Res call({
 String id, String name, String businessCode, String? description, String? logoUrl, List<BusinessLocation> locations, List<String> serviceCategories, BusinessHours? hours, String? phone, String? email, String? website, double? rating, int? reviewCount
});


$BusinessHoursCopyWith<$Res>? get hours;

}
/// @nodoc
class _$BusinessDetailsCopyWithImpl<$Res>
    implements $BusinessDetailsCopyWith<$Res> {
  _$BusinessDetailsCopyWithImpl(this._self, this._then);

  final BusinessDetails _self;
  final $Res Function(BusinessDetails) _then;

/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? businessCode = null,Object? description = freezed,Object? logoUrl = freezed,Object? locations = null,Object? serviceCategories = null,Object? hours = freezed,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? rating = freezed,Object? reviewCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,businessCode: null == businessCode ? _self.businessCode : businessCode // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,locations: null == locations ? _self.locations : locations // ignore: cast_nullable_to_non_nullable
as List<BusinessLocation>,serviceCategories: null == serviceCategories ? _self.serviceCategories : serviceCategories // ignore: cast_nullable_to_non_nullable
as List<String>,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as BusinessHours?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<$Res>? get hours {
    if (_self.hours == null) {
    return null;
  }

  return $BusinessHoursCopyWith<$Res>(_self.hours!, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}


/// Adds pattern-matching-related methods to [BusinessDetails].
extension BusinessDetailsPatterns on BusinessDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessDetails value)  $default,){
final _that = this;
switch (_that) {
case _BusinessDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessDetails value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String businessCode,  String? description,  String? logoUrl,  List<BusinessLocation> locations,  List<String> serviceCategories,  BusinessHours? hours,  String? phone,  String? email,  String? website,  double? rating,  int? reviewCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessDetails() when $default != null:
return $default(_that.id,_that.name,_that.businessCode,_that.description,_that.logoUrl,_that.locations,_that.serviceCategories,_that.hours,_that.phone,_that.email,_that.website,_that.rating,_that.reviewCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String businessCode,  String? description,  String? logoUrl,  List<BusinessLocation> locations,  List<String> serviceCategories,  BusinessHours? hours,  String? phone,  String? email,  String? website,  double? rating,  int? reviewCount)  $default,) {final _that = this;
switch (_that) {
case _BusinessDetails():
return $default(_that.id,_that.name,_that.businessCode,_that.description,_that.logoUrl,_that.locations,_that.serviceCategories,_that.hours,_that.phone,_that.email,_that.website,_that.rating,_that.reviewCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String businessCode,  String? description,  String? logoUrl,  List<BusinessLocation> locations,  List<String> serviceCategories,  BusinessHours? hours,  String? phone,  String? email,  String? website,  double? rating,  int? reviewCount)?  $default,) {final _that = this;
switch (_that) {
case _BusinessDetails() when $default != null:
return $default(_that.id,_that.name,_that.businessCode,_that.description,_that.logoUrl,_that.locations,_that.serviceCategories,_that.hours,_that.phone,_that.email,_that.website,_that.rating,_that.reviewCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessDetails implements BusinessDetails {
  const _BusinessDetails({required this.id, required this.name, required this.businessCode, this.description, this.logoUrl, final  List<BusinessLocation> locations = const [], final  List<String> serviceCategories = const [], this.hours, this.phone, this.email, this.website, this.rating, this.reviewCount}): _locations = locations,_serviceCategories = serviceCategories;
  factory _BusinessDetails.fromJson(Map<String, dynamic> json) => _$BusinessDetailsFromJson(json);

@override final  String id;
@override final  String name;
@override final  String businessCode;
@override final  String? description;
@override final  String? logoUrl;
 final  List<BusinessLocation> _locations;
@override@JsonKey() List<BusinessLocation> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

 final  List<String> _serviceCategories;
@override@JsonKey() List<String> get serviceCategories {
  if (_serviceCategories is EqualUnmodifiableListView) return _serviceCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceCategories);
}

@override final  BusinessHours? hours;
@override final  String? phone;
@override final  String? email;
@override final  String? website;
@override final  double? rating;
@override final  int? reviewCount;

/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessDetailsCopyWith<_BusinessDetails> get copyWith => __$BusinessDetailsCopyWithImpl<_BusinessDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.businessCode, businessCode) || other.businessCode == businessCode)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&const DeepCollectionEquality().equals(other._locations, _locations)&&const DeepCollectionEquality().equals(other._serviceCategories, _serviceCategories)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,businessCode,description,logoUrl,const DeepCollectionEquality().hash(_locations),const DeepCollectionEquality().hash(_serviceCategories),hours,phone,email,website,rating,reviewCount);

@override
String toString() {
  return 'BusinessDetails(id: $id, name: $name, businessCode: $businessCode, description: $description, logoUrl: $logoUrl, locations: $locations, serviceCategories: $serviceCategories, hours: $hours, phone: $phone, email: $email, website: $website, rating: $rating, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class _$BusinessDetailsCopyWith<$Res> implements $BusinessDetailsCopyWith<$Res> {
  factory _$BusinessDetailsCopyWith(_BusinessDetails value, $Res Function(_BusinessDetails) _then) = __$BusinessDetailsCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String businessCode, String? description, String? logoUrl, List<BusinessLocation> locations, List<String> serviceCategories, BusinessHours? hours, String? phone, String? email, String? website, double? rating, int? reviewCount
});


@override $BusinessHoursCopyWith<$Res>? get hours;

}
/// @nodoc
class __$BusinessDetailsCopyWithImpl<$Res>
    implements _$BusinessDetailsCopyWith<$Res> {
  __$BusinessDetailsCopyWithImpl(this._self, this._then);

  final _BusinessDetails _self;
  final $Res Function(_BusinessDetails) _then;

/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? businessCode = null,Object? description = freezed,Object? logoUrl = freezed,Object? locations = null,Object? serviceCategories = null,Object? hours = freezed,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? rating = freezed,Object? reviewCount = freezed,}) {
  return _then(_BusinessDetails(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,businessCode: null == businessCode ? _self.businessCode : businessCode // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<BusinessLocation>,serviceCategories: null == serviceCategories ? _self._serviceCategories : serviceCategories // ignore: cast_nullable_to_non_nullable
as List<String>,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as BusinessHours?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of BusinessDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<$Res>? get hours {
    if (_self.hours == null) {
    return null;
  }

  return $BusinessHoursCopyWith<$Res>(_self.hours!, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}


/// @nodoc
mixin _$BusinessLocation {

 String get id; String get name; String? get address; String? get city; String? get state; String? get zipCode; String? get phone;
/// Create a copy of BusinessLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessLocationCopyWith<BusinessLocation> get copyWith => _$BusinessLocationCopyWithImpl<BusinessLocation>(this as BusinessLocation, _$identity);

  /// Serializes this BusinessLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessLocation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.zipCode, zipCode) || other.zipCode == zipCode)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,city,state,zipCode,phone);

@override
String toString() {
  return 'BusinessLocation(id: $id, name: $name, address: $address, city: $city, state: $state, zipCode: $zipCode, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $BusinessLocationCopyWith<$Res>  {
  factory $BusinessLocationCopyWith(BusinessLocation value, $Res Function(BusinessLocation) _then) = _$BusinessLocationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? address, String? city, String? state, String? zipCode, String? phone
});




}
/// @nodoc
class _$BusinessLocationCopyWithImpl<$Res>
    implements $BusinessLocationCopyWith<$Res> {
  _$BusinessLocationCopyWithImpl(this._self, this._then);

  final BusinessLocation _self;
  final $Res Function(BusinessLocation) _then;

/// Create a copy of BusinessLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? zipCode = freezed,Object? phone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,zipCode: freezed == zipCode ? _self.zipCode : zipCode // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessLocation].
extension BusinessLocationPatterns on BusinessLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessLocation value)  $default,){
final _that = this;
switch (_that) {
case _BusinessLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessLocation value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? address,  String? city,  String? state,  String? zipCode,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessLocation() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.city,_that.state,_that.zipCode,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? address,  String? city,  String? state,  String? zipCode,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _BusinessLocation():
return $default(_that.id,_that.name,_that.address,_that.city,_that.state,_that.zipCode,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? address,  String? city,  String? state,  String? zipCode,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _BusinessLocation() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.city,_that.state,_that.zipCode,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessLocation implements BusinessLocation {
  const _BusinessLocation({required this.id, required this.name, this.address, this.city, this.state, this.zipCode, this.phone});
  factory _BusinessLocation.fromJson(Map<String, dynamic> json) => _$BusinessLocationFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? address;
@override final  String? city;
@override final  String? state;
@override final  String? zipCode;
@override final  String? phone;

/// Create a copy of BusinessLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessLocationCopyWith<_BusinessLocation> get copyWith => __$BusinessLocationCopyWithImpl<_BusinessLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessLocation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.zipCode, zipCode) || other.zipCode == zipCode)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,city,state,zipCode,phone);

@override
String toString() {
  return 'BusinessLocation(id: $id, name: $name, address: $address, city: $city, state: $state, zipCode: $zipCode, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$BusinessLocationCopyWith<$Res> implements $BusinessLocationCopyWith<$Res> {
  factory _$BusinessLocationCopyWith(_BusinessLocation value, $Res Function(_BusinessLocation) _then) = __$BusinessLocationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? address, String? city, String? state, String? zipCode, String? phone
});




}
/// @nodoc
class __$BusinessLocationCopyWithImpl<$Res>
    implements _$BusinessLocationCopyWith<$Res> {
  __$BusinessLocationCopyWithImpl(this._self, this._then);

  final _BusinessLocation _self;
  final $Res Function(_BusinessLocation) _then;

/// Create a copy of BusinessLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? zipCode = freezed,Object? phone = freezed,}) {
  return _then(_BusinessLocation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,zipCode: freezed == zipCode ? _self.zipCode : zipCode // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BusinessHours {

 DayHours? get monday; DayHours? get tuesday; DayHours? get wednesday; DayHours? get thursday; DayHours? get friday; DayHours? get saturday; DayHours? get sunday;
/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<BusinessHours> get copyWith => _$BusinessHoursCopyWithImpl<BusinessHours>(this as BusinessHours, _$identity);

  /// Serializes this BusinessHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessHours&&(identical(other.monday, monday) || other.monday == monday)&&(identical(other.tuesday, tuesday) || other.tuesday == tuesday)&&(identical(other.wednesday, wednesday) || other.wednesday == wednesday)&&(identical(other.thursday, thursday) || other.thursday == thursday)&&(identical(other.friday, friday) || other.friday == friday)&&(identical(other.saturday, saturday) || other.saturday == saturday)&&(identical(other.sunday, sunday) || other.sunday == sunday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,monday,tuesday,wednesday,thursday,friday,saturday,sunday);

@override
String toString() {
  return 'BusinessHours(monday: $monday, tuesday: $tuesday, wednesday: $wednesday, thursday: $thursday, friday: $friday, saturday: $saturday, sunday: $sunday)';
}


}

/// @nodoc
abstract mixin class $BusinessHoursCopyWith<$Res>  {
  factory $BusinessHoursCopyWith(BusinessHours value, $Res Function(BusinessHours) _then) = _$BusinessHoursCopyWithImpl;
@useResult
$Res call({
 DayHours? monday, DayHours? tuesday, DayHours? wednesday, DayHours? thursday, DayHours? friday, DayHours? saturday, DayHours? sunday
});


$DayHoursCopyWith<$Res>? get monday;$DayHoursCopyWith<$Res>? get tuesday;$DayHoursCopyWith<$Res>? get wednesday;$DayHoursCopyWith<$Res>? get thursday;$DayHoursCopyWith<$Res>? get friday;$DayHoursCopyWith<$Res>? get saturday;$DayHoursCopyWith<$Res>? get sunday;

}
/// @nodoc
class _$BusinessHoursCopyWithImpl<$Res>
    implements $BusinessHoursCopyWith<$Res> {
  _$BusinessHoursCopyWithImpl(this._self, this._then);

  final BusinessHours _self;
  final $Res Function(BusinessHours) _then;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? monday = freezed,Object? tuesday = freezed,Object? wednesday = freezed,Object? thursday = freezed,Object? friday = freezed,Object? saturday = freezed,Object? sunday = freezed,}) {
  return _then(_self.copyWith(
monday: freezed == monday ? _self.monday : monday // ignore: cast_nullable_to_non_nullable
as DayHours?,tuesday: freezed == tuesday ? _self.tuesday : tuesday // ignore: cast_nullable_to_non_nullable
as DayHours?,wednesday: freezed == wednesday ? _self.wednesday : wednesday // ignore: cast_nullable_to_non_nullable
as DayHours?,thursday: freezed == thursday ? _self.thursday : thursday // ignore: cast_nullable_to_non_nullable
as DayHours?,friday: freezed == friday ? _self.friday : friday // ignore: cast_nullable_to_non_nullable
as DayHours?,saturday: freezed == saturday ? _self.saturday : saturday // ignore: cast_nullable_to_non_nullable
as DayHours?,sunday: freezed == sunday ? _self.sunday : sunday // ignore: cast_nullable_to_non_nullable
as DayHours?,
  ));
}
/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get monday {
    if (_self.monday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.monday!, (value) {
    return _then(_self.copyWith(monday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get tuesday {
    if (_self.tuesday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.tuesday!, (value) {
    return _then(_self.copyWith(tuesday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get wednesday {
    if (_self.wednesday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.wednesday!, (value) {
    return _then(_self.copyWith(wednesday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get thursday {
    if (_self.thursday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.thursday!, (value) {
    return _then(_self.copyWith(thursday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get friday {
    if (_self.friday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.friday!, (value) {
    return _then(_self.copyWith(friday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get saturday {
    if (_self.saturday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.saturday!, (value) {
    return _then(_self.copyWith(saturday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get sunday {
    if (_self.sunday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.sunday!, (value) {
    return _then(_self.copyWith(sunday: value));
  });
}
}


/// Adds pattern-matching-related methods to [BusinessHours].
extension BusinessHoursPatterns on BusinessHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessHours value)  $default,){
final _that = this;
switch (_that) {
case _BusinessHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessHours value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DayHours? monday,  DayHours? tuesday,  DayHours? wednesday,  DayHours? thursday,  DayHours? friday,  DayHours? saturday,  DayHours? sunday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
return $default(_that.monday,_that.tuesday,_that.wednesday,_that.thursday,_that.friday,_that.saturday,_that.sunday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DayHours? monday,  DayHours? tuesday,  DayHours? wednesday,  DayHours? thursday,  DayHours? friday,  DayHours? saturday,  DayHours? sunday)  $default,) {final _that = this;
switch (_that) {
case _BusinessHours():
return $default(_that.monday,_that.tuesday,_that.wednesday,_that.thursday,_that.friday,_that.saturday,_that.sunday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DayHours? monday,  DayHours? tuesday,  DayHours? wednesday,  DayHours? thursday,  DayHours? friday,  DayHours? saturday,  DayHours? sunday)?  $default,) {final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
return $default(_that.monday,_that.tuesday,_that.wednesday,_that.thursday,_that.friday,_that.saturday,_that.sunday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessHours implements BusinessHours {
  const _BusinessHours({this.monday, this.tuesday, this.wednesday, this.thursday, this.friday, this.saturday, this.sunday});
  factory _BusinessHours.fromJson(Map<String, dynamic> json) => _$BusinessHoursFromJson(json);

@override final  DayHours? monday;
@override final  DayHours? tuesday;
@override final  DayHours? wednesday;
@override final  DayHours? thursday;
@override final  DayHours? friday;
@override final  DayHours? saturday;
@override final  DayHours? sunday;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessHoursCopyWith<_BusinessHours> get copyWith => __$BusinessHoursCopyWithImpl<_BusinessHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessHours&&(identical(other.monday, monday) || other.monday == monday)&&(identical(other.tuesday, tuesday) || other.tuesday == tuesday)&&(identical(other.wednesday, wednesday) || other.wednesday == wednesday)&&(identical(other.thursday, thursday) || other.thursday == thursday)&&(identical(other.friday, friday) || other.friday == friday)&&(identical(other.saturday, saturday) || other.saturday == saturday)&&(identical(other.sunday, sunday) || other.sunday == sunday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,monday,tuesday,wednesday,thursday,friday,saturday,sunday);

@override
String toString() {
  return 'BusinessHours(monday: $monday, tuesday: $tuesday, wednesday: $wednesday, thursday: $thursday, friday: $friday, saturday: $saturday, sunday: $sunday)';
}


}

/// @nodoc
abstract mixin class _$BusinessHoursCopyWith<$Res> implements $BusinessHoursCopyWith<$Res> {
  factory _$BusinessHoursCopyWith(_BusinessHours value, $Res Function(_BusinessHours) _then) = __$BusinessHoursCopyWithImpl;
@override @useResult
$Res call({
 DayHours? monday, DayHours? tuesday, DayHours? wednesday, DayHours? thursday, DayHours? friday, DayHours? saturday, DayHours? sunday
});


@override $DayHoursCopyWith<$Res>? get monday;@override $DayHoursCopyWith<$Res>? get tuesday;@override $DayHoursCopyWith<$Res>? get wednesday;@override $DayHoursCopyWith<$Res>? get thursday;@override $DayHoursCopyWith<$Res>? get friday;@override $DayHoursCopyWith<$Res>? get saturday;@override $DayHoursCopyWith<$Res>? get sunday;

}
/// @nodoc
class __$BusinessHoursCopyWithImpl<$Res>
    implements _$BusinessHoursCopyWith<$Res> {
  __$BusinessHoursCopyWithImpl(this._self, this._then);

  final _BusinessHours _self;
  final $Res Function(_BusinessHours) _then;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? monday = freezed,Object? tuesday = freezed,Object? wednesday = freezed,Object? thursday = freezed,Object? friday = freezed,Object? saturday = freezed,Object? sunday = freezed,}) {
  return _then(_BusinessHours(
monday: freezed == monday ? _self.monday : monday // ignore: cast_nullable_to_non_nullable
as DayHours?,tuesday: freezed == tuesday ? _self.tuesday : tuesday // ignore: cast_nullable_to_non_nullable
as DayHours?,wednesday: freezed == wednesday ? _self.wednesday : wednesday // ignore: cast_nullable_to_non_nullable
as DayHours?,thursday: freezed == thursday ? _self.thursday : thursday // ignore: cast_nullable_to_non_nullable
as DayHours?,friday: freezed == friday ? _self.friday : friday // ignore: cast_nullable_to_non_nullable
as DayHours?,saturday: freezed == saturday ? _self.saturday : saturday // ignore: cast_nullable_to_non_nullable
as DayHours?,sunday: freezed == sunday ? _self.sunday : sunday // ignore: cast_nullable_to_non_nullable
as DayHours?,
  ));
}

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get monday {
    if (_self.monday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.monday!, (value) {
    return _then(_self.copyWith(monday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get tuesday {
    if (_self.tuesday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.tuesday!, (value) {
    return _then(_self.copyWith(tuesday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get wednesday {
    if (_self.wednesday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.wednesday!, (value) {
    return _then(_self.copyWith(wednesday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get thursday {
    if (_self.thursday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.thursday!, (value) {
    return _then(_self.copyWith(thursday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get friday {
    if (_self.friday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.friday!, (value) {
    return _then(_self.copyWith(friday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get saturday {
    if (_self.saturday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.saturday!, (value) {
    return _then(_self.copyWith(saturday: value));
  });
}/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get sunday {
    if (_self.sunday == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.sunday!, (value) {
    return _then(_self.copyWith(sunday: value));
  });
}
}


/// @nodoc
mixin _$DayHours {

 bool get isOpen; String? get openTime; String? get closeTime;
/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayHoursCopyWith<DayHours> get copyWith => _$DayHoursCopyWithImpl<DayHours>(this as DayHours, _$identity);

  /// Serializes this DayHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayHours&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOpen,openTime,closeTime);

@override
String toString() {
  return 'DayHours(isOpen: $isOpen, openTime: $openTime, closeTime: $closeTime)';
}


}

/// @nodoc
abstract mixin class $DayHoursCopyWith<$Res>  {
  factory $DayHoursCopyWith(DayHours value, $Res Function(DayHours) _then) = _$DayHoursCopyWithImpl;
@useResult
$Res call({
 bool isOpen, String? openTime, String? closeTime
});




}
/// @nodoc
class _$DayHoursCopyWithImpl<$Res>
    implements $DayHoursCopyWith<$Res> {
  _$DayHoursCopyWithImpl(this._self, this._then);

  final DayHours _self;
  final $Res Function(DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOpen = null,Object? openTime = freezed,Object? closeTime = freezed,}) {
  return _then(_self.copyWith(
isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,openTime: freezed == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as String?,closeTime: freezed == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayHours].
extension DayHoursPatterns on DayHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayHours value)  $default,){
final _that = this;
switch (_that) {
case _DayHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayHours value)?  $default,){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOpen,  String? openTime,  String? closeTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.isOpen,_that.openTime,_that.closeTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOpen,  String? openTime,  String? closeTime)  $default,) {final _that = this;
switch (_that) {
case _DayHours():
return $default(_that.isOpen,_that.openTime,_that.closeTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOpen,  String? openTime,  String? closeTime)?  $default,) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.isOpen,_that.openTime,_that.closeTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayHours implements DayHours {
  const _DayHours({required this.isOpen, this.openTime, this.closeTime});
  factory _DayHours.fromJson(Map<String, dynamic> json) => _$DayHoursFromJson(json);

@override final  bool isOpen;
@override final  String? openTime;
@override final  String? closeTime;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayHoursCopyWith<_DayHours> get copyWith => __$DayHoursCopyWithImpl<_DayHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayHours&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOpen,openTime,closeTime);

@override
String toString() {
  return 'DayHours(isOpen: $isOpen, openTime: $openTime, closeTime: $closeTime)';
}


}

/// @nodoc
abstract mixin class _$DayHoursCopyWith<$Res> implements $DayHoursCopyWith<$Res> {
  factory _$DayHoursCopyWith(_DayHours value, $Res Function(_DayHours) _then) = __$DayHoursCopyWithImpl;
@override @useResult
$Res call({
 bool isOpen, String? openTime, String? closeTime
});




}
/// @nodoc
class __$DayHoursCopyWithImpl<$Res>
    implements _$DayHoursCopyWith<$Res> {
  __$DayHoursCopyWithImpl(this._self, this._then);

  final _DayHours _self;
  final $Res Function(_DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOpen = null,Object? openTime = freezed,Object? closeTime = freezed,}) {
  return _then(_DayHours(
isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,openTime: freezed == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as String?,closeTime: freezed == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
