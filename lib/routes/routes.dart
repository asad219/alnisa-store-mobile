import 'package:alnisa_store/routes/routes_import.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:flutter/material.dart';

class Routes {
  Routes._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RoutesName.main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case RoutesName.signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case RoutesName.signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case RoutesName.productDetail:
        final productId = settings.arguments;
        if (productId is int) {
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid product id')), 
          ),
        );
      case RoutesName.about:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'About',
            message: 'About page coming soon.',
          ),
        );
      case RoutesName.contactUs:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Contact Us',
            message: 'Contact details coming soon.',
          ),
        );
      case RoutesName.terms:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Terms',
            message: 'Terms and conditions coming soon.',
          ),
        );
      case RoutesName.privacy:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Privacy',
            message: 'Privacy policy coming soon.',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
