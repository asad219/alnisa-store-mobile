import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onWishlistTap,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;

  bool get _isSoldOut => product.stockStatus == 'outofstock';

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first.src : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.background),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(imageUrl),
                  if (_isSoldOut)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sold out',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: onWishlistTap,
                      icon: const Icon(Icons.favorite_border),
                      color: AppColors.primary,
                      iconSize: 20,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPriceRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: AppColors.background),
      errorWidget: (context, url, error) => Container(
        color: AppColors.background,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildPriceRow() {
    if (!product.onSale || product.salePrice.isEmpty) {
      return Text(
        'AED ${product.price}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        Text(
          'AED ${product.regularPrice}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'AED ${product.salePrice}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
