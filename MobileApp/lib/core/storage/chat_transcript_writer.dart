import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:claim_ai/core/privacy/sensitive_data_masker.dart';

class TranscriptMessage {
  final String role; // 'user' | 'bot'
  final String text;
  final DateTime timestamp;
  final String? messageType;
  final List<String>? triggers;
  final Map<String, dynamic>? claimData;

  const TranscriptMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.messageType,
    this.triggers,
    this.claimData,
  });
}

/// Writes per-thread chat transcripts to the app's documents directory as
/// JSON files. Any vehicle / VIN / policy identifiers are masked before the
/// transcript is persisted — the raw values never touch disk.
class ChatTranscriptWriter {
  static const _dirName = 'chat_transcripts';

  Future<File> _fileFor(String threadId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$threadId.json');
  }

  /// Rewrites the entire transcript for [threadId]. Safe to call after every
  /// turn; each write serialises the full message list.
  Future<File> writeTranscript({
    required String threadId,
    String? claimId,
    required List<TranscriptMessage> messages,
  }) async {
    final file = await _fileFor(threadId);

    final rawSensitiveValues = <String>{};
    for (final m in messages) {
      final cd = m.claimData;
      if (cd != null) {
        rawSensitiveValues.addAll(SensitiveDataMasker.extractSensitiveValues(cd));
      }
    }

    final jsonMessages = messages.map((m) {
      return <String, dynamic>{
        'role': m.role,
        'text': SensitiveDataMasker.maskText(m.text, rawSensitiveValues),
        'timestamp': m.timestamp.toIso8601String(),
        if (m.messageType != null && m.messageType!.isNotEmpty)
          'messageType': m.messageType,
        if (m.triggers != null && m.triggers!.isNotEmpty) 'triggers': m.triggers,
        if (m.claimData != null)
          'claimData': SensitiveDataMasker.maskClaimData(m.claimData!),
      };
    }).toList();

    final payload = <String, dynamic>{
      'threadId': threadId,
      'claimId': ?claimId,
      'updatedAt': DateTime.now().toIso8601String(),
      'messages': jsonMessages,
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }
}
