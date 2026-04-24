import 'package:equatable/equatable.dart';

class ClaimSummaryEntity extends Equatable {
  final int totalClaims;
  final int pendingClaims;
  final int approvedClaims;
  final int rejectedClaims;
  final int inReviewClaims;
  final double totalAmount;
  final double approvedAmount;

  const ClaimSummaryEntity({
    required this.totalClaims,
    required this.pendingClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.inReviewClaims,
    required this.totalAmount,
    required this.approvedAmount,
  });

  @override
  List<Object?> get props => [
        totalClaims,
        pendingClaims,
        approvedClaims,
        rejectedClaims,
        inReviewClaims,
        totalAmount,
        approvedAmount,
      ];
}
