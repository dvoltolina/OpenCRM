// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_card_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftCardTemplate {

/// Unique template ID
 String get id;/// Business ID this template belongs to
 String get businessId;/// Template display name
 String get name;/// Template description
 String get description;/// Template image URL
 String get imageUrl;/// Background color (hex string, e.g., "#FF5733")
 String get backgroundColor;/// Text color (hex string, e.g., "#FFFFFF")
 String get textColor;/// Preset amounts in cents (null = custom amounts allowed)
 List<int>? get presetAmountsCents;/// Minimum allowed amount in cents
 int? get minAmountCents;/// Maximum allowed amount in cents
 int? get maxAmountCents;/// Number of days the gift card is valid (null = never expires)
 int? get validityDays;/// Whether the template is active and available for selection
 bool get isActive;/// When the template was created
@TimestampConverter() DateTime get createdAt;
/// Create a copy of GiftCardTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftCardTemplateCopyWith<GiftCardTemplate> get copyWith => _$GiftCardTemplateCopyWithImpl<GiftCardTemplate>(this as GiftCardTemplate, _$identity);

  /// Serializes this GiftCardTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftCardTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&const DeepCollectionEquality().equals(other.presetAmountsCents, presetAmountsCents)&&(identical(other.minAmountCents, minAmountCents) || other.minAmountCents == minAmountCents)&&(identical(other.maxAmountCents, maxAmountCents) || other.maxAmountCents == maxAmountCents)&&(identical(other.validityDays, validityDays) || other.validityDays == validityDays)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,description,imageUrl,backgroundColor,textColor,const DeepCollectionEquality().hash(presetAmountsCents),minAmountCents,maxAmountCents,validityDays,isActive,createdAt);

