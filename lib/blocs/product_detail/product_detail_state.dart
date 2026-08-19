import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/models/product/product_variation_model.dart';
import 'package:equatable/equatable.dart';

enum ProductDetailStatus { initial, loading, success, failure }

class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.variations = const [],
    this.selectedAttributes = const {},
    this.quantity = 1,
    this.error,
  });

  final ProductDetailStatus status;
  final ProductModel? product;
  final List<ProductVariationModel> variations;
  final Map<String, String> selectedAttributes;
  final int quantity;
  final String? error;

  ProductVariationModel? get matchedVariation {
    if (variations.isEmpty || selectedAttributes.isEmpty) return null;

    final requiredKeys = variations
        .expand((variation) => variation.attributes.keys)
        .toSet();

    if (requiredKeys.isEmpty) return null;
    final hasAllRequired = requiredKeys.every(
      (key) => selectedAttributes.containsKey(key),
    );
    if (!hasAllRequired) return null;

    for (final variation in variations) {
      final attributes = variation.attributes;
      if (attributes.length != requiredKeys.length) continue;

      var allMatch = true;
      for (final key in requiredKeys) {
        if (attributes[key] != selectedAttributes[key]) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        return variation;
      }
    }

    return null;
  }

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductModel? product,
    List<ProductVariationModel>? variations,
    Map<String, String>? selectedAttributes,
    int? quantity,
    String? error,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      variations: variations ?? this.variations,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
      quantity: quantity ?? this.quantity,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    product,
    variations,
    selectedAttributes,
    quantity,
    error,
  ];
}
