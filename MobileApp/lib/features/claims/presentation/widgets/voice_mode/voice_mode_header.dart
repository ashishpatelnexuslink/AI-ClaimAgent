import 'package:flutter/material.dart';

import 'voice_mode_colors.dart';

/// Top bar of the voice-mode screen: back button, "AI Claim Assistant"
/// title, and a "Close" pill that pops up the end-session dialog.
class VoiceModeHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEndSession;

  const VoiceModeHeader({
    super.key,
    required this.onBack,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kVmBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: kVmDark),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'AI Claim Assistant',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kVmDark,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onEndSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: kVmRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 14, color: kVmRed),
                  SizedBox(width: 4),
                  Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 13,
                      color: kVmRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
