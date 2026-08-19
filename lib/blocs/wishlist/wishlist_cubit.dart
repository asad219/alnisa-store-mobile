import 'package:alnisa_store/blocs/wishlist/wishlist_state.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/repository/product/product_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:alnisa_store/service/wishlist_storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit(ProductHttpApiRepository? productRepository)
    : _productRepository =
          productRepository ?? getIt<ProductHttpApiRepository>(),
      super(const WishlistState());

  final ProductHttpApiRepository _productRepository;

  Future<void> loadIds() async {
    final ids = await WishlistStorageService.instance.getIds();

    if (ids.isEmpty) {
      emit(
        state.copyWith(
          wishlistedIds: ids,
          wishlistedProducts: const [],
          status: WishlistStatus.success,
          error: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        wishlistedIds: ids,
        status: WishlistStatus.loading,
        error: null,
      ),
    );
    await loadWishlistedProducts();
  }

  Future<void> toggle(int productId) async {
    final wasWishlisted = state.wishlistedIds.contains(productId);
    final updatedIds = await WishlistStorageService.instance.toggle(productId);

    final updatedProducts = state.wishlistedProducts
        .where((product) => updatedIds.contains(product.id))
        .toList();

    emit(
      state.copyWith(
        wishlistedIds: updatedIds,
        wishlistedProducts: updatedProducts,
        status: WishlistStatus.success,
        error: null,
      ),
    );

    // When a product is newly wishlisted, fetch it immediately so the
    // wishlist tab reflects the change without requiring a restart.
    final isNowWishlisted = updatedIds.contains(productId);
    if (!wasWishlisted && isNowWishlisted) {
      try {
        final product = await _productRepository.fetchProductById(productId);
        final currentState = state;

        if (!currentState.wishlistedIds.contains(productId)) {
          return;
        }

        final alreadyLoaded = currentState.wishlistedProducts.any(
          (item) => item.id == productId,
        );
        if (alreadyLoaded) {
          return;
        }

        emit(
          currentState.copyWith(
            status: WishlistStatus.success,
            wishlistedProducts: [
              product,
              ...currentState.wishlistedProducts,
            ],
            error: null,
          ),
        );
      } catch (_) {
        // Keep ids updated even if product details fail to load here.
      }
    }
  }

  Future<void> loadWishlistedProducts() async {
    emit(state.copyWith(status: WishlistStatus.loading, error: null));

    final ids = state.wishlistedIds;
    if (ids.isEmpty) {
      emit(
        state.copyWith(
          status: WishlistStatus.success,
          wishlistedProducts: const [],
          error: null,
        ),
      );
      return;
    }

    try {
      final idList = ids.toList();
      final results = await Future.wait(
        idList.map((id) async {
          try {
            final product = await _productRepository.fetchProductById(id);
            return _WishlistFetchResult(id: id, product: product);
          } catch (error) {
            return _WishlistFetchResult(id: id, error: error);
          }
        }),
      );

      final staleIds = <int>{};
      final products = <ProductModel>[];

      for (final result in results) {
        if (result.product != null) {
          products.add(result.product!);
          continue;
        }

        final error = result.error;
        if (error is ApiException && error.statusCode == 404) {
          staleIds.add(result.id);
        }
      }

      var cleanedIds = Set<int>.from(ids);
      for (final staleId in staleIds) {
        if (cleanedIds.contains(staleId)) {
          cleanedIds = await WishlistStorageService.instance.toggle(staleId);
        }
      }

      emit(
        state.copyWith(
          status: WishlistStatus.success,
          wishlistedIds: cleanedIds,
          wishlistedProducts: products,
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WishlistStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }
}

class _WishlistFetchResult {
  const _WishlistFetchResult({required this.id, this.product, this.error});

  final int id;
  final ProductModel? product;
  final Object? error;
}
