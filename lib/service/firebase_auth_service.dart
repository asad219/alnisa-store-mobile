import 'package:firebase_auth/firebase_auth.dart';

/// Singleton wrapper around [FirebaseAuth] used for login/signup and to
/// source the ID token attached to WooCommerce requests tied to the
/// logged-in customer.
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  /// Firebase ID token for the current user, or `null` if signed out.
  /// Used by [ApiClient] as the `Authorization: Bearer` header for
  /// customer-specific endpoints.
  Future<String?> getIdToken({bool forceRefresh = false}) {
    final user = currentUser;
    if (user == null) return Future.value(null);
    return user.getIdToken(forceRefresh);
  }
}
