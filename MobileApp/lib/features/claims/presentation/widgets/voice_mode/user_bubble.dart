import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';

import 'formatted_text.dart';
import 'voice_mode_colors.dart';
import 'voice_mode_models.dart';

/// User-side chat bubble. Right-aligned blue pill containing the message
/// text, with optional image / document attachments stacked above and the
/// signed-in user's avatar (or initials fallback) to the right.
class UserBubble extends StatelessWidget {
  final ChatMessage msg;

  const UserBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final hasAttachments =
        msg.imagePaths.isNotEmpty || msg.documentNames.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasAttachments) ...[
                  UserAttachments(msg: msg),
                  const SizedBox(height: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: kVmBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: FormattedText(
                    text: msg.text,
                    baseStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (context) {
              final user = context.watch<AuthCubit>().state.user;
              final avatarUrl = user?.avatarUrl;
              final initials = (user?.fullName ?? '')
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .take(2)
                  .map((p) => p[0].toUpperCase())
                  .join();
              return Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (_, _, _) =>
                              _InitialsAvatar(initials: initials),
                        )
                      : _InitialsAvatar(initials: initials),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Image / document thumbnails stacked above the user bubble's text. Right-
/// aligned in a wrap so multiple images flow into rows. Document names get
/// their own outlined chips (Icon + filename).
class UserAttachments extends StatelessWidget {
  final ChatMessage msg;

  const UserAttachments({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.imagePaths.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: msg.imagePaths.map((path) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (msg.documentNames.isNotEmpty) ...[
          if (msg.imagePaths.isNotEmpty) const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: msg.documentNames.map((name) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 18,
                        color: kVmBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kVmDark,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: kVmUserInitialsBg,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: kVmUserInitialsText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Icon(Icons.person, size: 22, color: kVmUserInitialsText),
    );
  }
}
