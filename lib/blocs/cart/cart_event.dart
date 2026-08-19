part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class FetchCartEvent extends CartEvent {
  const FetchCartEvent();
}

class AddItemEvent extends CartEvent {
  const AddItemEvent({
    required this.productId,
    this.quantity = 1,
    this.variationId,
    this.variation,
  });

  final int productId;
  final int quantity;
  final int? variationId;
  final Map<String, String>? variation;

  @override
  List<Object?> get props => [productId, quantity, variationId, variation];
}

class UpdateItemQuantityEvent extends CartEvent {
  const UpdateItemQuantityEvent({required this.itemKey, required this.quantity});

  final String itemKey;
  final int quantity;

  @override
  List<Object?> get props => [itemKey, quantity];
}

class RemoveItemEvent extends CartEvent {
  const RemoveItemEvent({required this.itemKey});

  final String itemKey;

  @override
  List<Object?> get props => [itemKey];
}
