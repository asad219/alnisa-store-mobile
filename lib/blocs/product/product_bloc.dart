import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/repository/product/product_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'product_event.dart';
part 'product_state.dart';
part 'product_status.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(ProductHttpApiRepository? productRepository)
    : _productRepository =
          productRepository ?? getIt<ProductHttpApiRepository>(),
      super(const ProductState()) {
    on<FetchProductsEvent>(_onFetchProducts);
  }

  final ProductHttpApiRepository _productRepository;

  static const int _perPage = 20;

  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (event.reset) {
      emit(
        state.copyWith(status: ProductStatus.loading, hasReachedMax: false),
      );
    } else {
      if (state.hasReachedMax) return;
      emit(state.copyWith(status: ProductStatus.loadingMore));
    }

    try {
      final products = await _productRepository.fetchProducts(
        page: event.page,
        perPage: _perPage,
        categoryId: event.categoryId,
        orderby: event.orderby ?? 'date',
        order: event.order ?? 'desc',
        onSale: event.onSale,
        featured: event.featured,
      );

      final hasReachedMax = products.length < _perPage;
      final allProducts = event.reset
          ? products
          : [...state.products, ...products];

      emit(
        state.copyWith(
          status: ProductStatus.success,
          products: allProducts,
          hasReachedMax: hasReachedMax,
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }
}
