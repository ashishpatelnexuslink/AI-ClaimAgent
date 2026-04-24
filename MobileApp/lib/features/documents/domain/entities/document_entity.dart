import 'package:equatable/equatable.dart';

enum DocumentStatus { pending, uploaded, finalized, rejected }

class DocumentEntity extends Equatable {
  final String id;
  final String name;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DocumentStatus status;
  final String? claimId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentEntity({
    required this.id,
    required this.name,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.status,
    this.claimId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props =>
      [id, name, fileUrl, fileType, fileSize, status, claimId, createdAt, updatedAt];
}

class DocumentTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  @override
  List<Object?> get props => [id, name, description, category];
}
