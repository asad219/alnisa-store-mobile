import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_cubit.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_state.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:alnisa_store/widgets/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();

    final wishlistCubit = context.read<WishlistCubit>();
    final wishlistState = wishlistCubit.state;

    if (wishlistState.status == WishlistStatus.initial) {
      wishlistCubit.loadIds();
    } else if (wishlistState.wishlistedIds.isNotEmpty &&
        wishlistState.wishlistedProducts.isEmpty) {
      wishlistCubit.loadWishlistedProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          final isLoading =
              state.status == WishlistStatus.loading ||
              state.status == WishlistStatus.initial;

          // True empty state: not loading, and no products.
          if (!isLoading && state.wishlistedProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      color: AppColors.textSecondary,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your wishlist is empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MainTabCubit>().changeTab(0);
                      },
                      child: const Text('Browse Products'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Loading state (ids not yet checked, or products still being fetched)
          // and we don't have any products to show yet: show a clean spinner only.
          if (isLoading && state.wishlistedProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // We have products already (or are refreshing while showing stale ones): show the grid,
          // with a thin top progress bar if a refresh is in flight.
          return Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: state.wishlistedProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final product = state.wishlistedProducts[index];
                  return ProductCardWidget(
                    product: product,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        RoutesName.productDetail,
                        arguments: product.id,
                      );
                    },
                    onWishlistTap: () {
                      context.read<WishlistCubit>().toggle(product.id);
                    },
                  );
                },
              ),
              if (state.status == WishlistStatus.loading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }
}
