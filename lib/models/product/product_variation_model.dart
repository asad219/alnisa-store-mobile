import 'package:equatable/equatable.dart';

class ProductVariationModel extends Equatable {
  const ProductVariationModel({
    required this.id,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.stockStatus,
    required this.stockQuantity,
    required this.imageUrl,
    required this.attributes,
  });

  final int id;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final String stockStatus;
  final int? stockQuantity;
  final String imageUrl;
  final Map<String, String> attributes;

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final attributesList = json['attributes'] as List<dynamic>? ?? [];

    final mappedAttributes = <String, String>{};
    for (final item in attributesList) {
      if (item is! Map<String, dynamic>) continue;
      final key = (item['name']?.toString() ?? '').trim().toLowerCase();
      final value = item['option']?.toString() ?? '';
      if (key.isNotEmpty && value.isNotEmpty) {
        mappedAttributes[key] = value;
      }
    }

    return ProductVariationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      price: json['price']?.toString() ?? '',
      regularPrice: json['regular_price']?.toString() ?? '',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      stockStatus: json['stock_status'] as String? ?? '',
      stockQuantity: int.tryParse(json['stock_quantity']?.toString() ?? ''),
      imageUrl: image?['src']?.toString() ?? '',
      attributes: mappedAttributes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    price,
    regularPrice,
    salePrice,
    onSale,
    stockStatus,
    stockQuantity,
    imageUrl,
    attributes,
  ];
}
