import 'package:equatable/equatable.dart';

class PendingActionEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final String actionType;
  final String? actionUrl;
  final String? claimId;
  final String? claimNumber;
  final DateTime createdAt;

  const PendingActionEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.actionType,
    this.actionUrl,
    this.claimId,
    this.claimNumber,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        actionType,
        actionUrl,
        claimId,
        claimNumber,
        createdAt,
      ];
}
