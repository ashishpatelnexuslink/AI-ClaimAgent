import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:local_auth/local_auth.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_layout.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_gradient_button.dart';
import 'package:claim_ai/injection_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN', dialCode: '+91');
  bool _isPhoneValid = false;
  bool _isFocused = false;

  bool _showBiometricButton = false;
  IconData _biometricIcon = Icons.fingerprint;
  String _biometricLabel = 'Login with biometric';

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isFocused = _phoneFocusNode.hasFocus);
    });
    _evaluateBiometricVisibility();
  }

  Future<void> _evaluateBiometricVisibility() async {
    final biometricService = sl<BiometricService>();
    final localStorage = sl<LocalStorage>();
    final accessToken = await localStorage.getAccessToken();
    final refreshToken = await localStorage.getRefreshToken();
    final hasSession = await localStorage.hasStoredSession();
    final enabled = await localStorage.isBiometricEnabled();
    final available = await biometricService.isAvailable();
    final types = await biometricService.getAvailableBiometrics();
    debugPrint('[login/biometric] hasSession=$hasSession '
        '(access=${accessToken != null && accessToken.isNotEmpty}, '
        'refresh=${refreshToken != null && refreshToken.isNotEmpty}) '
        'biometricEnabledFlag=$enabled '
        'deviceAvailable=$available '
        'enrolledTypes=$types');
    if (!hasSession || !enabled || !available) {
      debugPrint('[login/biometric] hiding link — '
          'missing: ${[
        if (!hasSession) 'session',
        if (!enabled) 'flag',
        if (!available) 'device',
      ].join(", ")}');
      if (mounted) setState(() => _showBiometricButton = false);
      return;
    }
    final hasFace = types.contains(BiometricType.face);
    final hasFingerprint =
        types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);
    if (!mounted) return;
    setState(() {
      _showBiometricButton = true;
      if (hasFace && !hasFingerprint) {
        _biometricIcon = Icons.face;
        _biometricLabel = 'Login with Face ID';
      } else if (hasFingerprint && !hasFace) {
        _biometricIcon = Icons.fingerprint;
        _biometricLabel = 'Login with Fingerprint';
      } else {
        _biometricIcon = Icons.fingerprint;
        _biometricLabel = 'Login with biometric';
      }
    });
  }

  void _onBiometricLogin() {
    context.read<AuthCubit>().biometricLogin();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onContinue() {
    final complete = _phoneNumber.phoneNumber ?? '';
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your mobile number');
      return;
    }
    if (!_isPhoneValid || complete.isEmpty) {
      _showError('Enter a valid mobile number');
      return;
    }
    context.read<AuthCubit>().sendOtp(phoneOrEmail: complete);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        } else if (state.status == AuthStatus.otpSent) {
          Navigator.of(context).pushNamed(
            AppRoutes.otp,
            arguments: {
              'phoneOrEmail': _phoneNumber.phoneNumber ?? '',
              'otp': state.otp,
              'isNewUser': state.isNewUser,
            },
          );
        } else if (state.status == AuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: AuthLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your mobile number to get started.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isFocused
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFE5E7EB),
                  width: _isFocused ? 1.5 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _phoneNumber = number;
                },
                onInputValidated: (bool isValid) {
                  _isPhoneValid = isValid;
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  useEmoji: true,
                  setSelectorButtonAsPrefixIcon: true,
                  leadingPadding: 10,
                  trailingSpace: false,
                  useBottomSheetSafeArea: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                ),
                initialValue: _phoneNumber,
                textFieldController: _phoneController,
                focusNode: _phoneFocusNode,
                cursorColor: const Color(0xFF1A1A2E),
                formatInput: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                inputDecoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Mobile number',
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 4, right: 10),
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE5E7EB),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 24,
                  ),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                searchBoxDecoration: InputDecoration(
                  hintText: 'Search country or code',
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                ),
                spaceBetweenSelectorAndTextField: 0,
              ),
              ),
            ),
            const SizedBox(height: 24),
            // Continue button
            BlocBuilder<AuthCubit, AuthState>(
              buildWhen: (prev, curr) => prev.status != curr.status,
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;
                return AuthGradientButton(
                  label: 'Continue',
                  isLoading: isLoading,
                  onPressed: _onContinue,
                );
              },
            ),
            if (_showBiometricButton) ...[
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: _onBiometricLogin,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_biometricIcon,
                            size: 18, color: const Color(0xFF2A6FDB)),
                        const SizedBox(width: 6),
                        Text(
                          _biometricLabel,
                          style: const TextStyle(
                            color: Color(0xFF2A6FDB),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF2A6FDB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
