import 'package:flutter/material.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/utils/date_utils.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';

class ClaimCard extends StatelessWidget {
  final ClaimEntity claim;
  final VoidCallback onTap;

  const ClaimCard({
    super.key,
    required this.claim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconTile(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#${claim.claimNumber}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildStatusPill(claim.status, l),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _secondaryLine(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tertiaryLine(context, l),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.claimCard_policyType,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            claim.claimType.isEmpty
                                ? '—'
                                : _localizedPolicyType(claim.claimType, l),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.claimCard_viewDetails,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconTile() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(
        Icons.directions_car_outlined,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  String _secondaryLine() {
    if (claim.title.isNotEmpty) return claim.title;
    return claim.claimType;
  }

  String _tertiaryLine(BuildContext context, AppLocalizations l) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (claim.status) {
      case ClaimStatus.approved:
        final amount = claim.amount;
        final amountStr = amount != null
            ? l.claimCard_payout(amount.toStringAsFixed(2))
            : l.claimCard_approved;
        return '$amountStr  |  ${AppDateUtils.formatDate(claim.updatedAt, locale)}';
      case ClaimStatus.rejected:
      case ClaimStatus.closed:
        return l.claimCard_closedAt(
            AppDateUtils.formatDate(claim.updatedAt, locale));
      default:
        return l.claimCard_updatedTimeAgo(
            AppDateUtils.timeAgo(claim.updatedAt, l));
    }
  }

  String _localizedPolicyType(String raw, AppLocalizations l) {
    switch (raw.trim().toLowerCase()) {
      case 'vehicle':
        return l.policyType_vehicle;
      case 'home':
        return l.policyType_home;
      case 'health':
        return l.policyType_health;
      case 'life':
        return l.policyType_life;
      case 'travel':
        return l.policyType_travel;
      default:
        return raw;
    }
  }

  Widget _buildStatusPill(ClaimStatus status, AppLocalizations l) {
    final (Color bg, Color fg, String label) = switch (status) {
      ClaimStatus.draft => (
          const Color(0xFFE8EAED),
          const Color(0xFF5F6368),
          l.claim_status_draft,
        ),
      ClaimStatus.pending => (
          const Color(0xFFFFE7B8),
          const Color(0xFFB76E00),
          l.claim_status_pending,
        ),
      ClaimStatus.submitted => (
          const Color(0xFFD7E7FD),
          const Color(0xFF1557B0),
          l.claim_status_submitted,
        ),
      ClaimStatus.inReview => (
          const Color(0xFFEADFFD),
          const Color(0xFF6A3BD6),
          l.claim_status_needInfo,
        ),
      ClaimStatus.approved => (
          const Color(0xFFD5F1DE),
          const Color(0xFF0E7C3A),
          l.claim_status_approved,
        ),
      ClaimStatus.rejected => (
          const Color(0xFFFBDAD7),
          const Color(0xFFB3261E),
          l.claim_status_rejected,
        ),
      ClaimStatus.closed => (
          const Color(0xFFE8EAED),
          const Color(0xFF5F6368),
          l.claim_status_closed,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
