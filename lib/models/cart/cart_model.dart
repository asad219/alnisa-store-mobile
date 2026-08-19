import 'package:equatable/equatable.dart';

class CartModel extends Equatable {
  const CartModel({
    required this.itemsCount,
    required this.items,
    required this.totalPrice,
    required this.totalItems,
  });

  final int itemsCount;
  final List<CartItemModel> items;
  final String totalPrice;
  final int totalItems;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>?;

    return CartModel(
      itemsCount: _toInt(json['items_count']),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList(),
      totalPrice: totals?['total_price']?.toString() ?? '0',
      totalItems: _toInt(totals?['total_items']),
    );
  }

  static int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  @override
  List<Object?> get props => [itemsCount, items, totalPrice, totalItems];
}

class CartItemVariationModel extends Equatable {
  const CartItemVariationModel({required this.attribute, required this.value});

  final String attribute;
  final String value;

  factory CartItemVariationModel.fromJson(Map<String, dynamic> json) {
    return CartItemVariationModel(
      attribute: json['attribute']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [attribute, value];
}

class CartItemModel extends Equatable {
  const CartItemModel({
    required this.key,
    required this.id,
    required this.quantity,
    required this.name,
    required this.imageUrl,
    required this.variation,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.lineTotal,
  });

  final String key;
  final int id;
  final int quantity;
  final String name;
  final String imageUrl;
  final List<CartItemVariationModel> variation;
  final String price;
  final String regularPrice;
  final String salePrice;
  final String lineTotal;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    final firstImage = (images != null && images.isNotEmpty)
        ? images.first as Map<String, dynamic>?
        : null;
    final prices = json['prices'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;

    return CartItemModel(
      key: json['key']?.toString() ?? '',
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: firstImage?['src']?.toString() ?? '',
      variation: (json['variation'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CartItemVariationModel.fromJson)
          .toList(),
      price: prices?['price']?.toString() ?? '0',
      regularPrice: prices?['regular_price']?.toString() ?? '0',
      salePrice: prices?['sale_price']?.toString() ?? '0',
      lineTotal: totals?['line_total']?.toString() ?? '0',
    );
  }

  @override
  List<Object?> get props => [
    key,
    id,
    quantity,
    name,
    imageUrl,
    variation,
    price,
    regularPrice,
    salePrice,
    lineTotal,
  ];
}
