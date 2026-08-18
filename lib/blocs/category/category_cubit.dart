import 'package:alnisa_store/blocs/category/category_state.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/repository/product/product_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(ProductHttpApiRepository? productRepository)
    : _productRepository =
          productRepository ?? getIt<ProductHttpApiRepository>(),
      super(const CategoryState());

  final ProductHttpApiRepository _productRepository;

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CategoryStatus.loading));
    try {
      final categories = await _productRepository.fetchCategories();
      emit(
        state.copyWith(
          status: CategoryStatus.success,
          categories: categories,
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }
}