@override
String toString() {
  return 'GiftCardTemplate(id: $id, businessId: $businessId, name: $name, description: $description, imageUrl: $imageUrl, backgroundColor: $backgroundColor, textColor: $textColor, presetAmountsCents: $presetAmountsCents, minAmountCents: $minAmountCents, maxAmountCents: $maxAmountCents, validityDays: $validityDays, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GiftCardTemplateCopyWith<$Res>  {
  factory $GiftCardTemplateCopyWith(GiftCardTemplate value, $Res Function(GiftCardTemplate) _then) = _$GiftCardTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, String description, String imageUrl, String backgroundColor, String textColor, List<int>? presetAmountsCents, int? minAmountCents, int? maxAmountCents, int? validityDays, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$GiftCardTemplateCopyWithImpl<$Res>
    implements $GiftCardTemplateCopyWith<$Res> {
  _$GiftCardTemplateCopyWithImpl(this._self, this._then);

  final GiftCardTemplate _self;
  final $Res Function(GiftCardTemplate) _then;

/// Create a copy of GiftCardTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = null,Object? imageUrl = null,Object? backgroundColor = null,Object? textColor = null,Object? presetAmountsCents = freezed,Object? minAmountCents = freezed,Object? maxAmountCents = freezed,Object? validityDays = freezed,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String,presetAmountsCents: freezed == presetAmountsCents ? _self.presetAmountsCents : presetAmountsCents // ignore: cast_nullable_to_non_nullable
as List<int>?,minAmountCents: freezed == minAmountCents ? _self.minAmountCents : minAmountCents // ignore: cast_nullable_to_non_nullable
as int?,maxAmountCents: freezed == maxAmountCents ? _self.maxAmountCents : maxAmountCents // ignore: cast_nullable_to_non_nullable
as int?,validityDays: freezed == validityDays ? _self.validityDays : validityDays // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftCardTemplate].
extension GiftCardTemplatePatterns on GiftCardTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftCardTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftCardTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftCardTemplate value)  $default,){
final _that = this;
switch (_that) {
case _GiftCardTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftCardTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _GiftCardTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String description,  String imageUrl,  String backgroundColor,  String textColor,  List<int>? presetAmountsCents,  int? minAmountCents,  int? maxAmountCents,  int? validityDays,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftCardTemplate() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.imageUrl,_that.backgroundColor,_that.textColor,_that.presetAmountsCents,_that.minAmountCents,_that.maxAmountCents,_that.validityDays,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String description,  String imageUrl,  String backgroundColor,  String textColor,  List<int>? presetAmountsCents,  int? minAmountCents,  int? maxAmountCents,  int? validityDays,  bool isActive, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _GiftCardTemplate():
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.imageUrl,_that.backgroundColor,_that.textColor,_that.presetAmountsCents,_that.minAmountCents,_that.maxAmountCents,_that.validityDays,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  String description,  String imageUrl,  String backgroundColor,  String textColor,  List<int>? presetAmountsCents,  int? minAmountCents,  int? maxAmountCents,  int? validityDays,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GiftCardTemplate() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.imageUrl,_that.backgroundColor,_that.textColor,_that.presetAmountsCents,_that.minAmountCents,_that.maxAmountCents,_that.validityDays,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftCardTemplate extends GiftCardTemplate {
  const _GiftCardTemplate({required this.id, required this.businessId, required this.name, required this.description, required this.imageUrl, required this.backgroundColor, required this.textColor, final  List<int>? presetAmountsCents, this.minAmountCents, this.maxAmountCents, this.validityDays, this.isActive = true, @TimestampConverter() required this.createdAt}): _presetAmountsCents = presetAmountsCents,super._();
  factory _GiftCardTemplate.fromJson(Map<String, dynamic> json) => _$GiftCardTemplateFromJson(json);

/// Unique template ID
@override final  String id;
/// Business ID this template belongs to
@override final  String businessId;
/// Template display name
@override final  String name;
/// Template description
@override final  String description;
/// Template image URL
@override final  String imageUrl;
/// Background color (hex string, e.g., "#FF5733")
@override final  String backgroundColor;
/// Text color (hex string, e.g., "#FFFFFF")
@override final  String textColor;
/// Preset amounts in cents (null = custom amounts allowed)
 final  List<int>? _presetAmountsCents;
/// Preset amounts in cents (null = custom amounts allowed)
@override List<int>? get presetAmountsCents {
  final value = _presetAmountsCents;
  if (value == null) return null;
  if (_presetAmountsCents is EqualUnmodifiableListView) return _presetAmountsCents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Minimum allowed amount in cents
@override final  int? minAmountCents;
/// Maximum allowed amount in cents
@override final  int? maxAmountCents;
/// Number of days the gift card is valid (null = never expires)
@override final  int? validityDays;
/// Whether the template is active and available for selection
@override@JsonKey() final  bool isActive;
/// When the template was created
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of GiftCardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftCardTemplateCopyWith<_GiftCardTemplate> get copyWith => __$GiftCardTemplateCopyWithImpl<_GiftCardTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftCardTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftCardTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&const DeepCollectionEquality().equals(other._presetAmountsCents, _presetAmountsCents)&&(identical(other.minAmountCents, minAmountCents) || other.minAmountCents == minAmountCents)&&(identical(other.maxAmountCents, maxAmountCents) || other.maxAmountCents == maxAmountCents)&&(identical(other.validityDays, validityDays) || other.validityDays == validityDays)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,description,imageUrl,backgroundColor,textColor,const DeepCollectionEquality().hash(_presetAmountsCents),minAmountCents,maxAmountCents,validityDays,isActive,createdAt);

@override
String toString() {
  return 'GiftCardTemplate(id: $id, businessId: $businessId, name: $name, description: $description, imageUrl: $imageUrl, backgroundColor: $backgroundColor, textColor: $textColor, presetAmountsCents: $presetAmountsCents, minAmountCents: $minAmountCents, maxAmountCents: $maxAmountCents, validityDays: $validityDays, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GiftCardTemplateCopyWith<$Res> implements $GiftCardTemplateCopyWith<$Res> {
  factory _$GiftCardTemplateCopyWith(_GiftCardTemplate value, $Res Function(_GiftCardTemplate) _then) = __$GiftCardTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, String description, String imageUrl, String backgroundColor, String textColor, List<int>? presetAmountsCents, int? minAmountCents, int? maxAmountCents, int? validityDays, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$GiftCardTemplateCopyWithImpl<$Res>
    implements _$GiftCardTemplateCopyWith<$Res> {
  __$GiftCardTemplateCopyWithImpl(this._self, this._then);

  final _GiftCardTemplate _self;
  final $Res Function(_GiftCardTemplate) _then;

/// Create a copy of GiftCardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = null,Object? imageUrl = null,Object? backgroundColor = null,Object? textColor = null,Object? presetAmountsCents = freezed,Object? minAmountCents = freezed,Object? maxAmountCents = freezed,Object? validityDays = freezed,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_GiftCardTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String,presetAmountsCents: freezed == presetAmountsCents ? _self._presetAmountsCents : presetAmountsCents // ignore: cast_nullable_to_non_nullable
as List<int>?,minAmountCents: freezed == minAmountCents ? _self.minAmountCents : minAmountCents // ignore: cast_nullable_to_non_nullable
as int?,maxAmountCents: freezed == maxAmountCents ? _self.maxAmountCents : maxAmountCents // ignore: cast_nullable_to_non_nullable
as int?,validityDays: freezed == validityDays ? _self.validityDays : validityDays // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
