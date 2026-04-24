import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';
import 'package:claim_ai/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:claim_ai/features/chat/domain/usecases/get_chat_history_usecase.dart';
import 'package:claim_ai/features/chat/presentation/cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final GetChatHistoryUseCase _getChatHistoryUseCase;
  final _uuid = const Uuid();

  ChatCubit({
    required SendMessageUseCase sendMessageUseCase,
    required GetChatHistoryUseCase getChatHistoryUseCase,
  })  : _sendMessageUseCase = sendMessageUseCase,
        _getChatHistoryUseCase = getChatHistoryUseCase,
        super(const ChatState());

  Future<void> loadHistory(String claimId) async {
    emit(state.copyWith(isLoading: true));
    final result = await _getChatHistoryUseCase(claimId);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (history) => emit(state.copyWith(
        isLoading: false,
        messages: history,
      )),
    );
  }

  Future<void> sendMessage({
    required String message,
    required String claimId,
  }) async {
    if (message.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      content: message,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      claimId: claimId,
    );

    // Add loading placeholder
    final loadingId = _uuid.v4();
    final loadingMessage = ChatMessageEntity(
      id: loadingId,
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, loadingMessage],
      isSending: true,
    ));

    final result = await _sendMessageUseCase(
      SendMessageParams(message: message, claimId: claimId),
    );

    // Remove loading placeholder
    final updatedMessages =
        state.messages.where((m) => m.id != loadingId).toList();

    result.fold(
      (failure) => emit(state.copyWith(
        messages: updatedMessages,
        isSending: false,
        errorMessage: failure.message,
      )),
      (response) {
        final animatedResponse = ChatMessageEntity(
          id: response.id,
          content: response.content,
          role: response.role,
          timestamp: response.timestamp,
          claimId: response.claimId,
          animate: true,
        );
        emit(state.copyWith(
          messages: [...updatedMessages, animatedResponse],
          isSending: false,
        ));
      },
    );
  }

  void clearChat() {
    emit(const ChatState());
  }
}
