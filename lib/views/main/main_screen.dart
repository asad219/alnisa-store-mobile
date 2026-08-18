import 'package:alnisa_store/views/account/account_screen.dart';
import 'package:alnisa_store/views/cart/cart_screen.dart';
import 'package:alnisa_store/views/home/home_screen.dart';
import 'package:alnisa_store/views/shop/shop_screen.dart';
import 'package:alnisa_store/views/wishlist/wishlist_screen.dart';
import 'package:alnisa_store/widgets/app_bottom_nav_bar_widget.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  static const List<Widget> _tabs = [
    HomeScreen(),
    ShopScreen(),
    WishlistScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavBarWidget(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
