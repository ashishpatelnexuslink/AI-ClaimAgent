import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

const _kDark = Color(0xFF1A1D3B);

const List<Color> _kLabelColors = [
  Color(0xFF2A6FDB), // Front-Left  — blue
  Color(0xFF34C759), // Front-Right — green
  Color(0xFFFF9F0A), // Rear-Left   — orange
  Color(0xFF8E5BFF), // Rear-Right  — purple
];

/// Decodes a base64 image string that may carry a `data:image/...;base64,`
/// prefix. Returns `null` on any decode failure so callers can fall back to a
/// placeholder.
Uint8List? decodeBase64Image(String value) {
  try {
    var data = value.trim();
    final commaIdx = data.indexOf(',');
    if (data.startsWith('data:') && commaIdx != -1) {
      data = data.substring(commaIdx + 1);
    }
    return base64Decode(data);
  } catch (_) {
    return null;
  }
}

/// Pops up a centered modal showing the bot's `sample_images` payload as a
/// 2-column grid of labeled photos. Layout matches the figma reference for
/// the "See Sample" affordance.
Future<void> showSampleImagesDialog({
  required BuildContext context,
  required List<String> base64Images,
  required List<String> labels,
  Uint8List? Function(String)? decoder,
}) {
  if (base64Images.isEmpty) return Future.value();
  final decode = decoder ?? decodeBase64Image;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      return Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sample Photos',
                        style: TextStyle(
                          color: _kDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: () => Navigator.of(ctx).pop(),
                      radius: 18,
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: base64Images.length,
                  itemBuilder: (_, i) {
                    final bytes = decode(base64Images[i]);
                    final label =
                        i < labels.length ? labels[i] : 'Sample ${i + 1}';
                    final color = _kLabelColors[i % _kLabelColors.length];
                    return _SampleTile(
                      bytes: bytes,
                      label: label,
                      color: color,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SampleTile extends StatelessWidget {
  const _SampleTile({
    required this.bytes,
    required this.label,
    required this.color,
  });

  final Uint8List? bytes;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null)
            Image.memory(bytes!, fit: BoxFit.cover)
          else
            Container(
              color: const Color(0xFFEEF1F7),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.black26,
                size: 36,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
