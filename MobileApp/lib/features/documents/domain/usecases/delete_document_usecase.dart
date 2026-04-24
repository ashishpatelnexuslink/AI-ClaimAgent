import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/documents/domain/repositories/documents_repository.dart';

class DeleteDocumentUseCase extends UseCase<void, String> {
  final DocumentsRepository repository;

  DeleteDocumentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(String documentId) {
    return repository.deleteDocument(documentId);
  }
}
