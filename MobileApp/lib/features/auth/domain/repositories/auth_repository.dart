import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/domain/entities/auth_tokens.dart';
import 'package:claim_ai/features/auth/domain/entities/send_otp_result.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, SendOtpResult>> sendOtp({required String phoneOrEmail});

  Future<Either<Failure, AuthTokens>> verifyOtp({
    required String phoneOrEmail,
    required String otp,
  });

  Future<Either<Failure, UserEntity>> getUserProfile();

  Future<Either<Failure, void>> logout();

  Future<bool> isLoggedIn();

  Future<Either<Failure, UserEntity>> updateBiometricEnabled(bool isEnabled);

  Future<Either<Failure, AuthTokens>> refreshTokens();
}
