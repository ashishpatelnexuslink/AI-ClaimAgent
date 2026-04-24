import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';

abstract class DocumentsRepository {
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String claimId);

  Future<Either<Failure, DocumentEntity>> uploadDocument({
    required String claimId,
    required String filePath,
    required String fileName,
  });

  Future<Either<Failure, void>> deleteDocument(String documentId);

  Future<Either<Failure, DocumentEntity>> finalizeDocument(String documentId);

  Future<Either<Failure, List<DocumentTemplate>>> getTemplates();
}
