import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_state.dart';
import 'package:claim_ai/features/claims/presentation/pages/claims_list_page.dart';
import 'package:claim_ai/features/profile/presentation/pages/profile_screen.dart';
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

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return const ClaimsListPage();
      case 2:
        return const ProfileScreen();
      case 0:
      default:
        return _WelcomeContent(
          onTabSwitch: (i) => setState(() => _currentIndex = i),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _buildTab(_currentIndex),
            ),
          ),
          bottomNavigationBar: _BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
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
                  final result = await Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.avatarAssistant);
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
  return (fullName ?? '')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
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
        final initialsText = _initialsFrom(state.user?.fullName);
        final initials = Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          color: const Color(0xFFEEF3FC),
          child: initialsText.isNotEmpty
              ? Text(
                  initialsText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A6FDB),
                  ),
                )
              : const Icon(Icons.person, size: 26, color: Color(0xFF2A6FDB)),
        );
        return Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                        errorBuilder: (_, _, _) => initials,
                      )
                    : initials,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).home_welcomeBack,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D3B),
                    ),
                  ),
                  Text(
                    state.user?.fullName ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Notification bell
            const _NotificationBell(),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Bell (with unread badge) — opens a bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (prev, curr) =>
          prev.pendingActions.length != curr.pendingActions.length,
      builder: (context, state) {
        final unreadCount = state.pendingActions.length;
        return GestureDetector(
          onTap: () => _openSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: unreadCount > 9
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: unreadCount > 9
                          ? BorderRadius.circular(9)
                          : null,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: const _NotificationsSheet(),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context).notifications_title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D3B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state.pendingActions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).notifications_empty,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.pendingActions.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 56,
                    ),
                    itemBuilder: (_, i) {
                      final action = state.pendingActions[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF4E5),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          action.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          action.claimNumber != null
                              ? '${action.message} #${action.claimNumber}'
                              : action.message,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.grey,
                          ),
                          tooltip: AppLocalizations.of(
                            context,
                          ).notifications_markAsRead,
                          onPressed: () => context
                              .read<NotificationsCubit>()
                              .markAsRead(action.id),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            AppRoutes.claimDetail,
                            arguments: {'claimId': action.claimId ?? ''},
                          );
                        },
                      );
                    },
                  );
                },
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
            color: const Color(0xFFF3EFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9CFFF), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE05757),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.claimDetail,
                          arguments: {'claimId': action.claimId ?? ''},
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.of(context).home_uploadNow,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
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
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

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
            AppLocalizations.of(context).home_needHelpTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description
          Text(
            AppLocalizations.of(context).home_needHelpDescription,
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
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(AppLocalizations.of(context).home_claimNow),
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
              AppLocalizations.of(context).home_claimSummary,
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
                    label: AppLocalizations.of(context).home_totalClaims,
                    count: summary?.totalClaims ?? 0,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LargeSummaryCard(
                    label: AppLocalizations.of(context).home_pendingClaims,
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
                    label: AppLocalizations.of(context).status_approved,
                    count: summary?.approvedClaims ?? 0,
                    icon: Icons.check_circle,
                    iconColor: AppColors.success,
                    isLoading: state.isLoading && summary == null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SmallSummaryCard(
                    label: AppLocalizations.of(context).status_rejected,
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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

  const _BottomNavBar({required this.currentIndex, required this.onTap});

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
                label: AppLocalizations.of(context).nav_home,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: AppLocalizations.of(context).nav_claims,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: AppLocalizations.of(context).nav_profile,
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
    const duration = Duration(milliseconds: 320);
    const curve = Curves.easeOutCubic;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: isSelected ? 1.18 : 1.0),
              duration: duration,
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.85, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(isSelected),
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: curve,
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(-0.3, 0),
                    end: Offset.zero,
                  ).animate(anim);
                  return ClipRect(
                    child: FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: slide, child: child),
                    ),
                  );
                },
                child: isSelected
                    ? Padding(
                        key: ValueKey(label),
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
