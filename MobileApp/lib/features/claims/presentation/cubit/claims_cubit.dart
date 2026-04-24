import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_state.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_claims_usecase.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_claim_detail_usecase.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_dashboard_summary_usecase.dart';

class ClaimsCubit extends Cubit<ClaimsState> {
  final GetClaimsUseCase _getClaimsUseCase;
  final GetClaimDetailUseCase _getClaimDetailUseCase;
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;

  ClaimsCubit({
    required GetClaimsUseCase getClaimsUseCase,
    required GetClaimDetailUseCase getClaimDetailUseCase,
    required GetDashboardSummaryUseCase getDashboardSummaryUseCase,
  })  : _getClaimsUseCase = getClaimsUseCase,
        _getClaimDetailUseCase = getClaimDetailUseCase,
        _getDashboardSummaryUseCase = getDashboardSummaryUseCase,
        super(const ClaimsState());

  Future<void> fetchClaims({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        currentPage: 1,
        hasMore: true,
        claims: [],
        clearError: true,
      ));
    }

    if (!state.hasMore && !refresh) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getClaimsUseCase(
      GetClaimsParams(
        page: state.currentPage,
        status: state.selectedStatus,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (newClaims) => emit(state.copyWith(
        isLoading: false,
        claims: [...state.claims, ...newClaims],
        hasMore: newClaims.length >= 20,
        currentPage: state.currentPage + 1,
      )),
    );
  }

  Future<void> fetchClaimDetail(String claimId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getClaimDetailUseCase(claimId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (claim) => emit(state.copyWith(
        isLoading: false,
        selectedClaim: claim,
      )),
    );
  }

  Future<void> fetchDashboardSummary() async {
    final result = await _getDashboardSummaryUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (summary) => emit(state.copyWith(dashboardSummary: summary)),
    );
  }

  void onSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    fetchClaims(refresh: true);
  }

  void onFilterByStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
    fetchClaims(refresh: true);
  }
}
