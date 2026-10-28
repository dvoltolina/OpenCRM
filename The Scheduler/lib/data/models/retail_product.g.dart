// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retail_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RetailProduct _$RetailProductFromJson(Map<String, dynamic> json) =>
    _RetailProduct(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      priceCents: (json['priceCents'] as num).toInt(),
      costCents: (json['costCents'] as num?)?.toInt(),
      category: $enumDecode(_$ProductCategoryEnumMap, json['category']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      trackInventory: json['trackInventory'] as bool? ?? false,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      additionalImages:
          (json['additionalImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      availableForSale: json['availableForSale'] as bool? ?? true,
      taxable: json['taxable'] as bool? ?? true,
      taxCategoryId: json['taxCategoryId'] as String?,
      linkedServiceId: json['linkedServiceId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$RetailProductToJson(
  _RetailProduct instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'name': instance.name,
  'description': instance.description,
  'sku': instance.sku,
  'barcode': instance.barcode,
  'priceCents': instance.priceCents,
  'costCents': instance.costCents,
  'category': _$ProductCategoryEnumMap[instance.category]!,
  'tags': instance.tags,
  'trackInventory': instance.trackInventory,
  'stockQuantity': instance.stockQuantity,
  'lowStockThreshold': instance.lowStockThreshold,
  'imageUrl': instance.imageUrl,
  'additionalImages': instance.additionalImages,
  'isActive': instance.isActive,
  'availableForSale': instance.availableForSale,
  'taxable': instance.taxable,
  'taxCategoryId': instance.taxCategoryId,
  'linkedServiceId': instance.linkedServiceId,
  'sortOrder': instance.sortOrder,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};

const _$ProductCategoryEnumMap = {
  ProductCategory.skincare: 'skincare',
  ProductCategory.haircare: 'haircare',
  ProductCategory.supplements: 'supplements',
  ProductCategory.equipment: 'equipment',
  ProductCategory.merchandise: 'merchandise',
  ProductCategory.consumables: 'consumables',
  ProductCategory.other: 'other',
};
