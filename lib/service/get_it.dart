import 'package:alnisa_store/blocs/auth/auth_cubit.dart';
import 'package:alnisa_store/blocs/banner/banner_cubit.dart';
import 'package:alnisa_store/blocs/cart/cart_bloc.dart';
import 'package:alnisa_store/blocs/category/category_cubit.dart';
import 'package:alnisa_store/blocs/product_detail/product_detail_cubit.dart';
import 'package:alnisa_store/blocs/product/product_bloc.dart';
import 'package:alnisa_store/blocs/wishlist/wishlist_cubit.dart';
import 'package:alnisa_store/repository/banner/banner_http_api_repository.dart';
import 'package:alnisa_store/repository/cart/cart_http_api_repository.dart';
import 'package:alnisa_store/repository/product/product_http_api_repository.dart';
import 'package:alnisa_store/service/firebase_auth_service.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService.instance,
  );
  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(null));

  getIt.registerLazySingleton<ProductHttpApiRepository>(
    () => ProductHttpApiRepository(),
  );
  getIt.registerLazySingleton<BannerHttpApiRepository>(
    () => BannerHttpApiRepository(),
  );
  getIt.registerLazySingleton<CartHttpApiRepository>(
    () => CartHttpApiRepository(),
  );
  getIt.registerLazySingleton<CartBloc>(() => CartBloc(null));
  getIt.registerLazySingleton<WishlistCubit>(() => WishlistCubit(null));

  // Screen-scoped: a new instance per screen, not shared app-wide.
  getIt.registerFactory<ProductBloc>(() => ProductBloc(null));
  getIt.registerFactory<CategoryCubit>(() => CategoryCubit(null));
  getIt.registerFactory<BannerCubit>(() => BannerCubit(null));
  getIt.registerFactory<ProductDetailCubit>(() => ProductDetailCubit(null));
}
