import 'package:alnisa_store/models/product/product_model.dart';
import 'package:equatable/equatable.dart';

enum WishlistStatus { initial, loading, success, failure }

class WishlistState extends Equatable {
  const WishlistState({
    this.status = WishlistStatus.initial,
    this.wishlistedIds = const <int>{},
    this.wishlistedProducts = const [],
    this.error,
  });

  final WishlistStatus status;
  final Set<int> wishlistedIds;
  final List<ProductModel> wishlistedProducts;
  final String? error;

  WishlistState copyWith({
    WishlistStatus? status,
    Set<int>? wishlistedIds,
    List<ProductModel>? wishlistedProducts,
    String? error,
  }) {
    return WishlistState(
      status: status ?? this.status,
      wishlistedIds: wishlistedIds ?? this.wishlistedIds,
      wishlistedProducts: wishlistedProducts ?? this.wishlistedProducts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, wishlistedIds, wishlistedProducts, error];
}
