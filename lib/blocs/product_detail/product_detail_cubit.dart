import 'package:alnisa_store/blocs/product_detail/product_detail_state.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/models/product/product_variation_model.dart';
import 'package:alnisa_store/repository/product/product_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(ProductHttpApiRepository? productRepository)
    : _productRepository =
          productRepository ?? getIt<ProductHttpApiRepository>(),
      super(const ProductDetailState());

  final ProductHttpApiRepository _productRepository;

  Future<void> loadProduct(int id) async {
    emit(state.copyWith(status: ProductDetailStatus.loading, error: null));

    try {
      final product = await _productRepository.fetchProductById(id);
      final variations = product.type == 'variable'
          ? await _productRepository.fetchProductVariations(id)
          : <ProductVariationModel>[];

      emit(
        state.copyWith(
          status: ProductDetailStatus.success,
          product: product,
          variations: variations,
          selectedAttributes: const {},
          quantity: 1,
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductDetailStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }

  void selectAttribute(String name, String value) {
    final key = name.trim().toLowerCase();
    final nextSelected = Map<String, String>.from(state.selectedAttributes)
      ..[key] = value;

    final nextQuantity = _clampQuantity(
      state.quantity,
      selectedAttributes: nextSelected,
    );

    emit(
      state.copyWith(
        selectedAttributes: nextSelected,
        quantity: nextQuantity,
      ),
    );
  }

  void setQuantity(int quantity) {
    emit(state.copyWith(quantity: _clampQuantity(quantity)));
  }

  int _clampQuantity(int quantity, {Map<String, String>? selectedAttributes}) {
    final min = 1;
    final effectiveSelected = selectedAttributes ?? state.selectedAttributes;

    final matchedVariation = _matchVariation(effectiveSelected);
    final stockQuantity = matchedVariation?.stockQuantity ?? state.product?.stockQuantity;
    final max = stockQuantity != null
      ? (stockQuantity < 1 ? 1 : stockQuantity)
      : 10;

    if (quantity < min) return min;
    if (quantity > max) return max;
    return quantity;
  }

  ProductVariationModel? _matchVariation(Map<String, String> selected) {
    if (state.variations.isEmpty || selected.isEmpty) return null;

    final requiredKeys = state.variations
        .expand((variation) => variation.attributes.keys)
        .toSet();
    if (requiredKeys.isEmpty ||
        !requiredKeys.every((key) => selected.containsKey(key))) {
      return null;
    }

    for (final variation in state.variations) {
      if (variation.attributes.length != requiredKeys.length) continue;
      var matches = true;
      for (final key in requiredKeys) {
        if (variation.attributes[key] != selected[key]) {
          matches = false;
          break;
        }
      }
      if (matches) return variation;
    }

    return null;
  }
}
