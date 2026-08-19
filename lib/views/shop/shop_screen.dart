import 'package:alnisa_store/blocs/category/category_cubit.dart';
import 'package:alnisa_store/blocs/category/category_state.dart';
import 'package:alnisa_store/blocs/product/product_bloc.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_cubit.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/models/product/product_model.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:alnisa_store/widgets/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(create: (_) => getIt<ProductBloc>()),
        BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
      ],
      child: _ShopScreenBody(initialCategoryId: initialCategoryId),
    );
  }
}

class _ShopScreenBody extends StatefulWidget {
  const _ShopScreenBody({this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<_ShopScreenBody> createState() => _ShopScreenBodyState();
}

class _ShopScreenBodyState extends State<_ShopScreenBody> {
  final ScrollController _scrollController = ScrollController();

  int? _selectedCategoryId;
  _SortOption _selectedSort = _SortOption.newest;
  int _nextPage = 2;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    context.read<CategoryCubit>().loadCategories();
    _fetchProducts(reset: true);
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
        _fetchProducts(reset: false);
      }
    }
  }

  void _fetchProducts({required bool reset}) {
    final page = reset ? 1 : _nextPage;
    context.read<ProductBloc>().add(
      FetchProductsEvent(
        page: page,
        categoryId: _selectedCategoryId,
        orderby: _selectedSort.orderby,
        order: _selectedSort.order,
        reset: reset,
      ),
    );

    if (reset) {
      _nextPage = 2;
    } else {
      _nextPage++;
    }
  }

  void _onCategorySelected(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _fetchProducts(reset: true);
  }

  void _onSortSelected(_SortOption option) {
    if (_selectedSort == option) return;
    setState(() => _selectedSort = option);
    _fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () => Navigator.of(context).pushNamed(RoutesName.search),
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilterRow(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: _onCategorySelected,
          ),
          _SortControl(
            selectedSort: _selectedSort,
            onSortSelected: _onSortSelected,
          ),
          Expanded(
            child: _ProductGrid(
              scrollController: _scrollController,
              onRetry: () => _fetchProducts(reset: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        final categories = state.categories;

        return SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _CategoryChip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              ),
              ...categories.map(
                (category) => _CategoryChip(
                  label: category.name,
                  selected: selectedCategoryId == category.id,
                  onTap: () => onCategorySelected(category.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.background,
        ),
      ),
    );
  }
}

class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.selectedSort,
    required this.onSortSelected,
  });

  final _SortOption selectedSort;
  final ValueChanged<_SortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          PopupMenuButton<_SortOption>(
            initialValue: selectedSort,
            onSelected: onSortSelected,
            itemBuilder: (context) => _SortOption.values
                .map(
                  (option) => PopupMenuItem<_SortOption>(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.background),
              ),
              child: Row(
                children: [
                  Text(selectedSort.label),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.scrollController,
    required this.onRetry,
  });

  final ScrollController scrollController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.status == ProductStatus.loading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ProductStatus.failure && state.products.isEmpty) {
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
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status == ProductStatus.success && state.products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        final showLoaderAtEnd = state.status == ProductStatus.loadingMore;
        final itemCount = state.products.length + (showLoaderAtEnd ? 1 : 0);

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemBuilder: (context, index) {
            if (index >= state.products.length) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final ProductModel product = state.products[index];
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
        );
      },
    );
  }
}

enum _SortOption {
  newest(label: 'Newest', orderby: 'date', order: 'desc'),
  priceLowHigh(label: 'Price: Low to High', orderby: 'price', order: 'asc'),
  priceHighLow(label: 'Price: High to Low', orderby: 'price', order: 'desc'),
  bestRated(label: 'Best Rated', orderby: 'rating', order: 'desc');

  const _SortOption({
    required this.label,
    required this.orderby,
    required this.order,
  });

  final String label;
  final String orderby;
  final String order;
}
