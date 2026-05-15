import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_layout.dart';
import 'package:claim_ai/injection_container.dart';

class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key});

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

enum _BiometricKind { generic, face, fingerprint }

class _BiometricLoginPageState extends State<BiometricLoginPage> {
  var _biometricKind = _BiometricKind.generic;
  bool _initialized = false;

  IconData get _biometricIcon => switch (_biometricKind) {
        _BiometricKind.face => Icons.face,
        _BiometricKind.fingerprint => Icons.fingerprint,
        _BiometricKind.generic => Icons.fingerprint,
      };

  String _biometricLabel(AppLocalizations l) => switch (_biometricKind) {
        _BiometricKind.face => l.auth_login_biometricFace,
        _BiometricKind.fingerprint => l.auth_login_biometricFingerprint,
        _BiometricKind.generic => l.auth_login_biometricGeneric,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final biometricService = sl<BiometricService>();
    final localStorage = sl<LocalStorage>();

    final hasSession = await localStorage.hasStoredSession();
    final enabled = await localStorage.isBiometricEnabled();
    final available = await biometricService.isAvailable();

    // Defensive: if the precondition isn't met any more, fall back to login.
    if (!hasSession || !enabled || !available) {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      return;
    }

    final types = await biometricService.getAvailableBiometrics();
    final hasFace = types.contains(BiometricType.face);
    final hasFingerprint = types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);
    if (!mounted) return;
    setState(() {
      _initialized = true;
      if (hasFace && !hasFingerprint) {
        _biometricKind = _BiometricKind.face;
      } else if (hasFingerprint && !hasFace) {
        _biometricKind = _BiometricKind.fingerprint;
      } else {
        _biometricKind = _BiometricKind.generic;
      }
    });

    _authenticate();
  }

  void _authenticate() {
    context.read<AuthCubit>().biometricLogin();
  }

  void _usePhoneInstead() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        } else if (state.status == AuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: AuthLayout(
        content: BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (prev, curr) => prev.status != curr.status,
          builder: (context, state) {
            final isLoading =
                state.status == AuthStatus.loading || !_initialized;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l.auth_login_title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _biometricLabel(l),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 28),
                InkWell(
                  onTap: isLoading ? null : _authenticate,
                  borderRadius: BorderRadius.circular(60),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF4FF),
                      border: Border.all(
                        color: const Color(0xFF2A6FDB),
                        width: 1.5,
                      ),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF2A6FDB),
                            ),
                          )
                        : Icon(
                            _biometricIcon,
                            size: 48,
                            color: const Color(0xFF2A6FDB),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isLoading
                      ? l.auth_login_biometricGeneric
                      : 'Tap to authenticate',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _usePhoneInstead,
                  child: const Text(
                    'Use phone number instead',
                    style: TextStyle(
                      color: Color(0xFF2A6FDB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
