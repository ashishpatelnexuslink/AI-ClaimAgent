import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:claim_ai/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:claim_ai/injection_container.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Phase 1 — background reveal
  late final AnimationController _bgController;
  late final Animation<double> _bgOpacity;

  // Phase 2 — logo entrance
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Phase 3 — shimmer sweep across logo
  late final AnimationController _shimmerController;

  // Phase 4 — breathing glow behind logo (loops)
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  // Phase 5 — ring reveal (two concentric rings fade in sequentially)
  late final AnimationController _ringController;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _ring2Scale;

  // Exit — fade out
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    // Immersive status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Background fade-in
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeOut);

    // Logo — elegant scale from 0.85 → 1.0 (subtle, no bounce)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Shimmer light sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Breathing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glowScale = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.12, end: 0.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Concentric rings
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ring1Opacity = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _ring1Scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.0, end: 0.08).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Fade out
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInCubic),
    );
  }

  void _startSequence() async {
    // Phase 1 — background fades in
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _bgController.forward();

    // Phase 2 — logo enters after bg is partially visible
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _logoController.forward();
    _ringController.forward();

    // Phase 3 — start breathing glow
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _glowController.repeat(reverse: true);

    // Phase 4 — shimmer sweep after logo is fully visible
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _shimmerController.forward();

    // Begin auth check
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    debugPrint('[splash] _checkAuth: start');
    try {
      // Let the full animation play ~4.5s total
      await Future.delayed(const Duration(milliseconds: 2000));
      debugPrint('[splash] _checkAuth: delay done, resolving deps');

      final authRepo = sl<AuthRepository>();
      debugPrint('[splash] _checkAuth: authRepo resolved');
      var isLoggedIn = await authRepo.isLoggedIn();
      debugPrint('[splash] _checkAuth: hasToken=$isLoggedIn');

      // A stored token only proves we logged in once — it may be expired and
      // its refresh token may also be expired. Probe an authenticated endpoint
      // so the Dio interceptor exercises refresh-on-401; if both tokens are
      // dead the call returns Left(AuthFailure) and we route to login instead
      // of dropping the user on home with a stuck-loading screen.
      var biometricEnabled = false;
      if (isLoggedIn) {
        final probe = await sl<GetUserProfileUseCase>()(const NoParams());
        isLoggedIn = probe.isRight();
        debugPrint('[splash] _checkAuth: probe ok=$isLoggedIn');
        if (isLoggedIn) {
          biometricEnabled = await sl<LocalStorage>().isBiometricEnabled();
          debugPrint('[splash] _checkAuth: biometricEnabled=$biometricEnabled');
        }
      }

      if (!mounted) return;

      await _fadeOutController.forward();
      debugPrint('[splash] _checkAuth: fadeOut done, navigating');
      if (!mounted) return;

      // When biometric login is enabled, always route through the login page so
      // the user must tap the biometric button to unlock — even if tokens are
      // still valid. Without this gate, a valid token bypasses biometric and
      // the unlock prompt is never shown.
      if (isLoggedIn && !biometricEnabled) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (_) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
      }
    } catch (e, st) {
      debugPrint('[splash] _checkAuth: ERROR $e\n$st');
      if (!mounted) return;
      // Any unexpected failure (network down, dead tokens, parse error) must
      // not leave the user stranded on splash — fall through to login.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070E1A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _logoController,
          _shimmerController,
          _glowController,
          _ringController,
          _fadeOutController,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Deep gradient background
                Opacity(
                  opacity: _bgOpacity.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.15),
                        radius: 1.2,
                        colors: [
                          Color(0xFF0F2744),
                          Color(0xFF0A1C34),
                          Color(0xFF070E1A),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Subtle top-right accent glow
                Positioned(
                  top: -80,
                  right: -80,
                  child: Opacity(
                    opacity: _bgOpacity.value * 0.06,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF1A73E8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Subtle bottom-left accent glow
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Opacity(
                    opacity: _bgOpacity.value * 0.04,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF1A73E8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Center logo composition
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Transform.scale(
                          scale: _ring2Scale.value,
                          child: Opacity(
                            opacity: _ring2Opacity.value,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Inner ring
                        Transform.scale(
                          scale: _ring1Scale.value,
                          child: Opacity(
                            opacity: _ring1Opacity.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Breathing glow
                        Transform.scale(
                          scale: _glowScale.value,
                          child: Opacity(
                            opacity: _glowOpacity.value,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF1A73E8),
                                    blurRadius: 100,
                                    spreadRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Logo with shimmer
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                final shimmerPos =
                                    _shimmerController.value * 3 - 1;
                                return LinearGradient(
                                  begin: Alignment(shimmerPos - 0.5, -0.3),
                                  end: Alignment(shimmerPos + 0.5, 0.3),
                                  colors: const [
                                    Colors.white,
                                    Color(0xFFE0EEFF),
                                    Colors.white,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Image.asset(
                                'assets/images/draudita_logo.png',
                                width: 240,
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom fine line accent
                Positioned(
                  bottom: 50,
                  left: 60,
                  right: 60,
                  child: Opacity(
                    opacity: _logoOpacity.value * 0.12,
                    child: Container(
                      height: 0.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF1A73E8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
