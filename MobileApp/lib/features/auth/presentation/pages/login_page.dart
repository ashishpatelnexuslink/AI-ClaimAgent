import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:claim_ai/features/auth/presentation/widgets/country_picker.dart';
// import 'package:claim_ai/injection_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  String _dialCode = '+91';
  String _countryIso = 'IN';

  // Biometric login temporarily disabled.
  // bool _showBiometricButton = false;
  // bool _biometricBusy = false;
  // int _bioFailCount = 0;
  // static const _maxBioFailures = 3;

  // @override
  // void initState() {
  //   super.initState();
  //   _evaluateBiometricEligibility();
  // }

  // Future<void> _evaluateBiometricEligibility() async {
  //   final localStorage = sl<LocalStorage>();
  //   if (!localStorage.isBiometricEnabled) return;
  //   final biometricService = sl<BiometricService>();
  //   final available = await biometricService.isAvailable();
  //   if (!available) return;
  //   final hasSession = await localStorage.hasStoredSession();
  //   if (!hasSession) return;
  //   if (!mounted) return;
  //   setState(() => _showBiometricButton = true);
  // }

  // Future<void> _onBiometricLogin() async {
  //   if (_biometricBusy) return;
  //   setState(() => _biometricBusy = true);
  //   try {
  //     final biometricService = sl<BiometricService>();
  //     final ok = await biometricService.authenticate(
  //       reason: 'Sign in to ClaimAI',
  //     );
  //     if (!mounted) return;
  //     if (!ok) {
  //       _bioFailCount += 1;
  //       if (_bioFailCount >= _maxBioFailures) {
  //         await sl<LocalStorage>().setBiometricEnabled(false);
  //         if (!mounted) return;
  //         setState(() => _showBiometricButton = false);
  //         _showError(
  //           'Biometric login disabled after $_maxBioFailures failed attempts. Please sign in with OTP.',
  //         );
  //       } else {
  //         _showError('Biometric authentication failed — try again.');
  //       }
  //       return;
  //     }
  //
  //     // Biometric ok — validate the stored session against the server. The
  //     // Dio interceptor will refresh-on-401, so a Right means we can route
  //     // straight to Home; a Left means both tokens are dead and we must
  //     // fall back to OTP.
  //     final probe = await sl<GetUserProfileUseCase>()(const NoParams());
  //     if (!mounted) return;
  //     probe.fold(
  //       (_) async {
  //         await sl<AuthRepository>().logout();
  //         if (!mounted) return;
  //         setState(() => _showBiometricButton = false);
  //         _showError('Session expired, please sign in again.');
  //       },
  //       (_) {
  //         Navigator.of(context).pushNamedAndRemoveUntil(
  //           AppRoutes.home,
  //           (_) => false,
  //         );
  //       },
  //     );
  //   } finally {
  //     if (mounted) setState(() => _biometricBusy = false);
  //   }
  // }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Country get _country => countryByIso(_countryIso);

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _fullPhone => '$_dialCode$_digits';

  void _onContinue() {
    final digits = _digits;
    final country = _country;
    if (digits.isEmpty) {
      _showError('Please enter your mobile number');
      return;
    }
    if (!country.lengths.contains(digits.length)) {
      final expected = country.lengths.join('/');
      _showError(
        'Enter a valid ${country.name} number ($expected digits)',
      );
      return;
    }
    context.read<AuthCubit>().sendOtp(phoneOrEmail: _fullPhone);
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
              'phoneOrEmail': _fullPhone,
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
            // Phone input - two separate rounded containers
            Row(
              children: [
                // Country selector pill
                _CountrySelector(
                  iso: _countryIso,
                  dialCode: _dialCode,
                  onChanged: (c) {
                    setState(() {
                      _dialCode = c.dialCode;
                      _countryIso = c.iso;
                      _phoneController.clear();
                    });
                  },
                ),
                const SizedBox(width: 10),
                // Phone number input pill
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_country.maxLength),
                      ],
                      decoration: InputDecoration(
                        prefixText: '$_dialCode  ',
                        prefixStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: _country.example,
                        hintStyle: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.only(left: 20),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              ],
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
            //   Row(
            //     children: const [
            //       Expanded(child: Divider(color: Color(0xFFE5E7EB))),
            //       Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 12),
            //         child: Text(
            //           'or',
            //           style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            //         ),
            //       ),
            //       Expanded(child: Divider(color: Color(0xFFE5E7EB))),
            //     ],
            //   ),
            //   const SizedBox(height: 16),
            //   SizedBox(
            //     width: double.infinity,
            //     height: 50,
            //     child: OutlinedButton.icon(
            //       onPressed: _biometricBusy ? null : _onBiometricLogin,
            //       style: OutlinedButton.styleFrom(
            //         foregroundColor: const Color(0xFF1A1A2E),
            //         side: const BorderSide(color: Color(0xFFE5E7EB)),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(25),
            //         ),
            //       ),
            //       icon: _biometricBusy
            //           ? const SizedBox(
            //               width: 18,
            //               height: 18,
            //               child: CircularProgressIndicator(strokeWidth: 2),
            //             )
            //           : const Icon(Icons.fingerprint, size: 22),
            //       label: const Text(
            //         'Sign in with biometrics',
            //         style: TextStyle(
            //           fontSize: 14,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}

class _CountrySelector extends StatelessWidget {
  final String iso;
  final String dialCode;
  final ValueChanged<Country> onChanged;

  const _CountrySelector({
    required this.iso,
    required this.dialCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final country = countryByIso(iso);
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () async {
        final selected = await showCountryPicker(context);
        if (selected != null) onChanged(selected);
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
