// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intake_form.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FormField {

 String get id; String get label; FormFieldType get type; String? get placeholder; String? get helpText; bool get required; List<String> get options;// For dropdown/radio
 String? get validation;// Regex pattern for validation
 Map<String, dynamic> get metadata;
/// Create a copy of FormField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormFieldCopyWith<FormField> get copyWith => _$FormFieldCopyWithImpl<FormField>(this as FormField, _$identity);

  /// Serializes this FormField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormField&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder)&&(identical(other.helpText, helpText) || other.helpText == helpText)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.validation, validation) || other.validation == validation)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,type,placeholder,helpText,required,const DeepCollectionEquality().hash(options),validation,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'FormField(id: $id, label: $label, type: $type, placeholder: $placeholder, helpText: $helpText, required: $required, options: $options, validation: $validation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $FormFieldCopyWith<$Res>  {
  factory $FormFieldCopyWith(FormField value, $Res Function(FormField) _then) = _$FormFieldCopyWithImpl;
@useResult
$Res call({
 String id, String label, FormFieldType type, String? placeholder, String? helpText, bool required, List<String> options, String? validation, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$FormFieldCopyWithImpl<$Res>
    implements $FormFieldCopyWith<$Res> {
  _$FormFieldCopyWithImpl(this._self, this._then);

  final FormField _self;
  final $Res Function(FormField) _then;

/// Create a copy of FormField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? type = null,Object? placeholder = freezed,Object? helpText = freezed,Object? required = null,Object? options = null,Object? validation = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FormFieldType,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as String?,helpText: freezed == helpText ? _self.helpText : helpText // ignore: cast_nullable_to_non_nullable
as String?,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,validation: freezed == validation ? _self.validation : validation // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [FormField].
extension FormFieldPatterns on FormField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormField value)  $default,){
final _that = this;
switch (_that) {
case _FormField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormField value)?  $default,){
final _that = this;
switch (_that) {
case _FormField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  FormFieldType type,  String? placeholder,  String? helpText,  bool required,  List<String> options,  String? validation,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormField() when $default != null:
return $default(_that.id,_that.label,_that.type,_that.placeholder,_that.helpText,_that.required,_that.options,_that.validation,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  FormFieldType type,  String? placeholder,  String? helpText,  bool required,  List<String> options,  String? validation,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _FormField():
return $default(_that.id,_that.label,_that.type,_that.placeholder,_that.helpText,_that.required,_that.options,_that.validation,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  FormFieldType type,  String? placeholder,  String? helpText,  bool required,  List<String> options,  String? validation,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _FormField() when $default != null:
return $default(_that.id,_that.label,_that.type,_that.placeholder,_that.helpText,_that.required,_that.options,_that.validation,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FormField implements FormField {
  const _FormField({required this.id, required this.label, required this.type, this.placeholder, this.helpText, this.required = false, final  List<String> options = const [], this.validation, final  Map<String, dynamic> metadata = const {}}): _options = options,_metadata = metadata;
  factory _FormField.fromJson(Map<String, dynamic> json) => _$FormFieldFromJson(json);

@override final  String id;
@override final  String label;
@override final  FormFieldType type;
@override final  String? placeholder;
@override final  String? helpText;
@override@JsonKey() final  bool required;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

// For dropdown/radio
@override final  String? validation;
// Regex pattern for validation
 final  Map<String, dynamic> _metadata;
// Regex pattern for validation
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of FormField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormFieldCopyWith<_FormField> get copyWith => __$FormFieldCopyWithImpl<_FormField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormField&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder)&&(identical(other.helpText, helpText) || other.helpText == helpText)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.validation, validation) || other.validation == validation)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,type,placeholder,helpText,required,const DeepCollectionEquality().hash(_options),validation,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'FormField(id: $id, label: $label, type: $type, placeholder: $placeholder, helpText: $helpText, required: $required, options: $options, validation: $validation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$FormFieldCopyWith<$Res> implements $FormFieldCopyWith<$Res> {
  factory _$FormFieldCopyWith(_FormField value, $Res Function(_FormField) _then) = __$FormFieldCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, FormFieldType type, String? placeholder, String? helpText, bool required, List<String> options, String? validation, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$FormFieldCopyWithImpl<$Res>
    implements _$FormFieldCopyWith<$Res> {
  __$FormFieldCopyWithImpl(this._self, this._then);

  final _FormField _self;
  final $Res Function(_FormField) _then;

/// Create a copy of FormField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? type = null,Object? placeholder = freezed,Object? helpText = freezed,Object? required = null,Object? options = null,Object? validation = freezed,Object? metadata = null,}) {
  return _then(_FormField(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FormFieldType,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as String?,helpText: freezed == helpText ? _self.helpText : helpText // ignore: cast_nullable_to_non_nullable
as String?,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,validation: freezed == validation ? _self.validation : validation // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$IntakeFormTemplate {

 String get id; String get businessId; String get name; String? get description; List<FormField> get fields; List<String> get applicableIndustries;// therapist, dentist, etc.
 bool get isActive;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt; int? get version;
/// Create a copy of IntakeFormTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeFormTemplateCopyWith<IntakeFormTemplate> get copyWith => _$IntakeFormTemplateCopyWithImpl<IntakeFormTemplate>(this as IntakeFormTemplate, _$identity);

  /// Serializes this IntakeFormTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeFormTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.applicableIndustries, applicableIndustries)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,description,const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(applicableIndustries),isActive,createdAt,updatedAt,version);

@override
String toString() {
  return 'IntakeFormTemplate(id: $id, businessId: $businessId, name: $name, description: $description, fields: $fields, applicableIndustries: $applicableIndustries, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, version: $version)';
}


}

/// @nodoc
abstract mixin class $IntakeFormTemplateCopyWith<$Res>  {
  factory $IntakeFormTemplateCopyWith(IntakeFormTemplate value, $Res Function(IntakeFormTemplate) _then) = _$IntakeFormTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, String? description, List<FormField> fields, List<String> applicableIndustries, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, int? version
});




}
/// @nodoc
class _$IntakeFormTemplateCopyWithImpl<$Res>
    implements $IntakeFormTemplateCopyWith<$Res> {
  _$IntakeFormTemplateCopyWithImpl(this._self, this._then);

  final IntakeFormTemplate _self;
  final $Res Function(IntakeFormTemplate) _then;

/// Create a copy of IntakeFormTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? fields = null,Object? applicableIndustries = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,Object? version = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormField>,applicableIndustries: null == applicableIndustries ? _self.applicableIndustries : applicableIndustries // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [IntakeFormTemplate].
extension IntakeFormTemplatePatterns on IntakeFormTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntakeFormTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntakeFormTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntakeFormTemplate value)  $default,){
final _that = this;
switch (_that) {
case _IntakeFormTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntakeFormTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _IntakeFormTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  List<FormField> fields,  List<String> applicableIndustries,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  int? version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntakeFormTemplate() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.fields,_that.applicableIndustries,_that.isActive,_that.createdAt,_that.updatedAt,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  List<FormField> fields,  List<String> applicableIndustries,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  int? version)  $default,) {final _that = this;
switch (_that) {
case _IntakeFormTemplate():
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.fields,_that.applicableIndustries,_that.isActive,_that.createdAt,_that.updatedAt,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  String? description,  List<FormField> fields,  List<String> applicableIndustries,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  int? version)?  $default,) {final _that = this;
switch (_that) {
case _IntakeFormTemplate() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.fields,_that.applicableIndustries,_that.isActive,_that.createdAt,_that.updatedAt,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntakeFormTemplate extends IntakeFormTemplate {
  const _IntakeFormTemplate({required this.id, required this.businessId, required this.name, this.description, final  List<FormField> fields = const [], final  List<String> applicableIndustries = const [], this.isActive = true, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt, this.version}): _fields = fields,_applicableIndustries = applicableIndustries,super._();
  factory _IntakeFormTemplate.fromJson(Map<String, dynamic> json) => _$IntakeFormTemplateFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String name;
@override final  String? description;
 final  List<FormField> _fields;
@override@JsonKey() List<FormField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<String> _applicableIndustries;
@override@JsonKey() List<String> get applicableIndustries {
  if (_applicableIndustries is EqualUnmodifiableListView) return _applicableIndustries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_applicableIndustries);
}

// therapist, dentist, etc.
@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;
@override final  int? version;

/// Create a copy of IntakeFormTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntakeFormTemplateCopyWith<_IntakeFormTemplate> get copyWith => __$IntakeFormTemplateCopyWithImpl<_IntakeFormTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntakeFormTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntakeFormTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._applicableIndustries, _applicableIndustries)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,name,description,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_applicableIndustries),isActive,createdAt,updatedAt,version);

@override
String toString() {
  return 'IntakeFormTemplate(id: $id, businessId: $businessId, name: $name, description: $description, fields: $fields, applicableIndustries: $applicableIndustries, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, version: $version)';
}


}

/// @nodoc
abstract mixin class _$IntakeFormTemplateCopyWith<$Res> implements $IntakeFormTemplateCopyWith<$Res> {
  factory _$IntakeFormTemplateCopyWith(_IntakeFormTemplate value, $Res Function(_IntakeFormTemplate) _then) = __$IntakeFormTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, String? description, List<FormField> fields, List<String> applicableIndustries, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, int? version
});




}
/// @nodoc
class __$IntakeFormTemplateCopyWithImpl<$Res>
    implements _$IntakeFormTemplateCopyWith<$Res> {
  __$IntakeFormTemplateCopyWithImpl(this._self, this._then);

  final _IntakeFormTemplate _self;
  final $Res Function(_IntakeFormTemplate) _then;

/// Create a copy of IntakeFormTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? fields = null,Object? applicableIndustries = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,Object? version = freezed,}) {
  return _then(_IntakeFormTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormField>,applicableIndustries: null == applicableIndustries ? _self._applicableIndustries : applicableIndustries // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$IntakeFormSubmission {

 String get id; String get businessId; String get clientId; String get templateId; String? get templateName; int? get templateVersion; Map<String, dynamic> get responses;// fieldId -> value
@TimestampConverter() DateTime get submittedAt; String? get submittedBy;
/// Create a copy of IntakeFormSubmission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeFormSubmissionCopyWith<IntakeFormSubmission> get copyWith => _$IntakeFormSubmissionCopyWithImpl<IntakeFormSubmission>(this as IntakeFormSubmission, _$identity);

  /// Serializes this IntakeFormSubmission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeFormSubmission&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.templateVersion, templateVersion) || other.templateVersion == templateVersion)&&const DeepCollectionEquality().equals(other.responses, responses)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.submittedBy, submittedBy) || other.submittedBy == submittedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,clientId,templateId,templateName,templateVersion,const DeepCollectionEquality().hash(responses),submittedAt,submittedBy);

@override
String toString() {
  return 'IntakeFormSubmission(id: $id, businessId: $businessId, clientId: $clientId, templateId: $templateId, templateName: $templateName, templateVersion: $templateVersion, responses: $responses, submittedAt: $submittedAt, submittedBy: $submittedBy)';
}


}

/// @nodoc
abstract mixin class $IntakeFormSubmissionCopyWith<$Res>  {
  factory $IntakeFormSubmissionCopyWith(IntakeFormSubmission value, $Res Function(IntakeFormSubmission) _then) = _$IntakeFormSubmissionCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String clientId, String templateId, String? templateName, int? templateVersion, Map<String, dynamic> responses,@TimestampConverter() DateTime submittedAt, String? submittedBy
});




}
/// @nodoc
class _$IntakeFormSubmissionCopyWithImpl<$Res>
    implements $IntakeFormSubmissionCopyWith<$Res> {
  _$IntakeFormSubmissionCopyWithImpl(this._self, this._then);

  final IntakeFormSubmission _self;
  final $Res Function(IntakeFormSubmission) _then;

/// Create a copy of IntakeFormSubmission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? templateId = null,Object? templateName = freezed,Object? templateVersion = freezed,Object? responses = null,Object? submittedAt = null,Object? submittedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,templateVersion: freezed == templateVersion ? _self.templateVersion : templateVersion // ignore: cast_nullable_to_non_nullable
as int?,responses: null == responses ? _self.responses : responses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,submittedBy: freezed == submittedBy ? _self.submittedBy : submittedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IntakeFormSubmission].
extension IntakeFormSubmissionPatterns on IntakeFormSubmission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntakeFormSubmission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntakeFormSubmission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntakeFormSubmission value)  $default,){
final _that = this;
switch (_that) {
case _IntakeFormSubmission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntakeFormSubmission value)?  $default,){
final _that = this;
switch (_that) {
case _IntakeFormSubmission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  String templateId,  String? templateName,  int? templateVersion,  Map<String, dynamic> responses, @TimestampConverter()  DateTime submittedAt,  String? submittedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntakeFormSubmission() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.templateId,_that.templateName,_that.templateVersion,_that.responses,_that.submittedAt,_that.submittedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String clientId,  String templateId,  String? templateName,  int? templateVersion,  Map<String, dynamic> responses, @TimestampConverter()  DateTime submittedAt,  String? submittedBy)  $default,) {final _that = this;
switch (_that) {
case _IntakeFormSubmission():
return $default(_that.id,_that.businessId,_that.clientId,_that.templateId,_that.templateName,_that.templateVersion,_that.responses,_that.submittedAt,_that.submittedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String clientId,  String templateId,  String? templateName,  int? templateVersion,  Map<String, dynamic> responses, @TimestampConverter()  DateTime submittedAt,  String? submittedBy)?  $default,) {final _that = this;
switch (_that) {
case _IntakeFormSubmission() when $default != null:
return $default(_that.id,_that.businessId,_that.clientId,_that.templateId,_that.templateName,_that.templateVersion,_that.responses,_that.submittedAt,_that.submittedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntakeFormSubmission extends IntakeFormSubmission {
  const _IntakeFormSubmission({required this.id, required this.businessId, required this.clientId, required this.templateId, this.templateName, this.templateVersion, required final  Map<String, dynamic> responses, @TimestampConverter() required this.submittedAt, this.submittedBy}): _responses = responses,super._();
  factory _IntakeFormSubmission.fromJson(Map<String, dynamic> json) => _$IntakeFormSubmissionFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String clientId;
@override final  String templateId;
@override final  String? templateName;
@override final  int? templateVersion;
 final  Map<String, dynamic> _responses;
@override Map<String, dynamic> get responses {
  if (_responses is EqualUnmodifiableMapView) return _responses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_responses);
}

// fieldId -> value
@override@TimestampConverter() final  DateTime submittedAt;
@override final  String? submittedBy;

/// Create a copy of IntakeFormSubmission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntakeFormSubmissionCopyWith<_IntakeFormSubmission> get copyWith => __$IntakeFormSubmissionCopyWithImpl<_IntakeFormSubmission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntakeFormSubmissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntakeFormSubmission&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.templateVersion, templateVersion) || other.templateVersion == templateVersion)&&const DeepCollectionEquality().equals(other._responses, _responses)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.submittedBy, submittedBy) || other.submittedBy == submittedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,clientId,templateId,templateName,templateVersion,const DeepCollectionEquality().hash(_responses),submittedAt,submittedBy);

@override
String toString() {
  return 'IntakeFormSubmission(id: $id, businessId: $businessId, clientId: $clientId, templateId: $templateId, templateName: $templateName, templateVersion: $templateVersion, responses: $responses, submittedAt: $submittedAt, submittedBy: $submittedBy)';
}


}

/// @nodoc
abstract mixin class _$IntakeFormSubmissionCopyWith<$Res> implements $IntakeFormSubmissionCopyWith<$Res> {
  factory _$IntakeFormSubmissionCopyWith(_IntakeFormSubmission value, $Res Function(_IntakeFormSubmission) _then) = __$IntakeFormSubmissionCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String clientId, String templateId, String? templateName, int? templateVersion, Map<String, dynamic> responses,@TimestampConverter() DateTime submittedAt, String? submittedBy
});




}
/// @nodoc
class __$IntakeFormSubmissionCopyWithImpl<$Res>
    implements _$IntakeFormSubmissionCopyWith<$Res> {
  __$IntakeFormSubmissionCopyWithImpl(this._self, this._then);

  final _IntakeFormSubmission _self;
  final $Res Function(_IntakeFormSubmission) _then;

/// Create a copy of IntakeFormSubmission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? clientId = null,Object? templateId = null,Object? templateName = freezed,Object? templateVersion = freezed,Object? responses = null,Object? submittedAt = null,Object? submittedBy = freezed,}) {
  return _then(_IntakeFormSubmission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,templateVersion: freezed == templateVersion ? _self.templateVersion : templateVersion // ignore: cast_nullable_to_non_nullable
as int?,responses: null == responses ? _self._responses : responses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,submittedBy: freezed == submittedBy ? _self.submittedBy : submittedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
