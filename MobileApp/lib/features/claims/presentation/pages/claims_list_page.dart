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
    _StatusFilter(label: 'All Claims', value: null),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
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

                if (state.claims.isEmpty) {
                  return const EmptyWidget(
                    message: 'No claims found',
                    icon: Icons.assignment_outlined,
                  );
                }

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
                    itemCount: state.claims.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.claims.length) {
                        context.read<ClaimsCubit>().fetchClaims();
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final claim = state.claims[index];
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
        return SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            itemCount: _quickFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final filter = _quickFilters[i];
              final selected = state.selectedStatus == filter.value;
              return _FilterChipPill(
                label: filter.label,
                selected: selected,
                onTap: () => context
                    .read<ClaimsCubit>()
                    .onFilterByStatus(filter.value),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<ClaimsCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Status',
                  style:
                      Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<ClaimsCubit, ClaimsState>(
                  builder: (ctx, state) {
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _sheetChip('All', null, state.selectedStatus, ctx),
                        _sheetChip('Draft', 'draft', state.selectedStatus, ctx),
                        _sheetChip(
                            'Pending', 'pending', state.selectedStatus, ctx),
                        _sheetChip('Submitted', 'submitted',
                            state.selectedStatus, ctx),
                        _sheetChip('In Review', 'inReview',
                            state.selectedStatus, ctx),
                        _sheetChip('Approved', 'approved',
                            state.selectedStatus, ctx),
                        _sheetChip('Rejected', 'rejected',
                            state.selectedStatus, ctx),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetChip(
    String label,
    String? status,
    String? currentStatus,
    BuildContext context,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: currentStatus == status,
      onSelected: (_) {
        context.read<ClaimsCubit>().onFilterByStatus(status);
        Navigator.of(context).pop();
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
