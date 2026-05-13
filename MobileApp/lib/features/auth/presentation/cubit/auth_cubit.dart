import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/auth/session_event_bus.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/update_biometric_setting_usecase.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final LogoutUseCase _logoutUseCase;
  final BiometricLoginUseCase _biometricLoginUseCase;
  final UpdateBiometricSettingUseCase _updateBiometricSettingUseCase;
  final StreamSubscription<SessionEvent> _sessionSub;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
    required LogoutUseCase logoutUseCase,
    required BiometricLoginUseCase biometricLoginUseCase,
    required UpdateBiometricSettingUseCase updateBiometricSettingUseCase,
    required SessionEventBus sessionBus,
  })  : _loginUseCase = loginUseCase,
        _sendOtpUseCase = sendOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _getUserProfileUseCase = getUserProfileUseCase,
        _logoutUseCase = logoutUseCase,
        _biometricLoginUseCase = biometricLoginUseCase,
        _updateBiometricSettingUseCase = updateBiometricSettingUseCase,
        _sessionSub = sessionBus.stream.listen((_) {}),
        super(const AuthState()) {
    _sessionSub.onData((event) {
      if (event == SessionEvent.expired) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    });
  }

  @override
  Future<void> close() {
    _sessionSub.cancel();
    return super.close();
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) async {
        await fetchUserProfile();
        emit(state.copyWith(status: AuthStatus.authenticated));
      },
    );
  }

  Future<void> sendOtp({required String phoneOrEmail}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final result = await _sendOtpUseCase(
      SendOtpParams(phoneOrEmail: phoneOrEmail),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (otpResult) => emit(state.copyWith(
        status: AuthStatus.otpSent,
        otp: otpResult.otp,
        isNewUser: otpResult.isNewUser,
      )),
    );
  }

  Future<void> verifyOtp({
    required String phoneOrEmail,
    required String otp,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final result = await _verifyOtpUseCase(
      VerifyOtpParams(phoneOrEmail: phoneOrEmail, otp: otp),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) async {
        await fetchUserProfile();
        emit(state.copyWith(status: AuthStatus.authenticated));
      },
    );
  }

  Future<void> fetchUserProfile() async {
    final result = await _getUserProfileUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (userEntity) => emit(state.copyWith(user: userEntity)),
    );
  }

  Future<void> biometricLogin() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final result = await _biometricLoginUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> setBiometricEnabled(bool isEnabled) async {
    final result = await _updateBiometricSettingUseCase(isEnabled);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (user) => emit(state.copyWith(user: user)),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _logoutUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }
}
