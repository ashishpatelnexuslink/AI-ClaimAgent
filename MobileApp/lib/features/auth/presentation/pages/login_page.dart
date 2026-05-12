import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
// Biometric login temporarily disabled — re-enable by uncommenting these
// imports and the biometric block below.
// import 'package:claim_ai/core/services/biometric_service.dart';
// import 'package:claim_ai/core/storage/local_storage.dart';
// import 'package:claim_ai/core/usecases/usecase.dart';
// import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';
// import 'package:claim_ai/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_layout.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_gradient_button.dart';
// import 'package:claim_ai/injection_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN', dialCode: '+91');
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  leadingPadding: 8,
                  trailingSpace: false,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
                initialValue: _phoneNumber,
                textFieldController: _phoneController,
                formatInput: false,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Mobile number',
                  hintStyle: TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
                searchBoxDecoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                spaceBetweenSelectorAndTextField: 0,
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
            // Biometric login temporarily disabled.
            // if (_showBiometricButton) ...[
            //   const SizedBox(height: 16),
            //   ...
            // ],
          ],
        ),
      ),
    );
  }
}
