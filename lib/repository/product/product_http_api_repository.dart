import 'package:alnisa_store/core/api/api_response_parser.dart';
import 'package:alnisa_store/models/category/category_model.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/service/api_client.dart';

/// Talks to the WooCommerce `/products` and `/products/categories`
/// REST v3 endpoints. Throws [ApiException] on failure (already handled
/// inside [ApiClient]).
class ProductHttpApiRepository {
  Future<List<ProductModel>> fetchProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String orderby = 'date',
    String order = 'desc',
    bool? onSale,
    bool? featured,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'orderby': orderby,
      'order': order,
      'category': categoryId,
      'on_sale': onSale,
      'featured': featured,
      'search': search,
    };

    final decoded = await ApiClient.getList(
      '/products',
      queryParams: queryParams,
    );

    return ApiResponseParser.parseList(decoded, ProductModel.fromJson);
  }

  Future<ProductModel> fetchProductById(int id) async {
    final decoded = await ApiClient.get('/products/$id');
    return ApiResponseParser.parseObject(decoded, ProductModel.fromJson);
  }

  Future<List<CategoryModel>> fetchCategories({
    int perPage = 50,
    bool hideEmpty = true,
  }) async {
    final decoded = await ApiClient.getList(
      '/products/categories',
      queryParams: {'per_page': perPage, 'hide_empty': hideEmpty},
    );

    return ApiResponseParser.parseList(decoded, CategoryModel.fromJson);
  }
}
