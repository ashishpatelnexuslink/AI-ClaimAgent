import 'package:flutter/material.dart';

import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'voice_mode_colors.dart';

/// Center state-display avatar with status ring (idle / speaking / listening),
/// pulse animations, and a "Claim Assistant + status label" caption.
class StateAvatar extends StatelessWidget {
  final bool isRecording;
  final bool botSpeaking;
  final Animation<double> blinkController;
  final Animation<double> speakController;

  const StateAvatar({
    super.key,
    required this.isRecording,
    required this.botSpeaking,
    required this.blinkController,
    required this.speakController,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = isRecording;
    final isSpeaking = botSpeaking;
    final l = AppLocalizations.of(context);

    final Color ringColor = isListening ? const Color(0xFF22C55E) : kVmBlue;
    final Color dotColor = isListening
        ? const Color(0xFF22C55E)
        : (isSpeaking ? const Color(0xFFF59E0B) : Colors.grey.shade400);
    final String label = isListening
        ? l.voice_stateListening
        : (isSpeaking ? l.voice_stateSpeaking : l.voice_stateIdle);
    final Color labelColor = isListening
        ? const Color(0xFF22C55E)
        : (isSpeaking ? const Color(0xFFF59E0B) : Colors.grey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isListening)
                  AnimatedBuilder(
                    animation: blinkController,
                    builder: (_, _) {
                      final t = blinkController.value;
                      return Container(
                        width: 72 - 8 * t,
                        height: 72 - 8 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.18 * (1 - t)),
                        ),
                      );
                    },
                  )
                else if (isSpeaking)
                  AnimatedBuilder(
                    animation: speakController,
                    builder: (_, _) {
                      final t = speakController.value;
                      return Container(
                        width: 64 + 8 * t,
                        height: 64 + 8 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kVmBlue.withValues(alpha: 0.15 * (1 - t)),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor,
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.hearing_rounded
                        : Icons.sentiment_neutral_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: Border.all(color: kVmBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.chat_appBarTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kVmDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
