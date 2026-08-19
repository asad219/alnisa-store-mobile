import 'dart:async';
import 'dart:developer' as developer;

import 'package:alnisa_store/blocs/auth/auth_state.dart';
import 'package:alnisa_store/service/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(FirebaseAuthService? authService)
    : _authService = authService ?? FirebaseAuthService.instance,
      super(const AuthState()) {
    _subscription = _authService.authStateChanges().listen((user) {
      if (user == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated, email: null));
      } else {
        emit(AuthState(status: AuthStatus.authenticated, email: user.email));
      }
    });
  }

  final FirebaseAuthService _authService;
  late final StreamSubscription<User?> _subscription;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      final detailsBlob = '${error.message ?? ''} ${error.toString()}';
      developer.log(
        'FirebaseAuthException: code=${error.code}, message=${error.message}, details=$detailsBlob',
        name: 'AuthCubit',
      );
      return _friendlyMessage(error.code, detailsBlob);
    } catch (error) {
      developer.log('Unexpected auth error: $error', name: 'AuthCubit');
      return 'Unable to sign in right now. Please try again.';
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _authService.signUp(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      final detailsBlob = '${error.message ?? ''} ${error.toString()}';
      developer.log(
        'FirebaseAuthException: code=${error.code}, message=${error.message}, details=$detailsBlob',
        name: 'AuthCubit',
      );
      return _friendlyMessage(error.code, detailsBlob);
    } catch (error) {
      developer.log('Unexpected auth error: $error', name: 'AuthCubit');
      return 'Unable to sign up right now. Please try again.';
    }
  }

  Future<void> signOut() => _authService.signOut();

  String _friendlyMessage(String code, String? details) {
    final normalizedMessage = (details ?? '').toUpperCase();

    if (code == 'internal-error') {
      if (normalizedMessage.contains('CONFIGURATION_NOT_FOUND')) {
        return 'Sign-in is not configured correctly for this app. Please contact support.';
      }
      if (normalizedMessage.contains('OPERATION_NOT_ALLOWED')) {
        return 'Email/password sign-in is not enabled for this app yet. Please contact support.';
      }
      if (normalizedMessage.contains('INVALID_API_KEY') ||
          normalizedMessage.contains('APP_NOT_AUTHORIZED')) {
        return 'App configuration error. Please contact support.';
      }
      if (normalizedMessage.contains('INVALID_LOGIN_CREDENTIALS') ||
          normalizedMessage.contains('EMAIL_NOT_FOUND') ||
          normalizedMessage.contains('INVALID_PASSWORD')) {
        return 'Email or password is incorrect.';
      }
      if (normalizedMessage.contains('USER_DISABLED')) {
        return 'This account has been disabled. Please contact support.';
      }
      if (normalizedMessage.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        return 'Too many attempts. Please try again later.';
      }
      if (normalizedMessage.contains('NETWORK_REQUEST_FAILED')) {
        return 'Network error. Please check your internet connection and try again.';
      }
    }

    switch (code) {
      case 'user-not-found':
        return 'No account was found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this app yet. Please contact support.';
      case 'configuration-not-found':
        return 'Sign-in is not configured correctly for this app. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'App configuration error. Please contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
