import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class ChatMessageEntity extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;
  final bool animate;
  final String? claimId;

  const ChatMessageEntity({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
    this.animate = false,
    this.claimId,
  });

  @override
  List<Object?> get props => [id, content, role, timestamp, isLoading, animate, claimId];
}
