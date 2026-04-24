import 'package:hive/hive.dart';
import 'package:claim_ai/features/chat/data/models/chat_message_model.dart';

abstract class ChatLocalDataSource {
  Future<void> cacheMessages(String claimId, List<ChatMessageModel> messages);
  Future<List<ChatMessageModel>> getCachedMessages(String claimId);
  Future<void> cacheMessage(String claimId, ChatMessageModel message);
  Future<void> clearCache([String? claimId]);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const _boxName = 'chat_messages_cache';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  @override
  Future<void> cacheMessages(
      String claimId, List<ChatMessageModel> messages) async {
    final box = await _openBox();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await box.put(claimId, {'messages': jsonList});
  }

  @override
  Future<List<ChatMessageModel>> getCachedMessages(String claimId) async {
    final box = await _openBox();
    final data = box.get(claimId);
    if (data == null) return [];
    final list = (data['messages'] as List?)
            ?.map((json) => ChatMessageModel.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList() ??
        [];
    return list;
  }

  @override
  Future<void> cacheMessage(String claimId, ChatMessageModel message) async {
    final existing = await getCachedMessages(claimId);
    existing.add(message);
    await cacheMessages(claimId, existing);
  }

  @override
  Future<void> clearCache([String? claimId]) async {
    final box = await _openBox();
    if (claimId != null) {
      await box.delete(claimId);
    } else {
      await box.clear();
    }
  }
}
