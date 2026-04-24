import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/widgets/loading_widget.dart';
import 'package:claim_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:claim_ai/features/chat/presentation/cubit/chat_state.dart';
import 'package:claim_ai/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:claim_ai/features/chat/presentation/widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  final String claimId;

  const ChatPage({super.key, required this.claimId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadHistory(widget.claimId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<ChatCubit>().sendMessage(
          message: text,
          claimId: widget.claimId,
        );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        // Scroll to bottom when new messages arrive
        if (!state.isLoading && state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Assistant'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.read<ChatCubit>().clearChat(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state.isLoading && state.messages.isEmpty) {
                    return const LoadingWidget(message: 'Loading chat...');
                  }

                  if (state.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Ask me anything about this claim',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      if (message.isLoading) {
                        return const TypingIndicator();
                      }
                      return ChatBubble(message: message);
                    },
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.round),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    BlocBuilder<ChatCubit, ChatState>(
                      buildWhen: (prev, curr) =>
                          prev.isSending != curr.isSending,
                      builder: (context, state) {
                        return IconButton.filled(
                          onPressed:
                              state.isSending ? null : _sendMessage,
                          icon: state.isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
