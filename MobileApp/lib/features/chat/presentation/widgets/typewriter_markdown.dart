import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
class TypewriterMarkdown extends StatefulWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final VoidCallback? onComplete;

  const TypewriterMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
    this.onComplete,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  int _charCount = 0;
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    const charInterval = Duration(milliseconds: 15);
    _timer = Timer.periodic(charInterval, (timer) {
      if (_charCount >= widget.data.length) {
        timer.cancel();
        setState(() => _isComplete = true);
        widget.onComplete?.call();
        return;
      }
      setState(() {
        // Reveal multiple chars at once for speed on long messages
        _charCount = (_charCount + 2).clamp(0, widget.data.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = _isComplete
        ? widget.data
        : widget.data.substring(0, _charCount);

    return MarkdownBody(
      data: visibleText,
      selectable: _isComplete,
      fitContent: true,
      shrinkWrap: true,
      styleSheet: widget.styleSheet,
    );
  }
}
