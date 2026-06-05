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

  /// In-flight fetch, used to coalesce overlapping callers. Multiple widgets
  /// (HomePage.initState, voice mode close, ClaimsListPage refresh) can all
  /// trigger fetchClaims around the same time. Without this guard two
  /// page-1 requests race and their `fold`s both append to `state.claims`,
  /// producing duplicate rows in the list until the next refresh.
  Future<void>? _inFlight;

  ClaimsCubit({
    required GetClaimsUseCase getClaimsUseCase,
    required GetClaimDetailUseCase getClaimDetailUseCase,
    required GetDashboardSummaryUseCase getDashboardSummaryUseCase,
  })  : _getClaimsUseCase = getClaimsUseCase,
        _getClaimDetailUseCase = getClaimDetailUseCase,
        _getDashboardSummaryUseCase = getDashboardSummaryUseCase,
        super(const ClaimsState());

  Future<void> fetchClaims({bool refresh = false}) {
    final pending = _inFlight;
    if (pending != null) return pending;
    final future = _doFetchClaims(refresh: refresh);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetchClaims({required bool refresh}) async {
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
      (newClaims) {
        // Dedup by id when appending the next page — defense in depth against
        // any caller that bypasses the coalescing guard or against the server
        // returning an overlapping window between pages.
        final seen = {for (final c in state.claims) c.id};
        final additions =
            newClaims.where((c) => seen.add(c.id)).toList(growable: false);
        emit(state.copyWith(
          isLoading: false,
          claims: [...state.claims, ...additions],
          hasMore: newClaims.length >= 20,
          currentPage: state.currentPage + 1,
        ));
      },
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
  }
}
