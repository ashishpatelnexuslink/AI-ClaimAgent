import 'package:dio/dio.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/auth/data/models/auth_tokens_model.dart';
import 'package:claim_ai/features/auth/data/models/user_model.dart';
import 'package:claim_ai/features/auth/domain/entities/send_otp_result.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  });
  Future<SendOtpResult> sendOtp({required String phoneOrEmail});
  Future<AuthTokensModel> verifyOtp({
    required String phoneOrEmail,
    required String otp,
  });
  Future<UserModel> getUserProfile();
  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phone,
  });
  Future<String> uploadProfilePhoto({required String filePath});
  Future<void> logout();
  Future<UserModel> updateBiometricEnabled(bool isEnabled);
  Future<AuthTokensModel> refreshTokens({
    required String accessToken,
    required String refreshToken,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthTokensModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<SendOtpResult> sendOtp({required String phoneOrEmail}) async {
    final response = await _client.post(
      ApiConstants.sendOtp,
      data: {'phoneNumber': phoneOrEmail},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SendOtpResult(
      otp: data['otp'] as String,
      isNewUser: data['isNewUser'] as bool,
    );
  }

  @override
  Future<AuthTokensModel> verifyOtp({
    required String phoneOrEmail,
    required String otp,
  }) async {
    final response = await _client.post(
      ApiConstants.verifyOtp,
      data: {'phoneNumber': phoneOrEmail, 'otp': otp},
    );
    return AuthTokensModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getUserProfile() async {
    final response = await _client.get(ApiConstants.userProfile);
    return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    await _client.put(
      ApiConstants.updateProfile,
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
      },
    );
  }

  @override
  Future<String> uploadProfilePhoto({required String filePath}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _client.uploadFile(
      ApiConstants.uploadProfilePhoto,
      data: formData,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return data['avatarUrl'] as String;
  }

  @override
  Future<void> logout() async {
    await _client.post(ApiConstants.logout);
  }

  @override
  Future<UserModel> updateBiometricEnabled(bool isEnabled) async {
    final response = await _client.put(
      ApiConstants.updateBiometricSetting,
      data: {'isEnabled': isEnabled},
    );
    return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AuthTokensModel> refreshTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final response = await _client.post(
      ApiConstants.refreshToken,
      data: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
    return AuthTokensModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
