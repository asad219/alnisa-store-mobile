import 'package:alnisa_store/blocs/auth/auth_cubit.dart';
import 'package:alnisa_store/blocs/cart/cart_bloc.dart';
import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_cubit.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Registers all app-wide BlocProviders above the [MaterialApp].
///
/// Add new BlocProviders here as later steps introduce auth/product/cart
/// blocs, keeping all app-wide state providers in a single place.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MainTabCubit>(create: (_) => MainTabCubit()),
        BlocProvider<AuthCubit>(lazy: false, create: (_) => getIt<AuthCubit>()),
        // TODO: add ProductBloc/ProductCubit provider here.
        BlocProvider<CartBloc>(
          lazy: false,
          create: (_) => getIt<CartBloc>()..add(const FetchCartEvent()),
        ),
        BlocProvider<WishlistCubit>(
          lazy: false,
          create: (_) => getIt<WishlistCubit>()..loadIds(),
        ),
      ],
      child: child,
    );
  }
}
