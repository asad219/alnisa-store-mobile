import 'package:flutter/material.dart';

class AppBottomNavBarWidget extends StatelessWidget {
  const AppBottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
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
          icon: Icon(
            currentIndex == 3
                ? Icons.shopping_cart
                : Icons.shopping_cart_outlined,
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
