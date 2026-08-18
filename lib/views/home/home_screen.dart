import 'dart:async';

import 'package:alnisa_store/blocs/banner/banner_cubit.dart';
import 'package:alnisa_store/blocs/banner/banner_state.dart';
import 'package:alnisa_store/blocs/category/category_cubit.dart';
import 'package:alnisa_store/blocs/category/category_state.dart';
import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/blocs/product/product_bloc.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:alnisa_store/widgets/banner_carousel_widget.dart';
import 'package:alnisa_store/widgets/product_card_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(create: (_) => getIt<ProductBloc>()),
        BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
        BlocProvider<BannerCubit>(create: (_) => getIt<BannerCubit>()),
      ],
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  final ScrollController _scrollController = ScrollController();
  int _nextPage = 2;

  @override
  void initState() {
    super.initState();
    context.read<BannerCubit>().loadBanners();
    context.read<CategoryCubit>().loadCategories();
    context.read<ProductBloc>().add(
      const FetchProductsEvent(orderby: 'date', order: 'desc', reset: true),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      final state = context.read<ProductBloc>().state;
      if (!state.hasReachedMax && state.status != ProductStatus.loadingMore) {
        context.read<ProductBloc>().add(
          FetchProductsEvent(
            page: _nextPage,
            orderby: 'date',
            order: 'desc',
            reset: false,
          ),
        );
        _nextPage++;
      }
    }
  }

  Future<void> _onRefresh() async {
    _nextPage = 2;
    await Future.wait([
      context.read<BannerCubit>().loadBanners(),
      context.read<CategoryCubit>().loadCategories(),
    ]);
    if (!mounted) return;
    context.read<ProductBloc>().add(
      const FetchProductsEvent(orderby: 'date', order: 'desc', reset: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 16,
        title: Image.asset('assets/images/logo.webp', height: 32),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pushNamed(RoutesName.search);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              context.read<MainTabCubit>().changeTab(3);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerSection(),
              SizedBox(height: 16),
              _CategoryRow(),
              SizedBox(height: 16),
              _NewArrivalsSection(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerCubit, BannerState>(
      builder: (context, state) {
        if (state.status == BannerStatus.loading ||
            state.status == BannerStatus.initial) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        if (state.status == BannerStatus.failure) {
          return const SizedBox.shrink();
        }

        return BannerCarouselWidget(banners: state.banners);
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Shop by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              if (state.status == CategoryStatus.loading ||
                  state.status == CategoryStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == CategoryStatus.failure ||
                  state.categories.isEmpty) {
                return const SizedBox.shrink();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: navigate to Shop tab filtered by category.
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.background,
                            backgroundImage:
                                category.image != null &&
                                    category.image!.src.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    category.image!.src,
                                  )
                                : null,
                            child:
                                category.image == null ||
                                    category.image!.src.isEmpty
                                ? const Icon(
                                    Icons.category_outlined,
                                    color: AppColors.textSecondary,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 64,
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewArrivalsSection extends StatelessWidget {
  const _NewArrivalsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Arrivals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: navigate to Shop tab / full new-arrivals list.
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state.status == ProductStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.status == ProductStatus.failure &&
                state.products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(state.error ?? 'Something went wrong.'),
                ),
              );
            }

            if (state.products.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                  itemBuilder: (context, index) {
                    final ProductModel product = state.products[index];
                    return ProductCardWidget(
                      product: product,
                      onTap: () {
                        // TODO: navigate to product details screen.
                      },
                      onWishlistTap: () {
                        // TODO: wire up wishlist toggling.
                      },
                    );
                  },
                ),
                if (state.status == ProductStatus.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
