import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/views/account/account_screen.dart';
import 'package:alnisa_store/views/cart/cart_screen.dart';
import 'package:alnisa_store/views/home/home_screen.dart';
import 'package:alnisa_store/views/shop/shop_screen.dart';
import 'package:alnisa_store/views/wishlist/wishlist_screen.dart';
import 'package:alnisa_store/widgets/app_bottom_nav_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  static const List<Widget> _tabs = [
    HomeScreen(),
    ShopScreen(),
    WishlistScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<MainTabCubit>().state.index;
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavBarWidget(currentIndex: currentIndex),
    );
  }
}
