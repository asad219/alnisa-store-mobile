import 'package:alnisa_store/service/firebase_auth_service.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService.instance,
  );
}
