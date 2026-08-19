import 'package:alnisa_store/core/api/api_response_parser.dart';
import 'package:alnisa_store/models/cart/cart_model.dart';
import 'package:alnisa_store/service/api_client.dart';

class CartHttpApiRepository {
  Future<CartModel> fetchCart() async {
    final decoded = await ApiClient.getStoreApi('/cart');
    return ApiResponseParser.parseObject(decoded, CartModel.fromJson);
  }

  Future<CartModel> addItem({
    required int productId,
    int quantity = 1,
    int? variationId,
    Map<String, String>? variation,
  }) async {
    final decoded = await ApiClient.postStoreApi(
      '/cart/add-item',
      body: {
        'id': variationId ?? productId,
        'quantity': quantity,
        if (variation != null && variation.isNotEmpty)
          'variation': variation.entries
              .map((entry) => {
                    'attribute': entry.key,
                    'value': entry.value,
                  })
              .toList(),
      },
    );

    return ApiResponseParser.parseObject(decoded, CartModel.fromJson);
  }

  Future<CartModel> updateItemQuantity({
    required String itemKey,
    required int quantity,
  }) async {
    final decoded = await ApiClient.postStoreApi(
      '/cart/update-item',
      body: {'key': itemKey, 'quantity': quantity},
    );
    return ApiResponseParser.parseObject(decoded, CartModel.fromJson);
  }

  Future<CartModel> removeItem({required String itemKey}) async {
    final decoded = await ApiClient.postStoreApi(
      '/cart/remove-item',
      body: {'key': itemKey},
    );
    return ApiResponseParser.parseObject(decoded, CartModel.fromJson);
  }
}
