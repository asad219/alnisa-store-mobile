import 'package:alnisa_store/blocs/cart/cart_bloc.dart';
import 'package:alnisa_store/blocs/product_detail/product_detail_cubit.dart';
import 'package:alnisa_store/blocs/product_detail/product_detail_state.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_cubit.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:alnisa_store/widgets/product_price_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailCubit _productDetailCubit;
  final PageController _pageController = PageController();

  int _currentImagePage = 0;
  bool _awaitingAddToCart = false;

  @override
  void initState() {
    super.initState();
    _productDetailCubit = getIt<ProductDetailCubit>();
    _productDetailCubit.loadProduct(widget.productId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _productDetailCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailCubit>.value(
      value: _productDetailCubit,
      child: BlocListener<CartBloc, CartState>(
        listener: (context, cartState) {
          if (!_awaitingAddToCart) return;

          if (cartState.status == CartStatus.success) {
            _awaitingAddToCart = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to cart')),
            );
          } else if (cartState.status == CartStatus.failure) {
            _awaitingAddToCart = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(cartState.error ?? 'Failed to add item')),
            );
          }
        },
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) {
            final product = state.product;

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Product Details'),
                backgroundColor: Colors.white,
                actions: [
                  if (product != null)
                    Builder(
                      builder: (context) {
                        final isWishlisted = context
                            .watch<WishlistCubit>()
                            .state
                            .wishlistedIds
                            .contains(product.id);

                        return IconButton(
                          onPressed: () {
                            context.read<WishlistCubit>().toggle(product.id);
                          },
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                ],
              ),
              body: _buildBody(state, product),
              bottomNavigationBar: _buildBottomBar(state, product),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ProductDetailState state, ProductModel? product) {
    if (state.status == ProductDetailStatus.loading ||
        state.status == ProductDetailStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ProductDetailStatus.failure || product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<ProductDetailCubit>().loadProduct(
                  widget.productId,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final images = _galleryImages(state, product);
    final variationAttributes = product.attributes
        .where((attribute) => attribute.variation)
        .toList();
    final matchedVariation = state.matchedVariation;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(images),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.categories.first.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ProductPriceWidget(
                  price: matchedVariation?.price ?? product.price,
                  regularPrice:
                      matchedVariation?.regularPrice ?? product.regularPrice,
                  salePrice: matchedVariation?.salePrice ?? product.salePrice,
                  onSale: matchedVariation?.onSale ?? product.onSale,
                  priceFontSize: 18,
                  regularPriceFontSize: 14,
                ),
                const SizedBox(height: 10),
                if (product.ratingCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${product.averageRating} (${product.ratingCount})',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildStockText(state, product),
                if (variationAttributes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...variationAttributes.map(
                    (attribute) => _buildAttributeOptions(state, attribute),
                  ),
                ],
                const SizedBox(height: 16),
                if (_stripHtml(product.shortDescription).isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stripHtml(product.shortDescription),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildQuantityStepper(state),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (_currentImagePage >= images.length && images.isNotEmpty) {
      _currentImagePage = 0;
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (index) => setState(() => _currentImagePage = index),
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              }

              final imageUrl = images[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.background),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isActive = index == _currentImagePage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildAttributeOptions(
    ProductDetailState state,
    ProductAttributeModel attribute,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attribute.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attribute.options.map((option) {
              final selectedValue =
                  state.selectedAttributes[attribute.name.toLowerCase()];
              final isSelected = selectedValue == option;

              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) {
                  context.read<ProductDetailCubit>().selectAttribute(
                    attribute.name,
                    option,
                  );
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.background,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStockText(ProductDetailState state, ProductModel product) {
    final matchedVariation = state.matchedVariation;
    final stockStatus = matchedVariation?.stockStatus ?? product.stockStatus;
    final stockQuantity = matchedVariation?.stockQuantity ?? product.stockQuantity;

    final isOutOfStock =
        stockStatus == 'outofstock' ||
        (stockQuantity != null && stockQuantity <= 0);

    if (isOutOfStock) {
      return const Text(
        'Out of stock',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      );
    }

    if (stockQuantity != null && stockQuantity <= 5) {
      return Text(
        'Only $stockQuantity left',
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
      );
    }

    return const Text(
      'In stock',
      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildQuantityStepper(ProductDetailState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              context.read<ProductDetailCubit>().setQuantity(state.quantity - 1);
            },
            icon: const Icon(Icons.remove),
          ),
          Text(
            '${state.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () {
              context.read<ProductDetailCubit>().setQuantity(state.quantity + 1);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductDetailState state, ProductModel? product) {
    if (state.status != ProductDetailStatus.success || product == null) {
      return const SizedBox.shrink();
    }

    final matchedVariation = state.matchedVariation;
    final variableAttributes = product.attributes
        .where((attribute) => attribute.variation)
        .toList();

    final requiresVariationSelection =
        product.type == 'variable' && variableAttributes.isNotEmpty;
    final hasAllSelections = variableAttributes.every(
      (attribute) =>
          state.selectedAttributes.containsKey(attribute.name.toLowerCase()),
    );

    final stockStatus = matchedVariation?.stockStatus ?? product.stockStatus;
    final stockQuantity = matchedVariation?.stockQuantity ?? product.stockQuantity;
    final isOutOfStock =
        stockStatus == 'outofstock' ||
        (stockQuantity != null && stockQuantity <= 0);

    final disabled =
        (requiresVariationSelection && !hasAllSelections) || isOutOfStock;

    final unitPriceString =
        (matchedVariation?.onSale ?? false) &&
            (matchedVariation?.salePrice ?? '').isNotEmpty
        ? matchedVariation!.salePrice
        : matchedVariation?.price ??
              ((product.onSale && product.salePrice.isNotEmpty)
                  ? product.salePrice
                  : product.price);

    final unitPrice = double.tryParse(unitPriceString) ?? 0;
    final lineTotal = unitPrice * state.quantity;
    final lineTotalText = lineTotal % 1 == 0
        ? lineTotal.toStringAsFixed(0)
        : lineTotal.toStringAsFixed(2);

    final isAdding = _awaitingAddToCart;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  'AED $lineTotalText',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: disabled || isAdding
                  ? null
                  : () {
                      setState(() => _awaitingAddToCart = true);
                      context.read<CartBloc>().add(
                        AddItemEvent(
                          productId: product.id,
                          quantity: state.quantity,
                          variationId: matchedVariation?.id,
                          variation: product.type == 'variable'
                              ? state.selectedAttributes
                              : null,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(isAdding ? 'Adding...' : 'Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _galleryImages(ProductDetailState state, ProductModel product) {
    final productImages = product.images
        .map((image) => image.src)
        .where((url) => url.isNotEmpty)
        .toList();

    final variationImage = state.matchedVariation?.imageUrl ?? '';
    if (variationImage.isNotEmpty) {
      if (productImages.contains(variationImage)) {
        productImages.remove(variationImage);
      }
      productImages.insert(0, variationImage);
    }

    return productImages;
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
