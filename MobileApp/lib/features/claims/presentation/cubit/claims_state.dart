import 'package:equatable/equatable.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_summary_entity.dart';

class ClaimsState extends Equatable {
  final List<ClaimEntity> claims;
  final ClaimEntity? selectedClaim;
  final ClaimSummaryEntity? dashboardSummary;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;
  final String searchQuery;
  final String? selectedStatus;

  const ClaimsState({
    this.claims = const [],
    this.selectedClaim,
    this.dashboardSummary,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
    this.searchQuery = '',
    this.selectedStatus,
  });

  ClaimsState copyWith({
    List<ClaimEntity>? claims,
    ClaimEntity? selectedClaim,
    ClaimSummaryEntity? dashboardSummary,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    Object? selectedStatus = _unset,
    bool clearSelectedClaim = false,
    bool clearError = false,
  }) {
    return ClaimsState(
      claims: claims ?? this.claims,
      selectedClaim: clearSelectedClaim ? null : (selectedClaim ?? this.selectedClaim),
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => [
        claims,
        selectedClaim,
        dashboardSummary,
        isLoading,
        errorMessage,
        currentPage,
        hasMore,
        searchQuery,
        selectedStatus,
      ];
}
