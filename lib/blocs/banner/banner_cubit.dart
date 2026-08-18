import 'package:alnisa_store/blocs/banner/banner_state.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/models/banner/banner_model.dart';
import 'package:alnisa_store/repository/banner/banner_http_api_repository.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BannerCubit extends Cubit<BannerState> {
  BannerCubit(BannerHttpApiRepository? bannerRepository)
    : _bannerRepository = bannerRepository ?? getIt<BannerHttpApiRepository>(),
      super(const BannerState());

  final BannerHttpApiRepository _bannerRepository;

  /// Temporary fallback banners shown while the WordPress `banner` custom
  /// post type has no published posts yet. Once real banners are added in
  /// the backend, `fetchBanners()` will return them and this fallback is
  /// simply never used.
  static const List<BannerModel> _fallbackBanners = [
    BannerModel(
      id: -1,
      imageUrl:
          'https://i0.wp.com/alnisastore.com/wp-content/uploads/2022/06/zylish-bareez-vol-4-desktop-banner.jpg?w=1400&ssl=1',
      linkUrl: '',
    ),
    BannerModel(
      id: -2,
      imageUrl:
          'https://i0.wp.com/alnisastore.com/wp-content/uploads/2023/05/Fashion.png?w=1200&ssl=1',
      linkUrl: '',
    ),
  ];

  Future<void> loadBanners() async {
    emit(state.copyWith(status: BannerStatus.loading));
    try {
      final banners = await _bannerRepository.fetchBanners();
      emit(
        state.copyWith(
          status: BannerStatus.success,
          banners: banners.isEmpty ? _fallbackBanners : banners,
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: BannerStatus.failure,
          error: ApiException.toUserMessage(error),
        ),
      );
    }
  }
}
