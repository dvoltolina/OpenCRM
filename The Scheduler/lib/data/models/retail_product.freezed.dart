// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retail_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RetailProduct {

/// Unique product ID
 String get id;/// Business ID this product belongs to
 String get businessId;/// Product name
 String get name;/// Product description
 String? get description;/// Stock Keeping Unit (SKU) for inventory management
 String? get sku;/// Barcode (UPC/EAN) for scanner integration
 String? get barcode;/// Price in cents
 int get priceCents;/// Cost in cents (for profit tracking)
 int? get costCents;/// Product category
 ProductCategory get category;/// Tags for filtering/searching
 List<String> get tags;/// Whether to track inventory levels
 bool get trackInventory;/// Current stock quantity (when trackInventory is true)
 int? get stockQuantity;/// Low stock threshold for alerts
 int? get lowStockThreshold;/// Primary product image URL
 String? get imageUrl;/// Additional product images
 List<String> get additionalImages;/// Whether product is active (visible in system)
 bool get isActive;/// Whether product is available for sale
 bool get availableForSale;/// Whether product is taxable
 bool get taxable;/// Tax category ID (for tax rate lookup)
 String? get taxCategoryId;/// Optional: link to service ID if sold as add-on
 String? get linkedServiceId;/// Sort order for display
 int get sortOrder;/// When the product was created
@TimestampConverter() DateTime get createdAt;/// When the product was last updated
@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of RetailProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetailProductCopyWith<RetailProduct> get copyWith => _$RetailProductCopyWithImpl<RetailProduct>(this as RetailProduct, _$identity);

  /// Serializes this RetailProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetailProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.additionalImages, additionalImages)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.availableForSale, availableForSale) || other.availableForSale == availableForSale)&&(identical(other.taxable, taxable) || other.taxable == taxable)&&(identical(other.taxCategoryId, taxCategoryId) || other.taxCategoryId == taxCategoryId)&&(identical(other.linkedServiceId, linkedServiceId) || other.linkedServiceId == linkedServiceId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,sku,barcode,priceCents,costCents,category,const DeepCollectionEquality().hash(tags),trackInventory,stockQuantity,lowStockThreshold,imageUrl,const DeepCollectionEquality().hash(additionalImages),isActive,availableForSale,taxable,taxCategoryId,linkedServiceId,sortOrder,createdAt,updatedAt]);

