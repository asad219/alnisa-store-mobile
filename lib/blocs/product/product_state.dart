part of 'product_bloc.dart';

class ProductState extends Equatable {
  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.hasReachedMax = false,
    this.error,
  });

  final ProductStatus status;
  final List<ProductModel> products;
  final bool hasReachedMax;
  final String? error;

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? products,
    bool? hasReachedMax,
    String? error,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, products, hasReachedMax, error];
}
