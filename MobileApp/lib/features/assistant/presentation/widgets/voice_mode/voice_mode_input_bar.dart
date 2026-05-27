import 'package:flutter/material.dart';

import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'voice_mode_colors.dart';

/// Bottom input bar: rounded white pill with the textfield + an in-pill mic
/// button, and a separate gradient send button to the right.
class VoiceModeInputBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode inputFocus;
  final bool isRecording;
  final bool botSpeaking;
  final bool voiceAvailable;
  final bool hasDraftText;
  final VoidCallback onSubmitText;
  final VoidCallback onMicTap;

  const VoiceModeInputBar({
    super.key,
    required this.textController,
    required this.inputFocus,
    required this.isRecording,
    required this.botSpeaking,
    required this.voiceAvailable,
    required this.hasDraftText,
    required this.onSubmitText,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = inputFocus.hasFocus;
    final micActive = isRecording || botSpeaking;
    // Idle mic icon is a neutral dark grey to match the soft white pill;
    // active states (recording / interrupting) stay red for clarity.
    final micIconColor = micActive ? kVmRed : const Color(0xFF4A4F5C);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: const BoxDecoration(
        // Soft grey base so the white pill reads as a floating element
        // rather than blending into a pure-white bottom bar.
        color: Color(0xFFF3F4F8),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isFocused ? 0.05 : 0.03,
                    ),
                    blurRadius: isFocused ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      focusNode: inputFocus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmitText(),
                      minLines: 1,
                      maxLines: 4,
                      cursorColor: kVmBlue,
                      style: const TextStyle(
                        fontSize: 15,
                        color: kVmDark,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: botSpeaking
                            ? AppLocalizations.of(context).voice_tapMicToInterrupt
                            : AppLocalizations.of(context).voice_describeHere,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: voiceAvailable ? onMicTap : null,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F2F6),
                        shape: BoxShape.circle,
                      ),
                      child: voiceAvailable
                          ? Icon(
                              botSpeaking
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_none_rounded,
                              size: 20,
                              color: micIconColor,
                            )
                          : const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kVmBlue,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: hasDraftText
                ? onSubmitText
                : (voiceAvailable ? onMicTap : null),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isRecording
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kVmRed, kVmRed.withValues(alpha: 0.85)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3D7DE6), Color(0xFF1F4FB8)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? kVmRed : kVmBlue).withValues(
                      alpha: 0.35,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
