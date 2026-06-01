import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/services/fcm_service.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/notifications/domain/usecases/get_pending_actions_usecase.dart';
import 'package:claim_ai/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetPendingActionsUseCase _getPendingActionsUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  StreamSubscription<RemoteMessage>? _pushSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  NotificationsCubit({
    required GetPendingActionsUseCase getPendingActionsUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    FcmService? fcmService,
  })  : _getPendingActionsUseCase = getPendingActionsUseCase,
        _markAsReadUseCase = markAsReadUseCase,
        super(const NotificationsState()) {
    if (fcmService != null) {
      _pushSub = fcmService.onMessageReceived.listen((_) => fetchPendingActions());
      _tapSub = fcmService.onMessageTap.listen((_) => fetchPendingActions());
    }
  }

  @override
  Future<void> close() async {
    await _pushSub?.cancel();
    await _tapSub?.cancel();
    return super.close();
  }

  Future<void> fetchPendingActions() async {
    emit(state.copyWith(isLoading: true));
    final result = await _getPendingActionsUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (actions) => emit(state.copyWith(
        isLoading: false,
        pendingActions: actions,
      )),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final result = await _markAsReadUseCase(notificationId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        final updated = state.pendingActions
            .where((a) => a.id != notificationId)
            .toList();
        emit(state.copyWith(pendingActions: updated));
      },
    );
  }
}
