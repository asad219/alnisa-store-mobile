part of 'cart_bloc.dart';

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.initial,
    this.cart,
    this.error,
  });

  final CartStatus status;
  final CartModel? cart;
  final String? error;

  int get itemCount => cart?.itemsCount ?? 0;

  CartState copyWith({
    CartStatus? status,
    CartModel? cart,
    String? error,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, cart, error];
}
