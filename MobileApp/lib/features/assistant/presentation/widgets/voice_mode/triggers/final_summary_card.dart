import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../bot_avatar.dart';
import '../formatted_text.dart';
import '../voice_mode_colors.dart';

/// "Review Your Claim" card shown when the bot streams a `final_summary`
/// payload. The screen pre-organizes the payload fields into basic /
/// incident / document buckets and passes them as already-typed entry lists
/// — this widget is purely presentational.
class FinalSummaryCard extends StatelessWidget {
  /// Visible (typewriter-revealed) text of the intro bubble above the card.
  final String introVisibleText;
  /// Whether to show the intro bubble at all (false when the bot text is
  /// empty/whitespace).
  final bool hasIntroText;
  final List<MapEntry<String, String>> basicFields;
  final List<MapEntry<String, String>> incidentFields;
  final List<MapEntry<String, String>> documentFields;
  /// While this bubble's TTS is mid-utterance the table is held back so the
  /// user doesn't see the rows before the sentence above them is spoken.
  final bool isCurrentlySpeaking;
  final bool isLastBot;
  final bool botTyping;
  final bool confirming;
  final VoidCallback onConfirm;

  const FinalSummaryCard({
    super.key,
    required this.introVisibleText,
    required this.hasIntroText,
    required this.basicFields,
    required this.incidentFields,
    required this.documentFields,
    required this.isCurrentlySpeaking,
    required this.isLastBot,
    required this.botTyping,
    required this.confirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final maxCardWidth = MediaQuery.of(context).size.width * 0.86;
    final canConfirm =
        isLastBot && !confirming && !botTyping && !isCurrentlySpeaking;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BotAvatar(),
              const SizedBox(width: 10),
              if (hasIntroText)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: FormattedText(
                      text: introVisibleText,
                      baseStyle: const TextStyle(
                        fontSize: 14,
                        color: kVmDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (!isCurrentlySpeaking) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A6FDB), Color(0xFF1E5BC2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kVmBlue.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Review Your Claim',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ..._reviewRows(basicFields),
                      if (incidentFields.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _sectionHeader('INCIDENT DETAILS'),
                        const SizedBox(height: 10),
                        ..._reviewRows(incidentFields, multiline: true),
                      ],
                      if (documentFields.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _sectionHeader('DOCUMENTS'),
                        const SizedBox(height: 10),
                        ..._reviewRows(documentFields),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canConfirm ? onConfirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kVmBlue,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.7,
                            ),
                            disabledForegroundColor: kVmBlue.withValues(
                              alpha: 0.6,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: confirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(kVmBlue),
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)
                                      .chat_review_confirmSubmit,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  List<Widget> _reviewRows(
    List<MapEntry<String, String>> rows, {
    bool multiline = false,
  }) {
    return [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${r.key}:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  r.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                  textAlign: multiline ? TextAlign.left : TextAlign.right,
                  maxLines: multiline ? null : 2,
                  overflow: multiline
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
