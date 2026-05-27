import 'dart:io';

import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';
import 'image_trigger.dart';

/// Re-upload card shown after `/validate-images` rejects one or more angles.
/// Mirrors [ImageTrigger]'s angle-mode card (same title, counter, [AngleRow]
/// rows, DONE pill) so the user sees the same upload component they used
/// initially, with a red banner up top carrying the AI's failure reason.
class ImageValidationFailureList extends StatelessWidget {
  final List<String> angles;
  final Map<String, File> angleImages;
  /// For each failed angle, the path of the file at the time of failure.
  /// A row stays in the rejected state while [angleImages] still points at
  /// that same path — once the user picks a fresh file, the screen clears
  /// the entry and Submit unlocks.
  final Map<String, String> failedAnglePaths;
  final String? failureReason;
  final bool uploadingFiles;
  final bool botTyping;
  final bool groupAlreadyUploaded;
  final void Function(String angle) onPickAngleImage;
  final VoidCallback onSubmit;

  const ImageValidationFailureList({
    super.key,
    required this.angles,
    required this.angleImages,
    required this.failedAnglePaths,
    required this.uploadingFiles,
    required this.botTyping,
    required this.groupAlreadyUploaded,
    required this.onPickAngleImage,
    required this.onSubmit,
    this.failureReason,
  });

  bool _isStillRejected(String a) =>
      failedAnglePaths[a] != null &&
      angleImages[a]?.path == failedAnglePaths[a];


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allReplaced = angles.every((a) => !_isStillRejected(a));
    final canSubmit =
        allReplaced && !uploadingFiles && !botTyping && !groupAlreadyUploaded;
    final filledCount = angles.where(angleImages.containsKey).length;
    // The bot bubble already provides the white background + rounded corners
    // + shadow, so the failure card stays as a transparent inner layout to
    // avoid the double-bordered "card-in-a-card" look.
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.chat_uploadPhotos,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kVmDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.chat_quotaUploaded(filledCount, angles.length, angles.length),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.chat_someImagesReupload,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB00020),
                  ),
                ),
                if (angles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  for (final a in angles)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB00020),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l.chat_angleImageNotProper(humanizeAngle(a, l)),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB00020),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            AngleRow(
              angle: angles[i],
              picked: angleImages[angles[i]],
              atCap: false,
              uploadingFiles: uploadingFiles,
              stillRejected: _isStillRejected(angles[i]),
              onPick: () => onPickAngleImage(angles[i]),
              onRemove: () {},
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: canSubmit ? onSubmit : null,
            child: Opacity(
              opacity: canSubmit ? 1.0 : 0.5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: kVmBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (uploadingFiles)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      l.chat_done,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
