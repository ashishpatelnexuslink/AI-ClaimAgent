import 'package:flutter/material.dart';

import 'voice_mode_colors.dart';

/// Small circular avatar shown next to bot bubbles. When [animate] is true and
/// [speakController] is provided, a soft halo pulses around the avatar in time
/// with TTS playback.
class BotAvatar extends StatelessWidget {
  final bool animate;
  final Animation<double>? speakController;

  const BotAvatar({super.key, this.animate = false, this.speakController});

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: kVmBlue, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset(
          'assets/images/avatar_assistant.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
    if (!animate || speakController == null) return avatar;
    return AnimatedBuilder(
      animation: speakController!,
      builder: (_, child) {
        final t = speakController!.value;
        final scale = 1.0 + 0.08 * t;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36 + 12 * t,
              height: 36 + 12 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kVmBlue.withValues(alpha: 0.18 * (1 - t)),
              ),
            ),
            Transform.scale(scale: scale, child: child),
          ],
        );
      },
      child: avatar,
    );
  }
}
