import 'package:alnisa_store/core/api/api_response_parser.dart';
import 'package:alnisa_store/models/banner/banner_model.dart';
import 'package:alnisa_store/service/api_client.dart';

/// Talks to the public core WordPress REST API `banner` custom post type
/// (`/wp-json/wp/v2/banner`). Throws [ApiException] on failure (already
/// handled inside [ApiClient]).
class BannerHttpApiRepository {
  Future<List<BannerModel>> fetchBanners() async {
    // Core WP REST API doesn't support `orderby=meta_value_num` for a
    // custom field unless the backend explicitly registers it as an
    // allowed orderby param, so we fetch in default order and sort by
    // `meta.sort_order` client-side instead.
    final decoded = await ApiClient.getList(
      '/banner',
      useWpApi: true,
      useConsumerAuth: false,
      queryParams: {'_embed': '', 'per_page': 20, 'status': 'publish'},
    );

    final banners = ApiResponseParser.parseList(decoded, BannerModel.fromJson);
    banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return banners;
  }
}
