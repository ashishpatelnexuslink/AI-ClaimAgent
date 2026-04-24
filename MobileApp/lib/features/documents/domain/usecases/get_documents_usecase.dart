import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';
import 'package:claim_ai/features/documents/domain/repositories/documents_repository.dart';

class GetDocumentsUseCase extends UseCase<List<DocumentEntity>, String> {
  final DocumentsRepository repository;

  GetDocumentsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<DocumentEntity>>> call(String claimId) {
    return repository.getDocuments(claimId);
  }
}
