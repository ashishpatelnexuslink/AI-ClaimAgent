import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';

/// GET_DOCUMENT trigger card. Shows the picked-document list, an
/// upload/done button, an "Add more" affordance, and a Skip pill.
class DocumentTrigger extends StatelessWidget {
  final int minCount;
  final int maxCount;
  final int alreadyUploaded;
  final List<PlatformFile> pickedDocuments;
  final int maxDocuments;
  final bool uploadingFiles;
  final VoidCallback onPickDocuments;
  final void Function(int index) onRemoveDocument;
  final VoidCallback onSubmitDocuments;
  final VoidCallback onSkipDocuments;

  const DocumentTrigger({
    super.key,
    required this.minCount,
    required this.maxCount,
    required this.alreadyUploaded,
    required this.pickedDocuments,
    required this.maxDocuments,
    required this.uploadingFiles,
    required this.onPickDocuments,
    required this.onRemoveDocument,
    required this.onSubmitDocuments,
    required this.onSkipDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                l.chat_uploadDocuments,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kVmDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                minCount > 1
                    ? l.chat_quotaUploaded(alreadyUploaded, maxCount, minCount)
                    : l.chat_photosOrPdfHint,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (pickedDocuments.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(pickedDocuments.length, (index) {
                  final doc = pickedDocuments[index];
                  final sizeKb = doc.size ~/ 1024;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: kVmBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: kVmDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Document • $sizeKb KB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onRemoveDocument(index),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Text(
                  '${pickedDocuments.length}/$maxDocuments UPLOADED',
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
                    : (pickedDocuments.isEmpty
                          ? onPickDocuments
                          : onSubmitDocuments),
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
                          pickedDocuments.isEmpty
                              ? Icons.upload_file_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: kVmDark,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        pickedDocuments.isEmpty
                            ? l.chat_uploadCaps
                            : l.chat_done,
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
              if (pickedDocuments.isNotEmpty &&
                  pickedDocuments.length < maxDocuments) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: uploadingFiles ? null : onPickDocuments,
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
        ),
        // Skip is offered as a suggestion chip on the bot bubble above; we
        // intentionally don't render a second Skip pill here to avoid the
        // duplicate-affordance look.
      ],
    );
  }
}
