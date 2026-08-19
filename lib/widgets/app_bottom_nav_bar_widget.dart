import 'package:alnisa_store/blocs/cart/cart_bloc.dart';
import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBottomNavBarWidget extends StatelessWidget {
  const AppBottomNavBarWidget({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<CartBloc>().state.cart?.itemsCount ?? 0;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => context.read<MainTabCubit>().changeTab(index),
      items: [
        BottomNavigationBarItem(
          icon: Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1 ? Icons.storefront : Icons.storefront_outlined,
          ),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 2 ? Icons.favorite : Icons.favorite_border,
          ),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                currentIndex == 3
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined,
              ),
              if (itemCount > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      itemCount > 99 ? '99+' : '$itemCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(currentIndex == 4 ? Icons.person : Icons.person_outline),
          label: 'Account',
        ),
      ],
    );
  }
}
