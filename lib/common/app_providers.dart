import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
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
        // TODO: add AuthBloc/AuthCubit provider here.
        // TODO: add ProductBloc/ProductCubit provider here.
        // TODO: add CartBloc/CartCubit provider here.
      ],
      child: child,
    );
  }
}
