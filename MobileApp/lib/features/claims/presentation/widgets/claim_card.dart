import 'package:flutter/material.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
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
                              _buildStatusPill(claim.status),
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
                            _tertiaryLine(context),
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
                          const Text(
                            'POLICY TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            claim.claimType.isEmpty ? '—' : claim.claimType,
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
                        children: const [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
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

  String _tertiaryLine(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (claim.status) {
      case ClaimStatus.approved:
        final amount = claim.amount;
        final amountStr = amount != null
            ? 'Payout: \$${amount.toStringAsFixed(2)}'
            : 'Approved';
        return '$amountStr  |  ${AppDateUtils.formatDate(claim.updatedAt, locale)}';
      case ClaimStatus.rejected:
      case ClaimStatus.closed:
        return 'Closed at ${AppDateUtils.formatDate(claim.updatedAt, locale)}';
      default:
        return 'Updated ${AppDateUtils.timeAgo(claim.updatedAt)}';
    }
  }

  Widget _buildStatusPill(ClaimStatus status) {
    final (Color bg, Color fg, String label) = switch (status) {
      ClaimStatus.draft => (
          const Color(0xFFE8EAED),
          const Color(0xFF5F6368),
          'DRAFT',
        ),
      ClaimStatus.pending => (
          const Color(0xFFFFE7B8),
          const Color(0xFFB76E00),
          'PENDING',
        ),
      ClaimStatus.submitted => (
          const Color(0xFFD7E7FD),
          const Color(0xFF1557B0),
          'SUBMITTED',
        ),
      ClaimStatus.inReview => (
          const Color(0xFFEADFFD),
          const Color(0xFF6A3BD6),
          'NEED INFO',
        ),
      ClaimStatus.approved => (
          const Color(0xFFD5F1DE),
          const Color(0xFF0E7C3A),
          'APPROVED',
        ),
      ClaimStatus.rejected => (
          const Color(0xFFFBDAD7),
          const Color(0xFFB3261E),
          'REJECTED',
        ),
      ClaimStatus.closed => (
          const Color(0xFFE8EAED),
          const Color(0xFF5F6368),
          'CLOSED',
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
