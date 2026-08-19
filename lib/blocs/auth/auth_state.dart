import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.email});

  final AuthStatus status;
  final String? email;

  AuthState copyWith({AuthStatus? status, String? email}) {
    return AuthState(status: status ?? this.status, email: email);
  }

  @override
  List<Object?> get props => [status, email];
}
