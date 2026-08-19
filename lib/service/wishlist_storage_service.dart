import 'package:alnisa_store/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistStorageService {
  WishlistStorageService._();

  static final WishlistStorageService instance = WishlistStorageService._();

  Future<Set<int>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.wishlistProductIdsKey) ?? [];
    return stored.map(int.tryParse).whereType<int>().toSet();
  }

  Future<bool> isWishlisted(int productId) async {
    final ids = await getIds();
    return ids.contains(productId);
  }

  Future<Set<int>> toggle(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getIds();

    if (ids.contains(productId)) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }

    await prefs.setStringList(
      AppConstants.wishlistProductIdsKey,
      ids.map((id) => id.toString()).toList(),
    );

    return ids;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.wishlistProductIdsKey);
  }
}
