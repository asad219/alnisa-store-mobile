import 'package:alnisa_store/blocs/cart/cart_bloc.dart';
import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/models/cart/cart_model.dart';
import 'package:alnisa_store/utils/store_api_price_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) {
        return current.status == CartStatus.failure && current.cart != null;
      },
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Something went wrong.')),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final cart = state.cart;
            final isInitialLoading =
                state.status == CartStatus.loading && cart == null;
            final isMutationLoading =
                state.status == CartStatus.loading && cart != null;

            if (isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == CartStatus.failure && cart == null) {
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
                        onPressed: () {
                          context.read<CartBloc>().add(const FetchCartEvent());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (cart == null || cart.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 72,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<MainTabCubit>().changeTab(0);
                        },
                        child: const Text('Start Shopping'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (isMutationLoading)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Updating cart...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(
                        item: item,
                        controlsDisabled: isMutationLoading,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final cart = state.cart;
            if (cart == null || cart.items.isEmpty) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          formatStoreApiPrice(cart.totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        child: const Text('Checkout'),
                      ),
                    ),
                    // TODO: wire checkout flow when checkout APIs/screens exist.
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.controlsDisabled});

  final CartItemModel item;
  final bool controlsDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.background),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.variation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _variationSubtitle(item.variation),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuantityStepper(context),
                    const Spacer(),
                    Text(
                      formatStoreApiPrice(item.lineTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controlsDisabled
                ? null
                : () {
                    context.read<CartBloc>().add(
                      RemoveItemEvent(itemKey: item.key),
                    );
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.imageUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.background,
          width: 72,
          height: 72,
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.background,
          width: 72,
          height: 72,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
            onPressed: controlsDisabled
                ? null
                : () {
                    final newQuantity = item.quantity - 1;
                    if (newQuantity < 1) {
                      context.read<CartBloc>().add(
                        RemoveItemEvent(itemKey: item.key),
                      );
                      return;
                    }
                    context.read<CartBloc>().add(
                      UpdateItemQuantityEvent(
                        itemKey: item.key,
                        quantity: newQuantity,
                      ),
                    );
                  },
            icon: const Icon(Icons.remove, size: 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('${item.quantity}'),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
            onPressed: controlsDisabled
                ? null
                : () {
                    context.read<CartBloc>().add(
                      UpdateItemQuantityEvent(
                        itemKey: item.key,
                        quantity: item.quantity + 1,
                      ),
                    );
                  },
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  String _variationSubtitle(List<CartItemVariationModel> variation) {
    return variation
        .map((entry) => '${_capitalize(entry.attribute)}: ${entry.value}')
        .join(', ');
  }

  String _capitalize(String value) {
    final clean = value.trim().replaceAll('_', ' ');
    if (clean.isEmpty) return clean;
    return clean
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }
}
