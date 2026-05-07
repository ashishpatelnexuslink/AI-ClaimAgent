import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:claim_ai/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:claim_ai/features/auth/domain/entities/auth_tokens.dart';
import 'package:claim_ai/features/auth/domain/entities/send_otp_result.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LocalStorage localStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.localStorage,
  });

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final tokens = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await localStorage.saveAccessToken(tokens.accessToken);
      await localStorage.saveRefreshToken(tokens.refreshToken);
      return Right(tokens);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, SendOtpResult>> sendOtp({required String phoneOrEmail}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await remoteDataSource.sendOtp(phoneOrEmail: phoneOrEmail);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> verifyOtp({
    required String phoneOrEmail,
    required String otp,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final tokens = await remoteDataSource.verifyOtp(
        phoneOrEmail: phoneOrEmail,
        otp: otp,
      );
      await localStorage.saveAccessToken(tokens.accessToken);
      await localStorage.saveRefreshToken(tokens.refreshToken);
      return Right(tokens);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserProfile() async {
    if (!await networkInfo.isConnected) {
      final cached = await localDataSource.getCachedUser();
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.getUserProfile();
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: 401));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // Remote logout is best-effort. Local tokens/cache must always be cleared
    // so that force-kill + relaunch lands on the login screen even if the
    // server call fails (network error, 401 with dead refresh token, etc.).
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
    } catch (_) {
      // swallow — proceed to local cleanup
    }
    await localStorage.clearTokens();
    await localDataSource.clearCache();
    return const Right(null);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
