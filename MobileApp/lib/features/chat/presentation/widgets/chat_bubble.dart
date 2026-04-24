import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/utils/date_utils.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';
import 'package:claim_ai/features/chat/presentation/widgets/typewriter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;

  const ChatBubble({super.key, required this.message});

  static final _assistantMarkdownStyle = MarkdownStyleSheet(
    p: const TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    pPadding: EdgeInsets.zero,
    strong: const TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    tableHead: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    tableBody: const TextStyle(
      fontSize: 13,
      color: AppColors.textPrimary,
    ),
    tableBorder: TableBorder.all(
      color: AppColors.border,
      width: 0.5,
    ),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    blockSpacing: 8,
  );

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 0),
                  bottomRight: Radius.circular(isUser ? 0 : AppRadius.lg),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        )
                      : message.animate
                          ? TypewriterMarkdown(
                              data: message.content,
                              styleSheet: _assistantMarkdownStyle,
                            )
                          : MarkdownBody(
                              data: message.content,
                              selectable: true,
                              fitContent: true,
                              shrinkWrap: true,
                              styleSheet: _assistantMarkdownStyle,
                            ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppDateUtils.formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
