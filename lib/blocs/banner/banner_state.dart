import 'package:alnisa_store/models/banner/banner_model.dart';
import 'package:equatable/equatable.dart';

enum BannerStatus { initial, loading, success, failure }

class BannerState extends Equatable {
  const BannerState({
    this.status = BannerStatus.initial,
    this.banners = const [],
    this.error,
  });

  final BannerStatus status;
  final List<BannerModel> banners;
  final String? error;

  BannerState copyWith({
    BannerStatus? status,
    List<BannerModel>? banners,
    String? error,
  }) {
    return BannerState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, banners, error];
}
