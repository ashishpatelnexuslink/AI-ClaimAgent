import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/entities/send_otp_result.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';

class SendOtpUseCase extends UseCase<SendOtpResult, SendOtpParams> {
  final AuthRepository repository;

  SendOtpUseCase({required this.repository});

  @override
  Future<Either<Failure, SendOtpResult>> call(SendOtpParams params) {
    return repository.sendOtp(
      phoneOrEmail: params.phoneOrEmail,
      country: params.country,
    );
  }
}

class SendOtpParams {
  final String phoneOrEmail;
  final String? country;

  const SendOtpParams({required this.phoneOrEmail, this.country});
}