@override
String toString() {
  return 'RetailProduct(id: $id, businessId: $businessId, name: $name, description: $description, sku: $sku, barcode: $barcode, priceCents: $priceCents, costCents: $costCents, category: $category, tags: $tags, trackInventory: $trackInventory, stockQuantity: $stockQuantity, lowStockThreshold: $lowStockThreshold, imageUrl: $imageUrl, additionalImages: $additionalImages, isActive: $isActive, availableForSale: $availableForSale, taxable: $taxable, taxCategoryId: $taxCategoryId, linkedServiceId: $linkedServiceId, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RetailProductCopyWith<$Res>  {
  factory $RetailProductCopyWith(RetailProduct value, $Res Function(RetailProduct) _then) = _$RetailProductCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, String? description, String? sku, String? barcode, int priceCents, int? costCents, ProductCategory category, List<String> tags, bool trackInventory, int? stockQuantity, int? lowStockThreshold, String? imageUrl, List<String> additionalImages, bool isActive, bool availableForSale, bool taxable, String? taxCategoryId, String? linkedServiceId, int sortOrder,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$RetailProductCopyWithImpl<$Res>
    implements $RetailProductCopyWith<$Res> {
  _$RetailProductCopyWithImpl(this._self, this._then);

  final RetailProduct _self;
  final $Res Function(RetailProduct) _then;

/// Create a copy of RetailProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? sku = freezed,Object? barcode = freezed,Object? priceCents = null,Object? costCents = freezed,Object? category = null,Object? tags = null,Object? trackInventory = null,Object? stockQuantity = freezed,Object? lowStockThreshold = freezed,Object? imageUrl = freezed,Object? additionalImages = null,Object? isActive = null,Object? availableForSale = null,Object? taxable = null,Object? taxCategoryId = freezed,Object? linkedServiceId = freezed,Object? sortOrder = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockQuantity: freezed == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int?,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,additionalImages: null == additionalImages ? _self.additionalImages : additionalImages // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,availableForSale: null == availableForSale ? _self.availableForSale : availableForSale // ignore: cast_nullable_to_non_nullable
as bool,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,taxCategoryId: freezed == taxCategoryId ? _self.taxCategoryId : taxCategoryId // ignore: cast_nullable_to_non_nullable
as String?,linkedServiceId: freezed == linkedServiceId ? _self.linkedServiceId : linkedServiceId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RetailProduct].
extension RetailProductPatterns on RetailProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetailProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetailProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetailProduct value)  $default,){
final _that = this;
switch (_that) {
case _RetailProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetailProduct value)?  $default,){
final _that = this;
switch (_that) {
case _RetailProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  String? sku,  String? barcode,  int priceCents,  int? costCents,  ProductCategory category,  List<String> tags,  bool trackInventory,  int? stockQuantity,  int? lowStockThreshold,  String? imageUrl,  List<String> additionalImages,  bool isActive,  bool availableForSale,  bool taxable,  String? taxCategoryId,  String? linkedServiceId,  int sortOrder, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetailProduct() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.sku,_that.barcode,_that.priceCents,_that.costCents,_that.category,_that.tags,_that.trackInventory,_that.stockQuantity,_that.lowStockThreshold,_that.imageUrl,_that.additionalImages,_that.isActive,_that.availableForSale,_that.taxable,_that.taxCategoryId,_that.linkedServiceId,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  String? sku,  String? barcode,  int priceCents,  int? costCents,  ProductCategory category,  List<String> tags,  bool trackInventory,  int? stockQuantity,  int? lowStockThreshold,  String? imageUrl,  List<String> additionalImages,  bool isActive,  bool availableForSale,  bool taxable,  String? taxCategoryId,  String? linkedServiceId,  int sortOrder, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RetailProduct():
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.sku,_that.barcode,_that.priceCents,_that.costCents,_that.category,_that.tags,_that.trackInventory,_that.stockQuantity,_that.lowStockThreshold,_that.imageUrl,_that.additionalImages,_that.isActive,_that.availableForSale,_that.taxable,_that.taxCategoryId,_that.linkedServiceId,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  String? description,  String? sku,  String? barcode,  int priceCents,  int? costCents,  ProductCategory category,  List<String> tags,  bool trackInventory,  int? stockQuantity,  int? lowStockThreshold,  String? imageUrl,  List<String> additionalImages,  bool isActive,  bool availableForSale,  bool taxable,  String? taxCategoryId,  String? linkedServiceId,  int sortOrder, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RetailProduct() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.sku,_that.barcode,_that.priceCents,_that.costCents,_that.category,_that.tags,_that.trackInventory,_that.stockQuantity,_that.lowStockThreshold,_that.imageUrl,_that.additionalImages,_that.isActive,_that.availableForSale,_that.taxable,_that.taxCategoryId,_that.linkedServiceId,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RetailProduct extends RetailProduct {
  const _RetailProduct({required this.id, required this.businessId, required this.name, this.description, this.sku, this.barcode, required this.priceCents, this.costCents, required this.category, final  List<String> tags = const [], this.trackInventory = false, this.stockQuantity, this.lowStockThreshold, this.imageUrl, final  List<String> additionalImages = const [], this.isActive = true, this.availableForSale = true, this.taxable = true, this.taxCategoryId, this.linkedServiceId, this.sortOrder = 0, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _tags = tags,_additionalImages = additionalImages,super._();
  factory _RetailProduct.fromJson(Map<String, dynamic> json) => _$RetailProductFromJson(json);

/// Unique product ID
@override final  String id;
/// Business ID this product belongs to
@override final  String businessId;
/// Product name
@override final  String name;
/// Product description
@override final  String? description;
/// Stock Keeping Unit (SKU) for inventory management
@override final  String? sku;
/// Barcode (UPC/EAN) for scanner integration
@override final  String? barcode;
/// Price in cents
@override final  int priceCents;
/// Cost in cents (for profit tracking)
@override final  int? costCents;
/// Product category
@override final  ProductCategory category;
/// Tags for filtering/searching
 final  List<String> _tags;
/// Tags for filtering/searching
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Whether to track inventory levels
@override@JsonKey() final  bool trackInventory;
/// Current stock quantity (when trackInventory is true)
@override final  int? stockQuantity;
/// Low stock threshold for alerts
@override final  int? lowStockThreshold;
/// Primary product image URL
@override final  String? imageUrl;
/// Additional product images
 final  List<String> _additionalImages;
/// Additional product images
@override@JsonKey() List<String> get additionalImages {
  if (_additionalImages is EqualUnmodifiableListView) return _additionalImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_additionalImages);
}

/// Whether product is active (visible in system)
@override@JsonKey() final  bool isActive;
/// Whether product is available for sale
@override@JsonKey() final  bool availableForSale;
/// Whether product is taxable
@override@JsonKey() final  bool taxable;
/// Tax category ID (for tax rate lookup)
@override final  String? taxCategoryId;
/// Optional: link to service ID if sold as add-on
@override final  String? linkedServiceId;
/// Sort order for display
@override@JsonKey() final  int sortOrder;
/// When the product was created
@override@TimestampConverter() final  DateTime createdAt;
/// When the product was last updated
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of RetailProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetailProductCopyWith<_RetailProduct> get copyWith => __$RetailProductCopyWithImpl<_RetailProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RetailProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetailProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._additionalImages, _additionalImages)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.availableForSale, availableForSale) || other.availableForSale == availableForSale)&&(identical(other.taxable, taxable) || other.taxable == taxable)&&(identical(other.taxCategoryId, taxCategoryId) || other.taxCategoryId == taxCategoryId)&&(identical(other.linkedServiceId, linkedServiceId) || other.linkedServiceId == linkedServiceId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,sku,barcode,priceCents,costCents,category,const DeepCollectionEquality().hash(_tags),trackInventory,stockQuantity,lowStockThreshold,imageUrl,const DeepCollectionEquality().hash(_additionalImages),isActive,availableForSale,taxable,taxCategoryId,linkedServiceId,sortOrder,createdAt,updatedAt]);

