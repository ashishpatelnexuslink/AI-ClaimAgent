import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_state.dart';
import 'package:claim_ai/features/claims/presentation/pages/claims_list_page.dart';
import 'package:claim_ai/features/claims/presentation/pages/profile_screen.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_state.dart';

class HomePage extends StatefulWidget {
  final int initialTab;

  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex = widget.initialTab;

  @override
  void initState() {
    super.initState();
    context.read<ClaimsCubit>().fetchDashboardSummary();
    context.read<ClaimsCubit>().fetchClaims(refresh: true);
    context.read<AuthCubit>().fetchUserProfile();
    context.read<NotificationsCubit>().fetchPendingActions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (_) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _WelcomeContent(onTabSwitch: (index) => setState(() => _currentIndex = index)),
            const ClaimsListPage(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Content (Tab 0)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.onTabSwitch});

  final ValueChanged<int> onTabSwitch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ClaimsCubit>().fetchDashboardSummary(),
            context.read<NotificationsCubit>().fetchPendingActions(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: AppSpacing.md),
              const _ActionRequiredSection(),
              const SizedBox(height: AppSpacing.md),
              _HeroCard(
                onClaimNow: () async {
                  final result = await Navigator.of(context).pushNamed(
                    AppRoutes.avatarAssistant,
                  );
                  if (result is int && result != 0) {
                    onTabSwitch(result);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ClaimSummarySection(),
            ],
          ),
        ),
      ),
    );
  }
}

String _initialsFrom(String? fullName) {
  final initials = (fullName ?? '')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
  return initials.isNotEmpty ? initials : '?';
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: Avatar + Welcome + Notification Bell
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, state) {
        final avatarUrl = state.user?.avatarUrl;
        final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
        return Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEEF3FC),
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      _initialsFrom(state.user?.fullName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A6FDB),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D3B),
                    ),
                  ),
                  Text(
                    state.user?.fullName ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Notification bell
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1A1D3B),
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Action Required Section (driven by NotificationsCubit)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRequiredSection extends StatelessWidget {
  const _ActionRequiredSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (prev, curr) =>
          prev.pendingActions != curr.pendingActions ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        if (state.pendingActions.isEmpty) {
          return const SizedBox.shrink();
        }

        final action = state.pendingActions.first;
        final claimRef = action.claimNumber != null
            ? ' #${action.claimNumber}'
            : '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8E4FF),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${action.message}$claimRef',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.documents,
                          arguments: {'claimId': action.claimId ?? ''},
                        );
                        context
                            .read<NotificationsCubit>()
                            .markAsRead(action.id);
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Upload Now',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' \u2192',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Gradient Card — "Need Help With A Claim?"
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  final VoidCallback onClaimNow;

  const _HeroCard({required this.onClaimNow});

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with TickerProviderStateMixin {
  // Gentle float (up-down)
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  // Pulsing ring that expands outward
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // Soft breathing glow
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Animated bot icon
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController,
              _pulseController,
              _glowController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatOffset.value),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding pulse ring
                      Transform.scale(
                        scale: _pulseScale.value,
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4A8FE7),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Breathing glow
                      Opacity(
                        opacity: _glowOpacity.value,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF044DAE),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF044DAE),
                            width: 2.5,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/ai_agent_icon.svg',
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            'Need Help With A Claim?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description
          Text(
            'Connect with our smart avatar assistant to easily file, manage, and track your claim with personalized guidance at every step.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // CTA Button
          ElevatedButton(
            onPressed: widget.onClaimNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1D3B),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 14,
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Claim Now'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claim Summary Section
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimSummarySection extends StatelessWidget {
  const _ClaimSummarySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClaimsCubit, ClaimsState>(
      buildWhen: (prev, curr) =>
          prev.dashboardSummary != curr.dashboardSummary ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        final summary = state.dashboardSummary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Total / Pending row
            Row(
              children: [
                Expanded(
                  child: _LargeSummaryCard(
                    label: 'Total Claims',
                    count: summary?.totalClaims ?? 0,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LargeSummaryCard(
                    label: 'Pending Claims',
                    count: summary?.pendingClaims ?? 0,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Approved / Rejected row
            Row(
              children: [
                Expanded(
                  child: _SmallSummaryCard(
                    label: 'Approved',
                    count: summary?.approvedClaims ?? 0,
                    icon: Icons.check_circle,
                    iconColor: AppColors.success,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SmallSummaryCard(
                    label: 'Rejected',
                    count: summary?.rejectedClaims ?? 0,
                    icon: Icons.cancel,
                    iconColor: AppColors.error,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Large Summary Card (Total Claims / Pending Claims)
// ─────────────────────────────────────────────────────────────────────────────

class _LargeSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final bool isLoading;

  const _LargeSummaryCard({
    required this.label,
    required this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          isLoading
              ? const SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  count.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar accent
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Summary Card (Approved / Rejected)
// ─────────────────────────────────────────────────────────────────────────────

class _SmallSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;

  const _SmallSummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  count.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: 'Claims',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
