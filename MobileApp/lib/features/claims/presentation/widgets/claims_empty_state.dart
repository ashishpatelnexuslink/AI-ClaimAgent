import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';

class ClaimsEmptyState extends StatefulWidget {
  final VoidCallback onClaimNow;

  const ClaimsEmptyState({super.key, required this.onClaimNow});

  @override
  State<ClaimsEmptyState> createState() => _ClaimsEmptyStateState();
}

class _ClaimsEmptyStateState extends State<ClaimsEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _lottieController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  static const _lottieAsset = 'assets/animations/empty_claims.json';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 220,
                  child: Lottie.asset(
                    _lottieAsset,
                    fit: BoxFit.contain,
                    controller: _lottieController,
                    onLoaded: (composition) {
                      // Loop a trimmed range so the animation never lands on
                      // empty in/out frames. We play 10%-90% of the timeline.
                      final total = composition.duration;
                      final start = total * 0.10;
                      final end = total * 0.90;
                      final loopDuration = end - start;
                      _lottieController
                        ..duration = total
                        ..value = start.inMilliseconds / total.inMilliseconds
                        ..repeat(
                          min: start.inMilliseconds / total.inMilliseconds,
                          max: end.inMilliseconds / total.inMilliseconds,
                          period: loopDuration,
                          reverse: false,
                        );
                    },
                    errorBuilder: (_, _, _) => const _FallbackAnimatedIcon(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.claims_empty,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D3B),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.claims_empty_subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ClaimNowButton(
                  label: l.home_claimNow,
                  onTap: widget.onClaimNow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimNowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ClaimNowButton({required this.label, required this.onTap});

  @override
  State<_ClaimNowButton> createState() => _ClaimNowButtonState();
}

class _ClaimNowButtonState extends State<_ClaimNowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final t = _shimmer.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.round),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25 + 0.15 * t),
                blurRadius: 16 + 8 * t,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.round),
          onTap: widget.onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF044DAE), Color(0xFF2A6FDB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackAnimatedIcon extends StatefulWidget {
  const _FallbackAnimatedIcon();

  @override
  State<_FallbackAnimatedIcon> createState() => _FallbackAnimatedIconState();
}

class _FallbackAnimatedIconState extends State<_FallbackAnimatedIcon>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _pulse]),
      builder: (context, _) {
        final floatY = -6 + 12 * _float.value;
        final pulseScale = 1.0 + 0.6 * _pulse.value;
        final pulseOpacity = (1 - _pulse.value).clamp(0.0, 1.0) * 0.4;
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: pulseOpacity),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, floatY),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEF3FC),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 44,
                    color: Color(0xFF2A6FDB),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
