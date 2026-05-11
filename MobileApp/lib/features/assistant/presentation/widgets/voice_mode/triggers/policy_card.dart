import 'package:flutter/material.dart';

import '../voice_mode_colors.dart';

/// Structured card with a header (green check + title) and a list of
/// label/value rows. Used by bot bubbles whose payload is a parsed table or
/// a Markdown "**Key:** Value" block. Status rows tinted green when the
/// value contains "active".
class PolicyCard extends StatelessWidget {
  final String title;
  final Map<String, String> fields;

  const PolicyCard({super.key, required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    final statusValue = fields.entries
        .where((e) => e.key.toLowerCase() == 'status')
        .map((e) => e.value)
        .firstOrNull;
    final isActive =
        statusValue != null && statusValue.toLowerCase().contains('active');
    final maxCardWidth = MediaQuery.of(context).size.width * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxCardWidth),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34A853),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kVmDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Column(
                children: List.generate(fields.length, (i) {
                  final entry = fields.entries.elementAt(i);
                  final isStatus = entry.key.toLowerCase() == 'status';
                  final isLast = i == fields.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            '${entry.key}:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isStatus && isActive
                                  ? const Color(0xFF34A853)
                                  : kVmDark,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
