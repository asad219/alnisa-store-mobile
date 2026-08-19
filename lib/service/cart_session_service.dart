import 'package:alnisa_store/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists WooCommerce Store API session headers across app launches.
///
/// - `Cart-Token` identifies the cart session.
/// - `Nonce` authorizes mutating cart requests.
class CartSessionService {
  CartSessionService._();

  static final CartSessionService instance = CartSessionService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> getCartToken() {
    return _secureStorage.read(key: AppConstants.cartTokenKey);
  }

  Future<void> setCartToken(String cartToken) {
    return _secureStorage.write(
      key: AppConstants.cartTokenKey,
      value: cartToken,
    );
  }

  Future<String?> getNonce() {
    return _secureStorage.read(key: AppConstants.cartNonceKey);
  }

  Future<void> setNonce(String nonce) {
    return _secureStorage.write(key: AppConstants.cartNonceKey, value: nonce);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: AppConstants.cartTokenKey);
    await _secureStorage.delete(key: AppConstants.cartNonceKey);
  }
}
