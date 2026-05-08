import 'dart:io';

import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';

String _humanizeAngle(String angle) {
  return angle
      .split(RegExp(r'[_\s]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');
}

/// Shown after `/validate-images` rejects one or more angles. Lists each
/// failed angle with the rejected/replacement thumbnail, status, and an
/// Upload/Replace button. Submit is enabled once every failed angle has a
/// fresh path (and the screen confirms the group hasn't already uploaded).
class ImageValidationFailureList extends StatelessWidget {
  final List<String> angles;
  final Map<String, File> angleImages;
  /// For each failed angle, the path of the file at the time of failure.
  /// Used to detect whether the user has supplied a *replacement* — until
  /// they do, Submit stays disabled.
  final Map<String, String> failedAnglePaths;
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
  });

  bool _isStillRejected(String a) =>
      failedAnglePaths[a] != null &&
      angleImages[a]?.path == failedAnglePaths[a];

  @override
  Widget build(BuildContext context) {
    final allReplaced = angles.every((a) => !_isStillRejected(a));
    final canSubmit =
        allReplaced && !uploadingFiles && !botTyping && !groupAlreadyUploaded;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Some images need to be re-uploaded',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB00020),
            ),
          ),
          const SizedBox(height: 8),
          ...angles.map((angle) {
            final picked = angleImages[angle];
            final stillRejected = _isStillRejected(angle);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (picked != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        picked,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _humanizeAngle(angle),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kVmDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stillRejected
                              ? '${_humanizeAngle(angle)} does not match the required view. Please re-upload.'
                              : 'Ready to submit',
                          style: TextStyle(
                            fontSize: 11,
                            color: stillRejected
                                ? const Color(0xFFB00020)
                                : kVmBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: uploadingFiles
                        ? null
                        : () => onPickAngleImage(angle),
                    icon: Icon(
                      stillRejected ? Icons.camera_alt_outlined : Icons.refresh,
                      size: 16,
                    ),
                    label: Text(
                      stillRejected ? 'Upload' : 'Replace',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: kVmBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kVmBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: uploadingFiles
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