@override
String toString() {
  return 'RetailProduct(id: $id, businessId: $businessId, name: $name, description: $description, sku: $sku, barcode: $barcode, priceCents: $priceCents, costCents: $costCents, category: $category, tags: $tags, trackInventory: $trackInventory, stockQuantity: $stockQuantity, lowStockThreshold: $lowStockThreshold, imageUrl: $imageUrl, additionalImages: $additionalImages, isActive: $isActive, availableForSale: $availableForSale, taxable: $taxable, taxCategoryId: $taxCategoryId, linkedServiceId: $linkedServiceId, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RetailProductCopyWith<$Res> implements $RetailProductCopyWith<$Res> {
  factory _$RetailProductCopyWith(_RetailProduct value, $Res Function(_RetailProduct) _then) = __$RetailProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, String? description, String? sku, String? barcode, int priceCents, int? costCents, ProductCategory category, List<String> tags, bool trackInventory, int? stockQuantity, int? lowStockThreshold, String? imageUrl, List<String> additionalImages, bool isActive, bool availableForSale, bool taxable, String? taxCategoryId, String? linkedServiceId, int sortOrder,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$RetailProductCopyWithImpl<$Res>
    implements _$RetailProductCopyWith<$Res> {
  __$RetailProductCopyWithImpl(this._self, this._then);

  final _RetailProduct _self;
  final $Res Function(_RetailProduct) _then;

/// Create a copy of RetailProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? sku = freezed,Object? barcode = freezed,Object? priceCents = null,Object? costCents = freezed,Object? category = null,Object? tags = null,Object? trackInventory = null,Object? stockQuantity = freezed,Object? lowStockThreshold = freezed,Object? imageUrl = freezed,Object? additionalImages = null,Object? isActive = null,Object? availableForSale = null,Object? taxable = null,Object? taxCategoryId = freezed,Object? linkedServiceId = freezed,Object? sortOrder = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_RetailProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockQuantity: freezed == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int?,lowStockThreshold: freezed == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,additionalImages: null == additionalImages ? _self._additionalImages : additionalImages // ignore: cast_nullable_to_non_nullable
as List<String>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,availableForSale: null == availableForSale ? _self.availableForSale : availableForSale // ignore: cast_nullable_to_non_nullable
as bool,taxable: null == taxable ? _self.taxable : taxable // ignore: cast_nullable_to_non_nullable
as bool,taxCategoryId: freezed == taxCategoryId ? _self.taxCategoryId : taxCategoryId // ignore: cast_nullable_to_non_nullable
as String?,linkedServiceId: freezed == linkedServiceId ? _self.linkedServiceId : linkedServiceId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
