import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/widgets/loading_widget.dart';
import 'package:claim_ai/core/widgets/error_widget.dart';
import 'package:claim_ai/core/widgets/empty_widget.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_state.dart';
import 'package:claim_ai/features/claims/presentation/widgets/claim_card.dart';

class ClaimsListPage extends StatelessWidget {
  const ClaimsListPage({super.key});

  static const List<_StatusFilter> _quickFilters = [
    _StatusFilter(label: 'All', value: null),
    _StatusFilter(label: 'Approved', value: 'approved'),
    _StatusFilter(label: 'Pending', value: 'pending'),
    _StatusFilter(label: 'In Review', value: 'inReview'),
    _StatusFilter(label: 'Rejected', value: 'rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Claims'),
      ),
      body: Column(
        children: [
          _buildFilterChipsRow(),
          Expanded(
            child: BlocBuilder<ClaimsCubit, ClaimsState>(
              builder: (context, state) {
                if (state.isLoading && state.claims.isEmpty) {
                  return const LoadingWidget(message: 'Loading claims...');
                }

                if (state.errorMessage != null && state.claims.isEmpty) {
                  return AppErrorWidget(
                    message: state.errorMessage!,
                    onRetry: () =>
                        context.read<ClaimsCubit>().fetchClaims(refresh: true),
                  );
                }

                final selected = state.selectedStatus;
                final visibleClaims = selected == null
                    ? state.claims
                    : state.claims
                        .where((c) => c.status.name == selected)
                        .toList();

                if (visibleClaims.isEmpty) {
                  return const EmptyWidget(
                    message: 'No claims found',
                    icon: Icons.assignment_outlined,
                  );
                }

                final showLoader = state.hasMore && selected == null;
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<ClaimsCubit>().fetchClaims(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: visibleClaims.length + (showLoader ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == visibleClaims.length) {
                        context.read<ClaimsCubit>().fetchClaims();
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final claim = visibleClaims[index];
                      return ClaimCard(
                        claim: claim,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.claimDetail,
                          arguments: {'claimId': claim.id},
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return BlocBuilder<ClaimsCubit, ClaimsState>(
      buildWhen: (prev, curr) => prev.selectedStatus != curr.selectedStatus,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final filter in _quickFilters)
                _FilterChipPill(
                  label: filter.label,
                  selected: state.selectedStatus == filter.value,
                  onTap: () => context
                      .read<ClaimsCubit>()
                      .onFilterByStatus(filter.value),
                ),
            ],
          ),
        );
      },
    );
  }

}

class _StatusFilter {
  final String label;
  final String? value;

  const _StatusFilter({required this.label, required this.value});
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.round),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
