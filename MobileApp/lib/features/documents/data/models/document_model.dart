import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.name,
    required super.fileUrl,
    required super.fileType,
    required super.fileSize,
    required super.status,
    super.claimId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      status: _parseStatus(json['status'] as String),
      claimId: json['claimId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static DocumentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DocumentStatus.pending;
      case 'uploaded':
        return DocumentStatus.uploaded;
      case 'finalized':
        return DocumentStatus.finalized;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}

class DocumentTemplateModel extends DocumentTemplate {
  const DocumentTemplateModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
  });

  factory DocumentTemplateModel.fromJson(Map<String, dynamic> json) {
    return DocumentTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }
}
