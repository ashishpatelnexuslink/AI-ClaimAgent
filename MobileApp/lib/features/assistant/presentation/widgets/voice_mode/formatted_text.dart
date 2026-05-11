import 'package:flutter/material.dart';

/// Renders [text] as Text.rich, with `**bold**` segments turned into bold
/// spans. Used by bot bubbles to render Markdown-light replies inline.
class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const FormattedText({super.key, required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    int cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
