import 'package:flutter/material.dart';

import 'voice_mode_colors.dart';

/// Suggestion chips rendered below the latest bot bubble. Each chip submits
/// its label as the user's next message via [onSelect].
class ChatChips extends StatelessWidget {
  final List<String> options;
  final void Function(String value) onSelect;

  const ChatChips({super.key, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kVmBlue),
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 13,
                color: kVmBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
