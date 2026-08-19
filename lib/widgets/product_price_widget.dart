import 'package:alnisa_store/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ProductPriceWidget extends StatelessWidget {
  const ProductPriceWidget({
    super.key,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    this.priceFontSize = 13,
    this.regularPriceFontSize = 12,
  });

  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final double priceFontSize;
  final double regularPriceFontSize;

  @override
  Widget build(BuildContext context) {
    if (!onSale || salePrice.isEmpty) {
      return Text(
        'AED $price',
        style: TextStyle(fontSize: priceFontSize, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        Text(
          'AED $regularPrice',
          style: TextStyle(
            fontSize: regularPriceFontSize,
            color: AppColors.textSecondary,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'AED $salePrice',
          style: TextStyle(
            fontSize: priceFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
