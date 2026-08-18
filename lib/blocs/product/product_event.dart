part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches products from the catalog.
///
/// `reset: true` (default) replaces the current list — used for the initial
/// load, pull-to-refresh, or when filters change. `reset: false` appends the
/// returned page to the existing list — used for pagination/infinite scroll.
class FetchProductsEvent extends ProductEvent {
  const FetchProductsEvent({
    this.page = 1,
    this.categoryId,
    this.orderby,
    this.order,
    this.onSale,
    this.featured,
    this.reset = true,
  });

  final int page;
  final int? categoryId;
  final String? orderby;
  final String? order;
  final bool? onSale;
  final bool? featured;
  final bool reset;

  @override
  List<Object?> get props => [
    page,
    categoryId,
    orderby,
    order,
    onSale,
    featured,
    reset,
  ];
}
