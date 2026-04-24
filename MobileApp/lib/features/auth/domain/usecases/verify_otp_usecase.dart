import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/entities/auth_tokens.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase extends UseCase<AuthTokens, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtpUseCase({required this.repository});

  @override
  Future<Either<Failure, AuthTokens>> call(VerifyOtpParams params) {
    return repository.verifyOtp(
      phoneOrEmail: params.phoneOrEmail,
      otp: params.otp,
    );
  }
}

class VerifyOtpParams {
  final String phoneOrEmail;
  final String otp;

  const VerifyOtpParams({required this.phoneOrEmail, required this.otp});
}
