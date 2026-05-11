import 'package:flutter/material.dart';

import 'voice_mode_colors.dart';

/// Footer banner shown while the mic is actively listening. A blinking red
/// dot, the live transcript-so-far, a delete button, and a Stop button.
class ListeningBanner extends StatelessWidget {
  final Animation<double> blinkController;
  final String liveTranscript;
  final VoidCallback onDeleteTranscript;
  final VoidCallback onStop;

  const ListeningBanner({
    super.key,
    required this.blinkController,
    required this.liveTranscript,
    required this.onDeleteTranscript,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: blinkController,
                builder: (_, child) {
                  return Opacity(
                    opacity: 0.2 + 0.8 * (1.0 - blinkController.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: kVmRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Listening... speak now',
                style: TextStyle(
                  fontSize: 13,
                  color: kVmDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              if (liveTranscript.trim().isNotEmpty)
                GestureDetector(
                  onTap: onDeleteTranscript,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kVmRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      fontSize: 13,
                      color: kVmRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (liveTranscript.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                liveTranscript,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
