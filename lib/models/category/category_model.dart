import 'package:alnisa_store/models/product/product_model.dart';
import 'package:equatable/equatable.dart';

/// A WooCommerce `/wp-json/wc/v3/products/categories` resource.
class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    required this.count,
    required this.parent,
  });

  final int id;
  final String name;
  final String slug;
  final ProductImageModel? image;
  final int count;
  final int parent;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'];
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      image: imageJson is Map<String, dynamic>
          ? ProductImageModel.fromJson(imageJson)
          : null,
      count: json['count'] as int? ?? 0,
      parent: json['parent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'image': image?.toJson(),
    'count': count,
    'parent': parent,
  };

  @override
  List<Object?> get props => [id, name, slug, image, count, parent];
}
