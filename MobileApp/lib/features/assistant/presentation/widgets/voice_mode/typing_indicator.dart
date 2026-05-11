import 'package:flutter/material.dart';

import 'bot_avatar.dart';

/// "Bot is typing" three-dot indicator shown while [_streamBotReply] is
/// waiting on the SSE stream. The dots bounce out of phase, driven by
/// [typingController] (a repeating animation owned by the screen).
class TypingIndicator extends StatelessWidget {
  final Animation<double> typingController;

  const TypingIndicator({super.key, required this.typingController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: typingController,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.15;
                    final t = (typingController.value - delay).clamp(0.0, 1.0);
                    final offset =
                        -4.0 * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0));
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
