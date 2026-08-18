import 'package:equatable/equatable.dart';

/// A single product image, as returned inside `images: [...]` on a
/// WooCommerce `/products` resource.
class ProductImageModel extends Equatable {
  const ProductImageModel({required this.id, required this.src, this.alt = ''});

  final int id;
  final String src;
  final String alt;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as int? ?? 0,
      // WooCommerce sometimes returns `src: false` for a broken/missing
      // media reference instead of a string or null.
      src: json['src'] is String ? json['src'] as String : '',
      alt: json['alt'] is String ? json['alt'] as String : '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'src': src, 'alt': alt};

  @override
  List<Object?> get props => [id, src, alt];
}

/// A lightweight reference to a category, as returned inside
/// `categories: [...]` on a WooCommerce `/products` resource.
class ProductCategoryRefModel extends Equatable {
  const ProductCategoryRefModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory ProductCategoryRefModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryRefModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};

  @override
  List<Object?> get props => [id, name, slug];
}

/// A WooCommerce `/wp-json/wc/v3/products` resource.
class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.permalink,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.featured,
    required this.stockStatus,
    required this.stockQuantity,
    required this.averageRating,
    required this.ratingCount,
    required this.images,
    required this.categories,
  });

  final int id;
  final String name;
  final String slug;
  final String permalink;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool featured;
  final String stockStatus;
  final int? stockQuantity;
  final String averageRating;
  final int ratingCount;
  final List<ProductImageModel> images;
  final List<ProductCategoryRefModel> categories;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      permalink: json['permalink'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      price: json['price']?.toString() ?? '',
      regularPrice: json['regular_price']?.toString() ?? '',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      stockStatus: json['stock_status'] as String? ?? '',
      stockQuantity: json['stock_quantity'] as int?,
      averageRating: json['average_rating']?.toString() ?? '0',
      ratingCount: json['rating_count'] as int? ?? 0,
      images: (json['images'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductImageModel.fromJson)
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductCategoryRefModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'permalink': permalink,
    'description': description,
    'short_description': shortDescription,
    'price': price,
    'regular_price': regularPrice,
    'sale_price': salePrice,
    'on_sale': onSale,
    'featured': featured,
    'stock_status': stockStatus,
    'stock_quantity': stockQuantity,
    'average_rating': averageRating,
    'rating_count': ratingCount,
    'images': images.map((image) => image.toJson()).toList(),
    'categories': categories.map((category) => category.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    permalink,
    description,
    shortDescription,
    price,
    regularPrice,
    salePrice,
    onSale,
    featured,
    stockStatus,
    stockQuantity,
    averageRating,
    ratingCount,
    images,
    categories,
  ];
}
