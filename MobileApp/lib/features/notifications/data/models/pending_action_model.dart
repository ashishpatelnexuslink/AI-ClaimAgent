import 'package:claim_ai/features/notifications/domain/entities/pending_action_entity.dart';

class PendingActionModel extends PendingActionEntity {
  const PendingActionModel({
    required super.id,
    required super.title,
    required super.message,
    required super.actionType,
    super.actionUrl,
    super.claimId,
    super.claimNumber,
    required super.createdAt,
  });

  factory PendingActionModel.fromJson(Map<String, dynamic> json) {
    return PendingActionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      actionType: json['actionType'] as String,
      actionUrl: json['actionUrl'] as String?,
      claimId: json['claimId'] as String?,
      claimNumber: json['claimNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
