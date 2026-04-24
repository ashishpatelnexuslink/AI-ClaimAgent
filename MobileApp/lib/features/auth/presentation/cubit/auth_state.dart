import 'package:equatable/equatable.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, otpSent, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final String? otp;
  final bool isNewUser;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.otp,
    this.isNewUser = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    String? otp,
    bool? isNewUser,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      otp: otp ?? this.otp,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, otp, isNewUser];
}
