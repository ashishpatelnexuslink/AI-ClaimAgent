import 'dart:io';

import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';

/// "front_left" → "Front Left".
String _humanizeAngle(String angle) {
  return angle
      .split(RegExp(r'[_\s]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');
}

/// GET_IMAGE trigger card. Renders a per-angle uploader when the bot's
/// payload includes `allowed_angles`; otherwise renders the legacy free-form
/// multi-image picker. The widget is purely a renderer — picking, removing,
/// and submitting are forwarded to the screen via callbacks.
class ImageTrigger extends StatelessWidget {
  // Per-angle inputs (empty `angles` ⇒ legacy mode)
  final List<String> angles;
  final int minCount;
  final int maxCount;
  final Map<String, File> angleImages;
  final void Function(String angle) onPickAngleImage;
  final void Function(String angle) onRemoveAngleImage;
  final VoidCallback onSubmitAngleImages;

  // Legacy free-form inputs
  final List<File> legacyImages;
  final int legacyMaxImages;
  final VoidCallback onPickImages;
  final void Function(int index) onRemoveImage;
  final VoidCallback onSubmitImages;

  // Shared
  final bool uploadingFiles;
  final bool botTyping;

  const ImageTrigger({
    super.key,
    required this.angles,
    required this.minCount,
    required this.maxCount,
    required this.angleImages,
    required this.onPickAngleImage,
    required this.onRemoveAngleImage,
    required this.onSubmitAngleImages,
    required this.legacyImages,
    required this.legacyMaxImages,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmitImages,
    required this.uploadingFiles,
    required this.botTyping,
  });

  @override
  Widget build(BuildContext context) {
    if (angles.isEmpty) return _buildLegacy();
    return _buildAngleMode();
  }

  Widget _buildAngleMode() {
    final filledCount = angles.where(angleImages.containsKey).length;
    final canSubmit = filledCount >= minCount && !uploadingFiles && !botTyping;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kVmDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$filledCount of $maxCount uploaded · min $minCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _AngleRow(
              angle: angles[i],
              picked: angleImages[angles[i]],
              atCap:
                  angleImages.length >= maxCount &&
                  !angleImages.containsKey(angles[i]),
              uploadingFiles: uploadingFiles,
              onPick: () => onPickAngleImage(angles[i]),
              onRemove: () => onRemoveAngleImage(angles[i]),
            ),
          ],
          const SizedBox(height: 12),
          if (filledCount >= minCount)
            GestureDetector(
              onTap: canSubmit ? onSubmitAngleImages : null,
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
                      const Text(
                        'DONE',
                        style: TextStyle(
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

  Widget _buildLegacy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kVmDark,
            ),
          ),
          if (legacyImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: legacyImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          legacyImages[index],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${legacyImages.length}/$legacyMaxImages UPLOADED',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: uploadingFiles
                ? null
                : (legacyImages.isEmpty ? onPickImages : onSubmitImages),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
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
                        color: kVmDark,
                      ),
                    )
                  else
                    Icon(
                      legacyImages.isEmpty
                          ? Icons.camera_alt_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: kVmDark,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    legacyImages.isEmpty ? 'UPLOAD' : 'DONE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kVmDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (legacyImages.isNotEmpty &&
              legacyImages.length < legacyMaxImages) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: uploadingFiles ? null : onPickImages,
              child: Text(
                '+ Add more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AngleRow extends StatelessWidget {
  final String angle;
  final File? picked;
  final bool atCap;
  final bool uploadingFiles;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _AngleRow({
    required this.angle,
    required this.picked,
    required this.atCap,
    required this.uploadingFiles,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (picked != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(picked!, width: 48, height: 48, fit: BoxFit.cover),
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
              Icons.image_outlined,
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
                picked == null ? 'Not uploaded' : 'Uploaded',
                style: TextStyle(
                  fontSize: 11,
                  color: picked == null ? Colors.grey.shade600 : kVmBlue,
                ),
              ),
            ],
          ),
        ),
        if (picked != null)
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
          ),
        TextButton.icon(
          onPressed: (atCap || uploadingFiles) ? null : onPick,
          icon: Icon(
            picked == null ? Icons.camera_alt_outlined : Icons.refresh,
            size: 16,
          ),
          label: Text(
            picked == null ? 'Upload' : 'Replace',
            style: const TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: kVmBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
