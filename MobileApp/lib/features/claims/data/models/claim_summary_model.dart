import 'package:claim_ai/features/claims/domain/entities/claim_summary_entity.dart';

class ClaimSummaryModel extends ClaimSummaryEntity {
  const ClaimSummaryModel({
    required super.totalClaims,
    required super.pendingClaims,
    required super.approvedClaims,
    required super.rejectedClaims,
    required super.inReviewClaims,
    required super.totalAmount,
    required super.approvedAmount,
  });

  factory ClaimSummaryModel.fromJson(Map<String, dynamic> json) {
    return ClaimSummaryModel(
      totalClaims: json['totalClaims'] as int,
      pendingClaims: json['pendingClaims'] as int,
      approvedClaims: json['approvedClaims'] as int,
      rejectedClaims: json['rejectedClaims'] as int,
      inReviewClaims: json['inReviewClaims'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      approvedAmount: (json['approvedAmount'] as num).toDouble(),
    );
  }
}
