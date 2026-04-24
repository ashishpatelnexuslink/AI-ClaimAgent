import 'package:equatable/equatable.dart';
import 'package:claim_ai/features/notifications/domain/entities/pending_action_entity.dart';

class NotificationsState extends Equatable {
  final List<PendingActionEntity> pendingActions;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsState({
    this.pendingActions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    List<PendingActionEntity>? pendingActions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      pendingActions: pendingActions ?? this.pendingActions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [pendingActions, isLoading, errorMessage];
}
