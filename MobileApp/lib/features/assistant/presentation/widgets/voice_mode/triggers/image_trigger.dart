import 'dart:io';

import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';

/// Maps a backend angle key (e.g. "front_left") to a localized label,
/// falling back to a title-cased humanization for unknown angles.
String humanizeAngle(String angle, AppLocalizations l) {
  switch (angle.trim().toLowerCase()) {
    case 'front_left':
      return l.imageAngle_frontLeft;
    case 'front_right':
      return l.imageAngle_frontRight;
    case 'rear_left':
    case 'back_left':
      return l.imageAngle_rearLeft;
    case 'rear_right':
    case 'back_right':
      return l.imageAngle_rearRight;
    case 'front':
      return l.imageAngle_front;
    case 'rear':
    case 'back':
      return l.imageAngle_rear;
    case 'left':
      return l.imageAngle_left;
    case 'right':
      return l.imageAngle_right;
    case 'interior':
      return l.imageAngle_interior;
    case 'dashboard':
      return l.imageAngle_dashboard;
    default:
      return angle
          .split(RegExp(r'[_\s]+'))
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');
  }
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
    final l = AppLocalizations.of(context);
    if (angles.isEmpty) return _buildLegacy(l);
    return _buildAngleMode(l);
  }

  Widget _buildAngleMode(AppLocalizations l) {
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
            l.chat_quotaUploaded(filledCount, maxCount, minCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            AngleRow(
              angle: angles[i],
              picked: angleImages[angles[i]],
              atCap:
                  angleImages.length >= maxCount &&
                  !angleImages.containsKey(angles[i]),
              uploadingFiles: uploadingFiles,
              stillRejected: false,
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

  Widget _buildLegacy(AppLocalizations l) {
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
          Text(
            l.chat_uploadPhotos,
            style: const TextStyle(
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
              l.chat_legacyUploadedCount(legacyImages.length, legacyMaxImages),
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
                    legacyImages.isEmpty ? l.chat_uploadCaps : l.chat_done,
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
                l.chat_addMore,
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

/// One row of the per-angle uploader: thumbnail + label/status + Upload /
/// Replace / Remove. When [stillRejected] is true the row renders in the
/// re-upload state (red status text, broken-image placeholder, no Remove
/// button) so the same widget can back both [ImageTrigger] and the
/// validation-failure card.
class AngleRow extends StatelessWidget {
  final String angle;
  final File? picked;
  final bool atCap;
  final bool uploadingFiles;
  final bool stillRejected;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const AngleRow({
    super.key,
    required this.angle,
    required this.picked,
    required this.atCap,
    required this.uploadingFiles,
    required this.stillRejected,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Per-angle error text now lives only in the failure card's banner —
    // the row keeps a neutral "Not uploaded" so the Upload button sits flush.
    final String statusText;
    final Color statusColor;
    if (stillRejected || picked == null) {
      statusText = l.chat_notUploaded;
      statusColor = Colors.grey.shade600;
    } else {
      statusText = l.chat_uploaded;
      statusColor = kVmBlue;
    }
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
              stillRejected
                  ? Icons.broken_image_outlined
                  : Icons.image_outlined,
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
                humanizeAngle(angle, l),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kVmDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(fontSize: 11, color: statusColor),
              ),
            ],
          ),
        ),
        if (picked != null && !stillRejected)
          IconButton(
            tooltip: l.chat_remove,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
          ),
        // "Replace" collapses to a bare refresh icon to match the X next to
        // it; "Upload" keeps its label + camera icon so the affordance is
        // obvious on empty rows.
        if (picked == null || stillRejected)
          TextButton.icon(
            onPressed: (atCap || uploadingFiles) ? null : onPick,
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: Text(l.chat_upload, style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: kVmBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          )
        else
          IconButton(
            tooltip: l.chat_replace,
            onPressed: (atCap || uploadingFiles) ? null : onPick,
            icon: const Icon(Icons.refresh, size: 18, color: kVmBlue),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
