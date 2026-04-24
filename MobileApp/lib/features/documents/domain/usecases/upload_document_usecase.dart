import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';
import 'package:claim_ai/features/documents/domain/repositories/documents_repository.dart';

class UploadDocumentUseCase extends UseCase<DocumentEntity, UploadDocumentParams> {
  final DocumentsRepository repository;

  UploadDocumentUseCase({required this.repository});

  @override
  Future<Either<Failure, DocumentEntity>> call(UploadDocumentParams params) {
    return repository.uploadDocument(
      claimId: params.claimId,
      filePath: params.filePath,
      fileName: params.fileName,
    );
  }
}

class UploadDocumentParams {
  final String claimId;
  final String filePath;
  final String fileName;

  const UploadDocumentParams({
    required this.claimId,
    required this.filePath,
    required this.fileName,
  });
}
