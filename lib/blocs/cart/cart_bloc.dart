import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/models/cart/cart_model.dart';
import 'package:alnisa_store/repository/cart/cart_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'cart_event.dart';
part 'cart_state.dart';
part 'cart_status.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(CartHttpApiRepository? cartRepository)
    : _cartRepository = cartRepository ?? getIt<CartHttpApiRepository>(),
      super(const CartState()) {
    on<FetchCartEvent>(_onFetchCart);
    on<AddItemEvent>(_onAddItem);
    on<UpdateItemQuantityEvent>(_onUpdateItemQuantity);
    on<RemoveItemEvent>(_onRemoveItem);
  }

  final CartHttpApiRepository _cartRepository;

  Future<void> _onFetchCart(FetchCartEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _cartRepository.fetchCart();
      emit(state.copyWith(status: CartStatus.success, cart: cart, error: null));
    } catch (error) {
      emit(
        state.copyWith(
          status: CartStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }

  Future<void> _onAddItem(AddItemEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _cartRepository.addItem(
        productId: event.productId,
        quantity: event.quantity,
        variationId: event.variationId,
        variation: event.variation,
      );
      emit(state.copyWith(status: CartStatus.success, cart: cart, error: null));
    } catch (error) {
      emit(
        state.copyWith(
          status: CartStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }

  Future<void> _onUpdateItemQuantity(
    UpdateItemQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _cartRepository.updateItemQuantity(
        itemKey: event.itemKey,
        quantity: event.quantity,
      );
      emit(state.copyWith(status: CartStatus.success, cart: cart, error: null));
    } catch (error) {
      emit(
        state.copyWith(
          status: CartStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }

  Future<void> _onRemoveItem(
    RemoveItemEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _cartRepository.removeItem(itemKey: event.itemKey);
      emit(state.copyWith(status: CartStatus.success, cart: cart, error: null));
    } catch (error) {
      emit(
        state.copyWith(
          status: CartStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }
}
