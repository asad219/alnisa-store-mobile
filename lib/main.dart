import 'package:alnisa_store/common/app_providers.dart';
import 'package:alnisa_store/config/env_config.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/firebase_options.dart';
import 'package:alnisa_store/routes/routes.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:alnisa_store/service/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.validate();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Alnisa Store',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        initialRoute: RoutesName.splash,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
