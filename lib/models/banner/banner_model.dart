import 'package:equatable/equatable.dart';

/// A WordPress `banner` custom post type resource
/// (`/wp-json/wp/v2/banner`), with an embedded featured image and a
/// `meta` object containing `link_url`/`sort_order`.
class BannerModel extends Equatable {
  const BannerModel({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
    this.sortOrder = 0,
  });

  final int id;
  final String imageUrl;
  final String linkUrl;
  final int sortOrder;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final featuredMedia = embedded?['wp:featuredmedia'] as List<dynamic>?;
    final firstMedia = (featuredMedia != null && featuredMedia.isNotEmpty)
        ? featuredMedia[0] as Map<String, dynamic>?
        : null;
    final meta = json['meta'] as Map<String, dynamic>?;

    return BannerModel(
      id: json['id'] as int? ?? 0,
      imageUrl: firstMedia?['source_url'] as String? ?? '',
      linkUrl: meta?['link_url'] as String? ?? '',
      sortOrder: int.tryParse(meta?['sort_order']?.toString() ?? '') ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, linkUrl, sortOrder];
}
